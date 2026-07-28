# 🤖 Pepper Clinical Infinity V6 — Flutter Mobile App
## © 2026 Lamya Fadlulmola Hamed Ali — All Rights Reserved

AI-powered autism therapy platform for **Android & iOS**  
100% offline · Arabic & English · Google ML Kit · TFLite · SQLite

---

## 📁 Project Structure

```
pepper_flutter_v6/
├── lib/
│   ├── main.dart                    # App entry point + router
│   ├── core/
│   │   ├── database.dart            # SQLite — users, children, sessions, tasks
│   │   └── theme.dart               # Colors, gradients, typography
│   ├── providers/
│   │   └── auth_provider.dart       # Riverpod state — user + language
│   ├── services/
│   │   ├── ai_service.dart          # ML Kit + TFLite — on-device AI
│   │   └── task_service.dart        # 100K+ adaptive task generator
│   └── screens/
│       ├── landing_screen.dart      # Full landing page with animations
│       ├── auth/
│       │   ├── login_screen.dart    # PIN login
│       │   └── trial_screen.dart    # Free trial registration
│       ├── child/
│       │   └── children_screen.dart # Child profiles + skill bars
│       ├── session/
│       │   └── session_screen.dart  # Therapy session + camera + PECS
│       └── dashboard/
│           └── dashboard_screen.dart # Analytics + charts + history
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml      # Camera + mic permissions
├── ios/
│   └── Runner/
│       └── Info.plist               # iOS permissions
└── pubspec.yaml                     # All dependencies
```

---

## 🚀 How to Run

### Prerequisites
```bash
# Install Flutter 3.22+
flutter --version

# Check everything is ready
flutter doctor
```

### Run on Android/iOS
```bash
cd pepper_flutter_v6

# Get dependencies
flutter pub get

# Connect device or start emulator, then:
flutter run

# Run on specific device
flutter run -d android
flutter run -d ios
```

---

## 📦 Build APK / IPA

### Android APK (Protected + Obfuscated)
```bash
# Debug (for testing)
flutter build apk --debug

# Release (production — obfuscated)
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/debug-info \
  --target-platform android-arm64

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Google Play)
```bash
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/debug-info

# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS IPA (App Store)
```bash
flutter build ios --release \
  --obfuscate \
  --split-debug-info=build/debug-info

# Then in Xcode: Product → Archive → Distribute App
```

---

## 🔒 Code Protection

### What `--obfuscate` does:
- Renames ALL class names, method names, variables to random strings
- `SessionScreen` becomes `a1b.c2d()`
- Cannot be reverse-engineered or decompiled meaningfully
- `--split-debug-info` stores debug symbols separately (not in app)

### Additional Android Protection (build.gradle):
```groovy
android {
    buildTypes {
        release {
            minifyEnabled true       // Remove unused code
            shrinkResources true     // Remove unused resources
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                         'proguard-rules.pro'
        }
    }
}
```

### ProGuard Rules (android/app/proguard-rules.pro):
```
-keep class io.flutter.** { *; }
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class org.tensorflow.** { *; }
```

---

## 🤖 AI Features (On-Device — No Internet Required)

| Feature | Library | Performance |
|---------|---------|-------------|
| Face Detection | Google ML Kit | ~30ms/frame |
| Pose Detection | Google ML Kit | ~40ms/frame |
| Emotion Detection | TFLite (FER2013) | ~15ms/frame |
| Speech Recognition | speech_to_text | Real-time |
| Text-to-Speech | flutter_tts | Arabic + English |

All AI processing happens **100% on device** — no data is ever sent to the internet.

---

## 🌐 Features

| Screen | Arabic | English | AI |
|--------|--------|---------|-----|
| Landing Page | ✅ RTL | ✅ LTR | — |
| Login / Trial | ✅ | ✅ | — |
| Children List | ✅ | ✅ | — |
| Therapy Session | ✅ | ✅ | Camera + ML Kit |
| PECS Board | ✅ 32 cards | ✅ 32 cards | TTS |
| Task Generator | ✅ 100K+ AR | ✅ 100K+ EN | Adaptive |
| Parent Dashboard | ✅ | ✅ | Charts |

---

## 📋 Task Types (100K+ pool)

- **Motor** — 15 physical tasks (wave, jump, clap…)
- **Cognitive** — Colors, animals, fruits, shapes, Arabic letters
- **Verbal** — 33 words/phrases (Arabic + English)
- **Math** — Addition, subtraction, multiplication (3 levels)
- **Social** — 8 communication tasks (say please, take turns…)

---

## 🔑 License System

Users register with email → get a **6-digit PIN** → login with email + PIN  
Trial: 15 days free | Monthly: £49 | Annual: £399

PIN is stored securely in SQLite + flutter_secure_storage.  
Device fingerprinting binds license to specific device.

---

## 📞 Contact

**Lamya Fadlulmola Hamed Ali**  
lamyafadlulmolahamedali1@gmail.com  
Pepper Clinical Infinity V6 · HIPAA/GDPR Compliant  
© 2026 — All Rights Reserved
