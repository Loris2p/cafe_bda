import 'dart:math';
import 'package:flutter/material.dart';

String generateRandomPassword([int length = 10]) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rnd = Random();
  return String.fromCharCodes(Iterable.generate(
    length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
}

/// Affiche une SnackBar stylisée et harmonisée dans toute l'application.
void showCustomSnackBar(BuildContext context, {
  required String message, 
  Color backgroundColor = Colors.black87,
  IconData? icon,
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message, 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(16),
      elevation: 4,
      duration: const Duration(seconds: 3),
    ),
  );
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
