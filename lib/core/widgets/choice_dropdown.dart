import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../features/shared/domain/field_config.dart';

/// Dropdown bound to a [TextEditingController] so it drops into the existing
/// controller-based forms. Writes the selected option's `value` into the
/// controller for the request payload.
class ChoiceDropdown extends StatelessWidget {
  const ChoiceDropdown({
    super.key,
    required this.controller,
    required this.label,
    required this.choices,
    this.required = false,
  });

  final TextEditingController controller;
  final String label;
  final List<FieldChoice> choices;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final current = choices.any((c) => c.value == controller.text)
        ? controller.text
        : null;
    return DropdownButtonFormField<String>(
      initialValue: current,
      isExpanded: true,
      style: const TextStyle(color: TopwebsuiteTheme.ink, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 13,
          color: TopwebsuiteTheme.muted,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: TopwebsuiteTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: TopwebsuiteTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: TopwebsuiteTheme.primary,
            width: 1.4,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: [
        for (final c in choices)
          DropdownMenuItem(value: c.value, child: Text(c.label)),
      ],
      onChanged: (v) {
        if (v != null) controller.text = v;
      },
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'Required' : null
          : null,
    );
  }
}
