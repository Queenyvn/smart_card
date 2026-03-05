import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../backend/backend.dart';
import 'package:firebase_auth/firebase_auth.dart';

// CBOC Branding Colors
const Color cbocPrimary = Color(0xFFB71C1C);
const Color cbocSecondary = Color(0xFFD32F2F);
const Color cbocAccent = Color(0xFFFFCDD2);
const Color cbocBackground = Color(0xFFD2F8D2);

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

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_orFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your Official Receipt (OR) document'),
          backgroundColor: cbocBackground,
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
        title: const Text("Complete Registration", style: TextStyle(color: Colors.white)),
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
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          Text(
                            widget.googleUser.email ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Password
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) =>
                    value == null || value.length < 6
                        ? 'Password must be at least 6 characters'
                        : null,
              ),
              const SizedBox(height: 12),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Business Name
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(labelText: 'Business Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Nature of Business
              TextFormField(
                controller: _businessNatureController,
                decoration: const InputDecoration(labelText: 'Nature of Business'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                            const Icon(Icons.check_circle, color: cbocPrimary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _orFileName!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: cbocSecondary),
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
                        _orFileName == null ? Icons.upload_file : Icons.change_circle,
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
                  ? const Center(child: CircularProgressIndicator(color: cbocSecondary))
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

              // Result message
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