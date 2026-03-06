import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../backend/backend.dart';

const Color cbocPrimary = Color(0xFFB71C1C);
const Color cbocSecondary = Color(0xFFD32F2F);
const Color cbocAccent = Color(0xFFFFCDD2);
const LatLng _caviteCenter = LatLng(14.2456, 120.8786);

// ================================================================
// LOCAL BUSINESS FORM MODEL (UI only — not stored directly)
// Used when the user is adding a new business in edit mode.
// On save, this gets submitted to the 'businesses' collection
// via BackendService.submitBusiness().
// ================================================================
class BusinessForm {
  final TextEditingController name;
  final TextEditingController desc;
  final TextEditingController address;
  final TextEditingController phone;
  final List<Uint8List> images;

  LatLng? pinnedLocation;
  String? logoUrl;
  Uint8List? logoPreviewBytes;

  Uint8List? dtiDocBytes;
  String? dtiFileName;

  BusinessForm({
    required this.name,
    required this.desc,
    required this.address,
    required this.phone,
    List<Uint8List>? images,
    this.pinnedLocation,
    this.logoUrl,
    this.logoPreviewBytes,
    this.dtiDocBytes,
    this.dtiFileName,
  }) : images = images ?? [];

  bool get hasDtiDocument => dtiDocBytes != null;

  void dispose() {
    name.dispose();
    desc.dispose();
    address.dispose();
    phone.dispose();
  }
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

  // Personal info controllers
  final nameController = TextEditingController();
  final roleController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  // All businesses from the 'businesses' collection (any status)
  List<BusinessRecord> _businesses = [];

  // New business forms being filled in during edit mode (not yet submitted)
  final List<BusinessForm> _newForms = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _subscribeToBusinesses();
  }

  @override
  void dispose() {
    nameController.dispose();
    roleController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    for (final f in _newForms) f.dispose();
    super.dispose();
  }

  // ================================================================
  // SUBSCRIBE TO BUSINESSES (real-time, single collection)
  // ================================================================
  void _subscribeToBusinesses() {
    BackendService.myBusinessesStream().listen((list) {
      if (mounted) setState(() => _businesses = list);
    });
  }

  // ================================================================
  // LOAD PROFILE
  // ================================================================
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final data = await BackendService.fetchUserProfile();
    if (data != null && mounted) {
      setState(() {
        nameController.text = data['name'] ?? '';
        emailController.text = data['email'] ?? '';
        phoneController.text = data['phone'] ?? '';
        addressController.text = data['address'] ?? '';
        roleController.text = data['userType'] ?? '';
      });
    }
    setState(() => _isLoading = false);
  }

  // ================================================================
  // SAVE PROFILE
  // ================================================================
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    // Validate new business forms
    for (final form in _newForms) {
      if (form.name.text.trim().isEmpty) {
        _showError('Please enter a business name for all new businesses.');
        setState(() => _isSaving = false);
        return;
      }
      if (!form.hasDtiDocument) {
        _showError(
            'Please upload a DTI document for "${form.name.text.trim()}" before saving.');
        setState(() => _isSaving = false);
        return;
      }
    }

    // Save personal info
    final result = await BackendService.saveUserProfile(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      address: addressController.text.trim(),
    );

    if (!result.success) {
      _showError('Error saving profile: ${result.message}');
      setState(() => _isSaving = false);
      return;
    }

    // Submit each new business form to the 'businesses' collection
    for (final form in _newForms) {
      final submitResult = await BackendService.submitBusiness(
        name: form.name.text.trim(),
        desc: form.desc.text.trim(),
        address: form.address.text.trim(),
        phone: form.phone.text.trim(),
        lat: form.pinnedLocation?.latitude,
        lng: form.pinnedLocation?.longitude,
        logoUrl: form.logoUrl,
        dtiDocBytes: form.dtiDocBytes!,
        dtiFileName: form.dtiFileName!,
      );
      if (!submitResult.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Failed to submit "${form.name.text}": ${submitResult.message}'),
          backgroundColor: Colors.red[700],
        ));
      }
    }

    // Clear new forms after submission
    for (final f in _newForms) f.dispose();
    _newForms.clear();

    setState(() => _isSaving = false);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text(
          'Profile saved! New businesses are pending admin approval.'),
      backgroundColor: Colors.green[700],
      duration: const Duration(seconds: 4),
    ));
    setState(() => isEditing = false);
  }

  // ================================================================
  // PICK DTI DOCUMENT
  // ================================================================
  Future<void> _pickDtiDocument(BusinessForm form) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) return;
      setState(() {
        form.dtiDocBytes = file.bytes;
        form.dtiFileName = file.name;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('DTI document selected: ${file.name}'),
          backgroundColor: Colors.green[700],
        ));
      }
    } catch (e) {
      _showError('Could not pick file: $e');
    }
  }

  // ================================================================
  // UPLOAD LOGO for a new business form
  // ================================================================
  Future<void> _pickAndUploadLogo(BusinessForm form) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => form.logoPreviewBytes = bytes);
    final url = await BackendService.uploadLogoImage(bytes, file.name);
    if (url != null) {
      setState(() => form.logoUrl = url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Logo uploaded!'),
          backgroundColor: Colors.green,
        ));
      }
    } else {
      _showError('Logo upload failed.');
    }
  }

  // ================================================================
  // OPEN FULL-SCREEN MAP PICKER
  // ================================================================
  Future<void> _openMapPicker(BusinessForm form) async {
    final LatLng startCenter = form.pinnedLocation ?? _caviteCenter;
    LatLng tempPin = form.pinnedLocation ?? _caviteCenter;
    final addressCtrl = TextEditingController(text: form.address.text);

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
                title: const Text('Pin Business Location'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        form.pinnedLocation = tempPin;
                        form.address.text = addressCtrl.text;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Confirm',
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
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Full Business / Office Address',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: addressCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText:
                                'e.g. Unit 2, Brgy. Tejero, Cavite City, 4100',
                            prefixIcon: const Icon(Icons.location_on,
                                color: cbocPrimary),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: cbocPrimary, width: 2),
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
                                  'Tap anywhere on the map to place or move your pin',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.brown),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: startCenter,
                            initialZoom:
                                form.pinnedLocation != null ? 16 : 13,
                            minZoom: 10,
                            maxZoom: 19,
                            onTap: (_, point) =>
                                setModal(() => tempPin = point),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                              subdomains: const ['a', 'b', 'c', 'd'],
                              userAgentPackageName: 'com.yourapp.smartcard',
                              maxZoom: 19,
                            ),
                            MarkerLayer(markers: [
                              Marker(
                                point: tempPin,
                                width: 60,
                                height: 76,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        border: Border.all(
                                            color: cbocPrimary, width: 2.5),
                                        boxShadow: const [
                                          BoxShadow(
                                              blurRadius: 8,
                                              color: Colors.black38,
                                              offset: Offset(0, 3))
                                        ],
                                        image: form.logoPreviewBytes != null
                                            ? DecorationImage(
                                                image: MemoryImage(
                                                    form.logoPreviewBytes!),
                                                fit: BoxFit.cover)
                                            : form.logoUrl != null
                                                ? DecorationImage(
                                                    image: NetworkImage(
                                                        form.logoUrl!),
                                                    fit: BoxFit.cover)
                                                : null,
                                      ),
                                      child: (form.logoPreviewBytes == null &&
                                              form.logoUrl == null)
                                          ? const Icon(Icons.business,
                                              color: cbocPrimary, size: 26)
                                          : null,
                                    ),
                                    Container(
                                        width: 3,
                                        height: 14,
                                        color: cbocPrimary),
                                  ],
                                ),
                              ),
                            ]),
                          ],
                        ),
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
                                BoxShadow(blurRadius: 6, color: Colors.black26)
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.gps_fixed,
                                    color: cbocPrimary, size: 15),
                                const SizedBox(width: 6),
                                Text(
                                  'Lat: ${tempPin.latitude.toStringAsFixed(5)}'
                                  '   Lng: ${tempPin.longitude.toStringAsFixed(5)}',
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
  Future<void> _pickProfileImage() async {
    final XFile? f = await _picker.pickImage(source: ImageSource.gallery);
    if (f != null) {
      final bytes = await f.readAsBytes();
      setState(() => profileImage = bytes);
    }
  }

  Future<void> _addBusinessImage(BusinessForm form) async {
    if (form.images.length >= 5) return;
    final XFile? f = await _picker.pickImage(source: ImageSource.gallery);
    if (f != null) {
      final bytes = await f.readAsBytes();
      setState(() => form.images.add(bytes));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red[700],
    ));
  }

  void _cancelEdit() {
    for (final f in _newForms) f.dispose();
    _newForms.clear();
    _loadProfile();
    setState(() => isEditing = false);
  }

  // ================================================================
  // LABELED FIELD (personal info)
  // ================================================================
  Widget _labeledField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    if (!isEditing && controller.text.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
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
            : Text(controller.text,
                style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
      ],
    );
  }

  // ================================================================
  // APPROVED / PENDING / REJECTED BUSINESS RECORD CARD (read-only)
  // Shows a card for each BusinessRecord from the 'businesses' collection.
  // ================================================================
  Widget _businessRecordCard(BusinessRecord biz, int displayIndex) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (biz.status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.verified;
        statusLabel = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusLabel = 'Rejected';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top;
        statusLabel = 'Pending Approval';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      color: statusColor.withOpacity(0.03),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    biz.name.isNotEmpty ? biz.name : 'Unnamed Business',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: statusColor.withOpacity(0.4), width: 1),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Logo + info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (biz.logoUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(biz.logoUrl!,
                        width: 52, height: 52, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (biz.address.isNotEmpty)
                        _infoRow(Icons.location_on, biz.address),
                      if (biz.phone.isNotEmpty)
                        _infoRow(Icons.phone, biz.phone),
                      if (biz.desc.isNotEmpty)
                        _infoRow(Icons.info_outline, biz.desc, maxLines: 2),
                    ],
                  ),
                ),
              ],
            ),

            // Map preview (approved businesses with a pin)
            if (biz.isApproved && biz.lat != null && biz.lng != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 140,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(biz.lat!, biz.lng!),
                      initialZoom: 16,
                      interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.yourapp.smartcard',
                      ),
                      MarkerLayer(markers: [
                        Marker(
                          point: LatLng(biz.lat!, biz.lng!),
                          width: 44,
                          height: 54,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                      color: cbocPrimary, width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                        blurRadius: 4, color: Colors.black26)
                                  ],
                                  image: biz.logoUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(biz.logoUrl!),
                                          fit: BoxFit.cover)
                                      : null,
                                ),
                                child: biz.logoUrl == null
                                    ? const Icon(Icons.business,
                                        color: cbocPrimary, size: 18)
                                    : null,
                              ),
                              Container(
                                  width: 2, height: 10, color: cbocPrimary),
                            ],
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],

            // DTI document status
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  biz.isApproved ? Icons.verified : Icons.description,
                  size: 14,
                  color: biz.isApproved ? Colors.green : Colors.blueGrey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    biz.isApproved
                        ? 'DTI Document Verified'
                        : biz.dtiFileName ?? 'DTI document attached',
                    style: TextStyle(
                        fontSize: 11,
                        color:
                            biz.isApproved ? Colors.green : Colors.blueGrey,
                        fontWeight: biz.isApproved
                            ? FontWeight.w600
                            : FontWeight.normal),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Rejection reason
            if (biz.isRejected && biz.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reason: ${biz.rejectionReason}',
                        style:
                            const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Submitted date
            const SizedBox(height: 6),
            Text(
              'Submitted: ${_formatDate(biz.submittedAt)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // NEW BUSINESS FORM CARD (edit mode only)
  // ================================================================
  Widget _newBusinessFormCard(int index) {
    final form = _newForms[index];

    return Card(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cbocPrimary.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.add_business, color: cbocPrimary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'New Business',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: cbocPrimary),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => setState(() {
                    form.dispose();
                    _newForms.removeAt(index);
                  }),
                  tooltip: 'Remove',
                ),
              ],
            ),

            // Pending notice
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.pending_actions, color: Colors.amber, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This business will be reviewed by an admin before appearing on the map.',
                      style: TextStyle(fontSize: 11, color: Colors.brown),
                    ),
                  ),
                ],
              ),
            ),

            // Business Name
            const Text('Business Name *',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            TextField(
              controller: form.name,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 14),

            // Description
            const Text('Business Description',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            TextField(
              controller: form.desc,
              maxLines: 3,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 14),

            // Phone
            const Text('Business Contact Number',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            TextField(
              controller: form.phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 14),

            // DTI Document
            _dtiUploadWidget(form),

            // Map pin + logo
            _locationWidget(form),

            // Business images
            _businessImagesWidget(form),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // DTI UPLOAD WIDGET
  // ================================================================
  Widget _dtiUploadWidget(BusinessForm form) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.description, color: cbocPrimary, size: 18),
            const SizedBox(width: 6),
            const Text('DTI Business Registration',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: cbocPrimary),
              ),
              child: const Text('Required',
                  style: TextStyle(
                      color: cbocPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickDtiDocument(form),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: form.hasDtiDocument
                  ? Colors.green.shade50
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: form.hasDtiDocument
                    ? Colors.green.shade400
                    : cbocPrimary,
                width: form.hasDtiDocument ? 1.5 : 1,
              ),
            ),
            child: form.hasDtiDocument
                ? Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(form.dtiFileName ?? 'Document attached',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                            const Text('Tap to replace',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit, color: cbocPrimary, size: 16),
                    ],
                  )
                : Column(
                    children: [
                      const Icon(Icons.upload_file,
                          color: cbocPrimary, size: 32),
                      const SizedBox(height: 6),
                      const Text('Tap to upload DTI document',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: cbocPrimary,
                              fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Accepted: PDF, JPG, PNG',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 11)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.blue),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Your business appears on the map only after admin reviews your DTI.',
                  style:
                      TextStyle(fontSize: 11, color: Colors.blueGrey),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  // ================================================================
  // LOCATION + LOGO WIDGET (new business form)
  // ================================================================
  Widget _locationWidget(BusinessForm form) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Business / Office Location',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),

        // Address field
        TextField(
          controller: form.address,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Full Address',
            hintText: 'e.g. Unit 2, Brgy. Tejero, Cavite City, 4100',
            prefixIcon:
                const Icon(Icons.home_work, color: cbocPrimary, size: 20),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),

        // Map preview
        if (form.pinnedLocation != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 140,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: form.pinnedLocation!,
                  initialZoom: 16,
                  interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.yourapp.smartcard',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: form.pinnedLocation!,
                      width: 44,
                      height: 54,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border:
                                  Border.all(color: cbocPrimary, width: 2),
                              image: form.logoPreviewBytes != null
                                  ? DecorationImage(
                                      image:
                                          MemoryImage(form.logoPreviewBytes!),
                                      fit: BoxFit.cover)
                                  : form.logoUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(form.logoUrl!),
                                          fit: BoxFit.cover)
                                      : null,
                            ),
                            child: (form.logoPreviewBytes == null &&
                                    form.logoUrl == null)
                                ? const Icon(Icons.business,
                                    color: cbocPrimary, size: 18)
                                : null,
                          ),
                          Container(
                              width: 2, height: 10, color: cbocPrimary),
                        ],
                      ),
                    ),
                  ]),
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
                'Lat: ${form.pinnedLocation!.latitude.toStringAsFixed(5)}, '
                'Lng: ${form.pinnedLocation!.longitude.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],

        // Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openMapPicker(form),
                icon: const Icon(Icons.map, color: cbocPrimary, size: 18),
                label: Text(
                  form.pinnedLocation == null ? 'Pin on Map' : 'Edit Pin',
                  style: const TextStyle(color: cbocPrimary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: cbocPrimary),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickAndUploadLogo(form),
                icon: const Icon(Icons.image, color: cbocPrimary, size: 18),
                label: Text(
                  form.logoUrl != null ? 'Change Logo' : 'Add Logo',
                  style: const TextStyle(color: cbocPrimary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: cbocPrimary),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            if (form.logoUrl != null || form.logoPreviewBytes != null) ...[
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: form.logoPreviewBytes != null
                    ? Image.memory(form.logoPreviewBytes!,
                        width: 36, height: 36, fit: BoxFit.cover)
                    : Image.network(form.logoUrl!,
                        width: 36, height: 36, fit: BoxFit.cover),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  // ================================================================
  // BUSINESS IMAGES WIDGET
  // ================================================================
  Widget _businessImagesWidget(BusinessForm form) {
    if (!isEditing && form.images.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Business Images',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < form.images.length; i++)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(form.images[i],
                        width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: Colors.red,
                      onPressed: () =>
                          setState(() => form.images.removeAt(i)),
                    ),
                  ),
                ],
              ),
            if (form.images.length < 5)
              GestureDetector(
                onTap: () => _addBusinessImage(form),
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
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.blueGrey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  // ================================================================
  // BUILD
  // ================================================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final approvedCount =
        _businesses.where((b) => b.isApproved).length;
    final pendingOrRejectedCount =
        _businesses.where((b) => !b.isApproved).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
            // ── Profile picture ──
            Center(
              child: GestureDetector(
                onTap: isEditing ? _pickProfileImage : null,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundImage: profileImage != null
                          ? MemoryImage(profileImage!)
                          : const AssetImage('assets/profile.jpg')
                              as ImageProvider,
                    ),
                    if (isEditing)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt,
                            size: 18, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Personal info ──
            _labeledField(label: 'Name', controller: nameController),
            _labeledField(label: 'Role/Title', controller: roleController),
            _labeledField(
                label: 'Email',
                controller: emailController,
                readOnly: true),
            _labeledField(
                label: 'Phone Number', controller: phoneController),
            _labeledField(
                label: 'Personal Address',
                controller: addressController,
                maxLines: 2),

            const Divider(height: 32),

            // ── BUSINESSES HEADER ──
            Row(
              children: [
                Text('Businesses',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (approvedCount > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text('$approvedCount Approved',
                        style: const TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                if (pendingOrRejectedCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Text('$pendingOrRejectedCount Pending/Rejected',
                        style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // ── ALL BUSINESS RECORDS (single collection, any status) ──
            if (_businesses.isEmpty && !isEditing)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.business_outlined,
                        color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Text('No businesses registered yet.',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),

            for (int i = 0; i < _businesses.length; i++)
              _businessRecordCard(_businesses[i], i + 1),

            // ── ADD BUSINESS BUTTON (edit mode) ──
            if (isEditing) ...[
              const SizedBox(height: 4),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_business, color: cbocPrimary),
                label: const Text('Add Business',
                    style: TextStyle(color: cbocPrimary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: cbocPrimary),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                onPressed: () {
                  setState(() {
                    _newForms.add(BusinessForm(
                      name: TextEditingController(),
                      desc: TextEditingController(),
                      address: TextEditingController(),
                      phone: TextEditingController(),
                    ));
                  });
                },
              ),

              // ── NEW BUSINESS FORMS ──
              for (int i = 0; i < _newForms.length; i++)
                _newBusinessFormCard(i),
            ],

            // ── SAVE / CANCEL ──
            if (isEditing) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _cancelEdit,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: cbocPrimary),
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : const Text('Save',
                              style: TextStyle(color: Colors.white)),
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