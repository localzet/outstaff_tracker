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
