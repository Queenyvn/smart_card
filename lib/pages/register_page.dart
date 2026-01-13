  import 'package:flutter/material.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import '../providers/google_sign_in_provider.dart';
  import 'edit_profile.dart'; // for full form

  class RegisterPage extends StatefulWidget {
    const RegisterPage({super.key});

    @override
    State<RegisterPage> createState() => _RegisterPageState();
  }

  class _RegisterPageState extends State<RegisterPage> {
    final TextEditingController _firstNameController = TextEditingController();
    final TextEditingController _lastNameController = TextEditingController();
    final TextEditingController _usernameController = TextEditingController(); 
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _confirmPasswordController = TextEditingController();

    bool _acceptTerms = false;
    bool _isLoading = false;
    String? _errorMessage;

    @override
    void dispose() {
      _firstNameController.dispose();
      _lastNameController.dispose();
      _usernameController.dispose();
      _emailController.dispose();
      _passwordController.dispose();
      _confirmPasswordController.dispose();
      super.dispose();
    }

    Future<void> _registerUser() async {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();

      if (username.isEmpty ||
          email.isEmpty ||
          password.isEmpty ||
          confirmPassword.isEmpty) {
        setState(() {
          _errorMessage = "Please fill out all fields.";
          _isLoading = false;
        });
        return;
      }

      if (password != confirmPassword) {
        setState(() {
          _errorMessage = "Passwords do not match.";
          _isLoading = false;
        });
        return;
      }

      try {
        // Check if username already exists
        final usernameQuery = await FirebaseFirestore.instance
            .collection('usernames')
            .where('username', isEqualTo: username)
            .get();

        if (usernameQuery.docs.isNotEmpty) {
          setState(() {
            _errorMessage = "Username already taken.";
            _isLoading = false;
          });
          return;
        }

        // Create user in Firebase Auth
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Save username to email mapping in Firestore
        await FirebaseFirestore.instance.collection('usernames').add({
          'username': username,
          'email': email,
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'uid': userCredential.user!.uid,
        });

        // Navigate to full profile form
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EditProfilePage(fromRegister: true),
          ),
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          if (e.code == 'email-already-in-use') {
            _errorMessage = "This email is already registered.";
          } else if (e.code == 'invalid-email') {
            _errorMessage = "The email address is badly formatted.";
          } else if (e.code == 'weak-password') {
            _errorMessage = "Password should be at least 6 characters.";
          } else {
            _errorMessage = "Registration failed: ${e.message}";
          }
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = "An error occurred. Please try again.";
          _isLoading = false;
        });
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFD32F2F), 
          title: const Text("Register"),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // First & Last Name
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: "First Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: "Last Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Username
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),

              // Email
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 20),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 20),

              // Confirm Password
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 20),

              // Terms & Privacy Policy
              Row(
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptTerms = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFFD32F2F), // CBOC Red
                  ),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.black),
                        children: [
                          TextSpan(text: "I accept "),
                          TextSpan(
                            text: "terms and privacy policy",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Error Message
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              if (_errorMessage != null) const SizedBox(height: 10),

              // Register Button
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.red)
                  : ElevatedButton(
                      onPressed: () {
                        if (_acceptTerms) {
                          _registerUser();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Please accept the terms and privacy policy."),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F), 
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Continue",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(height: 20),

              //Google Sign In ButtonOutlinedButton
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () async {
                  final googleProvider = GoogleSignInProvider();
                  final user = await googleProvider.signInWithGoogle();

                  if (user != null) {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                      'firstName': _firstNameController.text.trim(),
                      'lastName': _lastNameController.text.trim(),
                      'username': _usernameController.text.trim(),
                      'email': user.email,
                      'uid': user.uid,
                      'createdAt': Timestamp.now(),
                    });

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePage(fromRegister: true),
                      ),
                    );
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/google_logo.png', //
                      height: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Sign up with Google",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // END OF Google Sign In Button CODE //


              // Already Have Account? Login
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  "Already have an account? Log In here",
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
