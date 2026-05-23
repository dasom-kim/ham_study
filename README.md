# HamStudy

HamStudy is a cute character study timer app planned for iOS and Android.

The current scaffold follows `HamStudy.md` and starts with a Flutter app shell,
feature-first folders, Riverpod state management, local timer logic, and clear
slots for Firebase sync, purchases, statistics, D-Day, and home screen widgets.

## Setup

Install Flutter, then run:

```sh
flutter create --platforms=ios,android .
flutter pub get
flutter run
```

`flutter create` is only needed because the Flutter SDK was not available when
this scaffold was created, so native iOS/Android runner files could not be
generated automatically.
