// lib/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BRAND TOKENS  (identical to home_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────
class _B {
  static const Color pink = Color(0xFFE91E8C);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color bg = Color(0xFF1A2530);
  static const Color nav = Color(0xFF111D27);
  static const Color card = Color(0xFF243040);
  static const Color border = Color(0x14FFFFFF);
  static const Color faint = Color(0x0DFFFFFF);
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _loading = false;
  bool _showPwd = false;
  bool _showConf = false;

  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _auth = FirebaseAuth.instance;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Input decoration ───────────────────────────────────────────────────────
  InputDecoration _inputStyle(
    String hint, {
    IconData? prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.28), fontSize: 13),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: Colors.white30, size: 18)
          : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _B.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _B.cyan.withOpacity(0.55), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pwd = _pwdCtrl.text.trim();

    if (email.isEmpty) {
      _err('Please enter your email');
      return;
    }
    if (pwd.isEmpty) {
      _err('Please enter your password');
      return;
    }

    if (!_isLogin) {
      if (pwd != _confirmCtrl.text) {
        _err('Passwords do not match');
        return;
      }
      if (pwd.length < 6) {
        _err('Password must be at least 6 characters');
        return;
      }
    }

    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(email: email, password: pwd);
      } else {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: pwd,
        );
        if (_phoneCtrl.text.trim().isNotEmpty) {
          await cred.user?.updateDisplayName(_phoneCtrl.text.trim());
        }
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _err(_authMsg(e.code));
    } catch (e) {
      if (mounted) _err('An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authMsg(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found. Please sign up.';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'invalid-email':
        return 'Please enter a valid email.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'Email already registered. Please login.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[900],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _toggle() {
    _animCtrl.reset();
    setState(() {
      _isLogin = !_isLogin;
      _emailCtrl.clear();
      _phoneCtrl.clear();
      _pwdCtrl.clear();
      _confirmCtrl.clear();
    });
    _animCtrl.forward();
  }

  // ── Forgot password ────────────────────────────────────────────────────────
void _forgotPassword() {
  final ctrl = TextEditingController();
  final messenger = ScaffoldMessenger.of(context); // ← capture BEFORE dialog

  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: _B.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _B.cyan.withOpacity(0.12),
                border: Border.all(color: _B.cyan.withOpacity(0.3)),
              ),
              child: const Icon(Icons.lock_reset, color: _B.cyan, size: 26),
            ),
            const SizedBox(height: 14),
            const Text(
              'Reset Password',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your email to receive a reset link.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: _inputStyle(
                'Email address',
                prefixIcon: Icons.email_outlined,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: BorderSide(color: _B.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final email = ctrl.text.trim();
                      if (email.isEmpty) {
                        messenger.showSnackBar(SnackBar(
                          content: const Text(
                            'Please enter your email',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red[900],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ));
                        return;
                      }
                      try {
                        await _auth.sendPasswordResetEmail(email: email);
                        Navigator.pop(context); // ← safe, dialog's own context
                        messenger.showSnackBar(SnackBar(
                          content: const Text(
                            'Reset email sent! Check your inbox.',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.green[800],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ));
                      } on FirebaseAuthException catch (e) {
                        Navigator.pop(context);
                        messenger.showSnackBar(SnackBar(
                          content: Row(children: [
                            const Icon(Icons.error_outline,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _authMsg(e.code),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ]),
                          backgroundColor: Colors.red[900],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _B.cyan,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Send',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _B.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero (mirrors home_screen hero style) ──────────────────────
            _buildHero(),
            // ── Auth card + footer ─────────────────────────────────────────
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
                  child: Column(
                    children: [
                      _buildCard(),
                      const SizedBox(height: 16),
                      _buildToggleRow(),
                      if (_isLogin) ...[
                        const SizedBox(height: 6),
                        _buildForgotBtn(),
                      ],
                      const SizedBox(height: 32),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero — same visual language as CustomerScreen._hero() ─────────────────
  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 32),
      decoration: BoxDecoration(
        color: _B.nav,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        border: Border(bottom: BorderSide(color: _B.border, width: 0.5)),
      ),
      child: Column(
        children: [
          // Logo ring
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _B.pink.withOpacity(0.45), width: 2),
              color: _B.pink.withOpacity(0.06),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _B.cyan.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                ClipOval(
                  child: Image.asset(
                    'assets/images/rohinixer.jpeg',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ROHINI',
                          style: TextStyle(
                            color: _B.pink,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const Text(
                          'XERO',
                          style: TextStyle(
                            color: _B.cyan,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'ROHINI ',
                  style: TextStyle(
                    color: _B.pink,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                TextSpan(
                  text: 'XEROX',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'KING OF XEROX · SINCE 2002',
            style: TextStyle(fontSize: 11, color: _B.cyan, letterSpacing: 2.0),
          ),
          const SizedBox(height: 20),
          // Same badges as home screen hero
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _badge(Icons.security_outlined, 'Secure', _B.cyan),
              const SizedBox(width: 10),
              _badge(Icons.bolt_outlined, 'Fast', _B.pink),
              const SizedBox(width: 10),
              _badge(
                Icons.support_agent_outlined,
                'Support',
                const Color(0xFF9C27B0),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Mode pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _B.faint,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _B.border, width: 0.5),
            ),
            child: Text(
              _isLogin ? '👋  Welcome back!' : '🚀  Create your account',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.25), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Main card — same _Card style as home_screen ────────────────────────────
  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _B.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _B.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header row — icon + title
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _B.pink.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _B.pink.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  _isLogin
                      ? Icons.login_rounded
                      : Icons.person_add_alt_1_rounded,
                  color: _B.pink,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isLogin ? 'Welcome back!' : 'Create account',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _isLogin ? 'Sign in to continue' : 'Sign up to get started',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.38),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: _B.border, height: 1),
          const SizedBox(height: 20),

          // Email
          _fieldLabel('Email Address', Icons.email_outlined, _B.cyan),
          const SizedBox(height: 6),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputStyle(
              'e.g. you@email.com',
              prefixIcon: Icons.email_outlined,
            ),
          ),
          const SizedBox(height: 14),

          // Phone (signup only)
          if (!_isLogin) ...[
            _fieldLabel('Phone Number', Icons.phone_outlined, Colors.white38),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: _inputStyle(
                'Optional',
                prefixIcon: Icons.phone_outlined,
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Password
          _fieldLabel('Password', Icons.lock_outline, _B.cyan),
          const SizedBox(height: 6),
          TextField(
            controller: _pwdCtrl,
            obscureText: !_showPwd,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputStyle(
              'Enter password',
              prefixIcon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  _showPwd
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white30,
                  size: 18,
                ),
                onPressed: () => setState(() => _showPwd = !_showPwd),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Confirm password (signup only)
          if (!_isLogin) ...[
            _fieldLabel('Confirm Password', Icons.lock_outline, _B.cyan),
            const SizedBox(height: 6),
            TextField(
              controller: _confirmCtrl,
              obscureText: !_showConf,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: _inputStyle(
                'Re-enter password',
                prefixIcon: Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    _showConf
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.white30,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _showConf = !_showConf),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          const SizedBox(height: 4),

          // Submit button — identical style to home screen CTA
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _B.pink,
                disabledBackgroundColor: Colors.white10,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white30,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: _loading ? 0 : 6,
                shadowColor: _B.pink.withOpacity(0.4),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isLogin
                              ? Icons.login_rounded
                              : Icons.person_add_alt_1_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isLogin ? 'Login' : 'Create Account',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label, IconData icon, Color c) => Row(
    children: [
      Icon(icon, size: 13, color: c),
      const SizedBox(width: 5),
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.42),
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    ],
  );

  // ── Toggle row ─────────────────────────────────────────────────────────────
  Widget _buildToggleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account?" : 'Already have an account?',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
        ),
        TextButton(
          onPressed: _loading ? null : _toggle,
          style: TextButton.styleFrom(
            foregroundColor: _B.cyan,
            padding: const EdgeInsets.only(left: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _isLogin ? 'Sign Up' : 'Login',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _B.cyan,
            ),
          ),
        ),
      ],
    );
  }

  // ── Forgot password button ─────────────────────────────────────────────────
  Widget _buildForgotBtn() {
    return Center(
      child: TextButton(
        onPressed: _loading ? null : _forgotPassword,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white30,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Forgot Password?', style: TextStyle(fontSize: 12)),
      ),
    );
  }

  // ── Footer — identical to home_screen footer ───────────────────────────────
  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'ROHINI XEROX',
          style: TextStyle(
            color: Colors.white.withOpacity(0.15),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'KING OF XEROX · SINCE 2002',
          style: TextStyle(
            color: Colors.white.withOpacity(0.08),
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
