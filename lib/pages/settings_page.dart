import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView(
        children: [
          _buildSection(
            context,
            title: "Account Preference",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountPreferencePage()),
              );
            },
          ),
          _buildSection(context, title: "Notifications"),
          _buildSection(
            context,
            title: "Terms and Privacy Policy",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TermsPrivacyPage(),
                ),
              );
            },
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

class AccountPreferencePage extends StatelessWidget {
  const AccountPreferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account Preference"),
      ),
      body: ListView(
        children: [
          _sectionHeader("Account Preference"),

          _item(
            context,
            "Profile Information",
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DigitalCardInfoPage(),
              ),
            ),
          ),

          _item(
            context,
            "Display",
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DisplayPage()),
            ),
          ),

          _item(
            context,
            "General Preferences",
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GeneralPreferencePage()),
            ),
          ),

          _item(
            context,
            "Account Management",
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountManagementPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _item(BuildContext context, String title, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class DisplayPage extends StatefulWidget {
  const DisplayPage({super.key});

  @override
  State<DisplayPage> createState() => _DisplayPageState();
}

class _DisplayPageState extends State<DisplayPage> {
  String selectedMode = "device";

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
      groupValue: selectedMode,
      onChanged: (val) {
        setState(() {
          selectedMode = val!;
        });
      },
    );
  }
}

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String selectedLanguage = "English";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Language")),
      body: Column(
        children: [
          RadioListTile(
            title: const Text("English"),
            value: "English",
            groupValue: selectedLanguage,
            onChanged: (value) {
              setState(() => selectedLanguage = value!);
            },
          ),
          RadioListTile(
            title: const Text("Filipino"),
            value: "Filipino",
            groupValue: selectedLanguage,
            onChanged: (value) {
              setState(() => selectedLanguage = value!);
            },
          ),
        ],
      ),
    );
  }
}

class AccountManagementPage extends StatelessWidget {
  const AccountManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account Management")),
      body: ListTile(
        title: const Text(
          "Delete Account",
          style: TextStyle(color: Colors.red),
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Delete Account"),
              content: const Text(
                "Are you sure you want to delete your account?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Firebase delete logic
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TermsPrivacyPage extends StatelessWidget {
  const TermsPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms and Privacy Policy"),
      ),
      body: ListView(
        children: [
          _item(context, "Help Center"),
          _item(context, "Professional Community Policies"),
          _item(context, "Recommendations Transparency"),
          _item(context, "User Agreement"),
          _item(context, "End User License Agreement"),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, String title) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Navigate to detail page / webview
      },
    );
  }
}

class DigitalCardInfoPage extends StatelessWidget {
  const DigitalCardInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Digital Card Information"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _InfoField(label: "Company Name"),
            _InfoField(label: "Company Number"),
            _InfoField(label: "Email"),
            _InfoField(label: "Website"),
            _InfoField(label: "Services"),
            SizedBox(height: 20),
            Text(
              "Edit your card details from your profile.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;

  const _InfoField({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class GeneralPreferencePage extends StatelessWidget {
  const GeneralPreferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("General Preferences"),
      ),
      body: ListView(
        children: [
          _item(
            context,
            "Language",
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LanguagePage()),
            ),
          ),
          _item(
            context,
            "Show Profile Photos",
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ShowProfilePhotosPage(),
              ),
            ),
          ),
          _item(
            context,
            "People you blocked",
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BlockedPeoplePage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, String title, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class ShowProfilePhotosPage extends StatefulWidget {
  const ShowProfilePhotosPage({super.key});

  @override
  State<ShowProfilePhotosPage> createState() => _ShowProfilePhotosPageState();
}

class _ShowProfilePhotosPageState extends State<ShowProfilePhotosPage> {
  String selectedOption = "connections";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Show Profile Photos")),
      body: Column(
        children: [
          _radio("No one", "none"),
          _radio("Your connections", "connections"),
          _radio("All CBOC Members", "all"),
        ],
      ),
    );
  }

  Widget _radio(String title, String value) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: selectedOption,
      onChanged: (val) {
        setState(() => selectedOption = val!);
      },
    );
  }
}

class BlockedPeoplePage extends StatelessWidget {
  const BlockedPeoplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Blocked People")),
      body: ListView(
        children: const [
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text("Unknown"),
            subtitle: Text("+639562145287"),
          ),
        ],
      ),
    );
  }
}
