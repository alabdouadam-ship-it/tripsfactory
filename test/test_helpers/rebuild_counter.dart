import 'package:flutter/widgets.dart';

/// Lightweight test helper to count how many times a widget subtree rebuilds.
/// Use only in test code. Wrap the widget under test as child; [onBuild] is
/// called on every build of this wrapper, so the child's rebuilds are counted.
class RebuildCounter extends StatefulWidget {
  const RebuildCounter({
    super.key,
    required this.child,
    required this.onBuild,
  });

  final Widget child;
  final VoidCallback onBuild;

  @override
  State<RebuildCounter> createState() => _RebuildCounterState();
}

class _RebuildCounterState extends State<RebuildCounter> {
  @override
  void initState() {
    super.initState();
    widget.onBuild();
  }

  @override
  Widget build(BuildContext context) {
    widget.onBuild();
    return widget.child;
  }
}
