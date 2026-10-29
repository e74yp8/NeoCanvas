# NeoCanvas

A lightweight, fast Canvas LMS client for City University of Hong Kong,
built with Flutter.

> NeoCanvas is an unofficial project and is not affiliated with
> City University of Hong Kong or Instructure.

## Features

- Personal Access Token (PAT) login; the token is stored in platform secure storage
- Course list grouped by term, favorites first, instant search
- Course home with tabs, syllabus, and front page
- Native PDF reader with local cache, page navigation, and remembered position
- Responsive layout: three-pane master-detail on Windows, bottom navigation on Android
- Light, dark, and system themes

## Status

MVP. LTI / external tools are not embedded yet; they open in the system browser.

## Requirements

- Flutter 3.47.8+ (Dart 3.13+)
- Windows:
  - Visual Studio 2022 Build Tools with Desktop C++ and ATL
  - Developer Mode enabled (required by `pdfrx`)
- Android:
  - Android SDK 36
  - JDK 17

## Getting started

```bash
flutter pub get
flutter run -d windows
```

For Android:

```bash
flutter run -d <device-id>
```

## Build

```bash
flutter build windows --debug
flutter build apk --debug
```

## Project structure

```text
lib/
  core/       config, network, routing, theme, content routing
  features/   auth, courses, course_home, files, pdf_viewer, settings
  shared/     reusable widgets
docs/
  ARCHITECTURE.md
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the design.

## Security and privacy

- Your Canvas token is stored only in platform secure storage.
- Tokens are never logged or sent to third-party servers.
- PDFs are cached locally and cleared on logout by default.

## Getting a Canvas token

1. Sign in to Canvas in a browser.
2. Open Account -> Settings.
3. Find Approved Integrations and create a new access token.
4. Paste the token into NeoCanvas.

## Known limitations

- External tools / LTI are opened in the system browser, not embedded.
- HTML content that requires authenticated images may not render fully.
- iOS is not configured yet.

## License

MIT. See [LICENSE](LICENSE).
