# SSM SkipQ — Flutter: From Zero to APK (Windows)

Complete guide to install Flutter, run the SkipQ app, and build an Android APK you can share or install on phones.

**Time:** First-time setup ~1–2 hours (downloads + installs)  
**Disk space needed:** ~10 GB free (Flutter + Android Studio + SDK)

**Project folder:** `ssm-skipq-flutter/`  
**Default API:** `https://ssmskipq-1-s1dg.onrender.com/api`

---

## Overview

```
Install Flutter + Android tools
        ↓
flutter doctor  (fix any ❌)
        ↓
flutter create + pub get  (one-time in this folder)
        ↓
flutter run  (test on phone/emulator)
        ↓
flutter build apk  (create installable APK)
        ↓
Copy APK from build folder → share/install
```

---

## Part 1 — Install Flutter SDK

### 1.1 Download

1. Open: https://docs.flutter.dev/get-started/install/windows
2. Download **flutter_windows_x.xx.x-stable.zip**

### 1.2 Extract (important)

Extract to a **short path** — **not** inside OneDrive if you can avoid it:

```
C:\src\flutter
```

Or if `C:` is full:

```
D:\flutter
```

You should end up with:

```
C:\src\flutter\bin\flutter.bat
```

### 1.3 Add Flutter to PATH

1. Press **Win + S** → search **Environment Variables**
2. **Edit the system environment variables** → **Environment Variables**
3. Under **User variables** → select **Path** → **Edit** → **New**
4. Add:
   ```
   C:\src\flutter\bin
   ```
5. Click **OK** on all dialogs
6. **Close and reopen** PowerShell or Terminal (required)

### 1.4 Verify

```powershell
flutter --version
```

You should see Flutter and Dart version numbers.

---

## Part 2 — Install Android tools

### 2.1 Android Studio

1. Download: https://developer.android.com/studio
2. Run installer → **Standard** setup → finish
3. Open Android Studio once → complete first-run wizard (downloads SDK)

### 2.2 SDK components

In Android Studio:

1. **More Actions** → **SDK Manager** (or **Settings** → **Languages & Frameworks** → **Android SDK**)
2. **SDK Platforms** tab — check **Android 14 (API 34)** or latest
3. **SDK Tools** tab — ensure checked:
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android SDK Platform-Tools
4. **Apply** → wait for download

### 2.3 Accept Android licenses

```powershell
flutter doctor --android-licenses
```

Type **`y`** and Enter for each prompt.

### 2.4 Windows Developer Mode (recommended)

1. **Settings** → **Privacy & security** → **For developers**
2. Turn on **Developer Mode**

Helps Flutter builds on Windows.

---

## Part 3 — Check everything

```powershell
flutter doctor
```

**Goal:** No red ❌ on **Flutter** and **Android toolchain**.

Example of a good result:

```
[✓] Flutter
[✓] Windows Version
[✓] Android toolchain
[✓] Chrome
...
```

If something fails, read the line under it — common fixes:

| Problem | Fix |
|---------|-----|
| Android licenses not accepted | Run `flutter doctor --android-licenses` again |
| cmdline-tools missing | Install via Android Studio SDK Manager |
| Android SDK not found | Set `ANDROID_HOME` to `%LOCALAPPDATA%\Android\Sdk` |

Optional — set `ANDROID_HOME` (if doctor asks):

1. Environment Variables → **New** user variable:
   - Name: `ANDROID_HOME`
   - Value: `C:\Users\YOUR_NAME\AppData\Local\Android\Sdk`
2. Add to Path: `%ANDROID_HOME%\platform-tools`

---

## Part 4 — Prepare the SkipQ Flutter project (one-time)

Open PowerShell:

```powershell
cd "C:\Users\Kavirathna\OneDrive\Desktop\resume projects\skipQ\ssm-skipq-flutter"
```

> Replace the path above if your repo is elsewhere.

### 4.1 Generate Android project files

The repo has `lib/` and `pubspec.yaml` but needs Android folders:

```powershell
flutter create . --org com.ssm.skipq --project-name ssm_skipq
```

This adds `android/`, `ios/`, etc. without replacing your `lib/` code.

### 4.2 Install packages

```powershell
flutter pub get
```

### 4.3 Wake the backend (before testing)

Open in browser and wait until you see `"db":"connected"` (may take up to 60 seconds on free Render):

https://ssmskipq-1-s1dg.onrender.com/api/health

---

## Part 5 — Run on a device (test before APK)

### Option A — Real Android phone (recommended)

1. On phone: **Settings** → **About phone** → tap **Build number** 7 times → Developer options on
2. **Settings** → **Developer options** → enable **USB debugging**
3. Connect phone with USB → allow debugging on phone
4. Check device:

```powershell
flutter devices
```

You should see your phone listed.

5. Run the app:

```powershell
flutter run --dart-define=API_BASE_URL=https://ssmskipq-1-s1dg.onrender.com/api
```

First build takes several minutes. The app opens on your phone.

**Hot reload while developing:** press **`r`** in the terminal.

### Option B — Android emulator

1. Android Studio → **Device Manager** → **Create Device** → pick a phone → download system image → **Finish**
2. Start the emulator (▶)
3. Run:

```powershell
flutter run --dart-define=API_BASE_URL=https://ssmskipq-1-s1dg.onrender.com/api
```

---

## Part 6 — Build the APK (installable file)

When the app works in `flutter run`, build release APK:

```powershell
cd "C:\Users\Kavirathna\OneDrive\Desktop\resume projects\skipQ\ssm-skipq-flutter"

flutter build apk --release --dart-define=API_BASE_URL=https://ssmskipq-1-s1dg.onrender.com/api
```

Wait for **Built build\app\outputs\flutter-apk\app-release.apk**.

### 6.1 Where is the APK?

Full path:

```
ssm-skipq-flutter\build\app\outputs\flutter-apk\app-release.apk
```

Open in File Explorer:

```powershell
explorer build\app\outputs\flutter-apk
```

### 6.2 Install on a phone

**Method 1 — USB:** Copy `app-release.apk` to phone → open file → Install (allow unknown sources if asked).

**Method 2 — Share:** Upload to Google Drive / WhatsApp → download on phone → install.

### 6.3 Smaller APK (optional — split by CPU)

```powershell
flutter build apk --split-per-abi --release --dart-define=API_BASE_URL=https://ssmskipq-1-s1dg.onrender.com/api
```

Creates separate APKs in the same folder (`app-armeabi-v7a-release.apk`, etc.) — each smaller than the universal APK.

---

## Part 7 — Change API URL (local backend)

If backend runs on your PC at port 5000:

| Where you run | API_BASE_URL |
|---------------|----------------|
| **Real phone** (same Wi‑Fi) | `http://YOUR_PC_IP:5000/api` (e.g. `http://192.168.1.5:5000/api`) |
| **Android emulator** | `http://10.0.2.2:5000/api` |
| **Production (Render)** | `https://ssmskipq-1-s1dg.onrender.com/api` |

Find your PC IP:

```powershell
ipconfig
```

Look for **IPv4 Address** under Wi‑Fi.

Example local build:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.5:5000/api
```

> Phone and PC must be on the **same Wi‑Fi**. Render/production should use **https**.

---

## Part 8 — Test login after install

| Role | How to test |
|------|-------------|
| **Student** | Register with name + 10-digit mobile |
| **Manager** | `SSM001` / `manager123` (if backend was seeded) |

Try: browse menu → add to cart → place order → manager sees order on Orders tab.

---

## Part 9 — Troubleshooting

### `flutter` is not recognized

- PATH not set or terminal not restarted after PATH change
- Fix Part 1.3, close ALL terminals, open new PowerShell

### Gradle build failed / out of memory

```powershell
flutter clean
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://ssmskipq-1-s1dg.onrender.com/api
```

### App opens but “Unable to connect”

1. Open health URL in phone browser — does it load?
2. Wrong `API_BASE_URL` — rebuild APK with correct URL
3. Render sleeping — open health URL, wait 60s, retry app

### `flutter create` overwrote something

Your `lib/` code should be safe. If `pubspec.yaml` changed unexpectedly, restore from git:

```powershell
git checkout pubspec.yaml
flutter pub get
```

### Build very slow

Normal on first build (5–15 min). Later builds are faster.

### APK not installing

- **Settings** → **Security** → allow install from unknown sources
- Uninstall old test version first if package name conflicts

---

## Part 10 — Quick command cheat sheet

```powershell
# Go to project
cd "C:\Users\Kavirathna\OneDrive\Desktop\resume projects\skipQ\ssm-skipq-flutter"

# One-time setup
flutter create . --org com.ssm.skipq --project-name ssm_skipq
flutter pub get

# Check setup
flutter doctor

# Run on connected phone
flutter run --dart-define=API_BASE_URL=https://ssmskipq-1-s1dg.onrender.com/api

# Build APK for client
flutter build apk --release --dart-define=API_BASE_URL=https://ssmskipq-1-s1dg.onrender.com/api

# Open APK folder
explorer build\app\outputs\flutter-apk
```

---

## Part 11 — Build APK without installing Flutter (alternative)

If your PC runs out of space, use **GitHub Actions** instead:

1. Push repo to GitHub
2. **Actions** → **Build Flutter APK** → **Run workflow**
3. Download artifact **skipq-flutter-apk**

See `.github/workflows/flutter-apk.yml` in the repo root.

---

## What to send your client

| Item | Location |
|------|----------|
| **APK file** | `app-release.apk` from Part 6 |
| **Source code** | `ssm-skipq-flutter/` folder |
| **Backend** | Already hosted on Render (share health URL) |

---

*SSM SkipQ — Flutter mobile client. Backend: Express + MongoDB (unchanged).*
