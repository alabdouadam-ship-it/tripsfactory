import 'package:flutter/material.dart';

class DraggableFloatingButton extends StatefulWidget {
  final Widget child;
  final Offset initialOffset;
  final VoidCallback onPressed;
  final double parentWidth;
  final double parentHeight;

  const DraggableFloatingButton({
    super.key,
    required this.child,
    required this.initialOffset,
    required this.onPressed,
    required this.parentWidth,
    required this.parentHeight,
  });

  @override
  State<DraggableFloatingButton> createState() =>
      _DraggableFloatingButtonState();
}

class _DraggableFloatingButtonState extends State<DraggableFloatingButton> {
  late Offset _offset;

  @override
  void initState() {
    super.initState();
    _offset = widget.initialOffset;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            double newX = _offset.dx + details.delta.dx;
            double newY = _offset.dy + details.delta.dy;

            // Clamp x
            // Button width approx 150-180. Using 60 as safety margin for now
            if (newX < 0) newX = 0;
            if (newX > widget.parentWidth - 60) newX = widget.parentWidth - 60;

            // Clamp y
            // Button height approx 50-60.
            final maxY =
                widget.parentHeight - 80; // 80 to be safe (height + margin)

            if (newY < 0) newY = 0;
            if (newY > maxY) newY = maxY;

            _offset = Offset(newX, newY);
          });
        },
        child: ConstrainedBox(
          // Ensure the FAB does not get infinite width from Positioned
          constraints: const BoxConstraints(maxWidth: 300),
          child: widget.child,
        ),
      ),
    );
  }
}
