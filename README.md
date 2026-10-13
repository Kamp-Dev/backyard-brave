# Backyard Brave

A portrait garden survival game. Mobile test builds:

- Browser: https://kamp-dev.github.io/backyard-brave/
- Android APK: https://github.com/Kamp-Dev/backyard-brave/releases/download/mobile-test/Backyard-Brave.apk

Open `game/project.godot` in Godot 4.7.2. GitHub Actions imports the project, exports a single-threaded Web build and a debug-signed Android APK, then publishes GitHub Pages and a test release. The APK supports ARMv7 and ARM64 phones. Audio starts after interaction with the page. Saves are local to each browser/device; clearing browser storage removes that browser's progress.

Android builds use a cached development signing key, not a production store key. Assets include AI-generated illustrations. Source art and native labels remain separate. No player save files or private signing credentials are included.
