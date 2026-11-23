# Keystone Employee — Google Play Console Upload Guide

Everything in this folder (`play_store_release/`) is prepared for uploading `Keystone Employee` (`com.keystone.user`) to Google Play Console.

## 1. Files Ready in This Folder
- **`keystone-employee-release.aab`** — Signed Android App Bundle (`minSdk 24`, `targetSdk 36`, R8 shrinking enabled, `arm64-v8a` + `armeabi-v7a` + `x86_64`).
- **`store_icon_512x512.png`** — 512x512 high-resolution Play Store app icon.
- **`feature_graphic_1024x500.png`** — 1024x500 Play Store feature graphic banner.

## 2. Signing Key Backup (Important)
- Release upload keystore: `android/keystone-upload.jks` (excluded from Git via `android/.gitignore`)
- Signing configuration: `android/key.properties` (excluded from Git via `android/.gitignore`)
- Back up `android/keystone-upload.jks` and `android/key.properties` safely offline; Google Play App Signing expects future updates to be signed by this same upload key.

## 3. Before Uploading Final Production Bundle
If your backend is deployed to an HTTPS domain (for example `https://api.yourcompany.com`), build the final `.aab` pointing to that live URL and increment the version build number (`1.0.0+2` in `pubspec.yaml`):

```bash
cd /Users/athletesingh/Projects/HRM/hrm-employee
flutter build appbundle --release \
  --dart-define=KEYSTONE_API_URL=https://api.yourcompany.com
cp build/app/outputs/bundle/release/app-release.aab play_store_release/keystone-employee-release.aab
```

> Without `--dart-define=KEYSTONE_API_URL=https://...`, new installs default to `http://10.0.2.2:3000` (emulator local host) unless changed under `Server address` on the Sign-In screen.

## 4. Play Console Form Answers (To Prevent Rejection)

### A. App Access (Mandatory for apps with sign-in)
- Select **"All or some functionality is restricted"** and click **Add instructions**.
- Provide a valid employee test email, password, and (if needed) your live server URL so Google Play reviewers can sign in and test Home, Attendance/Map, Leave, Payslips, and Helpdesk.

### B. Privacy Policy & In-App Policy
- The app includes an unauthenticated **"Privacy policy"** link directly on the Sign-In screen and under **More -> Privacy & data policy**.
- In Play Console (**App content -> Privacy policy**), enter your hosted privacy policy URL matching those disclosures (camera for attendance selfies, foreground GPS for office geofence/OpenStreetMap routing, on-device biometrics only, and employee data deletion via HR admin / Helpdesk).

### C. Data Safety Summary
- **Does your app collect or share user data?** Yes (collects employee workspace data; does not sell data; no ads).
- **Is all collected data encrypted in transit?** Yes (HTTPS enforced by `network_security_config.xml` for all non-local domains).
- **Data types collected:**
  - *Location -> Precise location* (App functionality — foreground geofence punch verification & field visit logging; optional/user-initiated).
  - *Photos and videos -> Photos* (App functionality — attendance verification selfie / field visit photo when taken by user).
  - *Personal info -> Name, Email address, Phone number, User IDs* (Account management & App functionality — employee directory/profile synced with organization workspace).
- **Delete account / data request:** Provided via organization HR Administrator and in-app Helpdesk & HR Queries (`Privacy & Data Policy` screen documents this).

### D. Permissions Used (`AndroidManifest.xml`)
- `INTERNET` — Syncs employee workspace data with your Keystone server & renders OpenStreetMap / OSRM Open Router map routes.
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` — Foreground GPS check for office geofence radius & field visits (no background location permission requested).
- `CAMERA` — Front selfie capture on punch / field check-in.
- `USE_BIOMETRIC` / `USE_FINGERPRINT` — Local hardware Face ID / Fingerprint prompt.
- Hardware `<uses-feature>` entries (`camera`, `camera.front`, `location.gps`) are marked `required="false"` so devices without GPS/camera remain eligible.

### E. Ads & Target Audience
- **Contains ads:** No.
- **Target age group:** 18+ (Enterprise HR / Workforce app — do not target children).

