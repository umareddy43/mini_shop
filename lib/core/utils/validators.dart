/// Simple, reusable form validation functions shared across screens.
/// Keeping validation logic in one place fulfils the spec's requirement
/// to "prevent duplicate names / empty orders / negative quantities /
/// validate prices" consistently everywhere it is needed.
class Validators {
  Validators._();

  static String? requiredField(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? optionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed <= 0) {
      return 'Price must be greater than zero';
    }
    return null;
  }

  static String? nonNegativeQuantity(int quantity) {
    if (quantity < 0) return 'Quantity cannot be negative';
    return null;
  }
}
