# Deendoon Mobile — Release Build Checklist

## The one command that matters most

The production API URL is **not** baked into the app by default — `Env.apiBaseUrl`
(`lib/core/config/env.dart`) defaults to the Android emulator's loopback address
(`http://10.0.2.2:8000/api/v1`) so local development works out of the box. A
plain `flutter build apk --release` will silently produce an APK that cannot
reach the internet from any real device — no crash, just every API call
failing.

**Always build the final release APK with:**

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://deendoon-app.onrender.com/api/v1
```

(Substitute the confirmed current production URL if it has changed since this
was written.)

## Release signing

The release build is signed with a real upload keystore
(`android/deendoon-release.jks` + `android/key.properties`), **not** the debug
key. Both files are gitignored (`android/.gitignore`: `key.properties`,
`**/*.keystore`, `**/*.jks`) — they must never be committed, and must be
backed up somewhere secure outside this repository. Losing the keystore means
losing the ability to publish updates to the same app listing; anyone who
holds it can sign an app that impersonates this one.

If `android/key.properties` is missing (e.g. a fresh checkout without the
real keystore), `android/app/build.gradle.kts` falls back to debug signing
automatically so local `flutter run`/debug builds keep working — but that
fallback build is **not** suitable for distribution. Confirm the keystore is
present before producing the artifact you intend to actually ship.

## Pre-flight checklist

- [ ] `flutter analyze` — 0 issues
- [ ] Relevant `flutter test` suites pass
- [ ] `android/key.properties` and `android/deendoon-release.jks` are present locally (not committed — confirm via `git status`)
- [ ] Build command includes `--dart-define=API_BASE_URL=<production URL>`
- [ ] Sanity-check the resulting APK's app label ("Deendoon"), launcher icon, and splash screen look correct on a real or emulated device before distributing
