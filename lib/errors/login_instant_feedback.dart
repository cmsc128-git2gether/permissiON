// Instant validation that runs on device, not Firestore
// Returns error or null message otherwise
String? validateEmail(String? value) {
  final v = value?.trim() ?? '';

  // Blank field
  if (v.isEmpty) return 'Email is required';

  // Checks form
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
    return 'Enter a valid email';
  }
  return null;
}

String? validatePassword(String? value) {
  final v = value ?? '';

  // Blank field
  if (v.isEmpty) return 'Password is required';

  // Firebase rejects passwords shorter than 8 characters
  if (v.length < 8) return 'Password must be at least 8 characters';
  return null;
}
