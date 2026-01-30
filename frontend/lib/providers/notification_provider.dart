import 'package:flutter/material.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/config.dart';
import 'auth_provider.dart';

class NotificationProvider with ChangeNotifier {
  final AuthProvider authProvider;
  PusherChannelsClient? _pusher;
  StreamSubscription? _eventSubscription;
  StreamSubscription? _connectionSubscription;

  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  NotificationProvider(this.authProvider) {
    _init();
  }

  void _init() {
    if (authProvider.isAuthenticated) {
      fetchNotifications();
      _initPusher();
    }
  }

  void update(AuthProvider auth) {
    if (auth.isAuthenticated) {
      if (_pusher == null) {
        _initPusher();
      }
    } else {
      _disconnectPusher();
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
    }
  }

  Future<void> _initPusher() async {
    final userId = authProvider.userId;
    if (userId == null || !authProvider.isAuthenticated) return;
    if (_pusher != null) return;

    try {
      debugPrint('Initializing Dart Pusher for user: $userId');

      final options = PusherChannelsOptions.fromCluster(
        scheme: 'wss',
        cluster: Constants.pusherCluster,
        key: Constants.pusherKey,
        port: 443,
      );

      _pusher = PusherChannelsClient.websocket(
        options: options,
        connectionErrorHandler: (error, trace, refresh) {
          debugPrint("Pusher Connection Error: $error");
          refresh();
        },
      );

      // Listen to connection changes via event stream
      _connectionSubscription = _pusher!.eventStream.listen((event) {
        if (event.name == 'pusher:connection_established') {
          debugPrint("Pusher Connected");
          _subscribeToPrivateChannel(userId);
        }
      });

      await _pusher?.connect();
      debugPrint("Pusher Connecting...");
    } catch (e) {
      debugPrint("Error initializing Pusher: $e");
    }
  }

  void _subscribeToPrivateChannel(String userId) {
    if (_pusher == null) return;

    final channelName = "private-user-$userId";

    // Custom Authorizer Delegate

    final privateChannel = _pusher!.privateChannel(
      channelName,
      authorizationDelegate:
          EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
            authorizationEndpoint: Uri.parse(
              "${Constants.baseUrl}/pusher/auth",
            ),
            headers: {
              'Authorization': 'Bearer ${authProvider.token}',
              'Content-Type': 'application/json',
            },
          ),
    );

    debugPrint("Subscribing to $channelName");
    privateChannel.subscribe();

    _eventSubscription = privateChannel.bind('notification').listen((event) {
      debugPrint('📢 [Pusher] Event: ${event.name} | Data: [MASKED]');
      if (event.data != null) {
        try {
          final data = json.decode(event.data!);
          debugPrint('🔔 [Pusher] ✅ Notification Received');
          _notifications.insert(0, data);
          _unreadCount++;
          notifyListeners();
        } catch (e) {
          debugPrint("Error parsing notification data: $e");
        }
      }
    });

    // Also log balance updates
    privateChannel.bind('balanceUpdate').listen((event) {
      debugPrint('💰 [Pusher] Balance Update received');
      if (event.data != null) {
        try {
          final data = json.decode(event.data!);
          final newBalance = (data['balance'] as num).toDouble();
          authProvider.updateBalance(newBalance);
        } catch (e) {
          debugPrint("Error parsing balance data: $e");
        }
      }
    });
  }

  void _disconnectPusher() {
    _eventSubscription?.cancel();
    _connectionSubscription?.cancel();
    _pusher?.disconnect();
    _pusher?.dispose();
    _pusher = null;
    debugPrint("Pusher Disconnected");
  }

  Future<void> fetchNotifications() async {
    if (!authProvider.isAuthenticated) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint(
        '🌐 [NotificationProvider] Fetching notifications from server...',
      );
      final response = await http
          .get(
            Uri.parse('${Constants.baseUrl}/notifications'),
            headers: {
              'Authorization': 'Bearer ${authProvider.token}',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _notifications = data['data'];
        _unreadCount = _notifications.where((n) => n['seen'] == false).length;
        debugPrint(
          '✅ [NotificationProvider] Fetched ${_notifications.length} notifications',
        );
      } else {
        _errorMessage =
            data['message'] ?? 'Server error ${response.statusCode}';
      }
    } on TimeoutException {
      _errorMessage = 'Connection timed out';
    } catch (e) {
      _errorMessage = 'Failed to load notifications: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsSeen(String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/notifications/$notificationId/seen'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );
      if (response.statusCode == 200) {
        final index = _notifications.indexWhere(
          (n) => n['_id'] == notificationId,
        );
        if (index != -1) {
          _notifications[index]['seen'] = true;
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error marking notification as seen: $e');
    }
  }

  Future<void> markAllAsSeen() async {
    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/notifications/mark-all-seen'),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        for (var n in _notifications) {
          n['seen'] = true;
        }
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking all notifications as seen: $e');
    }
  }

  @override
  void dispose() {
    _disconnectPusher();
    super.dispose();
  }
}
