# Timelog Book

A very simple time logbook for Android (iOS planned). Free software, no ads, no tracking –
your data never leaves your device.

- One big button: **Start logging** / **Stop logging**
- While logging, a persistent notification with a **Stop logging** button, so you can
  pause without opening the app. After stopping, a dismissible notification shows the
  day's total and has a **Start logging** button.
- **Time total** for the day, all entries with start/stop, the sum of **breaks** and the
  **corrected end** (first start + total, i.e. the end time without breaks).
  Example: 07:20 – 15:20 with a one hour break → corrected end 14:20.
- Edit, add and delete entries, browse past days, export as CSV.

An entry that runs past midnight counts for the day it started.

## Build

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable).

```sh
flutter pub get
flutter test
flutter run                       # on a connected device / emulator
flutter build apk --split-per-abi # release APKs in build/app/outputs/flutter-apk/
```

## Notes on Android

The "logging" notification belongs to a foreground service (type `specialUse`), which is
what keeps it in place. The service does no work; the notification's chronometer is
counted by the system. On Android 14+ a foreground service notification can be swiped
away; the app then shows it again immediately.

## License

Copyright (C) 2026 Leo Stumpf

This program is free software: you can redistribute it and/or modify it under the terms
of the GNU Affero General Public License as published by the Free Software Foundation,
either version 3 of the License, or (at your option) any later version. See
[LICENSE](LICENSE).
