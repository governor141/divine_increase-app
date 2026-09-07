import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'pin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _autoAdvance;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _autoAdvance = Timer(const Duration(seconds: 3), _goNext);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _autoAdvance?.cancel();
    super.dispose();
  }

  void _goNext() {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Already signed in from last time — just ask for the PIN instead
      // of making them sign in with email/password all over again.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PinScreen(mode: PinMode.unlock, email: user.email ?? '')),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _goNext,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.1,
              colors: [AppColors.navy2, AppColors.navy],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, child) {
                          final glow = 0.12 + (_pulse.value * 0.12);
                          return Container(
                            width: 132,
                            height: 132,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.gold.withOpacity(0.08),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withOpacity(glow),
                                  blurRadius: 60,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 104,
                            height: 104,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text('Divine Increase', style: AppTheme.heading(size: 22, color: AppColors.goldSoft)),
                      const SizedBox(height: 6),
                      Text(
                        'SPIRITUS SANCTUS IGNIS MINISTRY',
                        style: AppTheme.body(size: 11, color: const Color(0xFF9CA1B5)),
                      ),
                      const SizedBox(height: 26),
                      _Dots(controller: _pulse),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 44,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Tap to continue',
                    textAlign: TextAlign.center,
                    style: AppTheme.body(size: 11, color: const Color(0xFF7B8095)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final AnimationController controller;
  const _Dots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final phase = (controller.value + (i * 0.2)) % 1.0;
            final opacity = (0.3 + (phase < 0.5 ? phase : 1 - phase)).clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(opacity),
              ),
            );
          },
        );
      }),
    );
  }
}
