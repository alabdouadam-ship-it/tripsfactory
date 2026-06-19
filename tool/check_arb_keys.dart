// ignore_for_file: avoid_print
// Run from project root: dart run tool/check_arb_keys.dart
// Checks which ARB localization keys are not used in lib/ (excluding l10n/generated).

import 'dart:io';

void main() async {
  final projectRoot = Directory.current.path;
  final libDir = Directory('$projectRoot/lib');
  final generatedPath = 'l10n/generated';
  final keys = await _extractKeys(projectRoot);
  final unused = <String>[];

  for (final key in keys) {
    final used = await _keyUsedInLib(key, libDir, generatedPath);
    if (!used) unused.add(key);
  }

  final out = StringBuffer();
  out.writeln('Total keys: ${keys.length}');
  out.writeln('Unused keys: ${unused.length}');
  out.writeln('');
  out.writeln('--- Unused ARB keys ---');
  for (final k in unused..sort()) {
    out.writeln(k);
  }
  final result = out.toString();
  print(result);
  final outPath = '$projectRoot/tool/unused_arb_keys.txt';
  await File(outPath).writeAsString(result);
}

Future<List<String>> _extractKeys(String projectRoot) async {
  final file = File('$projectRoot/lib/l10n/generated/app_localizations.dart');
  final content = await file.readAsString();
  final keys = <String>[];
  final getterReg = RegExp(r'String get (\w+);');
  final methodReg = RegExp(r'String (\w+)\([^)]*\);');
  for (final m in getterReg.allMatches(content)) {
    keys.add(m.group(1)!);
  }
  for (final m in methodReg.allMatches(content)) {
    keys.add(m.group(1)!);
  }
  return keys;
}

Future<bool> _keyUsedInLib(String key, Directory libDir, String excludePath) async {
  final normalizedExclude = excludePath.replaceAll('\\', '/');
  bool found = false;
  await for (final entity in libDir.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    if (entity.path.replaceAll('\\', '/').contains(normalizedExclude)) continue;
    final content = await entity.readAsString();
    if (content.contains('localizations.$key') ||
        content.contains('l10n.$key') ||
        content.contains('AppLocalizations.of(context)!.$key') ||
        content.contains('ref.read(appLocalizationsProvider).$key')) {
      found = true;
      break;
    }
    if (content.contains('.$key(')) {
      found = true;
      break;
    }
  }
  return found;
}
