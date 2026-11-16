class PasswordPolicy {
  static const description =
      'Use at least 8 characters, including an uppercase letter, a lowercase letter, a number, and a special character.';
  static bool isValid(String value) =>
      value == value.trim() &&
      value.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(value) &&
      RegExp(r'[a-z]').hasMatch(value) &&
      RegExp(r'[0-9]').hasMatch(value) &&
      RegExp(r'[^a-zA-Z0-9\s]').hasMatch(value);
}
