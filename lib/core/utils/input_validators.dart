// Input validation utilities for security and data integrity.

const int kMaxNameLength = 100;
const int kMaxDescriptionLength = 1000;
const int kMaxMessageLength = 500;
const int kMinPasswordLength = 6;
const double kMaxWeightKg = 10000;
const double kMinWeightKg = 0.1;

/// Validates and sanitizes display name.
String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final sanitized = value.trim();
  if (sanitized.length > kMaxNameLength) {
    return sanitized.substring(0, kMaxNameLength);
  }
  return sanitized;
}

/// Validates and sanitizes description text.
String? validateDescription(String? value) {
  if (value == null) return null;
  final sanitized = value.trim();
  if (sanitized.isEmpty) return null;
  if (sanitized.length > kMaxDescriptionLength) {
    return sanitized.substring(0, kMaxDescriptionLength);
  }
  return sanitized;
}

/// Validates and sanitizes chat/message text.
String? validateMessage(String? value) {
  if (value == null) return null;
  final sanitized = value.trim();
  if (sanitized.isEmpty) return null;
  if (sanitized.length > kMaxMessageLength) {
    return sanitized.substring(0, kMaxMessageLength);
  }
  return sanitized;
}

/// Validates weight in kg.
double? validateWeight(double? value) {
  if (value == null) return null;
  if (value < kMinWeightKg || value > kMaxWeightKg) return null;
  return value;
}

/// Sanitizes search query (trim, limit length).
String sanitizeSearchQuery(String? value) {
  if (value == null) return '';
  final trimmed = value.trim();
  return trimmed.substring(0, trimmed.length.clamp(0, 200));
}
