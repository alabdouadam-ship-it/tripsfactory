/// Captures analytics/funnel events for conversion tests. Inject in tests to assert
/// event names, params, and no duplicates.
class FakeAnalytics {
  final List<FakeAnalyticsEvent> events = [];

  void track(String name, [Map<String, dynamic>? params]) {
    events.add(FakeAnalyticsEvent(
      name: name,
      params: params != null ? Map<String, dynamic>.from(params) : null,
    ));
  }

  List<FakeAnalyticsEvent> named(String name) =>
      events.where((e) => e.name == name).toList();

  int countNamed(String name) => named(name).length;

  void clear() => events.clear();
}

class FakeAnalyticsEvent {
  final String name;
  final Map<String, dynamic>? params;

  FakeAnalyticsEvent({required this.name, this.params});
}
