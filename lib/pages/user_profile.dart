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
  final TextEditingController locationLink;
  final List<Uint8List> images;

  Business({
    required this.name,
    required this.desc,
    required this.address,
    required this.phone,
    required this.locationLink,
    List<Uint8List>? images,
  }) : images = images ?? [];

  bool get isEmpty =>
      name.text.isEmpty &&
      desc.text.isEmpty &&
      address.text.isEmpty &&
      phone.text.isEmpty &&
      locationLink.text.isEmpty &&
      images.isEmpty;
}

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final ImagePicker _picker = ImagePicker();

  bool isEditing = false;
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
      b.locationLink.dispose();
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
        nameController.text = data['name'] ?? '';
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
                locationLink: TextEditingController(text: b['locationLink'] ?? ''),
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
        'locationLink': b.locationLink.text.trim(),
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
        SnackBar(
          content: const Text('Profile saved successfully!'),
          backgroundColor: Colors.green[700],
        ),
      );
      setState(() {
        isEditing = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${result.message}'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  /// ===============================
  /// IMAGE PICKERS
  /// ===============================
  Future<void> pickProfileImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
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

  /// ===============================
  /// UI WIDGETS
  /// ===============================
  Widget businessImages(Business business) {
    if (!isEditing && business.images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Business Images",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < business.images.length; i++)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      business.images[i],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (isEditing)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: Colors.red,
                        onPressed: () {
                          setState(() {
                            business.images.removeAt(i);
                          });
                        },
                      ),
                    ),
                ],
              ),
            if (isEditing && business.images.length < 5)
              GestureDetector(
                onTap: () => addBusinessImage(business),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_a_photo),
                ),
              ),
          ],
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
    if (!isEditing && controller.text.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? "$label (Required)" : label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        isEditing
            ? TextField(
                controller: controller,
                maxLines: maxLines,
                readOnly: readOnly,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  filled: readOnly,
                  fillColor: readOnly ? Colors.grey[100] : null,
                ),
              )
            : Text(
                controller.text,
                style: const TextStyle(fontSize: 16),
              ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget businessSection(int index) {
    final business = businesses[index];
    if (!isEditing && business.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Business ${index + 1}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        businesses.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            labeledField(label: "Business Name", controller: business.name),
            businessImages(business),
            labeledField(label: "Business Description", controller: business.desc, maxLines: 3),
            labeledField(label: "Business Address", controller: business.address, maxLines: 2),
            labeledField(label: "Business Location Link", controller: business.locationLink),
            labeledField(label: "Business Contact Number", controller: business.phone),
          ],
        ),
      ),
    );
  }

  void cancelEdit() {
    _loadUserProfile();
    setState(() {
      isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Profile"),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: isEditing ? pickProfileImage : null,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundImage: profileImage != null
                          ? MemoryImage(profileImage!)
                          : const AssetImage("assets/profile.jpg") as ImageProvider,
                    ),
                    if (isEditing)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            /// PERSONAL INFO
            labeledField(label: "Name", controller: nameController, required: true),
            labeledField(label: "Role", controller: roleController),
            labeledField(label: "Personal Email", controller: emailController, readOnly: true),
            labeledField(label: "Personal Phone Number", controller: phoneController),
            labeledField(label: "Personal Address", controller: addressController, maxLines: 2),

            const SizedBox(height: 16),

            /// BUSINESSES
            Text(
              "Businesses",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < businesses.length; i++) businessSection(i),

            if (isEditing)
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Business"),
                onPressed: () {
                  setState(() {
                    businesses.add(
                      Business(
                        name: TextEditingController(),
                        desc: TextEditingController(),
                        address: TextEditingController(),
                        phone: TextEditingController(),
                        locationLink: TextEditingController(),
                      ),
                    );
                  });
                },
              ),

            if (isEditing) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : cancelEdit,
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text("Save"),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}