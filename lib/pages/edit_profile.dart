import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  final bool fromRegister;

  const EditProfilePage({super.key, this.fromRegister = false});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Form controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _barangayController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _socialLink1Controller = TextEditingController();
  final TextEditingController _socialLink2Controller = TextEditingController();

  @override
  void dispose() {
    // Dispose controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _streetController.dispose();
    _barangayController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _zipCodeController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _socialLink1Controller.dispose();
    _socialLink2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.fromRegister ? "Complete Profile" : "Edit Profile"),
        backgroundColor: Colors.red,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProfilePictureSection(),
            const SizedBox(height: 20),

            _buildSectionHeader("Personal Information"),
            _buildDoubleTextField("First Name", "Last Name", _firstNameController, _lastNameController),
            _buildSingleTextField("Street, House No.", _streetController),
            _buildDoubleTextField("Barangay", "City", _barangayController, _cityController),
            _buildDoubleTextField("Province", "Zip Code", _provinceController, _zipCodeController),

            _buildSectionHeader("Professional Information"),
            _buildSingleTextField("Title/Position", _titleController),
            _buildSingleTextField("Description/Bio", _bioController, maxLines: 3),

            _buildSectionHeader("Contact Information"),
            _buildDoubleTextField("Phone Number", "Email", _phoneController, _emailController),
            _buildSingleTextField("Website", _websiteController),

            _buildSectionHeader("Social Links"),
            _buildDoubleTextField("Social Link 1", "Social Link 2", _socialLink1Controller, _socialLink2Controller),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              icon: const Icon(Icons.check, color: Colors.white),
              label: Text(
                widget.fromRegister ? "Submit" : "Save Changes",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === Reusable UI Widgets ===

  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            const CircleAvatar(
              radius: 55,
              backgroundImage: NetworkImage("https://i.pravatar.cc/300"), // placeholder
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: _changeProfilePicture,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _changeProfilePicture,
          child: const Text(
            "Change Profile Picture",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
      ),
    );
  }

  Widget _buildSingleTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildDoubleTextField(
      String label1, String label2, TextEditingController controller1, TextEditingController controller2) {
    return Row(
      children: [
        Expanded(child: _buildSingleTextField(label1, controller1)),
        const SizedBox(width: 12),
        Expanded(child: _buildSingleTextField(label2, controller2)),
      ],
    );
  }

  // === Actions ===
  void _changeProfilePicture() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Profile Picture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.red),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement camera picker
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.red),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement gallery picker
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.fromRegister
            ? 'Profile submitted successfully!'
            : 'Profile saved successfully!'),
      ),
    );

    if (widget.fromRegister) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pop(context);
    }
  }
}
