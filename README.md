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
