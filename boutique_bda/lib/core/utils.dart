import 'dart:math';

String generateRandomPassword([int length = 10]) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rnd = Random();
  return String.fromCharCodes(Iterable.generate(
    length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
}

/// Parse une date qui peut être soit un [Timestamp] Firestore, soit une [String] ISO8601, soit null.
DateTime? parseFirestoreDate(dynamic value) {
  if (value == null) return null;
  
  // Utilisation du nom du type pour éviter l'import direct de cloud_firestore sur desktop
  final typeName = value.runtimeType.toString();
  if (typeName == 'Timestamp' || typeName == '_JsonTimestamp') {
    try {
      return (value as dynamic).toDate();
    } catch (e) {
      return null;
    }
  }
  
  if (value is DateTime) return value;
  
  if (value is String) {
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
  
  return null;
}

/// Version non-nullable de [parseFirestoreDate].
DateTime parseRequiredFirestoreDate(dynamic value) {
  return parseFirestoreDate(value) ?? DateTime.now();
}

/// Parse un nombre de manière robuste (String, int, double).
double parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Parse un entier de manière robuste.
int parseInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}
