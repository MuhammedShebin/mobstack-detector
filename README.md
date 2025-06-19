# 📱 Mobile App Framework Detector

Detects the technology stack used in Android (`.apk`, `.xapk`, `.zip`) and iOS (`.ipa`) mobile apps — such as **Flutter**, **React Native**, **WebView-based hybrid**, or **Native** applications.

> 🎯 Ideal for mobile penetration testers, security analysts, and reverse engineers looking to triage apps quickly before deeper analysis.

---

## ✨ Features

- 🔍 Detects frameworks: Flutter, React Native, WebView-based, Native (Java/Kotlin or Swift/Obj-C)
- 📦 Supports `.apk`, `.xapk`, `.zip` (multi-APK), and `.ipa` file formats
- 🎯 Handles split APKs and multi-architecture bundles
- 📈 Detects ABI architecture: `arm64-v8a`, `x86`, `armeabi-v7a`, etc.
- 🎨 Fancy CLI animation & color-coded output for presentations and reports
- 🧪 Silent and CI-friendly logic for automation pipelines

---

## 📸 Demo

```bash
$ ./detect_app_frameworks.sh app.apk
[*] Processing: app.apk
[✓] Detected: APK
[>] Analyzing APK: app.apk
[+] Framework: Flutter
[•] Architectures: arm64-v8a, armeabi-v7a
