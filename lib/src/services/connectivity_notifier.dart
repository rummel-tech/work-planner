import 'package:flutter/foundation.dart';

/// Tracks whether the app is currently operating in offline/cached mode.
/// Repositories update this when API calls succeed or fail with a network error.
class ConnectivityNotifier {
  ConnectivityNotifier._();

  static final ValueNotifier<bool> isOffline = ValueNotifier(false);

  static void setOffline(bool value) {
    if (isOffline.value != value) isOffline.value = value;
  }
}
