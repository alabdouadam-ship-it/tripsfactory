import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class TripShipExpandableText extends StatefulWidget {
  final String text;
  final int trimLines;
  final TextStyle? style;
  final Color? toggleColor;
  final ValueChanged<bool>? onToggle;

  const TripShipExpandableText({
    super.key,
    required this.text,
    this.trimLines = 2,
    this.style,
    this.toggleColor,
    this.onToggle,
  });

  @override
  State<TripShipExpandableText> createState() => _TripShipExpandableTextState();
}

class _TripShipExpandableTextState extends State<TripShipExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final toggleColor = widget.toggleColor ?? theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final span = TextSpan(text: widget.text, style: widget.style);
            final tp = TextPainter(
              text: span,
              maxLines: widget.trimLines,
              textDirection: Directionality.of(context),
            );
            tp.layout(maxWidth: constraints.maxWidth);

            if (tp.didExceedMaxLines) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.text,
                    style: widget.style,
                    maxLines: _isExpanded ? null : widget.trimLines,
                    overflow: _isExpanded
                        ? TextOverflow.clip
                        : TextOverflow.ellipsis,
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _isExpanded = !_isExpanded);
                      widget.onToggle?.call(_isExpanded);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        _isExpanded ? l10n.showLess : l10n.showMore,
                        style: TextStyle(
                          color: toggleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return Text(widget.text, style: widget.style);
            }
          },
        ),
      ],
    );
  }
}
