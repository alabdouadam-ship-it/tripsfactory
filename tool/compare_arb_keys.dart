// ignore_for_file: avoid_print
// Compare keys in app_en.arb vs app_ar.arb
// Run: dart run tool/compare_arb_keys.dart

import 'dart:convert';
import 'dart:io';

void main() {
  final dir = Directory.current.path;
  final enPath = '$dir/lib/l10n/app_en.arb';
  final arPath = '$dir/lib/l10n/app_ar.arb';
  if (!File(enPath).existsSync()) {
    print('EN file not found: $enPath');
    return;
  }

  final enKeys = _keysFromArb(File(enPath).readAsStringSync());
  final arKeys = _keysFromArb(File(arPath).readAsStringSync());

  final onlyEn = enKeys.difference(arKeys);
  final onlyAr = arKeys.difference(enKeys);
  final common = enKeys.intersection(arKeys);

  print('=== ARB Keys Comparison ===\n');
  print('Number of keys in English: ${enKeys.length}');
  print('Number of keys in Arabic:  ${arKeys.length}');
  print('Common keys:               ${common.length}\n');

  if (onlyEn.isNotEmpty) {
    print('--- Keys only in English (missing in Arabic): ${onlyEn.length} ---');
    for (final k in onlyEn.toList()..sort()) {
      print('  $k');
    }
    print('');
  }

  if (onlyAr.isNotEmpty) {
    print('--- Keys only in Arabic (missing in English): ${onlyAr.length} ---');
    for (final k in onlyAr.toList()..sort()) {
      print('  $k');
    }
    print('');
  }

  if (onlyEn.isEmpty && onlyAr.isEmpty) {
    print('Yes, the keys are identical in both files.');
  } else {
    print('No, the keys are not identical. Review the lists above.');
  }

  // Write to file
  final outPath = '$dir/lib/l10n/arb_keys_comparison.txt';
  final buf = StringBuffer();
  buf.writeln('EN keys: ${enKeys.length}, AR keys: ${arKeys.length}, Common: ${common.length}');
  if (onlyEn.isNotEmpty) {
    buf.writeln('\nOnly in EN (${onlyEn.length}): ${onlyEn.join(', ')}');
  }
  if (onlyAr.isNotEmpty) {
    buf.writeln('\nOnly in AR (${onlyAr.length}): ${onlyAr.join(', ')}');
  }
  File(outPath).writeAsStringSync(buf.toString());
}

Set<String> _keysFromArb(String content) {
  final map = jsonDecode(content) as Map<String, dynamic>;
  return map.keys.where((k) => !k.startsWith('@')).toSet();
}
