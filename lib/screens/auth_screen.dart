import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'pin_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = AuthService();
  bool _signUpMode = false;
  bool _loading = false;
  String? _error;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_signUpMode) {
        await _auth.signUpWithEmail(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          fullName: _nameCtrl.text,
        );
      } else {
        await _auth.signInWithEmail(_emailCtrl.text, _passwordCtrl.text);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PinScreen(mode: _signUpMode ? PinMode.setup : PinMode.unlock, email: _emailCtrl.text.trim()),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Something went wrong. Please try again.');
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
              Text(_signUpMode ? 'Create your account' : 'Welcome back', style: AppTheme.heading(size: 24)),
              const SizedBox(height: 4),
              Text(
                _signUpMode ? 'Join the Kingdom business network.' : 'Sign in to your Kingdom business network.',
                style: AppTheme.body(size: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 26),
              _TabSwitch(
                signUpMode: _signUpMode,
                onChanged: (v) => setState(() {
                  _signUpMode = v;
                  _error = null;
                }),
              ),
              if (_signUpMode) ...[
                _Field(label: 'Full name', icon: Icons.person_outline, controller: _nameCtrl, hint: 'Okoro Titus'),
                const SizedBox(height: 16),
              ],
              _Field(
                label: 'Email address',
                icon: Icons.mail_outline,
                controller: _emailCtrl,
                hint: 'you@email.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _Field(
                label: 'Password',
                icon: Icons.lock_outline,
                controller: _passwordCtrl,
                hint: '••••••••',
                obscure: true,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: AppTheme.body(size: 12.5, color: AppColors.danger)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Continue', style: AppTheme.body(size: 14, weight: FontWeight.w700, color: AppColors.navy)),
                ),
              ),
              const SizedBox(height: 18),
              Row(children: [
                const Expanded(child: Divider(color: AppColors.line)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('or', style: AppTheme.body(size: 11, color: AppColors.muted))),
                const Expanded(child: Divider(color: AppColors.line)),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Google Sign-In is coming in the next update.')),
                    );
                  },
                  icon: const Icon(Icons.g_mobiledata, color: AppColors.charcoal),
                  label: Text('Continue with Google', style: AppTheme.body(size: 13, weight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.cream2,
                    side: const BorderSide(color: AppColors.line),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: GestureDetector(
                  onTap: () => setState(() => _signUpMode = !_signUpMode),
                  child: RichText(
                    text: TextSpan(
                      style: AppTheme.body(size: 12.5, color: AppColors.muted),
                      children: [
                        TextSpan(text: _signUpMode ? 'Already have an account? ' : 'New here? '),
                        TextSpan(
                          text: _signUpMode ? 'Sign in' : 'Create an account',
                          style: AppTheme.body(size: 12.5, weight: FontWeight.w700, color: AppColors.navy),
                        ),
                      ],
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

class _TabSwitch extends StatelessWidget {
  final bool signUpMode;
  final ValueChanged<bool> onChanged;
  const _TabSwitch({required this.signUpMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cream2,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Expanded(child: _TabButton(label: 'Sign In', active: !signUpMode, onTap: () => onChanged(false))),
        Expanded(child: _TabButton(label: 'Sign Up', active: signUpMode, onTap: () => onChanged(true))),
      ]),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTheme.body(size: 13, weight: FontWeight.w600, color: active ? AppColors.goldSoft : AppColors.muted),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.icon,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.body(size: 11.5, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cream2,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            Icon(icon, size: 18, color: AppColors.muted),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: obscure,
                keyboardType: keyboardType,
                style: AppTheme.body(size: 14),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppTheme.body(size: 14, color: AppColors.muted),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
