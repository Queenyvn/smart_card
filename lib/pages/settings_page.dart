import 'package:flutter/material.dart';

// =========================================================
// THEME NOTIFIER
// Holds the current ThemeMode and notifies listeners on change.
// Wrap your MaterialApp with a ListenableBuilder (or use a
// state-management solution) and pass themeNotifier.value to
// MaterialApp.themeMode.
//
// Usage in main.dart:
//   ListenableBuilder(
//     listenable: themeNotifier,
//     builder: (context, _) => MaterialApp(
//       theme: ThemeData.light(),
//       darkTheme: ThemeData.dark(),
//       themeMode: themeNotifier.value,
//       ...
//     ),
//   );
// =========================================================
class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);
}

/// Global instance — import and reference wherever needed.
final themeNotifier = ThemeNotifier();

// =========================================================
// SETTINGS PAGE
// Top-level settings screen.
// =========================================================
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        elevation: 1,
      ),
      body: ListView(
        children: [
          // ── Account ─────────────────────────────────────────────────
          _buildSection(
            context,
            title: "Account",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountPage()),
            ),
          ),

          // ── Privacy & Security ───────────────────────────────────────
          _buildSection(
            context,
            title: "Privacy & Security",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacySecurityPage()),
            ),
          ),

          // ── Display (Dark Mode) ──────────────────────────────────────
          _buildSection(
            context,
            title: "Display",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DisplayPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// =========================================================
// ACCOUNT PAGE
// Contains: Change Password, Logout
// =========================================================
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account")),
      body: ListView(
        children: [
          // ── Change Password ─────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text("Change Password"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── Logout ──────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  // ── Logout Confirmation Dialog ────────────────────────────────────────
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // TODO: Firebase sign out logic
              Navigator.pop(context);
            },
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// CHANGE PASSWORD PAGE
// TODO: Wire up Firebase reauthentication + updatePassword
// =========================================================
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleChangePassword() {
    final current = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New passwords do not match.")),
      );
      return;
    }

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Password must be at least 6 characters.")),
      );
      return;
    }

    // TODO: Firebase reauthenticate then call user.updatePassword(newPass)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Current Password ────────────────────────────────────
            TextField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: "Current Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── New Password ────────────────────────────────────────
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: "New Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Confirm New Password ────────────────────────────────
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: "Confirm New Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Save Button ─────────────────────────────────────────
            ElevatedButton(
              onPressed: _handleChangePassword,
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// PRIVACY & SECURITY PAGE
// Contains: Manage Data / Privacy, Terms & Conditions,
//           Privacy Policy
// =========================================================
class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Privacy & Security")),
      body: ListView(
        children: [
          // ── Manage Data / Privacy ───────────────────────────────────
          ListTile(
            leading: const Icon(Icons.manage_accounts_outlined),
            title: const Text("Manage Data / Privacy"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageDataPage()),
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── Terms & Conditions ──────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text("Terms & Conditions"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to Terms & Conditions detail page / webview
            },
          ),

          // ── Privacy Policy ──────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text("Privacy Policy"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to Privacy Policy detail page / webview
            },
          ),
        ],
      ),
    );
  }
}

// =========================================================
// MANAGE DATA / PRIVACY PAGE
// Placeholder — add data management options here such as:
// - Download your data
// - Clear activity history
// - Data sharing preferences
// =========================================================
class ManageDataPage extends StatelessWidget {
  const ManageDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Data / Privacy")),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "Your privacy settings and data management options will appear here.",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

// =========================================================
// DISPLAY PAGE
// Lets the user switch between Device / Light / Dark mode.
// Updates the global [themeNotifier] which drives ThemeMode
// in MaterialApp — no restart required.
// =========================================================
class DisplayPage extends StatefulWidget {
  const DisplayPage({super.key});

  @override
  State<DisplayPage> createState() => _DisplayPageState();
}

class _DisplayPageState extends State<DisplayPage> {
  // Mirror the current global theme mode locally so radio tiles
  // reflect the live selection on first render.
  late String _selectedMode;

  @override
  void initState() {
    super.initState();
    // Convert ThemeMode → local string key
    switch (themeNotifier.value) {
      case ThemeMode.light:
        _selectedMode = "light";
        break;
      case ThemeMode.dark:
        _selectedMode = "dark";
        break;
      case ThemeMode.system:
      default:
        _selectedMode = "device";
    }
  }

  void _onModeChanged(String? value) {
    if (value == null) return;
    setState(() => _selectedMode = value);

    // Apply the selected mode globally via the notifier
    switch (value) {
      case "light":
        themeNotifier.value = ThemeMode.light;
        break;
      case "dark":
        themeNotifier.value = ThemeMode.dark;
        break;
      case "device":
      default:
        themeNotifier.value = ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Display")),
      body: Column(
        children: [
          _radioTile("Device Setting", "device"),
          _radioTile("Light Mode", "light"),
          _radioTile("Dark Mode", "dark"),
        ],
      ),
    );
  }

  Widget _radioTile(String title, String value) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: _selectedMode,
      onChanged: _onModeChanged,
    );
  }
}