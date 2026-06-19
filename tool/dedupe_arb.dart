// ignore_for_file: avoid_print
// Remove duplicate keys from app_en.arb and app_ar.arb.
// Run from project root: dart run tool/dedupe_arb.dart
// JSON parsing keeps the last value for duplicate keys; we then write back unique keys.

import 'dart:convert';
import 'dart:io';

void main() {
  final dir = Directory.current.path;
  final enPath = '$dir/lib/l10n/app_en.arb';
  final arPath = '$dir/lib/l10n/app_ar.arb';

  for (final path in [enPath, arPath]) {
    final file = File(path);
    if (!file.existsSync()) {
      print('Skip (not found): $path');
      continue;
    }
    final content = file.readAsStringSync();
    final map = jsonDecode(content) as Map<String, dynamic>;
    // Re-encode with indent to get one key per line; duplicates are already removed by JSON parse
    const encoder = JsonEncoder.withIndent('    ');
    final out = encoder.convert(map);
    file.writeAsStringSync('$out\n');
    print('Deduplicated: $path (${map.length} keys)');
  }
}
