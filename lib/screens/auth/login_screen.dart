import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _pinCtrl   = TextEditingController();
  String _error    = '';
  bool   _loading  = false;

  @override
  void dispose() { _emailCtrl.dispose(); _pinCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ar = ref.watch(langProvider) == 'ar';
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: PepperGradients.landing),
        child: SafeArea(child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PepperColors.purple.withValues(alpha: 0.22)),
              boxShadow: [BoxShadow(color: PepperColors.purple.withValues(alpha: 0.1), blurRadius: 20)],
            ),
            child: Column(children: [
              const Text('🤖', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(ar ? '🔑 دخول' : '🔑 Login',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: PepperColors.dark)),
              const SizedBox(height: 6),
              Text(ar ? 'بيبر كلينيكال إنفينيتي V6' : 'Pepper Clinical Infinity V6',
                  style: TextStyle(fontSize: 11, color: PepperColors.dark.withValues(alpha: 0.5))),
              const SizedBox(height: 24),
              TextField(
                controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: ar ? 'البريد الإلكتروني' : 'Email address',
                  prefixIcon: const Icon(Icons.email_outlined, color: PepperColors.purple),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pinCtrl, obscureText: true,
                keyboardType: TextInputType.number, maxLength: 6,
                decoration: InputDecoration(
                  hintText: ar ? 'رقم PIN (6 أرقام)' : 'PIN (6 digits)',
                  prefixIcon: const Icon(Icons.lock_outline, color: PepperColors.purple),
                  counterText: '',
                ),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error,
                      style: const TextStyle(color: Colors.red, fontSize: 11),
                      textAlign: TextAlign.center),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _doLogin,
                  child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(ar ? '🚀 دخول' : '🚀 Login',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/trial'),
                child: Text(
                  ar ? 'ليس لديك حساب؟ ابدأ التجربة المجانية'
                     : "Don't have an account? Start free trial",
                  style: const TextStyle(color: PepperColors.purple, fontSize: 12)),
              ),
              TextButton(
                onPressed: () => context.go('/'),
                child: Text(ar ? '← الرئيسية' : '← Home',
                    style: TextStyle(color: PepperColors.dark.withValues(alpha: 0.45), fontSize: 11)),
              ),
            ]),
          ),
        ))),
      ),
    );
  }

  Future<void> _doLogin() async {
    final ar    = ref.read(langProvider) == 'ar';
    final email = _emailCtrl.text.trim();
    final pin   = _pinCtrl.text.trim();
    if (email.isEmpty || pin.isEmpty) {
      setState(() => _error = ar ? 'الرجاء ملء جميع الحقول' : 'Please fill all fields');
      return;
    }
    setState(() { _loading = true; _error = ''; });
    try {
      final user = await AppDatabase.instance.loginPin(email, pin);
      if (user == null) {
        setState(() {
          _error   = ar ? 'بريد أو PIN غير صحيح' : 'Invalid email or PIN';
          _loading = false;
        });
        return;
      }
      if (!AppDatabase.instance.isLicenseValid(user)) {
        setState(() {
          _error   = ar ? 'انتهى الاشتراك. يرجى التجديد.' : 'License expired. Please renew.';
          _loading = false;
        });
        return;
      }
      ref.read(authProvider.notifier).setAuth(user);
      if (mounted) context.go('/children');
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }
}
