class InputValidators {
  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static final RegExp _ugandaPhoneRegex = RegExp(r'^(\+256|0)?7\d{8}$');
  static final RegExp _passwordRuleRegex = RegExp('[A-Za-z0-9]');

  static String? requiredField(final String? value, final String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  static String? email(final String? value) {
    final requiredError = requiredField(value, 'your email');
    if (requiredError != null) return requiredError;

    if (!_emailRegex.hasMatch(value!.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? ugandaPhone(final String? value) {
    final requiredError = requiredField(value, 'your phone number');
    if (requiredError != null) return requiredError;

    final cleaned = value!.replaceAll(' ', '');
    if (!_ugandaPhoneRegex.hasMatch(cleaned)) {
      return 'Use a valid Ugandan phone number';
    }
    return null;
  }

  static String? password(final String? value, {final String label = 'password'}) {
    final requiredError = requiredField(value, label);
    if (requiredError != null) return requiredError;

    if (value!.length < 4) {
      return 'Password must be at least 4 characters';
    }
    if (!_passwordRuleRegex.hasMatch(value)) {
      return 'Password must include at least one letter or number';
    }
    return null;
  }
}
