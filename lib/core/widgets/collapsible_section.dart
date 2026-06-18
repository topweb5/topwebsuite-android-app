import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// A collapsible "accordion" section used by the document creation forms.
///
/// Renders a tappable header (title + optional badge + chevron) and an
/// animated body. The [child] stays mounted while collapsed (the body is
/// clipped, not removed) so form-field validation and controller state are
/// preserved across expand/collapse.
class CollapsibleSection extends StatefulWidget {
  const CollapsibleSection({
    super.key,
    required this.title,
    required this.child,
    this.badge,
    this.initiallyExpanded = true,
  });

  final String title;
  final String? badge;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TopwebsuiteTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: TopwebsuiteTheme.ink,
                      ),
                    ),
                  ),
                  if (widget.badge != null) ...[
                    Text(
                      widget.badge!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: TopwebsuiteTheme.muted,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: TopwebsuiteTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              heightFactor: _expanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
