# SkipQ Flutter — Simple Guide (Start Here)

You need **2 things** on your computer:
1. **Flutter** (builds the app)
2. **Android Studio** (lets Flutter make Android apps)

Need about **10 GB free space**. Takes **1–2 hours** the first time.

---
## STEP 1 — Install Flutter (15 min)

1. Open this link in Chrome:  
   https://docs.flutter.dev/get-started/install/windows

2. Click the big blue button to **download Flutter** (zip file).

3. Open the zip. **Extract** the folder called `flutter` to:
   ```
   C:\src\flutter
  ```
   (Create folder `C:\src` if it doesn't exist.)

4. Add Flutter to Windows PATH:
   - Press **Windows key**, type **environment**
   - Click **Edit the system environment variables**
   - Click **Environment Variables**
   - Under **User variables**, click **Path** → **Edit** → **New**
   - Type: `C:\src\flutter\bin`
   - Click **OK** on everything

5. **Close Cursor completely.** Open a **new** PowerShell window.

6. Type:
   ```
   flutter --version
   ```
   If you see version numbers → **Step 1 done ✓**

---

## STEP 2 — Install Android Studio (30 min)

1. Open: https://developer.android.com/studio  
2. Download and install (click Next, Next, Finish).
3. Open Android Studio when done.
4. Let it download extra files (wait until finished).

5. In PowerShell, type:
   ```
   flutter doctor --android-licenses
   ```
   Type **y** and Enter every time it asks.

6. Type:
   ```
   flutter doctor
   ```
   You want **green checkmarks** on Flutter and Android.  
   If red X appears, read what it says on screen.

---

## STEP 3 — Open your project (2 min)

Copy and paste these lines **one at a time** in PowerShell:

```
cd "C:\Users\Kavirathna\OneDrive\Desktop\resume projects\skipQ\ssm-skipq-flutter"
```

```
flutter create . --org com.ssm.skipq --project-name ssm_skipq
```

```
flutter pub get
```

Wait until each command finishes.

---

## STEP 4 — Test on your phone (10 min)

**On your Android phone:**
- Settings → About phone → tap **Build number** 7 times
- Settings → Developer options → turn on **USB debugging**
- Plug phone into PC with USB cable → tap **Allow** on phone

**On PC**, type:

```
flutter devices
```

You should see your phone name.

Then run the app:

```
flutter run --dart-define=API_BASE_URL=https://ssmskipq-1-s1dg.onrender.com/api
```

**First time takes 5–15 minutes.** App opens on your phone when done.

**Before running:** open this in phone browser (wake up server):  
https://ssmskipq-1-s1dg.onrender.com/api/health

---

## STEP 5 — Make the APK file (5–15 min)

When the app works on your phone, build the install file:

```
flutter build apk --release --dart-define=API_BASE_URL=https://ssmskipq-1-s1dg.onrender.com/api
```

When it says **Built app-release.apk** → you're done.

---

## STEP 6 — Find and share the APK

1. Open File Explorer.
2. Go to folder:
   ```
   C:\Users\Kavirathna\OneDrive\Desktop\resume projects\skipQ\ssm-skipq-flutter\build\app\outputs\flutter-apk
   ```
3. File name: **`app-release.apk`**
4. Copy to phone (USB / WhatsApp / Google Drive) → open on phone → Install.

**That APK is what you give your client.**

---

## Login to test

| Who | How |
|-----|-----|
| Student | Register with name + mobile number |
| Manager | ID: `SSM001` Password: `manager123` |

---

## Something went wrong?

| Problem | What to do |
|---------|------------|
| `flutter` not recognized | Redo Step 1 PATH, **restart computer**, try again |
| Phone not showing | USB cable connected? USB debugging on? |
| App can't connect | Open health link in phone browser first, wait 60 sec |
| Build failed | Run `flutter clean` then try Step 5 again |

---

## All commands in one place (copy-paste)

```powershell
cd "C:\Users\Kavirathna\OneDrive\Desktop\resume projects\skipQ\ssm-skipq-flutter"

flutter create . --org com.ssm.skipq --project-name ssm_skipq

flutter pub get

flutter run --dart-define=API_BASE_URL=https://ssmskipq-1-s1dg.onrender.com/api

flutter build apk --release --dart-define=API_BASE_URL=https://ssmskipq-1-s1dg.onrender.com/api
```

---

## Still stuck?

Tell me **which STEP number** you are on and **copy the error message** from the screen. Example: *"Step 4 — flutter devices shows nothing"* or paste the red error text.

---

*Detailed version (optional): see FLUTTER_SETUP_AND_APK.md in this same folder.*
