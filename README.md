# Outstaff Tracker

Local-first cross-platform time analytics app for freelancers working through Kimai.

## Stack

- Flutter stable
- Riverpod
- go_router
- Dio
- Drift + SQLite
- flutter_secure_storage
- fl_chart
- intl

## Development

If platform runner files are not present yet, generate them once with Flutter:

```bash
flutter create . --project-name outstaff_tracker --platforms=windows,android,web
```

Generate Drift code before running the app:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Then run Flutter for the target platform:

```bash
flutter run -d windows
flutter run -d chrome
flutter run -d android
```

## Validation

```bash
dart format lib test
flutter analyze
flutter test --reporter compact
flutter build windows --debug
flutter build windows --release
```

## Windows release

```bash
flutter build windows --release
```

The release executable is created under:

```text
build/windows/x64/runner/Release/outstaff_tracker.exe
```

## Windows Code Signing

The GitHub release workflow can sign the Windows installer when a code signing
certificate is available. Signing is optional: without these secrets the workflow
still builds unsigned artifacts.

Required GitHub Actions secrets:

- `WINDOWS_SIGNING_CERTIFICATE_BASE64` — base64-encoded `.pfx` certificate
- `WINDOWS_SIGNING_CERTIFICATE_PASSWORD` — password for the `.pfx`

Create the base64 value on Windows:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("certificate.pfx")) | Set-Content certificate.pfx.base64
```

Unsigned installers may show Microsoft Defender SmartScreen warnings such as
`Unknown publisher`. A valid Authenticode signature is required for Windows to
display the verified publisher.

## Auto-update

Windows builds check GitHub Releases for updates. The app reads:

- `latest.json` for version metadata, release notes URL, installer URL and SHA256.
- `appcast.xml` for the native `auto_updater` / WinSparkle install flow.
- GitHub Releases API
  `https://api.github.com/repos/{owner}/{repo}/releases/latest` as a safe
  fallback when native update metadata is unavailable.

Automatic checks run in the app at most once per day and can be disabled in
settings. Windows prefers the native installer flow when appcast metadata is
available. In fallback mode the app opens the installer asset or release page in
the external browser and never silently downloads or executes an `.exe`.

The Windows installer artifact is:

```text
outstaff_tracker-setup-{version}.exe
```

Android does not install updates silently. Use the APK/AAB release artifacts or
store distribution later. Web builds are updated by redeploying the hosted web
bundle.

Create a release by pushing a semantic version tag:

```bash
git tag v0.1.1
git push origin v0.1.1
```

GitHub Actions builds and attaches:

- `outstaff_tracker-setup-{version}.exe`
- `outstaff_tracker-windows-portable-{version}.zip`
- `outstaff_tracker-android-{version}.apk`
- `outstaff_tracker-android-{version}.aab`
- `outstaff_tracker-web-{version}.zip`
- `SHA256SUMS.txt`
- `latest.json`
- `appcast.xml`

If signing secrets are absent, the installer and updater still work, but Windows
may show SmartScreen warnings. Production distribution should use a trusted
OV/EV Authenticode certificate; self-signed certificates are useful only for
testing and do not create a trusted publisher identity.

## Branding Assets

Branding source and generated platform icons are checked into the repository:

- `assets/brand/app_icon.png` — 1024x1024 source icon
- `windows/runner/resources/app_icon.ico` — Windows executable and installer icon
- `android/app/src/main/res/mipmap-*/ic_launcher.png` — Android launcher icons
- `web/favicon.png` and `web/icons/*.png` — Web favicon and PWA icons
- `installer/windows/assets/*.bmp` — Inno Setup wizard images

Regenerate all branding assets from the deterministic PowerShell script:

```powershell
pwsh ./tool/generate_brand_assets.ps1
```

On Windows without PowerShell 7:

```powershell
powershell -ExecutionPolicy Bypass -File ./tool/generate_brand_assets.ps1
```

The generator uses the same dark minimalist visual language as the app UI: near-black surface, thin grid lines, green time accent, and a subtle money marker. Re-run it after changing the icon composition, then commit the generated files.
