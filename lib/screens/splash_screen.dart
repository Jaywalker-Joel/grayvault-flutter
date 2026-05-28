import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Controllers ───────────────────────────────────────────────────────────
  late AnimationController _logoCtrl;
  late AnimationController _lineCtrl;
  late AnimationController _brandCtrl;
  late AnimationController _exitCtrl;

  // ── Logo animations ───────────────────────────────────────────────────────
  late Animation<double>  _logoScale;
  late Animation<double>  _logoFade;
  late Animation<Offset>  _graySlide;
  late Animation<double>  _grayFade;
  late Animation<Offset>  _vaultSlide;
  late Animation<double>  _vaultFade;

  // ── Underline ─────────────────────────────────────────────────────────────
  late Animation<double>  _lineWidth;

  // ── Brand name ────────────────────────────────────────────────────────────
  late Animation<double>  _brandFade;

  // ── Exit ─────────────────────────────────────────────────────────────────
  late Animation<double>  _exitFade;

  static const _bg        = Color(0xFF111111);
  static const _green     = Color(0xFF1D9E75);
  static const _greenDark = Color(0xFF085041);

  @override
  void initState() {
    super.initState();

    // Logo controller — handles image scale+fade + text slides (0–1400ms)
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // "GRAY" slides in from left
    _graySlide = Tween<Offset>(
      begin: const Offset(-0.4, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoCtrl,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
    ));
    _grayFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );

    // "VAULT" slides in from right slightly after
    _vaultSlide = Tween<Offset>(
      begin: const Offset(0.4, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoCtrl,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
    ));
    _vaultFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.5, 0.78, curve: Curves.easeOut),
      ),
    );

    // Line draws in after logo (0–600ms, starts after logo finishes)
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _lineWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _lineCtrl, curve: Curves.easeOutCubic),
    );

    // Brand name fades in (0–600ms, starts after line)
    _brandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _brandFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _brandCtrl, curve: Curves.easeOut),
    );

    // Exit fade out
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    // 1. Logo image + text slides in
    await _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 80));

    // 2. Underline draws in
    await _lineCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 120));

    // 3. Brand name fades in
    await _brandCtrl.forward();

    // 4. Hold for a beat
    await Future.delayed(const Duration(milliseconds: 900));

    // 5. Fade out everything
    await _exitCtrl.forward();

    // 6. Navigate
    if (!mounted) return;
    final auth = context.read<AuthService>();
    await auth.checkLoginStatus();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _lineCtrl.dispose();
    _brandCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _exitFade,
        child: Stack(
          children: [
            // ── Centred logo + wordmark ──────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo image
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: Image.asset(
                        'assets/images/grayvault.png',
                        width: size.width * 0.48,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // GRAY  VAULT  wordmark
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      // GRAY
                      SlideTransition(
                        position: _graySlide,
                        child: FadeTransition(
                          opacity: _grayFade,
                          child: Text(
                            'GRAY',
                            style: GoogleFonts.inter(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ),
                      // VAULT
                      SlideTransition(
                        position: _vaultSlide,
                        child: FadeTransition(
                          opacity: _vaultFade,
                          child: Text(
                            'VAULT',
                            style: GoogleFonts.inter(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: _green,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Animated underline
                  AnimatedBuilder(
                    animation: _lineWidth,
                    builder: (_, __) => Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: (size.width * 0.52) * _lineWidth.value,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_green, _greenDark],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── "Jaywalker Inc." — bottom right ──────────────────────────
            Positioned(
              bottom: 36 + MediaQuery.of(context).padding.bottom,
              right: 24,
              child: FadeTransition(
                opacity: _brandFade,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Jaywalker Inc.',
                      style: GoogleFonts.inter(
                        color: _green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your money. Your rules.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF444444),
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
