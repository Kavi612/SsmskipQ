# START HERE — Run SkipQ Flutter (Complete Beginner Guide)

**Read this file only.** Everything you need is here.

---

## Can the AI work inside Android Studio?

**No.** I cannot click buttons in Android Studio on your computer.

**What I CAN do:**
- Fix the code in this folder (already done — project should run)
- Give you **exact steps** — follow them one by one
- Help if you **copy-paste an error message** from the bottom of Android Studio

**What YOU do:** Open Android Studio and click Run. Or double-click `run_app.bat` in this folder.

---

## IMPORTANT: Do NOT create a new Flutter project

Your app **already exists** in this folder:

```
ssm-skipq-flutter
```

You only **open** this folder. You do **not** use File → New Project.

---

## Part A — One-time setup (you may have done this already)

Your PC already shows:
- Flutter installed ✓
- Android Studio installed ✓
- Android licenses accepted ✓

If `flutter doctor` ever fails, run in PowerShell:

```powershell
flutter doctor
```

Fix anything with a red **X** (not yellow warnings).

---

## Part B — Open the project in Android Studio

### Step 1 — Open the CORRECT folder

1. Open **Android Studio**
2. Click **Open** (or **File → Open**)
3. Go to:
   ```
   C:\Users\Kavirathna\OneDrive\Desktop\resume projects\skipQ\ssm-skipq-flutter
   ```
4. Select the **`ssm-skipq-flutter`** folder (not `skipQ`, not `ssm-skipq-backend`)
5. Click **OK**

### Step 2 — Wait

- Bottom of screen: **Gradle sync** / **Indexing** — wait until it finishes (2–10 min first time)
- Do not click Run until sync is done

### Step 3 — Install Flutter plugin (if Android Studio asks)

1. **File → Settings** (or **Android Studio → Settings** on Mac)
2. **Plugins**
3. Search **Flutter** → Install (also installs **Dart**)
4. Restart Android Studio
5. Open the same `ssm-skipq-flutter` folder again

---

## Part C — Create an Android emulator (virtual phone)

You need a **virtual device** if you don't have a real phone plugged in.

### Step 1 — Open Device Manager

1. In Android Studio top bar: click **Device Manager** icon (phone with Android logo)  
   Or: **Tools → Device Manager**

### Step 2 — Create device

1. Click **+** (Create Virtual Device)
2. Choose **Phone** → pick **Pixel 7** (or any phone) → **Next**
3. **System Image:** pick **API 34** or **API 36** (Download if needed — wait for download)
4. **Next** → **Finish**

### Step 3 — Start emulator

1. In Device Manager, click the **▶ Play** button next to your device
2. Wait until a phone window opens on your screen (1–3 minutes)

---

## Part D — Run the app

### Step 1 — Select device

Top toolbar, device dropdown (next to green ▶):

- Choose your **emulator** name (e.g. `Pixel 7 API 34`)  
  OR your **physical phone** if USB connected

### Step 2 — Click Run

1. Click the green **▶ Run** button  
   Or press **Shift + F10**

2. **First run takes 10–15 minutes.** This is normal. Wait.
[main.dart](lib/main.dart)
3. When done, the **SkipQ** app opens on the emulator.

### Step 3 — Before testing login

The app needs the internet backend. Wake it up once:

Open in emulator browser or PC browser:
```
https://ssmskipq-1-s1dg.onrender.com/api/health
```
Wait until you see `"db":"connected"`.

---

## Part E — Easier way (without Android Studio buttons)

1. Start your **emulator** first (Part C, Step 3)
2. Open File Explorer → go to `ssm-skipq-flutter` folder
3. **Double-click `run_app.bat`**
4. Wait — a black window shows progress. App opens on emulator when finished.

---

## Part F — Build APK file (for client)

1. Double-click **`build_apk.bat`** in this folder  
   OR in PowerShell:
   ```powershell
   cd "C:\Users\Kavirathna\OneDrive\Desktop\resume projects\skipQ\ssm-skipq-flutter"
   flutter build apk --release --dart-define=API_BASE_URL=https://ssmskipq-1-s1dg.onrender.com/api
   ```
2. APK location:
   ```
   build\app\outputs\flutter-apk\app-release.apk
   ```

---

## Test login

| Role | Login |
|------|--------|
| **Student** | Register with name + 10-digit mobile |
| **Manager** | ID: `SSM001` Password: `manager123` |

---

## Online payments (Razorpay test mode — no bank account)

For development you do **not** need a bank account. Razorpay test mode uses fake money only.

1. Create a free account at [dashboard.razorpay.com](https://dashboard.razorpay.com)
2. Switch to **Test Mode** (toggle at top of dashboard)
3. Go to **Account & Settings → API Keys** → Generate test keys
4. Add to backend `.env` (in `ssm-skipq-backend`):
   ```
   RAZORPAY_KEY_ID=rzp_test_xxxx
   RAZORPAY_KEY_SECRET=your_test_secret
   ```
5. Restart the backend (`npm run dev`)
6. In checkout, choose **Pay Online** — Razorpay checkout opens

**Test card (any future expiry, any CVV):**
- Card number: `4111 1111 1111 1111`
- UPI test ID: `success@razorpay`

If keys are missing, checkout still works with **Pay at Counter**.

---

## Common problems

### "No devices found"

- Start the emulator (Device Manager → ▶ Play)  
- Or plug in phone + enable USB debugging

### Red errors in Android Studio after opening

In PowerShell:

```powershell
cd "C:\Users\Kavirathna\OneDrive\Desktop\resume projects\skipQ\ssm-skipq-flutter"
flutter clean
flutter pub get
```

Then Android Studio: **File → Invalidate Caches → Invalidate and Restart**

### Opened wrong folder

You must open **`ssm-skipq-flutter`**, not the parent `skipQ` folder.

### Gradle sync failed

1. Check internet connection  
2. **File → Settings → Build → Gradle** — use **Gradle JDK**: Embedded JDK  
3. Try **File → Sync Project with Gradle Files**

### App opens but "can't connect"

1. Open health URL in emulator browser first  
2. Emulator must have internet (Wi‑Fi icon in emulator)

### Build takes forever

First build = 10–15 min. Next runs = faster. Don't stop it.

---

## Copy-paste commands (PowerShell)

```powershell
cd "C:\Users\Kavirathna\OneDrive\Desktop\resume projects\skipQ\ssm-skipq-flutter"

flutter pub get

flutter devices

flutter run --dart-define=API_BASE_URL=https://ssmskipq-1-s1dg.onrender.com/api
```

---

## Checklist (print this)

- [ ] Opened folder `ssm-skipq-flutter` in Android Studio (not parent folder)
- [ ] Gradle sync finished
- [ ] Emulator created and **started** (▶ Play)
- [ ] Selected emulator in top dropdown
- [ ] Clicked green **Run ▶**
- [ ] Waited 10–15 min on first run
- [ ] Opened health URL before login test

---

## Still stuck?

Send me:
1. **Which step** you are on (e.g. "Part D, Step 2")
2. **Screenshot** or copy the **red error text** from the bottom of Android Studio

I will fix it in the code or tell you the exact next click.

---

## Android Studio shows red errors in "Inspect Code"?

**This is normal for Flutter projects.** Many items are **false alarms**, not real bugs.

| What Android Studio shows | Real problem? |
|---------------------------|---------------|
| `Unresolved class '{applicationName}'` in AndroidManifest | **No** — Flutter fills this at build time |
| `GeneratedPluginRegistrant.m` errors (C/C++) | **No** — iOS/macOS file; ignore in Android Studio |
| `styles.xml` / `launch_background.xml` warnings | **Usually no** — if the app runs, you are fine |
| Red errors in `lib/` Dart files | **Yes** — tell me the file name and message |

**Trust this instead of Inspect Code:**

```powershell
cd "C:\Users\Kavirathna\OneDrive\Desktop\resume projects\skipQ\ssm-skipq-flutter"
flutter analyze
flutter run
```

If `flutter analyze` shows **0 errors** and the app runs on the emulator, **ignore** the Android inspection panel.

**Also check:**
- Open folder **`ssm-skipq-flutter`** only (not the parent `skipQ` folder)
- Wait for **Gradle sync** to finish (bottom status bar)
- Close other Gradle builds (only one Android Studio / `flutter run` at a time)

---

*Project is fixed and ready. You do not need to create a new Flutter project.*
