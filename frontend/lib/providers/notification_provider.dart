import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/config.dart';
import 'auth_provider.dart';

class NotificationProvider with ChangeNotifier {
  final AuthProvider authProvider;
  io.Socket? _socket;

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
      _initSocket();
      fetchNotifications();
    }
  }

  // Called via proxy provider update
  void update(AuthProvider auth) {
    if (auth.isAuthenticated && _socket == null) {
      _initSocket();
      fetchNotifications();
    } else if (!auth.isAuthenticated && _socket != null) {
      _socket?.dispose();
      _socket = null;
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
    }
  }

  void _initSocket() {
    final userId = authProvider.userId;
    if (userId == null) return;

    print('Initializing Notification Socket for user: $userId');

    // Build socket connection
    _socket = io.io(
      Constants.baseUrl.replaceAll('/api', ''),
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'userId': userId})
          .enableForceNew()
          .build(),
    );

    _socket!.onConnect((_) {
      print('✅ Connected to Notification Socket');
    });

    _socket!.onConnectError((data) {
      print('❌ Socket Connect Error: $data');
    });

    _socket!.onError((data) {
      print('❌ Socket Error: $data');
    });

    _socket!.on('notification', (data) {
      print('🔔 New real-time notification received: $data');
      _notifications.insert(0, data);
      _unreadCount++;
      notifyListeners();
    });

    _socket!.on('balanceUpdate', (data) {
      print('💰 Real-time balance update received: $data');
      final newBalance = (data['balance'] as num).toDouble();
      authProvider.updateBalance(newBalance);
    });

    _socket!.onDisconnect((_) {
      print('🔌 Disconnected from Notification Socket');
    });
  }

  Future<void> fetchNotifications() async {
    if (!authProvider.isAuthenticated) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print(
        '🌐 [NotificationProvider] Fetching from: ${Constants.baseUrl}/notifications',
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

      print('🌐 [NotificationProvider] Status: ${response.statusCode}');
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _notifications = data['data'];
        _unreadCount = _notifications.where((n) => n['seen'] == false).length;
        print(
          '✅ [NotificationProvider] Fetched ${_notifications.length} notifications',
        );
      } else {
        _errorMessage =
            data['message'] ?? 'Server error ${response.statusCode}';
        print('❌ [NotificationProvider] Fetch failed: $_errorMessage');
      }
    } on TimeoutException {
      _errorMessage = 'Connection timed out';
      print('❌ [NotificationProvider] Timeout');
    } catch (e) {
      _errorMessage = 'Failed to load notifications: $e';
      print('❌ [NotificationProvider] Error: $e');
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
      print('Error marking notification as seen: $e');
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
      print('Error marking all notifications as seen: $e');
    }
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }
}
