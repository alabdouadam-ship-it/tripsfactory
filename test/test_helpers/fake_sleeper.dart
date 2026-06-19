/// Records delay durations for deterministic retry/backoff tests (no real sleep).
class FakeSleeper {
  final List<Duration> delays = [];

  Future<void> Function(Duration) get sleeper => (Duration d) {
        delays.add(d);
        return Future<void>.value();
      };

  void clear() => delays.clear();
}
