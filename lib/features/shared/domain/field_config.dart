class FieldConfig {
  const FieldConfig(
    this.key,
    this.label, {
    this.keyboard = FieldKeyboard.text,
    this.required = false,
    this.multiline = false,
  });

  final String key;
  final String label;
  final FieldKeyboard keyboard;
  final bool required;
  final bool multiline;
}

enum FieldKeyboard { text, email, phone, number, date, url }
