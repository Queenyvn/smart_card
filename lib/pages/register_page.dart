import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../backend/backend.dart';

// CBOC Branding Colors
const Color cbocPrimary = Color(0xFFB71C1C);
const Color cbocSecondary = Color(0xFFD32F2F);
const Color cbocAccent = Color(0xFFFFCDD2);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessNatureController = TextEditingController();
  final TextEditingController _professionalTitleController = TextEditingController();

  String userType = 'Business';
  bool _isLoading = false;
  String? _message;
  
  // DTI Document
  Uint8List? _dtiFileBytes;
  String? _dtiFileName;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _businessNameController.dispose();
    _businessNatureController.dispose();
    _professionalTitleController.dispose();
    super.dispose();
  }

  /// ===============================
  /// PICK DTI DOCUMENT
  /// ===============================
  Future<void> _pickDTIDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _dtiFileBytes = result.files.single.bytes;
          _dtiFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: cbocSecondary,
        ),
      );
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if DTI document is uploaded for Business users
    if (userType == 'Business' && _dtiFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your DTI document'),
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
      final result = await BackendService.registerUserForApproval(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        address: _addressController.text.trim(),
        userType: userType,
        businessName: userType == 'Business' ? _businessNameController.text.trim() : null,
        businessNature: userType == 'Business' ? _businessNatureController.text.trim() : null,
        professionalTitle: userType == 'Professional' ? _professionalTitleController.text.trim() : null,
        dtiFileBytes: userType == 'Business' ? _dtiFileBytes : null,
        dtiFileName: userType == 'Business' ? _dtiFileName : null,
      );

      setState(() {
        if (result.success) {
          _message = "Registration submitted! Wait for admin approval.";
        } else {
          _message = "Error: ${result.message}";
        }
        _isLoading = false;
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
        title: const Text(
          "Register",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => 
                value == null || value.length < 6
                ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: userType,
                decoration: const InputDecoration(labelText: 'User Type'),
                items: const [
                  DropdownMenuItem(value: 'Business', child: Text('Business')),
                  DropdownMenuItem(value: 'Professional', child: Text('Professional')),
                ],
                onChanged: (value) {
                  setState(() {
                    userType = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              if (userType == 'Business') ...[
                TextFormField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(labelText: 'Business Name'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _businessNatureController,
                  decoration: const InputDecoration(labelText: 'Nature of Business'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                // DTI Document Upload
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
                        children: [
                          const Icon(Icons.picture_as_pdf, color: cbocSecondary),
                          const SizedBox(width: 8),
                          const Text(
                            'DTI Document (Required)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_dtiFileName != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cbocAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: cbocPrimary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _dtiFileName!,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: cbocSecondary),
                                onPressed: () {
                                  setState(() {
                                    _dtiFileBytes = null;
                                    _dtiFileName = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      OutlinedButton.icon(
                        onPressed: _pickDTIDocument,
                        icon: Icon(
                          _dtiFileName == null ? Icons.upload_file : Icons.change_circle,
                          color: cbocSecondary,
                        ),
                        label: Text(
                          _dtiFileName == null ? 'Upload PDF' : 'Change File',
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
              ],
              if (userType == 'Professional') ...[
                TextFormField(
                  controller: _professionalTitleController,
                  decoration: const InputDecoration(labelText: 'Professional Title / Specialist'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
              ],
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator(color: cbocSecondary)
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
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
              if (_message != null) ...[
                const SizedBox(height: 20),
                Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _message!.contains('Error') ? cbocSecondary : Colors.green,
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