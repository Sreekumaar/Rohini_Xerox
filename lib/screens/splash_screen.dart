// lib/screens/splash_screen.dart
//
// Rohini Xerox — Animated Splash Screen
// Navigates to HomeScreen after animation completes (~3 seconds)

import 'dart:math';
import 'package:flutter/material.dart';
import 'auth_gate.dart';
// import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Brand colors ────────────────────────────────────────────────────────
  static const Color _pink = Color(0xFFE91E8C);
  static const Color _cyan = Color(0xFF00BCD4);
  static const Color _bg = Color(0xFF1A2530);
  static const Color _nav = Color(0xFF111D27);

  // ── Animation controllers ───────────────────────────────────────────────
  late final AnimationController _ringCtrl;
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _tagCtrl;
  late final AnimationController _badgeCtrl;
  late final AnimationController _exitCtrl;
  late final AnimationController _rotateCtrl;

  // ── Animations ───────────────────────────────────────────────────────────
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textSlide;
  late final Animation<double> _textOpacity;
  late final Animation<double> _tagOpacity;
  late final Animation<double> _badgeOpacity;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _rotate;

  @override
  void initState() {
    super.initState();

    // Slow continuous ring rotation
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _rotate = Tween(begin: 0.0, end: 2 * pi).animate(_rotateCtrl);

    // Ring pulse in
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _ringScale = Tween(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.elasticOut));
    _ringOpacity = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeIn));

    // Logo pop in
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoScale = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn));

    // ROHINI XEROX text slide up
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _textSlide = Tween(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textOpacity = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn));

    // Tagline fade in
    _tagCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _tagOpacity = Tween(begin: 0.0, end: 1.0).animate(_tagCtrl);

    // Badges fade in
    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _badgeOpacity = Tween(begin: 0.0, end: 1.0).animate(_badgeCtrl);

    // Exit fade out
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _exitOpacity = Tween(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _ringCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _logoCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 350));
    _textCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _tagCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 250));
    _badgeCtrl.forward();

    // Hold for a moment then exit
    await Future.delayed(const Duration(milliseconds: 900));
    await _exitCtrl.forward();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AuthGate(),
          transitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _tagCtrl.dispose();
    _badgeCtrl.dispose();
    _exitCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitOpacity,
      builder: (_, child) => Opacity(opacity: _exitOpacity.value, child: child),
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            // ── Subtle background glow ───────────────────────────────────
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_pink.withOpacity(0.08), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_cyan.withOpacity(0.07), Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── Main content ─────────────────────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Animated logo ring ───────────────────────────────
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _ringScale,
                      _ringOpacity,
                      _logoScale,
                      _logoOpacity,
                      _rotate,
                    ]),
                    builder: (_, __) => Opacity(
                      opacity: _ringOpacity.value,
                      child: Transform.scale(
                        scale: _ringScale.value,
                        child: SizedBox(
                          width: 140,
                          height: 140,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer rotating dashed ring
                              Transform.rotate(
                                angle: _rotate.value,
                                child: CustomPaint(
                                  size: const Size(140, 140),
                                  painter: _DashedCirclePainter(
                                    color: _pink.withOpacity(0.35),
                                    strokeWidth: 1.5,
                                    dashes: 12,
                                  ),
                                ),
                              ),
                              // Static inner ring
                              Container(
                                width: 116,
                                height: 116,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _cyan.withOpacity(0.25),
                                    width: 1,
                                  ),
                                  color: _pink.withOpacity(0.06),
                                ),
                              ),
                              // Logo text inside ring
                              Opacity(
                                opacity: _logoOpacity.value,
                                child: Transform.scale(
                                  scale: _logoScale.value,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'ROHINI',
                                        style: TextStyle(
                                          color: _pink.withOpacity(0.95),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.5,
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'XEROX',
                                        style: TextStyle(
                                          color: _cyan,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 2,
                                          height: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── ROHINI XEROX heading ─────────────────────────────
                  AnimatedBuilder(
                    animation: Listenable.merge([_textSlide, _textOpacity]),
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: Opacity(
                        opacity: _textOpacity.value,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'ROHINI ',
                                style: TextStyle(
                                  color: _pink,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              const TextSpan(
                                text: 'XEROX',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Tagline ──────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _tagOpacity,
                    builder: (_, __) => Opacity(
                      opacity: _tagOpacity.value,
                      child: const Text(
                        'KING OF XEROX · SINCE 2002',
                        style: TextStyle(
                          fontSize: 11,
                          color: _cyan,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Badges row ───────────────────────────────────────
                  AnimatedBuilder(
                    animation: _badgeOpacity,
                    builder: (_, __) => Opacity(
                      opacity: _badgeOpacity.value,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _badge(Icons.security_outlined, 'Secure', _cyan),
                          const SizedBox(width: 10),
                          _badge(Icons.bolt_outlined, 'Fast', _pink),
                          const SizedBox(width: 10),
                          _badge(
                            Icons.support_agent_outlined,
                            'Support',
                            const Color(0xFF9C27B0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom version text ──────────────────────────────────────
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _badgeOpacity,
                builder: (_, __) => Opacity(
                  opacity: _badgeOpacity.value * 0.4,
                  child: const Column(
                    children: [
                      Text(
                        'ROHINI XEROX',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Digital Print Services',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
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

  Widget _badge(IconData icon, String label, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHED CIRCLE PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int dashes;

  const _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;
    final dashAngle = (2 * pi) / (dashes * 2);

    for (int i = 0; i < dashes; i++) {
      final startAngle = i * 2 * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.dashes != dashes;
}
