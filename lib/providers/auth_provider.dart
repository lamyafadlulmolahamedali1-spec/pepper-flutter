import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. مزود حالة مصادقة المستخدم بنظام Notifier الحديث
class AuthNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() {
    return null; // الحالة الابتدائية
  }

  void setAuth(Map<String, dynamic>? data) {
    state = data;
  }

  void clearAuth() {
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, Map<String, dynamic>?>(() {
  return AuthNotifier();
});

final currentUserProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(authProvider);
});

// 2. مزود لغة النظام للتحكم بروبوت Pepper بنظام Notifier الحديث
class LangNotifier extends Notifier<String> {
  @override
  String build() {
    return 'ar'; // اللغة الافتراضية
  }

  void toggleLanguage() {
    state = state == 'ar' ? 'en' : 'ar';
  }
  
  void setLanguage(String lang) {
    state = lang;
  }
}

final langProvider = NotifierProvider<LangNotifier, String>(() {
  return LangNotifier();
});
