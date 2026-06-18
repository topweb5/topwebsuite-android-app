class FieldConfig {
  const FieldConfig(
    this.key,
    this.label, {
    this.keyboard = FieldKeyboard.text,
    this.required = false,
    this.multiline = false,
    this.choices,
  });

  final String key;
  final String label;
  final FieldKeyboard keyboard;
  final bool required;
  final bool multiline;

  /// When set, the field is rendered as a dropdown of these options (used for
  /// backend `choices` fields like status / stage / source).
  final List<FieldChoice>? choices;
}

class FieldChoice {
  const FieldChoice(this.value, this.label);
  final String value;
  final String label;
}

enum FieldKeyboard { text, email, phone, number, date, url }
