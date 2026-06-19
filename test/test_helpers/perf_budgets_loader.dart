import 'dart:io';
import 'package:yaml/yaml.dart';

/// Loads perf_budgets.yaml from project root (current directory when tests run).
Map<String, dynamic> loadPerfBudgets() {
  const paths = [
    'perf_budgets.yaml',
    'e:/Flutter/tripship/perf_budgets.yaml',
    '../perf_budgets.yaml',
    'test/../perf_budgets.yaml',
  ];
  for (final p in paths) {
    final f = File(p);
    if (f.existsSync()) {
      final yaml = loadYaml(f.readAsStringSync()) as YamlMap;
      return _yamlMapToDart(yaml);
    }
  }
  throw StateError('perf_budgets.yaml not found. Run tests from project root.');
}

Map<String, dynamic> _yamlMapToDart(YamlMap yaml) {
  final map = <String, dynamic>{};
  for (final e in yaml.entries) {
    final k = (e.key as Object).toString();
    final v = e.value;
    if (v is YamlMap) {
      map[k] = _yamlMapToDart(v);
    } else if (v is YamlList) {
      map[k] = v.map((e) => e is YamlMap ? _yamlMapToDart(e) : e).toList();
    } else {
      map[k] = v;
    }
  }
  return map;
}

int getInt(Map<String, dynamic> map, String key, [int defaultValue = 0]) {
  final v = map[key];
  if (v == null) return defaultValue;
  if (v is int) return v;
  return int.tryParse(v.toString()) ?? defaultValue;
}

List<String> getStringList(Map<String, dynamic> map, String key) {
  final v = map[key];
  if (v == null || v is! List) return [];
  return v.map((e) => e.toString()).toList();
}
