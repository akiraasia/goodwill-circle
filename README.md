# Goodwill Circle

Flutter app for Goodwill Circle, deployed as a static Flutter web build to Firebase Hosting.

## Local Checks

Use the same checks that run before Firebase deploy:

```powershell
flutter pub get
dart analyze lib test
flutter test
flutter build web --release --no-wasm-dry-run
```

Firebase Hosting serves the generated `build/web` directory. If deploy fails with `Directory 'build/web' for Hosting does not exist`, the web build step did not run or failed before `FirebaseExtended/action-hosting-deploy`.

## Firebase Hosting

Hosting is configured in `firebase.json`:

```json
{
  "hosting": {
    "public": "build/web"
  }
}
```

GitHub Actions builds with Flutter `3.44.1`, verifies `build/web/index.html` and `build/web/main.dart.js`, then deploys previews for pull requests and live Hosting on pushes to `main`.

Required GitHub secret:

```text
FIREBASE_SERVICE_ACCOUNT_GOODWILL_CIRCLE
```

## Stack Notes

- Flutter SDK: `3.44.1`
- Dart SDK: `3.12.1`
- Supabase stores app data and Week 9 trust records.
- Firebase Hosting serves the compiled Flutter web app only.
