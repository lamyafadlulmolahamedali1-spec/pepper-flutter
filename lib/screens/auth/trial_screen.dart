import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class TrialScreen extends ConsumerStatefulWidget {
  const TrialScreen({super.key});
  @override
  ConsumerState<TrialScreen> createState() => _TrialScreenState();
}

class _TrialScreenState extends ConsumerState<TrialScreen> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cnameCtrl = TextEditingController();
  int    _cage     = 6;
  bool   _consent  = false;
  bool   _loading  = false;
  String _error    = '';

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _cnameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = ref.watch(langProvider) == 'ar';
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: PepperGradients.landing),
        child: SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PepperColors.purple.withValues(alpha: 0.22)),
              boxShadow: [BoxShadow(color: PepperColors.purple.withValues(alpha: 0.1), blurRadius: 20)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Header
              Center(child: Column(children: [
                const Text('🆓', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 6),
                Text(ar ? 'ابدأ تجربتك المجانية' : 'Start Your Free Trial',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                        color: PepperColors.dark)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: PepperColors.purple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: PepperColors.purple.withValues(alpha: 0.3)),
                  ),
                  child: Text(ar ? '15 يوماً مجاناً · بدون بطاقة ائتمانية'
                                 : '15 Days Free · No Credit Card',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: PepperColors.purpleDark)),
                ),
              ])),

              const SizedBox(height: 24),

              // Parent Name
              _Label(ar ? 'اسم ولي الأمر / المعالج' : 'Parent / Therapist Name'),
              TextField(
                controller: _nameCtrl,
                textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: ar ? 'الاسم الكامل' : 'Full name',
                  prefixIcon: const Icon(Icons.person_outline, color: PepperColors.purple),
                ),
              ),
              const SizedBox(height: 12),

              // Email
              _Label(ar ? 'البريد الإلكتروني' : 'Email Address'),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: 'example@email.com',
                  prefixIcon: const Icon(Icons.email_outlined, color: PepperColors.purple),
                ),
              ),
              const SizedBox(height: 12),

              // Child Name
              _Label(ar ? 'اسم الطفل' : "Child's Name"),
              TextField(
                controller: _cnameCtrl,
                textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: ar ? 'اسم طفلك' : "Your child's name",
                  prefixIcon: const Icon(Icons.child_care, color: PepperColors.purple),
                ),
              ),
              const SizedBox(height: 12),

              // Child Age
              _Label(ar ? 'عمر الطفل' : "Child's Age"),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F5FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PepperColors.purple.withValues(alpha: 0.25)),
                ),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: PepperColors.purple),
                    onPressed: () => setState(() => _cage = (_cage - 1).clamp(2, 18)),
                  ),
                  Expanded(child: Text(
                    ar ? '$_cage سنوات' : '$_cage years',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: PepperColors.purple),
                  )),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: PepperColors.purple),
                    onPressed: () => setState(() => _cage = (_cage + 1).clamp(2, 18)),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // Consent
              GestureDetector(
                onTap: () => setState(() => _consent = !_consent),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _consent
                        ? PepperColors.purple.withValues(alpha: 0.06)
                        : Colors.grey.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _consent
                        ? PepperColors.purple.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Checkbox(
                      value: _consent, activeColor: PepperColors.purple,
                      onChanged: (v) => setState(() => _consent = v ?? false),
                    ),
                    Expanded(child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        ar ? 'أوافق على شروط الخدمة وسياسة الخصوصية. أفهم أن بيبر كلينيكال أداة مساعدة وليس بديلاً عن الرعاية الطبية المتخصصة.'
                           : 'I agree to the Terms of Service and Privacy Policy. I understand Pepper Clinical is a support tool, not a substitute for professional medical care.',
                        style: TextStyle(fontSize: 10, height: 1.55,
                            color: PepperColors.dark.withValues(alpha: 0.65)),
                      ),
                    )),
                  ]),
                ),
              ),

              // Error
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                  ),
                  child: Text(_error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 11)),
                ),
              ],

              const SizedBox(height: 20),

              // Submit
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: (_loading || !_consent) ? null : _doTrial,
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: PepperColors.purple.withValues(alpha: 0.3),
                  ),
                  child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(ar ? '🚀 ابدأ التجربة المجانية الآن'
                               : '🚀 Start Free Trial Now',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),

              const SizedBox(height: 12),
              Center(child: TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  ar ? 'لديك حساب بالفعل؟ تسجيل الدخول'
                     : 'Already have an account? Login',
                  style: const TextStyle(color: PepperColors.purple, fontSize: 12)),
              )),
              Center(child: TextButton(
                onPressed: () => context.go('/'),
                child: Text(ar ? '← الرئيسية' : '← Home',
                    style: TextStyle(color: PepperColors.dark.withValues(alpha: 0.4), fontSize: 11)),
              )),
            ]),
          )),
        )),
      ),
    );
  }

  Future<void> _doTrial() async {
    final ar    = ref.read(langProvider) == 'ar';
    final name  = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final cname = _cnameCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || cname.isEmpty) {
      setState(() => _error = ar ? 'الرجاء ملء جميع الحقول' : 'Please fill all fields');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = ar ? 'بريد إلكتروني غير صحيح' : 'Invalid email address');
      return;
    }

    setState(() { _loading = true; _error = ''; });

    try {
      final result = await AppDatabase.instance.createTrialUser(
        email: email, fullName: name,
        childName: cname, childAge: _cage,
        lang: ar ? 'ar' : 'en',
      );
      final user = await AppDatabase.instance.getUser(result['userId']!);
      ref.read(authProvider.notifier).setAuth(user);

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('✅', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(ar ? 'تم التسجيل بنجاح!' : 'Registration Successful!',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: PepperColors.dark)),
            const SizedBox(height: 12),
            Text(ar ? 'رقم PIN الخاص بك:' : 'Your Personal PIN:',
                style: TextStyle(fontSize: 12, color: PepperColors.dark.withValues(alpha: 0.6))),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [PepperColors.lavender, Color(0xFFF5F0FF)]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: PepperColors.purple, width: 2),
              ),
              child: Text(result['pin']!,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900,
                      color: PepperColors.purple, letterSpacing: 8)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Text(
                ar ? '⚠️ احتفظ بهذا الرقم — ستحتاجه لتسجيل الدخول لاحقاً. لن يُرسل بالبريد.'
                   : '⚠️ Save this PIN — you will need it to login later. It will not be emailed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.orange.shade800, height: 1.5)),
            ),
          ]),
          actions: [
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); context.go('/children'); },
                child: Text(ar ? '🚀 ابدأ الآن!' : '🚀 Let\'s Start!',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _error   = e.toString().contains('UNIQUE')
          ? (ar ? 'البريد الإلكتروني مسجّل مسبقاً. جرّب تسجيل الدخول.'
                : 'Email already registered. Try logging in.')
          : e.toString();
        _loading = false;
      });
    }
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: PepperColors.darkMid, letterSpacing: 0.3)),
  );
}
