import 'package:flutter/foundation.dart';

/// Silences debugPrint during tests to reduce noise.
void silenceDebugPrint() {
  debugPrint = (String? message, {int? wrapWidth}) {};
}
