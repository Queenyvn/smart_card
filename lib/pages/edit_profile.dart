import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class BusinessForm {
  String? id; // Firestore document ID

  final TextEditingController name = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController role = TextEditingController();
  final TextEditingController contact = TextEditingController();
  final TextEditingController address = TextEditingController();

  List<File> images = [];
  List<String> imageUrls = []; // uploaded Firebase URLs

  void dispose() {
    name.dispose();
    description.dispose();
    role.dispose();
    contact.dispose();
    address.dispose();
  }
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

  final List<BusinessForm> _businesses = [];
  final List<String> _deletedBusinessIds = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // DEV MODE: Bypass admin approval. Remove after thorough testing =====================================
  static const bool _devBypassApproval = true;
  // DEV MODE: Bypass admin approval. Remove after thorough testing =====================================

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
    "Grace Park East": "1403",
    "Grace Park West": "1406",
    "Isla de Cocomo":	"1412",


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
    _loadUserProfile();

    if (_businesses.isEmpty) {
      _businesses.add(BusinessForm());
    }
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

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return;

      final data = doc.data()!;

      setState(() {
        // Personal info
        _firstNameController.text = data['firstName'] ?? '';
        _lastNameController.text = data['lastName'] ?? '';
        _streetController.text = data['street'] ?? '';
        _barangayController.text = data['barangay'] ?? '';
        _cityController.text = data['city'] ?? '';
        _provinceController.text = data['province'] ?? '';
        _zipCodeController.text = data['zipCode'] ?? '';

        // NCR logic
        _isMetroManila = data['isMetroManila'] ?? false;

        if (_isMetroManila) {
          selectedNcrCity = data['city'];
          selectedBarangay = data['barangay'];
        }

        // Professional
        _titleController.text = data['title'] ?? '';
        _bioController.text = data['bio'] ?? '';

        // Contact
        _phoneController.text = data['phoneNumber'] ?? '';
        _emailController.text = data['email'] ?? '';
        _websiteController.text = data['website'] ?? '';

        // Social links
        final socials = data['socialLinks'] as Map<String, dynamic>? ?? {};
        _socialLink1Controller.text = socials['link1'] ?? '';
        _socialLink2Controller.text = socials['link2'] ?? '';

        // Files
        _profileImageUrl = data['profileImageUrl'];
        _dtiFileUrl = data['dtiFileUrl'];
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
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
                      if (_isMetroManila && _provinceController.text.isEmpty) {
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
            _buildSectionHeader("List of Businesses"),
            _buildBusinessesSection(),

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
                : (_profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : const NetworkImage("https://i.pravatar.cc/300"))
                as ImageProvider,
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
        if (_dtiFileUrl != null && _dtiFile == null)
          const Text(
            "DTI file already uploaded",
            style: TextStyle(fontSize: 12, color: Colors.green),
          ),
      ],
    );
  }

  Widget _buildBusinessesSection() {
    return Column(
      children: [
        ..._businesses.asMap().entries.map((entry) {
          final index = entry.key;
          final business = entry.value;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Business ${index + 1}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            if (business.id != null) {
                              _deletedBusinessIds.add(business.id!);
                            }
                            business.dispose();
                            _businesses.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),

                  _buildSingleTextField("Business Name", business.name),
                  _buildSingleTextField(
                    "Business Description",
                    business.description,
                    maxLines: 3,
                  ),
                  _buildSingleTextField("Business Role", business.role),
                  _buildSingleTextField("Business Contact Info", business.contact),
                  _buildSingleTextField("Business Address", business.address),

                  const SizedBox(height: 8),
                  _buildBusinessImages(business),
                ],
              ),
            ),
          );
        }),

        // Add business button
        OutlinedButton.icon(
          icon: const Icon(Icons.add, color: Colors.red),
          label: const Text("Add Business", style: TextStyle(color: Colors.red)),
          onPressed: () {
            setState(() {
              _businesses.add(BusinessForm());
            });
          },
        ),
      ],
    );
  }

  Widget _buildBusinessImages(BusinessForm business) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Business Images (max 5)",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...business.images.asMap().entries.map((entry) {
              final index = entry.key;
              final image = entry.value;

              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      image,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          business.images.removeAt(index);
                        });
                      },
                    ),
                  ),
                ],
              );
            }),

            // Add image button
            if (business.images.length < 5)
              GestureDetector(
                onTap: () => _pickBusinessImage(business),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_a_photo, color: Colors.grey),
                ),
              ),
          ],
        ),
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

  Future<void> _pickBusinessImage(BusinessForm business) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        if (business.images.length < 5) {
          business.images.add(File(picked.path));
        }
      });
    }
  }

  Future<List<String>> _uploadBusinessImages(
    String userId,
    BusinessForm business,
  ) async {
    final List<String> urls = [];

    for (final image in business.images) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('business_images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(image);
      urls.add(await ref.getDownloadURL());
    }

    return urls;
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userRef = _firestore.collection('users').doc(user.uid);

      final profileData = {
        // Core identity
        'uid': user.uid,
        'email': _emailController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),

        // Personal info
        'profileImageUrl': _profileImageUrl,
        'street': _streetController.text.trim(),
        'barangay': _barangayController.text.trim(),
        'city': _cityController.text.trim(),
        'province': _provinceController.text.trim(),
        'zipCode': _zipCodeController.text.trim(),
        'isMetroManila': _isMetroManila,

        // Professional
        'title': _titleController.text.trim(),
        'bio': _bioController.text.trim(),

        // Contact
        'phoneNumber': _phoneController.text.trim(),
        'website': _websiteController.text.trim(),

        // Social links
        'socialLinks': {
          'link1': _socialLink1Controller.text.trim(),
          'link2': _socialLink2Controller.text.trim(),
        },

        // Files / verification
        'dtiFileUrl': _dtiFileUrl,
        // DEV MODE - Replace after thorough testing. ==================================================
        // 'verificationStatus': widget.fromRegister ? 'pending' : 'approved',
        'verificationStatus': _devBypassApproval
          ? 'approved'
          : (widget.fromRegister ? 'pending' : 'approved'),
        // DEV MODE - Replace after thorough testing. ==================================================
        'isVerified': false,

        // App state
        'profileCompleted': true,
        // DEV MODE - Replace after thorough testing. ==================================================
        // 'accountStatus': widget.fromRegister ? 'pending' : 'active',
        'accountStatus': _devBypassApproval
          ? 'active'
          : (widget.fromRegister ? 'pending' : 'active'),
        // DEV MODE - Replace after thorough testing. ==================================================

        // Metadata
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Create or update safely
      await userRef.set(
        {
          ...profileData,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final businessesRef = userRef.collection('businesses');

      for (final business in _businesses) {
        // Skip empty business cards
        if (business.name.text.trim().isEmpty) continue;

        // Upload images if needed
        if (business.images.isNotEmpty) {
          business.imageUrls = await _uploadBusinessImages(user.uid, business);
        }

        final businessData = {
          'name': business.name.text.trim(),
          'description': business.description.text.trim(),
          'role': business.role.text.trim(),
          'contact': business.contact.text.trim(),
          'address': business.address.text.trim(),
          'images': business.imageUrls,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (business.id == null) {
          // CREATE
          final doc = await businessesRef.add({
            ...businessData,
            'createdAt': FieldValue.serverTimestamp(),
          });
          business.id = doc.id;
        } else {
          // UPDATE
          await businessesRef.doc(business.id).set(
            businessData,
            SetOptions(merge: true),
          );
        }
      }
      
      for (final id in _deletedBusinessIds) {
        await userRef.collection('businesses').doc(id).delete();
      }
      _deletedBusinessIds.clear();

      // UI feedback
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.fromRegister
                ? 'Profile submitted! Awaiting admin approval.'
                : 'Profile saved successfully!',
          ),
        ),
      );

      // Navigation
      // DEV MODE - Remove the ' && !_devBypassApproval' part after thorough testing ====================
      if (widget.fromRegister && !_devBypassApproval) {
        Navigator.pushReplacementNamed(context, '/pendingApproval');
      } else {
        Navigator.pop(context);
      }
      // DEV MODE - Remove the ' && !_devBypassApproval' part after thorough testing ====================
    } catch (e) {
      debugPrint('Error saving profile: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save profile. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
