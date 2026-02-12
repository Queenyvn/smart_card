import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../backend/backend.dart';

// CBOC Branding Colors
const Color cbocPrimary = Color(0xFFB71C1C);
const Color cbocSecondary = Color(0xFFD32F2F);
const Color cbocAccent = Color(0xFFFFCDD2);

class Business {
  final TextEditingController name;
  final TextEditingController desc;
  final TextEditingController address;
  final TextEditingController phone;
  final List<Uint8List> images;
  Uint8List? logoBytes;

  Business({
    required this.name,
    required this.desc,
    required this.address,
    required this.phone,
    List<Uint8List>? images,
    this.logoBytes,
  }) : images = images ?? [];

  bool get isEmpty =>
      name.text.isEmpty &&
      desc.text.isEmpty &&
      address.text.isEmpty &&
      phone.text.isEmpty &&
      images.isEmpty &&
      logoBytes == null;
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isSaving = false;
  Uint8List? profileImage;

  final nameController = TextEditingController();
  final roleController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  final List<Business> businesses = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    roleController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    for (final b in businesses) {
      b.name.dispose();
      b.desc.dispose();
      b.address.dispose();
      b.phone.dispose();
    }
    super.dispose();
  }

  /// ===============================
  /// LOAD USER PROFILE FROM BACKEND
  /// ===============================
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    final data = await BackendService.fetchUserProfile();

    if (data != null) {
      setState(() {
        nameController.text = data['username'] ?? '';
        emailController.text = data['email'] ?? '';
        phoneController.text = data['phone'] ?? '';
        addressController.text = data['address'] ?? '';
        roleController.text = data['userType'] ?? '';

        // Load businesses if they exist
        if (data['businesses'] != null && data['businesses'] is List) {
          businesses.clear();
          for (var b in data['businesses']) {
            businesses.add(
              Business(
                name: TextEditingController(text: b['name'] ?? ''),
                desc: TextEditingController(text: b['desc'] ?? ''),
                address: TextEditingController(text: b['address'] ?? ''),
                phone: TextEditingController(text: b['phone'] ?? ''),
              ),
            );
          }
        }
      });
    }

    setState(() => _isLoading = false);
  }

  /// ===============================
  /// SAVE PROFILE TO BACKEND
  /// ===============================
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    // Prepare businesses data
    final businessesData = businesses.map((b) {
      return {
        'name': b.name.text.trim(),
        'desc': b.desc.text.trim(),
        'address': b.address.text.trim(),
        'phone': b.phone.text.trim(),
        'logo': b.logoBytes,
      };
    }).toList();

    // Save to backend
    final result = await BackendService.saveUserProfile(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      address: addressController.text.trim(),
      location: null,
      businesses: businessesData,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: cbocPrimary,
        ),
      );
      Navigator.pop(context); // Go back after saving
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${result.message}'),
          backgroundColor: cbocSecondary,
        ),
      );
    }
  }

  /// ===============================
  /// IMAGE PICKERS
  /// ===============================
  Future<void> pickProfileImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        profileImage = bytes;
      });
    }
  }

  Future<void> addBusinessImage(Business business) async {
    if (business.images.length >= 5) return;
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        business.images.add(bytes);
      });
    }
  }

  Future<void> pickBusinessLogo(Business business) async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        business.logoBytes = bytes;
      });
    }
  }

  /// ===============================
  /// UI WIDGETS
  /// ===============================
  Widget businessLogo(Business business) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Business Logo",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => pickBusinessLogo(business),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
            child: business.logoBytes != null
                ? ClipOval(
                    child: Image.memory(
                      business.logoBytes!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.add_a_photo, size: 40),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget businessImages(Business business) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Business Images",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => addBusinessImage(business),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add_a_photo, size: 40),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget labeledField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    bool required = false,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? "$label (Required)" : label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(16),
            filled: readOnly,
            fillColor: readOnly ? Colors.grey[100] : null,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget businessSection(int index) {
    final business = businesses[index];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Business ${index + 1}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: cbocSecondary),
                  onPressed: () {
                    setState(() {
                      businesses.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            labeledField(label: "Business Name", controller: business.name),
            businessLogo(business),
            businessImages(business),
            labeledField(
                label: "Business Description",
                controller: business.desc,
                maxLines: 4),
            labeledField(
                label: "Business Address",
                controller: business.address,
                maxLines: 3),
            labeledField(
                label: "Business Contact Number", controller: business.phone),
          ],
        ),
      ),
    );
  }

  void cancelEdit() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Profile",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: cbocPrimary,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: cbocPrimary),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: cbocPrimary,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image
            Center(
              child: GestureDetector(
                onTap: pickProfileImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: profileImage != null
                          ? MemoryImage(profileImage!)
                          : const AssetImage("assets/profile.jpg")
                              as ImageProvider,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            /// PERSONAL INFO
            labeledField(
                label: "Name", controller: nameController, required: true),
            labeledField(label: "Role", controller: roleController),
            labeledField(
                label: "Personal Email",
                controller: emailController,
                readOnly: true),
            labeledField(
                label: "Personal Phone Number", controller: phoneController),
            labeledField(
                label: "Personal Address",
                controller: addressController,
                maxLines: 3),

            const SizedBox(height: 24),

            /// BUSINESSES SECTION
            const Text(
              "Businesses",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            for (int i = 0; i < businesses.length; i++) businessSection(i),

            // Add Business Button
            OutlinedButton.icon(
              icon: const Icon(Icons.add, color: cbocSecondary),
              label: const Text(
                "Add Business",
                style: TextStyle(color: cbocSecondary),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: cbocSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                setState(() {
                  businesses.add(
                    Business(
                      name: TextEditingController(),
                      desc: TextEditingController(),
                      address: TextEditingController(),
                      phone: TextEditingController(),
                    ),
                  );
                });
              },
            ),

            const SizedBox(height: 32),

            // Cancel and Save Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : cancelEdit,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: cbocSecondary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: cbocSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cbocAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "Save",
                            style: TextStyle(
                              fontSize: 16,
                              color: cbocSecondary,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}