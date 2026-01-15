import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/google_sign_in_provider.dart';
import 'package:flutter/foundation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isHovering = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  final username = _usernameController.text.trim();
  final password = _passwordController.text.trim();

  // dev bypass credential
  if (kDebugMode) {
    if (username == 'dev' && password == 'dev') {
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }
  

    // block everything else during dev
    setState(() {
      _errorMessage = 'DEV MODE: use username "dev" and password "dev".';
      _isLoading = false;
    });
    return;
  }  
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/logo.png',
                height: 100,
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                "Cavite Business Owners Club",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 40),

              // Username / Email
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
              const SizedBox(height: 10),

              // Remember Me + Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFFD32F2F),
                      ),
                      const Text("Remember Me"),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Forgot Password logic
                    },
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: Colors.red),
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

              // Login Button
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.red)
                  : ElevatedButton(
                      onPressed: _loginUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Log In",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(height: 20),

              // OR Divider //
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: const [
                    Flexible(child: Divider(thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text("OR SIGN IN WITH"),
                    ),
                    Flexible(child: Divider(thickness: 1)),
                  ],
                ),
              ),
              // END OF OR DIVIDER //
              const SizedBox(height: 20),
            

              // google sign in button
              Column(
                children: [

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
                        // Check if user already exists in Firestore
                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .get();

                        if (userDoc.exists) {
                          // REDIRECT TO HOME PAGE IF ALREADY REGISTERED //
                          Navigator.pushReplacementNamed(context, '/home');
                        } else {
                          // REDIRECT TO REGISTRATION PAGE IF NEW USER //
                          // (pass Google email so they don’t need to type it again) //
                          Navigator.pushReplacementNamed(
                            context,
                            '/register',
                            arguments: {
                              'email': user.email,
                              'displayName': user.displayName ?? '',
                            },
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Google sign-in failed. Please try again.")),
                        );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/google_logo.png',
                          height: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Sign in with Google",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),                            
              const SizedBox(height: 30),
              // END OF GOOGLE SIGN IN CODE //


              // Register Text with hover effect
              MouseRegion(
                onEnter: (_) => setState(() => _isHovering = true),
                onExit: (_) => setState(() => _isHovering = false),
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text(
                    "Doesn’t have an account yet? Register here",
                    style: TextStyle(
                      color: _isHovering
                          ? const Color(0xFFD32F2F)
                          : Colors.black87,
                      fontWeight:
                          _isHovering ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
