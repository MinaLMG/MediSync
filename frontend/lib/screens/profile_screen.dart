import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'login_screen.dart';
import 'account_details_screen.dart';
import 'help_screen.dart';
import 'subscription_screen.dart';
import 'change_password_screen.dart';
import '../l10n/generated/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navAccount),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 50, color: Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?['name'] ?? l10n.labelUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?['email'] ?? l10n.labelUserEmailPlaceholder,
                    style: TextStyle(color: Colors.blue[100], fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Language Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                child: Consumer<SettingsProvider>(
                  builder: (context, settings, _) {
                    return ListTile(
                      leading: const Icon(Icons.language, color: Colors.blue),
                      title: Text(l10n.labelAppLanguage),
                      trailing: DropdownButton<String>(
                        value: settings.locale.languageCode,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            settings.setLocale(Locale(newValue));
                            // Also update backend preference if logged in
                            final auth = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            if (auth.isAuthenticated) {
                              auth.updateLanguage(newValue);
                            }
                          }
                        },
                        items: [
                          DropdownMenuItem(
                            value: 'en',
                            child: Text(l10n.labelEnglish),
                          ),
                          DropdownMenuItem(
                            value: 'ar',
                            child: Text(l10n.labelArabic),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Menu Items
            _buildMenuItem(
              context: context,
              icon: Icons.account_circle_outlined,
              title: l10n.menuMyAccount,
              subtitle: l10n.subtitleMyAccount,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountDetailsScreen(),
                ),
              ),
            ),

            _buildMenuItem(
              context: context,
              icon: Icons.help_outline,
              title: l10n.menuHelp,
              subtitle: l10n.subtitleHelp,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              ),
            ),

            _buildMenuItem(
              context: context,
              icon: Icons.card_membership_outlined,
              title: l10n.titleSubscriptionPlans,
              subtitle: l10n.subtitleSubscription,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(),
                ),
              ),
            ),

            _buildMenuItem(
              context: context,
              icon: Icons.lock_reset_outlined,
              title: l10n.menuResetPassword,
              subtitle: l10n.subtitleResetPassword,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              ),
            ),

            const Divider(height: 32, indent: 20, endIndent: 20),

            _buildMenuItem(
              context: context,
              icon: Icons.logout,
              title: l10n.actionLogout,
              titleColor: Colors.red[700],
              iconColor: Colors.red[700],
              showArrow: false,
              onTap: () => _showLogoutDialog(context, authProvider),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
    bool showArrow = true,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.blue[800]!).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? Colors.blue[800]),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: titleColor),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing: showArrow ? const Icon(Icons.chevron_right, size: 20) : null,
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.actionLogout),
        content: Text(l10n.dialogLogoutMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () {
              authProvider.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(
              l10n.actionLogout,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
