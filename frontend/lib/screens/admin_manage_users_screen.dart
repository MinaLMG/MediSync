import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../utils/config.dart';
import '../utils/search_utils.dart';
import '../utils/ui_utils.dart';
import '../l10n/generated/app_localizations.dart';

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<dynamic> _waitingUsers = [];
  List<dynamic> _activeUsers = [];
  String _searchQuery = '';
  final Set<String> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _fetchUsers();
        setState(() {
          _selectedUserIds.clear();
        });
      }
    });
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final url = _tabController.index == 0
        ? '${Constants.baseUrl}/admin/waiting-users'
        : '${Constants.baseUrl}/admin/active-users';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          if (_tabController.index == 0)
            _waitingUsers = data['data'];
          else
            _activeUsers = data['data'];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredActiveUsers = _activeUsers.where((u) {
      return SearchUtils.matches(u['name'], _searchQuery) ||
          SearchUtils.matches(u['email'], _searchQuery) ||
          SearchUtils.matches(u['phone'], _searchQuery) ||
          SearchUtils.matches(u['pharmacy']?['name'], _searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manageUsersTitle),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchUsers),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.tabNewRequests),
            Tab(text: AppLocalizations.of(context)!.tabActiveUsers),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchUsersHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          if (_tabController.index == 1 && filteredActiveUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Checkbox(
                    value: _selectedUserIds.isNotEmpty &&
                        filteredActiveUsers.every((u) => _selectedUserIds.contains(u['_id'])),
                    onChanged: (bool? checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedUserIds.addAll(filteredActiveUsers.map((u) => u['_id'] as String));
                        } else {
                          for (var u in filteredActiveUsers) {
                            _selectedUserIds.remove(u['_id']);
                          }
                        }
                      });
                    },
                  ),
                  const Text('Select All'),
                  const Spacer(),
                  if (_selectedUserIds.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.clear_all, size: 18),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      label: Text('Clear (${_selectedUserIds.length})'),
                      onPressed: () {
                        setState(() {
                          _selectedUserIds.clear();
                        });
                      },
                    ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(_waitingUsers, isWaiting: true),
                _buildUserList(_activeUsers, isWaiting: false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _showCreateDeliveryDialog,
              child: const Icon(Icons.add),
              tooltip: AppLocalizations.of(
                context,
              )!.dialogCreateDeliveryAccount,
            )
          : FloatingActionButton(
              onPressed: _showSendNotificationDialog,
              child: const Icon(Icons.send),
              tooltip: 'Send Custom Notification',
            ),
    );
  }

  Widget _buildUserList(List<dynamic> users, {required bool isWaiting}) {
    if (_isLoading && users.isEmpty)
      return const Center(child: CircularProgressIndicator());

    final filteredUsers = users.where((u) {
      return SearchUtils.matches(u['name'], _searchQuery) ||
          SearchUtils.matches(u['email'], _searchQuery) ||
          SearchUtils.matches(u['phone'], _searchQuery) ||
          SearchUtils.matches(u['pharmacy']?['name'], _searchQuery);
    }).toList();

    if (filteredUsers.isEmpty && !_isLoading) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? AppLocalizations.of(context)!.noUsersFound
              : AppLocalizations.of(context)!.noMatchesFound,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchUsers,
      child: ListView.builder(
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          final pharmacy = user['pharmacy'];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: !isWaiting
                  ? Checkbox(
                      value: _selectedUserIds.contains(user['_id']),
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedUserIds.add(user['_id']);
                          } else {
                            _selectedUserIds.remove(user['_id']);
                          }
                        });
                      },
                    )
                  : null,
              title: Text(user['name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['email']),
                  InkWell(
                    onTap: pharmacy != null
                        ? () => UIUtils.showPharmacyInfo(context, pharmacy)
                        : null,
                    child: Text(
                      pharmacy?['name'] ??
                          AppLocalizations.of(context)!.noPharmacyLinked,
                      style: TextStyle(
                        color: pharmacy != null ? Colors.blue : Colors.grey,
                        fontWeight: pharmacy != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: isWaiting
                  ? const Icon(Icons.pending_actions, color: Colors.orange)
                  : const Icon(Icons.check_circle, color: Colors.green),
              onTap: () => _showUserDetails(user, isWaiting),
            ),
          );
        },
      ),
    );
  }

  void _showUserDetails(dynamic user, bool isWaiting) {
    final pharmacy = user['pharmacy'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                AppLocalizations.of(context)!.userInformation,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.labelName),
                subtitle: Text(user['name']),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.labelPhone),
                subtitle: Text(user['phone']),
              ),
              if (pharmacy != null) ...[
                const Divider(),
                Text(
                  AppLocalizations.of(context)!.pharmacyDocumentation,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.labelPharmacyName),
                  subtitle: Text(pharmacy['name']),
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.labelOwnerName),
                  subtitle: Text(pharmacy['ownerName']),
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.labelNationalId),
                  subtitle: Text(pharmacy['nationalId']),
                ),
                ListTile(
                  title: Text(
                    AppLocalizations.of(context)!.labelPharmacyAddress,
                  ),
                  subtitle: Text(pharmacy['address'] ?? 'N/A'),
                ),
                _buildImageSection(
                  AppLocalizations.of(context)!.labelPharmacistCard,
                  pharmacy['pharmacistCard'],
                ),
                _buildImageSection(
                  AppLocalizations.of(context)!.labelCommercialRegistry,
                  pharmacy['commercialRegistry'],
                ),
                _buildImageSection(
                  AppLocalizations.of(context)!.labelTaxCard,
                  pharmacy['taxCard'],
                ),
                _buildImageSection(
                  AppLocalizations.of(context)!.labelLicense,
                  pharmacy['pharmacyLicense'],
                ),
              ],
              if (isWaiting) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                          disabledForegroundColor: Colors.white,
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => _confirmAction(
                                title: AppLocalizations.of(
                                  context,
                                )!.dialogRejectRequest,
                                message: AppLocalizations.of(
                                  context,
                                )!.dialogRejectMessage,
                                onConfirm: () async {
                                  final res = await _reviewUser(
                                    user['_id'],
                                    'rejected',
                                  );
                                  if (res && mounted) setSheetState(() {});
                                },
                              ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(AppLocalizations.of(context)!.actionReject),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                          disabledForegroundColor: Colors.white,
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => _confirmAction(
                                title: AppLocalizations.of(
                                  context,
                                )!.dialogApproveUser,
                                message: AppLocalizations.of(
                                  context,
                                )!.dialogApproveMessage,
                                onConfirm: () async {
                                  final res = await _reviewUser(
                                    user['_id'],
                                    'active',
                                  );
                                  if (res && mounted) setSheetState(() {});
                                },
                              ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(AppLocalizations.of(context)!.actionApprove),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.managementActions,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(
                          user['status'] == 'suspended'
                              ? Icons.play_arrow
                              : Icons.block,
                        ),
                        label: Text(
                          user['status'] == 'suspended'
                              ? AppLocalizations.of(context)!.actionActivate
                              : AppLocalizations.of(context)!.actionSuspend,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: user['status'] == 'suspended'
                              ? Colors.green
                              : Colors.orange,
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => _confirmAction(
                                title: user['status'] == 'suspended'
                                    ? AppLocalizations.of(
                                        context,
                                      )!.dialogActivateUser
                                    : AppLocalizations.of(
                                        context,
                                      )!.dialogSuspendUser,
                                message: user['status'] == 'suspended'
                                    ? AppLocalizations.of(
                                        context,
                                      )!.dialogActivateUserMessage
                                    : AppLocalizations.of(
                                        context,
                                      )!.dialogSuspendUserMessage,
                                onConfirm: () async {
                                  await _adminAction(user['_id'], 'suspend');
                                  if (mounted) setSheetState(() {});
                                },
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.password),
                        label: Text(
                          AppLocalizations.of(context)!.actionResetPass,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => _confirmAction(
                                title: AppLocalizations.of(
                                  context,
                                )!.dialogResetPassword,
                                message: AppLocalizations.of(
                                  context,
                                )!.dialogResetPasswordMessage,
                                onConfirm: () async {
                                  await _adminAction(
                                    user['_id'],
                                    'reset-password',
                                  );
                                  if (mounted) setSheetState(() {});
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmAction({
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.actionCancel),
            ),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setDialogState(() => _isLoading = true);
                      await onConfirm();
                      setDialogState(() => _isLoading = false);
                      if (mounted) Navigator.pop(context);
                    },
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      AppLocalizations.of(context)!.actionConfirm,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _adminAction(String userId, String action) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final url = action == 'suspend'
        ? '${Constants.baseUrl}/admin/suspend-user/$userId'
        : '${Constants.baseUrl}/admin/reset-password/$userId';

    setState(() => _isLoading = true);
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      if (data['success']) {
        _fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? AppLocalizations.of(context)!.actionSuccessful,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateDeliveryDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.dialogCreateDeliveryAccount),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.labelName,
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? AppLocalizations.of(context)!.errorRequired
                      : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.labelEmail,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty
                      ? AppLocalizations.of(context)!.errorRequired
                      : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.labelPhone,
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty
                      ? AppLocalizations.of(context)!.errorRequired
                      : null,
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.labelPassword,
                  ),
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6
                      ? AppLocalizations.of(context)!.errorMin6Chars
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.actionCancel),
          ),
          StatefulBuilder(
            builder: (context, setState) => ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => _isLoading = true);
                        final token = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        ).token;
                        try {
                          final response = await http.post(
                            Uri.parse(
                              '${Constants.baseUrl}/admin/create-delivery',
                            ),
                            headers: {
                              'Content-Type': 'application/json',
                              'Authorization': 'Bearer $token',
                            },
                            body: json.encode({
                              'name': nameController.text,
                              'email': emailController.text,
                              'phone': phoneController.text,
                              'password': passwordController.text,
                            }),
                          );
                          final data = json.decode(response.body);
                          if (data['success']) {
                            Navigator.pop(context);
                            _fetchUsers();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.msgDeliveryUserCreated,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  data['message'] ??
                                      AppLocalizations.of(
                                        context,
                                      )!.msgFailedCreateUser,
                                ),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      }
                    },
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(AppLocalizations.of(context)!.actionCreate),
              style: _isLoading
                  ? ElevatedButton.styleFrom(
                      disabledBackgroundColor: Colors.grey,
                      disabledForegroundColor: Colors.white,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(String label, String? url) {
    String? fullUrl = url;
    if (url != null && !url.startsWith('http')) {
      final cleanPath = url.replaceAll('\\', '/');
      fullUrl = '${Constants.baseUrl.replaceAll('/api', '')}/$cleanPath';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        GestureDetector(
          onTap: fullUrl != null
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImage(imageUrl: fullUrl!),
                    ),
                  );
                }
              : null,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: fullUrl != null && fullUrl.startsWith('http')
                ? Hero(
                    tag: fullUrl,
                    child: Image.network(
                      fullUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          AppLocalizations.of(context)!.errorLoadingImage,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      AppLocalizations.of(context)!.noImage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<bool> _reviewUser(String id, String status) async {
    bool success = false;
    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/admin/review-user/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );
      if (json.decode(response.body)['success']) {
        _fetchUsers();
        success = true;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    return success;
  }

  void _showSendNotificationDialog() {
    final messageController = TextEditingController();
    final messageArController = TextEditingController();
    String selectedTarget = _selectedUserIds.isNotEmpty ? 'selected' : 'all';
    final formKey = GlobalKey<FormState>();
    bool isDialogLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Send Push Notification'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedUserIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Target: ${_selectedUserIds.length} selected users.',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    )
                  else ...[
                    const Text('Target Group:'),
                    DropdownButton<String>(
                      value: selectedTarget,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Active Users')),
                        DropdownMenuItem(value: 'pharmacies', child: Text('Pharmacy Owners & Managers')),
                        DropdownMenuItem(value: 'delivery', child: Text('Delivery Users')),
                        DropdownMenuItem(value: 'hubs', child: Text('Hub Pharmacies')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedTarget = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message (English)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (v) => v == null || v.isEmpty ? 'Message is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: messageArController,
                    decoration: const InputDecoration(
                      labelText: 'Message (Arabic - Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isDialogLoading ? null : () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.actionCancel),
            ),
            ElevatedButton(
              onPressed: isDialogLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() => isDialogLoading = true);
                        final token = Provider.of<AuthProvider>(context, listen: false).token;
                        
                        final Map<String, dynamic> body = {
                          'message': messageController.text,
                          'messageAr': messageArController.text.isNotEmpty ? messageArController.text : null,
                        };

                        if (_selectedUserIds.isNotEmpty) {
                          body['userIds'] = _selectedUserIds.toList();
                        } else {
                          body['targetGroup'] = selectedTarget;
                        }

                        try {
                          final response = await http.post(
                            Uri.parse('${Constants.baseUrl}/admin/send-custom-notification'),
                            headers: {
                              'Content-Type': 'application/json',
                              'Authorization': 'Bearer $token',
                            },
                            body: json.encode(body),
                          );

                          final data = json.decode(response.body);
                          if (data['success']) {
                            if (mounted) {
                              Navigator.pop(context);
                              setState(() {
                                _selectedUserIds.clear();
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(data['message'] ?? 'Notification sent successfully.')),
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(data['message'] ?? 'Failed to send notification.')),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        } finally {
                          setDialogState(() => isDialogLoading = false);
                        }
                      }
                    },
              child: isDialogLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: imageUrl,
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
      ),
    );
  }
}
