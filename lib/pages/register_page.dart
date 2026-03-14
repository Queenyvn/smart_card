import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:typed_data';
import '../backend/backend.dart';
import 'package:firebase_auth/firebase_auth.dart';

// CBOC Branding Colors
const Color cbocPrimary = Color(0xFFB71C1C);
const Color cbocSecondary = Color(0xFFD32F2F);
const Color cbocAccent = Color(0xFFFFCDD2);
const Color cbocBackground = Color(0xFFD2F8D2);

const LatLng _caviteCenter = LatLng(14.2456, 120.8786);

class RegisterPage extends StatefulWidget {
  final User googleUser;
  const RegisterPage({super.key, required this.googleUser});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessNatureController = TextEditingController();

  // ── Business location ──
  final TextEditingController _businessAddressController = TextEditingController();
  LatLng? _pinnedLocation;

  bool _isLoading = false;
  String? _message;

  Uint8List? _orFileBytes;
  String? _orFileName;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _businessNameController.dispose();
    _businessNatureController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  Future<void> _pickORDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _orFileBytes = result.files.single.bytes;
          _orFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e'), backgroundColor: cbocSecondary),
      );
    }
  }

  // ================================================================
  // FULL-SCREEN MAP PICKER  (mirrors edit page exactly)
  // ================================================================
  Future<void> _openMapPicker() async {
    final LatLng startCenter = _pinnedLocation ?? _caviteCenter;
    LatLng tempPin = _pinnedLocation ?? _caviteCenter;
    final addressCtrl = TextEditingController(text: _businessAddressController.text);

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
                        _pinnedLocation = tempPin;
                        _businessAddressController.text = addressCtrl.text;
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
                  // Address input above the map
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Full Business / Office Address',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
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

                  // Map
                  Expanded(
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: startCenter,
                            initialZoom: _pinnedLocation != null ? 16 : 13,
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
                                      ),
                                      child: const Icon(Icons.business,
                                          color: cbocPrimary, size: 26),
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

                        // Coordinates chip at bottom
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
  // BUSINESS LOCATION SECTION WIDGET
  // ================================================================
  Widget _buildBusinessLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: const [
              Icon(Icons.location_on, color: cbocPrimary, size: 20),
              SizedBox(width: 8),
              Text(
                'Business Location',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Optional — helps your business appear correctly on the map.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),

          // Address text field
          TextField(
            controller: _businessAddressController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Full Business Address',
              hintText: 'e.g. Unit 2, Brgy. Tejero, Cavite City, 4100',
              prefixIcon:
                  const Icon(Icons.home_work, color: cbocPrimary, size: 20),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // Map preview when a pin is set
          if (_pinnedLocation != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 150,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _pinnedLocation!,
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
                        point: _pinnedLocation!,
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
                                      blurRadius: 4,
                                      color: Colors.black26)
                                ],
                              ),
                              child: const Icon(Icons.business,
                                  color: cbocPrimary, size: 18),
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
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.gps_fixed, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Lat: ${_pinnedLocation!.latitude.toStringAsFixed(5)}, '
                  'Lng: ${_pinnedLocation!.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _pinnedLocation = null),
                  child: const Row(
                    children: [
                      Icon(Icons.close, size: 13, color: Colors.red),
                      SizedBox(width: 2),
                      Text('Remove pin',
                          style:
                              TextStyle(fontSize: 11, color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Pin / Edit button
          OutlinedButton.icon(
            onPressed: _openMapPicker,
            icon: const Icon(Icons.map, color: cbocPrimary, size: 18),
            label: Text(
              _pinnedLocation == null
                  ? 'Pin Location on Map'
                  : 'Edit Pin on Map',
              style: const TextStyle(color: cbocPrimary),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: cbocPrimary),
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SUBMIT
  // ================================================================
  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_orFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your Official Receipt (OR) document'),
          backgroundColor: cbocSecondary,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final result = await BackendService.registerGoogleUserForApproval(
        googleUser: widget.googleUser,
        name: _nameController.text.trim(),
        password: _passwordController.text.trim(),
        address: _addressController.text.trim(),
        userType: 'Business',
        businessName: _businessNameController.text.trim(),
        businessNature: _businessNatureController.text.trim(),
        orFileBytes: _orFileBytes,
        orFileName: _orFileName,
        // Pass location fields so backend can store them
        businessAddress: _businessAddressController.text.trim().isNotEmpty
            ? _businessAddressController.text.trim()
            : null,
        businessLat: _pinnedLocation?.latitude,
        businessLng: _pinnedLocation?.longitude,
      );

      setState(() {
        _isLoading = false;
        _message = result.success
            ? "Registration submitted! Please wait for admin approval."
            : "Error: ${result.message}";
      });
    } catch (e) {
      setState(() {
        _message = "Error: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cbocSecondary,
        title: const Text("Complete Registration",
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Google account banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cbocAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_circle, color: cbocPrimary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Signed in as',
                            style: TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                          Text(
                            widget.googleUser.email ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Password
              TextFormField(
                controller: _passwordController,
                decoration:
                    const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) =>
                    value == null || value.length < 6
                        ? 'Password must be at least 6 characters'
                        : null,
              ),
              const SizedBox(height: 12),

              // Personal Address
              TextFormField(
                controller: _addressController,
                decoration:
                    const InputDecoration(labelText: 'Personal Address'),
                validator: (value) =>
                    value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Business Name
              TextFormField(
                controller: _businessNameController,
                decoration:
                    const InputDecoration(labelText: 'Business Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Nature of Business
              TextFormField(
                controller: _businessNatureController,
                decoration: const InputDecoration(
                    labelText: 'Nature of Business'),
                validator: (value) =>
                    value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // ── Business Location (new) ──
              _buildBusinessLocationSection(),
              const SizedBox(height: 16),

              // OR Document Upload
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.picture_as_pdf, color: cbocSecondary),
                        SizedBox(width: 8),
                        Text(
                          'Official Receipt / OR (Required)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_orFileName != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cbocBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: cbocPrimary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_orFileName!,
                                  style: const TextStyle(fontSize: 14)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: cbocSecondary),
                              onPressed: () => setState(() {
                                _orFileBytes = null;
                                _orFileName = null;
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    OutlinedButton.icon(
                      onPressed: _pickORDocument,
                      icon: Icon(
                        _orFileName == null
                            ? Icons.upload_file
                            : Icons.change_circle,
                        color: cbocSecondary,
                      ),
                      label: Text(
                        _orFileName == null ? 'Upload PDF' : 'Change File',
                        style: const TextStyle(color: cbocSecondary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: cbocSecondary),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Submit button
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: cbocSecondary))
                  : ElevatedButton(
                      onPressed: _submitRegistration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cbocSecondary,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit Registration',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),

              // Result message
              if (_message != null) ...[
                const SizedBox(height: 20),
                Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _message!.contains('Error')
                        ? cbocSecondary
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}