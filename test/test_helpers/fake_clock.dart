/// Fake clock for deterministic tests (e.g. offline action createdAt).
class FakeClock {
  DateTime _now = DateTime.utc(2025, 1, 1, 12, 0, 0);

  DateTime get now => _now;

  void advance(Duration d) {
    _now = _now.add(d);
  }

  void setNow(DateTime t) {
    _now = t;
  }
}
