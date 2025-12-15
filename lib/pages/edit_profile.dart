import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final bool fromRegister;

  const EditProfilePage({super.key, this.fromRegister = false});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Controllers
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

  File? _profileImage;
  File? _dtiFile;
  String? _profileImageUrl;
  String? _dtiFileUrl;

  final _auth = FirebaseAuth.instance;

  // City-ZIP data
  final Map<String, String> _cityZipMap = {
    'Cavite City': '4100',
    'Tanza': '4108',
    'Imus': '4103',
    'Dasmariñas': '4114',
    'Tagaytay': '4120',
  };

    // Metro Manila toggle
  bool _isMetroManila = false;

  // NCR City dropdown
  String? selectedNcrCity;

  // Barangay dropdown
  String? selectedBarangay;

  // NCR cities with zip codes
  final Map<String, String> _ncrCityZipMap = {
    "Binondo": "1006",
    "Intramuros": "1002",
    "Malate": "1004",
    "Manila": "1000",
    "Paco": "1007",
    "Pandacan": "1008",
    "Port Area": "1018",
    "Quiapo": "1001",
    "Sampaloc East": "1008",
    "Sampaloc West": "1015",
    "San Andres Bukid": "1017",
    "San Miguel": "1005",
    "San Nicolas": "1010",
    "Santa Ana": "1009",
    "Santa Cruz North": "1014",
    "Santa Cruz South": "1003",
    "Santa Mesa": "1016",
    "Tondo North": "1013",
    "Tondo South": "1012",
    "Amparo Subdivision": "1425",
    "Bagong Silang": "1428",
    "Bagumbong/Pag-asa": "1421",
    "Bankers Village": "1426",
    "Capitol Parkland Subdivision": "1424",
    "Kaybiga/Deparo": "1420",
    "Lilles Ville Subdivision": "1420",
    "Novaliches North": "1422",
    "Tala Leprosarium": "1427",
    "Victory Heights": "1423",
    "1st Avenue to 7th Avenue-West": "1405",
    "Baesa": "1401",
    "Fish Market": "1411",

  };

  // Barangays per city
  final Map<String, List<String>> _barangaysByCity = {
    "Manila": ["Tondo", "Ermita", "Intramuros"],
    "Makati": ["Bel-Air", "Poblacion", "San Lorenzo"],
    "Quezon City": ["Batasan Hills", "Commonwealth", "Bagong Silangan"],
    "Pasig": ["Bagong Ilog", "Manggahan", "Ugong"],
    "Taguig": ["Bagumbayan", "Ususan", "Napindan"],
  };

  // Cleaner input decoration
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
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
    );
  }


  @override
  void initState() {
    super.initState();
    _autoFillFromGoogleAccount();
  }

  void _autoFillFromGoogleAccount() {
    final user = _auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      final nameParts = (user.displayName ?? '').split(' ');
      if (nameParts.isNotEmpty) _firstNameController.text = nameParts.first;
      if (nameParts.length > 1) _lastNameController.text = nameParts.sublist(1).join(' ');
    }
  }

  @override
  void dispose() {
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

            // Metro Manila (NCR) Checkbox
            Row(
              children: [
                Checkbox(
                  value: _isMetroManila,
                  activeColor: Colors.red,
                  onChanged: (value) {
                    setState(() {
                      _isMetroManila = value ?? false;
                      if (_isMetroManila) {
                        _provinceController.text = "Metro Manila (NCR)";
                      } else {
                        _provinceController.clear();
                        _zipCodeController.clear();
                        selectedNcrCity = null;
                        selectedBarangay = null;
                      }
                    });
                  },
                ),
                const Text(
                  "Metro Manila (NCR)",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),

            // City & Barangay dropdowns if NCR is checked
            if (_isMetroManila) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedNcrCity,
                decoration: _inputDecoration("City/Municipality"),
                items: _ncrCityZipMap.keys.map((city) {
                  return DropdownMenuItem(value: city, child: Text(city));
                }).toList(),
                onChanged: (city) {
                  setState(() {
                    selectedNcrCity = city;
                    _cityController.text = city ?? '';
                    _zipCodeController.text = _ncrCityZipMap[city] ?? '';
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedBarangay,
                decoration: _inputDecoration("Barangay"),
                items: [
                  'Barangay 1', 'Barangay 2', 'Barangay 3', 'Barangay 4', 'Barangay 5'
                ].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (b) {
                  setState(() {
                    selectedBarangay = b;
                    _barangayController.text = b ?? '';
                  });
                },
              ),
            ] else ...[
              // Non-NCR users
              _buildDoubleTextField("Barangay", "City", _barangayController, _cityController),
              _buildDoubleTextField("Province", "Zip Code", _provinceController, _zipCodeController),
            ],
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: _buildSingleTextField("Province", _provinceController)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _zipCodeController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Zip Code",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),

            _buildSectionHeader("Professional Information"),
            _buildSingleTextField("Title/Position", _titleController),
            _buildSingleTextField("Description/Bio", _bioController, maxLines: 3),

            _buildSectionHeader("Contact Information"),
            _buildDoubleTextField("Phone Number", "Email", _phoneController, _emailController),
            _buildSingleTextField("Website", _websiteController),

            _buildSectionHeader("Social Links"),
            _buildDoubleTextField("Social Link 1", "Social Link 2", _socialLink1Controller, _socialLink2Controller),

            const SizedBox(height: 16),
            _buildDTIUploader(),

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

  // === REUSABLE UI ===

  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 55,
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : const NetworkImage("https://i.pravatar.cc/300") as ImageProvider,
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

  Widget _buildDoubleTextField(String label1, String label2, TextEditingController controller1, TextEditingController controller2) {
    return Row(
      children: [
        Expanded(child: _buildSingleTextField(label1, controller1)),
        const SizedBox(width: 12),
        Expanded(child: _buildSingleTextField(label2, controller2)),
      ],
    );
  }

  Widget _buildDTIUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("DTI Registration"),
        OutlinedButton.icon(
          icon: const Icon(Icons.upload_file, color: Colors.red),
          label: const Text("Upload DTI PDF", style: TextStyle(color: Colors.red)),
          onPressed: _uploadDTIFile,
        ),
        if (_dtiFile != null)
          Text("Selected file: ${_dtiFile!.path.split('/').last}", style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // === ACTIONS ===

  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
      final ref = FirebaseStorage.instance.ref().child('profile_pictures/${_auth.currentUser!.uid}.jpg');
      await ref.putFile(_profileImage!);
      _profileImageUrl = await ref.getDownloadURL();
    }
  }

  Future<void> _uploadDTIFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() => _dtiFile = File(result.files.single.path!));
      final ref = FirebaseStorage.instance.ref().child('dti_files/${_auth.currentUser!.uid}.pdf');
      await ref.putFile(_dtiFile!);
      _dtiFileUrl = await ref.getDownloadURL();
    }
  }

  void _saveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.fromRegister
            ? 'Profile submitted! Admin will review your account.'
            : 'Profile saved successfully!'),
      ),
    );

    if (widget.fromRegister) {
      Navigator.pushReplacementNamed(context, '/pendingApproval');
    } else {
      Navigator.pop(context);
    }
  }
}
