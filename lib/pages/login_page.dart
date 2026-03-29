import 'package:flutter/material.dart';
import '../backend/backend.dart';
import '../providers/google_sign_in_provider.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _isLoading = false;
  // Controls whether the password field shows plain text or dots
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await BackendService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (result.success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _errorMessage = result.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final googleProvider = GoogleSignInProvider();
    final result = await googleProvider.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google sign-in failed.")),
      );
      return;
    }

    // Check if user already has a completed profile/approval
    final profileExists = await BackendService.checkUserProfileExists(result.uid);

    if (!mounted) return;

    if (profileExists == ProfileStatus.approvedExists) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (profileExists == ProfileStatus.pendingApproval) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your account is pending admin approval.")),
      );
    } else {
      // New Google user — show registration form
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterPage(
            googleUser: result,
          ),
        ),
      );
    }
  }

  // =========================================================
  // FORGOT PASSWORD — launches the multi-step bottom sheet
  // Step 1: Enter email → send code
  // Step 2: Enter 6-digit code → verify
  // Step 3: Enter + confirm new password → reset
  // =========================================================
  void _openForgotPasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ForgotPasswordSheet(),
    );
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
              Image.asset('assets/logo.png', height: 100),
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

              // Password — with show/hide toggle icon button
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  // Tapping the suffix icon toggles visibility
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                    ),
                    tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
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
                        onChanged: (value) =>
                            setState(() => _rememberMe = value ?? false),
                        activeColor: const Color(0xFFD32F2F),
                      ),
                      const Text("Remember Me"),
                    ],
                  ),
                  TextButton(
                    // Opens the multi-step forgot-password sheet
                    onPressed: _openForgotPasswordSheet,
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Error Message
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 10),
              ],

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

              // OR Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: const [
                    Flexible(child: Divider(thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text("OR"),
                    ),
                    Flexible(child: Divider(thickness: 1)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Google Sign-In
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
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/google_logo.png', height: 24),
                    const SizedBox(width: 12),
                    const Text(
                      "Sign in with Google",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Register via Google
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFFD32F2F)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/google_logo.png', height: 22),
                    const SizedBox(width: 12),
                    const Text(
                      "Register / Sign Up using Google Account",
                      style: TextStyle(
                        color: Color(0xFFD32F2F),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// FORGOT PASSWORD BOTTOM SHEET  (self-contained, 3-step wizard)
// =============================================================
// Step 1 — _ForgotStep.email    : user enters their registered email
// Step 2 — _ForgotStep.code     : user enters the 6-digit code
// Step 3 — _ForgotStep.newPass  : user sets + confirms a new password
// =============================================================

enum _ForgotStep { email, code, newPass }

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet();

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  // ── Shared state ──────────────────────────────────────────
  _ForgotStep _step = _ForgotStep.email;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Step 1 ────────────────────────────────────────────────
  final TextEditingController _emailCtrl = TextEditingController();

  // ── Step 2 ────────────────────────────────────────────────
  // Six individual single-character controllers + focus nodes for the
  // code boxes so the cursor auto-advances after each digit.
  final List<TextEditingController> _digitCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _digitFocus =
      List.generate(6, (_) => FocusNode());

  // ── Step 3 ────────────────────────────────────────────────
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    for (final c in _digitCtrl) c.dispose();
    for (final f in _digitFocus) f.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // ── HELPERS ───────────────────────────────────────────────

  /// Returns the 6-digit code assembled from the individual boxes.
  String get _enteredCode =>
      _digitCtrl.map((c) => c.text.trim()).join();

  void _setError(String? msg) => setState(() => _errorMessage = msg);
  void _setLoading(bool v) => setState(() => _isLoading = v);

  // ── STEP 1: send code ────────────────────────────────────
  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _setError('Please enter your email address.');
      return;
    }
    _setError(null);
    _setLoading(true);

    final result = await BackendService.sendPasswordResetCode(email);

    if (!mounted) return;
    _setLoading(false);

    if (result.success) {
      // Always advance to code entry regardless of whether the email
      // exists — avoids email enumeration (same UX for known/unknown).
      setState(() => _step = _ForgotStep.code);
    } else {
      _setError(result.message);
    }
  }

  // ── STEP 2: verify code ───────────────────────────────────
  Future<void> _verifyCode() async {
    final code = _enteredCode;
    if (code.length < 6) {
      _setError('Please enter all 6 digits of the code.');
      return;
    }
    _setError(null);
    _setLoading(true);

    final result = await BackendService.verifyPasswordResetCode(
      email: _emailCtrl.text.trim(),
      code: code,
    );

    if (!mounted) return;
    _setLoading(false);

    if (result.success) {
      setState(() => _step = _ForgotStep.newPass);
    } else {
      _setError(result.message);
    }
  }

  // ── STEP 3: reset password ────────────────────────────────
  Future<void> _resetPassword() async {
    final newPass = _newPassCtrl.text.trim();
    final confirm = _confirmPassCtrl.text.trim();

    if (newPass.length < 6) {
      _setError('Password must be at least 6 characters.');
      return;
    }
    if (newPass != confirm) {
      _setError('Passwords do not match.');
      return;
    }
    _setError(null);
    _setLoading(true);

    final result = await BackendService.resetPasswordWithCode(
      email: _emailCtrl.text.trim(),
      code: _enteredCode,
      newPassword: newPass,
    );

    if (!mounted) return;
    _setLoading(false);

    if (result.success) {
      Navigator.pop(context); // close sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully. You can now log in.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _setError(result.message);
    }
  }

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Step-aware title + subtitle
            Text(
              _stepTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB71C1C),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _stepSubtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // Step content
            if (_step == _ForgotStep.email) _buildEmailStep(),
            if (_step == _ForgotStep.code) _buildCodeStep(),
            if (_step == _ForgotStep.newPass) _buildNewPassStep(),

            // Error display
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Primary action button
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
                : ElevatedButton(
                    onPressed: _onPrimaryTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _primaryLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

            // Resend code link shown on step 2
            if (_step == _ForgotStep.code) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _sendCode,
                  child: const Text(
                    "Didn't receive a code? Resend",
                    style: TextStyle(color: Color(0xFFD32F2F)),
                  ),
                ),
              ),
            ],

            // Back button for steps 2 and 3
            if (_step != _ForgotStep.email) ...[
              const SizedBox(height: 4),
              Center(
                child: TextButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() {
                            _errorMessage = null;
                            _step = _step == _ForgotStep.newPass
                                ? _ForgotStep.code
                                : _ForgotStep.email;
                          }),
                  icon: const Icon(Icons.arrow_back, size: 16,
                      color: Colors.grey),
                  label: const Text('Back',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── STEP CONTENT BUILDERS ─────────────────────────────────

  Widget _buildEmailStep() {
    return TextField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(
        labelText: 'Registered Email Address',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.email_outlined),
      ),
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 6 individual digit boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 44,
              child: TextField(
                controller: _digitCtrl[i],
                focusNode: _digitFocus[i],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                // Auto-advance focus: after typing, move to next box;
                // on delete, move back to previous box.
                onChanged: (val) {
                  if (val.length == 1 && i < 5) {
                    _digitFocus[i + 1].requestFocus();
                  } else if (val.isEmpty && i > 0) {
                    _digitFocus[i - 1].requestFocus();
                  }
                },
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: Color(0xFFD32F2F), width: 2),
                  ),
                ),
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Code sent to: ${_emailCtrl.text.trim()}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildNewPassStep() {
    return Column(
      children: [
        // New password field
        TextField(
          controller: _newPassCtrl,
          obscureText: _obscureNew,
          decoration: InputDecoration(
            labelText: 'New Password',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey,
              ),
              tooltip: _obscureNew ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Confirm password field
        TextField(
          controller: _confirmPassCtrl,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey,
              ),
              tooltip: _obscureConfirm ? 'Show password' : 'Hide password',
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
      ],
    );
  }

  // ── COMPUTED PROPS ────────────────────────────────────────

  String get _stepTitle {
    switch (_step) {
      case _ForgotStep.email:
        return 'Forgot Password';
      case _ForgotStep.code:
        return 'Enter Verification Code';
      case _ForgotStep.newPass:
        return 'Set New Password';
    }
  }

  String get _stepSubtitle {
    switch (_step) {
      case _ForgotStep.email:
        return 'Enter your registered email. We\'ll send a 6-digit verification code.';
      case _ForgotStep.code:
        return 'A 6-digit code was sent to your email. It expires in 15 minutes.';
      case _ForgotStep.newPass:
        return 'Choose a new password with at least 6 characters.';
    }
  }

  String get _primaryLabel {
    switch (_step) {
      case _ForgotStep.email:
        return 'Send Verification Code';
      case _ForgotStep.code:
        return 'Verify Code';
      case _ForgotStep.newPass:
        return 'Reset Password';
    }
  }

  VoidCallback get _onPrimaryTap {
    switch (_step) {
      case _ForgotStep.email:
        return _sendCode;
      case _ForgotStep.code:
        return _verifyCode;
      case _ForgotStep.newPass:
        return _resetPassword;
    }
  }
}