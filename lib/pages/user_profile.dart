import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import '../backend/backend.dart';

const Color cbocPrimary = Color(0xFFB71C1C);
const Color cbocSecondary = Color(0xFFD32F2F);
const Color cbocAccent = Color(0xFFFFCDD2);
const LatLng _caviteCenter = LatLng(14.2456, 120.8786);

// ================================================================
// BUSINESS MODEL
// Now includes location (lat/lng) and logoUrl per business
// ================================================================
class Business {
  final TextEditingController name;
  final TextEditingController desc;
  final TextEditingController address; // full text address
  final TextEditingController phone;
  final List<Uint8List> images;

  // Map pin fields
  LatLng? pinnedLocation;
  String? logoUrl;
  Uint8List? logoPreviewBytes;
  bool locationSaved;

  Business({
    required this.name,
    required this.desc,
    required this.address,
    required this.phone,
    List<Uint8List>? images,
    this.pinnedLocation,
    this.logoUrl,
    this.logoPreviewBytes,
    this.locationSaved = false,
  }) : images = images ?? [];

  bool get isEmpty =>
      name.text.isEmpty &&
      desc.text.isEmpty &&
      address.text.isEmpty &&
      phone.text.isEmpty &&
      images.isEmpty &&
      pinnedLocation == null;

  Map<String, dynamic> toMap() => {
        'name': name.text.trim(),
        'desc': desc.text.trim(),
        'address': address.text.trim(),
        'phone': phone.text.trim(),
        if (pinnedLocation != null) ...{
          'lat': pinnedLocation!.latitude,
          'lng': pinnedLocation!.longitude,
        },
        'logoUrl': logoUrl,
      };
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

  // Personal info
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

  // ================================================================
  // LOAD
  // ================================================================
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

        if (data['businesses'] != null && data['businesses'] is List) {
          businesses.clear();
          for (var b in data['businesses']) {
            LatLng? loc;
            if (b['lat'] != null && b['lng'] != null) {
              loc = LatLng(
                (b['lat'] as num).toDouble(),
                (b['lng'] as num).toDouble(),
              );
            }
            businesses.add(Business(
              name: TextEditingController(text: b['name'] ?? ''),
              desc: TextEditingController(text: b['desc'] ?? ''),
              address: TextEditingController(text: b['address'] ?? ''),
              phone: TextEditingController(text: b['phone'] ?? ''),
              pinnedLocation: loc,
              logoUrl: b['logoUrl'] as String?,
              locationSaved: loc != null,
            ));
          }
        }
      });
    }
    setState(() => _isLoading = false);
  }

  // ================================================================
  // SAVE PROFILE
  // ================================================================
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final businessesData = businesses.map((b) => b.toMap()).toList();

    // Use first business location as the top-level map pin if available
    Map<String, dynamic>? locationData;
    String? topLogoUrl;
    for (final b in businesses) {
      if (b.pinnedLocation != null) {
        locationData = {
          'lat': b.pinnedLocation!.latitude,
          'lng': b.pinnedLocation!.longitude,
          'address': b.address.text.trim(),
        };
        topLogoUrl = b.logoUrl;
        break;
      }
    }

    // Save top-level location for the map (admin + home page)
    if (locationData != null) {
      await BackendService.saveBusinessLocation(
        lat: locationData['lat'],
        lng: locationData['lng'],
        address: locationData['address'],
        logoUrl: topLogoUrl,
      );
    }

    final result = await BackendService.saveUserProfile(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      address: addressController.text.trim(),
      location: locationData,
      businesses: businessesData,
    );

    setState(() => _isSaving = false);
    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profile saved successfully!'),
        backgroundColor: Colors.green[700],
      ));
      setState(() => isEditing = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${result.message}'),
        backgroundColor: Colors.red[700],
      ));
    }
  }

  // ================================================================
  // UPLOAD LOGO for a specific business
  // ================================================================
  Future<void> _pickAndUploadLogo(Business business) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => business.logoPreviewBytes = bytes);

    final url = await BackendService.uploadLogoImage(bytes, file.name);
    if (url != null) {
      setState(() => business.logoUrl = url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Logo uploaded!"),
          backgroundColor: Colors.green,
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Logo upload failed."),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // ================================================================
  // OPEN FULL-SCREEN MAP PICKER for a specific business
  // Like Foodpanda / MoveIt: address text on top, map below,
  // tap anywhere to move the pin
  // ================================================================
  Future<void> _openMapPicker(Business business) async {
    final LatLng startCenter = business.pinnedLocation ?? _caviteCenter;
    LatLng tempPin = business.pinnedLocation ?? _caviteCenter;
    final addressCtrl =
        TextEditingController(text: business.address.text);

    await showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: StatefulBuilder(
          builder: (ctx, setModal) {
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: cbocPrimary,
                foregroundColor: Colors.white,
                title: const Text("Pin Business Location"),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        business.pinnedLocation = tempPin;
                        business.address.text = addressCtrl.text;
                        business.locationSaved = false;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      "Confirm",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ],
              ),
              body: Column(
                children: [
                  // ── ADDRESS INPUT at the top (like Foodpanda) ──
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Full Business / Office Address",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: addressCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText:
                                "e.g. Unit 2, Brgy. Tejero, Cavite City, 4100",
                            prefixIcon: const Icon(Icons.location_on,
                                color: cbocPrimary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: cbocPrimary, width: 2),
                            ),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.touch_app,
                                  size: 16, color: Colors.amber),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "Tap anywhere on the map below to place or move your pin",
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.brown),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── MAP (fills the rest of the screen) ──
                  Expanded(
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: startCenter,
                            initialZoom: business.pinnedLocation != null
                                ? 16
                                : 13,
                            minZoom: 10,
                            maxZoom: 19,
                            onTap: (tapPos, point) {
                              setModal(() => tempPin = point);
                            },
                          ),
                          children: [
                            // CartoDB Voyager — street names, POIs,
                            // building labels (Google Maps-like detail)
                            TileLayer(
                              urlTemplate:
                                  'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                              subdomains: const ['a', 'b', 'c', 'd'],
                              userAgentPackageName: 'com.yourapp.smartcard',
                              maxZoom: 19,
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: tempPin,
                                  width: 60,
                                  height: 76,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Logo circle or icon
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          border: Border.all(
                                              color: cbocPrimary,
                                              width: 2.5),
                                          boxShadow: const [
                                            BoxShadow(
                                              blurRadius: 8,
                                              color: Colors.black38,
                                              offset: Offset(0, 3),
                                            )
                                          ],
                                          image: business.logoPreviewBytes !=
                                                  null
                                              ? DecorationImage(
                                                  image: MemoryImage(business
                                                      .logoPreviewBytes!),
                                                  fit: BoxFit.cover)
                                              : business.logoUrl != null
                                                  ? DecorationImage(
                                                      image: NetworkImage(
                                                          business.logoUrl!),
                                                      fit: BoxFit.cover)
                                                  : null,
                                        ),
                                        child: (business.logoPreviewBytes ==
                                                    null &&
                                                business.logoUrl == null)
                                            ? const Icon(Icons.business,
                                                color: cbocPrimary, size: 26)
                                            : null,
                                      ),
                                      // Pin tail
                                      Container(
                                          width: 3,
                                          height: 14,
                                          color: cbocPrimary),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Coordinates badge at bottom of map
                        Positioned(
                          bottom: 16,
                          left: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                    blurRadius: 6, color: Colors.black26)
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.gps_fixed,
                                    color: cbocPrimary, size: 15),
                                const SizedBox(width: 6),
                                Text(
                                  "Lat: ${tempPin.latitude.toStringAsFixed(5)}"
                                  "   Lng: ${tempPin.longitude.toStringAsFixed(5)}",
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ================================================================
  // PROFILE IMAGE PICKER
  // ================================================================
  Future<void> pickProfileImage() async {
    final XFile? f = await _picker.pickImage(source: ImageSource.gallery);
    if (f != null) {
      final bytes = await f.readAsBytes();
      setState(() => profileImage = bytes);
    }
  }

  Future<void> addBusinessImage(Business business) async {
    if (business.images.length >= 5) return;
    final XFile? f = await _picker.pickImage(source: ImageSource.gallery);
    if (f != null) {
      final bytes = await f.readAsBytes();
      setState(() => business.images.add(bytes));
    }
  }

  // ================================================================
  // LABELED FIELD
  // ================================================================
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
        Text(required ? "$label (Required)" : label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
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
            : Text(controller.text, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
      ],
    );
  }

  // ================================================================
  // BUSINESS IMAGES
  // ================================================================
  Widget _businessImages(Business business) {
    if (!isEditing && business.images.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Business Images",
            style: TextStyle(fontWeight: FontWeight.w600)),
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
                    child: Image.memory(business.images[i],
                        width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  if (isEditing)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: Colors.red,
                        onPressed: () =>
                            setState(() => business.images.removeAt(i)),
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

  // ================================================================
  // BUSINESS LOCATION WIDGET (replaces Business Location Link)
  // Address text field + mini map preview + open full picker button
  // ================================================================
  Widget _businessLocationWidget(Business business) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Icon(Icons.location_on, color: cbocPrimary, size: 18),
            const SizedBox(width: 6),
            const Text("Business / Office Location",
                style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            if (business.locationSaved) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // Full address text field
        if (isEditing)
          TextField(
            controller: business.address,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: "Full Address",
              hintText: "e.g. Unit 2, Brgy. Tejero, Cavite City, 4100",
              prefixIcon:
                  const Icon(Icons.home_work, color: cbocPrimary, size: 20),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          )
        else if (business.address.text.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.home_work, color: cbocPrimary, size: 16),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(business.address.text,
                      style: const TextStyle(fontSize: 14))),
            ],
          ),

        const SizedBox(height: 10),

        // Mini locked map preview (always visible if pin set)
        if (business.pinnedLocation != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 160,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: business.pinnedLocation!,
                  initialZoom: 16,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.yourapp.smartcard',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: business.pinnedLocation!,
                        width: 52,
                        height: 62,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                    color: cbocPrimary, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                      blurRadius: 4,
                                      color: Colors.black26)
                                ],
                                image: business.logoPreviewBytes != null
                                    ? DecorationImage(
                                        image: MemoryImage(
                                            business.logoPreviewBytes!),
                                        fit: BoxFit.cover)
                                    : business.logoUrl != null
                                        ? DecorationImage(
                                            image:
                                                NetworkImage(business.logoUrl!),
                                            fit: BoxFit.cover)
                                        : null,
                              ),
                              child: (business.logoPreviewBytes == null &&
                                      business.logoUrl == null)
                                  ? const Icon(Icons.business,
                                      color: cbocPrimary, size: 18)
                                  : null,
                            ),
                            Container(
                                width: 2, height: 10, color: cbocPrimary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.gps_fixed, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                "Lat: ${business.pinnedLocation!.latitude.toStringAsFixed(5)}, "
                "Lng: ${business.pinnedLocation!.longitude.toStringAsFixed(5)}",
                style:
                    const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ] else if (!isEditing) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey, size: 16),
                SizedBox(width: 6),
                Text("No location pinned yet",
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Edit mode: Open map + upload logo buttons
        if (isEditing) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              // Open map picker
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openMapPicker(business),
                  icon: const Icon(Icons.map, color: cbocPrimary, size: 18),
                  label: Text(
                    business.pinnedLocation == null
                        ? "Pin on Map"
                        : "Edit Pin",
                    style: const TextStyle(color: cbocPrimary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: cbocPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Upload logo
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickAndUploadLogo(business),
                  icon: const Icon(Icons.image, color: cbocPrimary, size: 18),
                  label: Text(
                    business.logoUrl != null ? "Change Logo" : "Add Logo",
                    style: const TextStyle(color: cbocPrimary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: cbocPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              // Logo preview thumbnail
              if (business.logoUrl != null ||
                  business.logoPreviewBytes != null) ...[
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: business.logoPreviewBytes != null
                      ? Image.memory(business.logoPreviewBytes!,
                          width: 36, height: 36, fit: BoxFit.cover)
                      : Image.network(business.logoUrl!,
                          width: 36, height: 36, fit: BoxFit.cover),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  // ================================================================
  // BUSINESS SECTION CARD
  // ================================================================
  Widget _businessSection(int index) {
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
                Text("Business ${index + 1}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        setState(() => businesses.removeAt(index)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            labeledField(label: "Business Name", controller: business.name),
            _businessImages(business),
            labeledField(
                label: "Business Description",
                controller: business.desc,
                maxLines: 3),
            labeledField(
                label: "Business Contact Number",
                controller: business.phone),
            // ── LOCATION (replaces Business Location Link) ──
            _businessLocationWidget(business),
          ],
        ),
      ),
    );
  }

  void cancelEdit() {
    _loadUserProfile();
    setState(() => isEditing = false);
  }

  // ================================================================
  // BUILD
  // ================================================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile"), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
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
              onPressed: () => setState(() => isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile picture
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
                          : const AssetImage("assets/profile.jpg")
                              as ImageProvider,
                    ),
                    if (isEditing)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 18, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Personal info
            labeledField(label: "Name", controller: nameController, required: true),
            labeledField(label: "Role", controller: roleController),
            labeledField(label: "Personal Email", controller: emailController, readOnly: true),
            labeledField(label: "Personal Phone Number", controller: phoneController),
            labeledField(label: "Personal Address", controller: addressController, maxLines: 2),

            const Divider(height: 32),

            // Businesses
            Text("Businesses", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (int i = 0; i < businesses.length; i++) _businessSection(i),

            if (isEditing)
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Business"),
                onPressed: () {
                  setState(() {
                    businesses.add(Business(
                      name: TextEditingController(),
                      desc: TextEditingController(),
                      address: TextEditingController(),
                      phone: TextEditingController(),
                    ));
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text("Save"),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}