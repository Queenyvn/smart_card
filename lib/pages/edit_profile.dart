import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../backend/backend.dart';

const Color cbocPrimary = Color(0xFFB71C1C);

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
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  bool isEditing = true;
  bool _isSaving = false;
  Uint8List? profileImageBytes;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final List<Business> businesses = [];

  LatLng? _pinnedLocation;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    for (var b in businesses) {
      b.name.dispose();
      b.desc.dispose();
      b.address.dispose();
      b.phone.dispose();
    }
    super.dispose();
  }

  /// ===============================
  /// LOAD USER PROFILE
  /// ===============================
  Future<void> _loadUserProfile() async {
    final data = await BackendService.fetchUserProfile(); // CHANGED
    if (data == null) return;

    setState(() {
      _nameController.text = data['name'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _addressController.text = data['address'] ?? '';

      if (data['location'] != null) {
        _pinnedLocation = LatLng(
          data['location']['lat'],
          data['location']['lng'],
        );
      }

      if (data['businesses'] != null) {
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


  /// ===============================
  /// PICK PROFILE IMAGE
  /// ===============================
  Future<void> pickProfileImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => profileImageBytes = bytes);
    }
  }

  /// ===============================
  /// PICK BUSINESS IMAGE
  /// ===============================
  Future<void> addBusinessImage(Business business) async {
    if (business.images.length >= 5) return;
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => business.images.add(bytes));
    }
  }

  Widget businessImages(Business business) {
    if (!isEditing && business.images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Business Images", style: TextStyle(fontWeight: FontWeight.w600)),
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
                          setState(() => business.images.removeAt(i));
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

  /// ========================================================
  /// BUSINESS LOGO
  /// ========================================================
  Future<void> pickBusinessLogo(Business business) async {
  final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
  if (file != null) {
    final bytes = await file.readAsBytes();
    setState(() => business.logoBytes = bytes);
  }
}

  /// ===============================
  /// SAVE PROFILE
  /// ===============================
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final businessesData = businesses.map((b) {
      return {
        'name': b.name.text.trim(),
        'desc': b.desc.text.trim(),
        'address': b.address.text.trim(),
        'phone': b.phone.text.trim(),
        'logo': b.logoBytes != null ? b.logoBytes : null,
      };
    }).toList();

    final result = await BackendService.saveUserProfile(
      name: _nameController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      location: _pinnedLocation == null
          ? null
          : {'lat': _pinnedLocation!.latitude, 'lng': _pinnedLocation!.longitude},
      businesses: businessesData,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.success ? 'Profile updated successfully' : result.message ?? 'Error')),
      );
    }
  }


  /// ===============================
  /// MAP SECTION
  /// ===============================
  Widget _buildMapSection() {
    return SizedBox(
      height: 250,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _pinnedLocation ?? const LatLng(14.4748, 120.9240),
          zoom: 15,
        ),
        mapType: MapType.normal,
        markers: _pinnedLocation == null
            ? {}
            : {
                Marker(
                  markerId: const MarkerId('business_location'),
                  position: _pinnedLocation!,
                  draggable: true,
                  onDragEnd: (pos) => setState(() => _pinnedLocation = pos),
                ),
              },
        onTap: (pos) => setState(() => _pinnedLocation = pos),
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
      ),
    );
  }

  Widget labeledField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(required ? "$label (Required)" : label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget businessSection(int index) {
    final business = businesses[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("Business ${index + 1}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => businesses.removeAt(index)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            labeledField(label: "Business Name", controller: business.name),
            businessImages(business),
            // Business Logo Picker
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Business Logo", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => pickBusinessLogo(business),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundImage: business.logoBytes != null
                        ? MemoryImage(business.logoBytes!)
                        : const AssetImage("assets/logo_placeholder.png") as ImageProvider,
                    child: business.logoBytes == null
                        ? const Icon(Icons.add_a_photo, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            labeledField(label: "Business Description", controller: business.desc, maxLines: 3),
            labeledField(label: "Business Address", controller: business.address, maxLines: 2),
            labeledField(label: "Business Phone", controller: business.phone),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cbocPrimary,
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: GestureDetector(
                  onTap: pickProfileImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundImage: profileImageBytes != null
                            ? MemoryImage(profileImageBytes!)
                            : const AssetImage("assets/profile.jpg") as ImageProvider,
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              labeledField(label: "Full Name", controller: _nameController, required: true),
              labeledField(label: "Phone Number", controller: _phoneController),
              labeledField(label: "Address", controller: _addressController),
              const SizedBox(height: 16),
              Text("Businesses", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (int i = 0; i < businesses.length; i++) businessSection(i),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Business"),
                onPressed: () => setState(() => businesses.add(Business(name: TextEditingController(), desc: TextEditingController(), address: TextEditingController(), phone: TextEditingController()))),
              ),
              const SizedBox(height: 20),
              Align(alignment: Alignment.centerLeft, child: Text('Business Location (Tap to pin)', style: Theme.of(context).textTheme.titleMedium)),
              const SizedBox(height: 10),
              _buildMapSection(),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: cbocPrimary, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
