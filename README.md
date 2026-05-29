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
