import 'package:flutter/material.dart';
import '../services/pin_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'auth_screen.dart';

enum PinMode { setup, unlock }

class PinScreen extends StatefulWidget {
  final PinMode mode;
  final String email;
  const PinScreen({super.key, required this.mode, required this.email});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _pinService = PinService();
  String _pin = '';
  String? _error;
  late PinMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    // If this is a "sign in" that lands here but no PIN has been set up
    // yet on this device (e.g. first login on a new phone), fall back to
    // asking them to create one instead of unlocking one that isn't there.
    if (_mode == PinMode.unlock) {
      _pinService.hasPin().then((has) {
        if (!has && mounted) setState(() => _mode = PinMode.setup);
      });
    }
  }

  Future<void> _press(String key) async {
    if (key == 'back') {
      setState(() => _pin = _pin.isEmpty ? _pin : _pin.substring(0, _pin.length - 1));
      return;
    }
    if (_pin.length >= 4) return;
    setState(() {
      _pin += key;
      _error = null;
    });
    if (_pin.length == 4) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (_mode == PinMode.setup) {
        await _pinService.setPin(_pin);
        _goHome();
      } else {
        final ok = await _pinService.verifyPin(_pin);
        if (ok) {
          _goHome();
        } else {
          setState(() {
            _error = 'Incorrect PIN. Try again.';
            _pin = '';
          });
        }
      }
    }
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  Future<void> _forgotPin() async {
    await _pinService.clearPin();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
  }

  String get _initials {
    final parts = widget.email.split('@').first.split(RegExp(r'[._]'));
    if (parts.isEmpty) return '?';
    final first = parts[0].isNotEmpty ? parts[0][0] : '';
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 4,
              child: IconButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                ),
                icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.navy),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 70),
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.navy),
                  alignment: Alignment.center,
                  child: Text(_initials, style: AppTheme.heading(size: 20, color: AppColors.goldSoft)),
                ),
                const SizedBox(height: 14),
                Text(
                  _mode == PinMode.setup ? 'Create your PIN' : 'Enter your PIN',
                  style: AppTheme.heading(size: 19),
                ),
                const SizedBox(height: 4),
                Text(widget.email, style: AppTheme.body(size: 12.5, color: AppColors.muted)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 20,
                  child: _error != null
                      ? Text(_error!, style: AppTheme.body(size: 12, color: AppColors.danger))
                      : null,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < _pin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? AppColors.navy : AppColors.cream2,
                        border: Border.all(color: filled ? AppColors.navy : AppColors.line, width: 1.6),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 36),
                _Keypad(onPress: _press),
                const SizedBox(height: 22),
                if (_mode == PinMode.unlock)
                  GestureDetector(
                    onTap: _forgotPin,
                    child: Text('Forgot PIN?', style: AppTheme.body(size: 12, weight: FontWeight.w700, color: AppColors.navy)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onPress;
  const _Keypad({required this.onPress});

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'back'];
    return SizedBox(
      width: 270,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1,
        children: keys.map((k) {
          if (k.isEmpty) return const SizedBox.shrink();
          return GestureDetector(
            onTap: () => onPress(k),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cream2,
                border: Border.all(color: AppColors.line),
              ),
              alignment: Alignment.center,
              child: k == 'back'
                  ? const Icon(Icons.backspace_outlined, size: 20, color: AppColors.muted)
                  : Text(k, style: AppTheme.body(size: 19, weight: FontWeight.w600)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
