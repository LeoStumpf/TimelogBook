# Privacy policy — Timelog Book

_Last updated: 2026-10-28_

**Short version:** Timelog Book collects nothing. It has no internet permission, no account,
no analytics, no crash reporting and no advertising. Your entries stay on your device.

## Data stored on your device

- Your time entries (start and stop times) in a local database inside the app's private
  storage. Nothing else is stored.
- No other app can read it. Uninstalling the app or clearing its data deletes it.
- Android's own device backup (if you have turned it on) may include this database, as it
  does for most apps. That backup is handled by Android and your Google account, not by
  Timelog Book.

## Network

The app does not declare the `INTERNET` permission, so it cannot send or receive anything
over the network.

## Permissions

- **Notifications** (`POST_NOTIFICATIONS`): the "logging" notification with its Stop button
  and the day's total after stopping.
- **Foreground service** (`FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SPECIAL_USE`): keeps the
  "logging" notification in place while you log. The service does no work and reads no data.

## Exporting

**Export as CSV** writes a file to the app's temporary folder and hands it to the Android
share sheet. Where it goes from there is your choice.

## Children

The app is not directed at children and collects no data from anyone.

## Changes

Changes to this policy are made in this file; the git history shows every version.

## Contact

Leo Stumpf — open an issue at <https://github.com/LeoStumpf/TimelogBook/issues>.
