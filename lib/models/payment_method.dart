import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethod {
  final String id;
  final String label;
  final String phone;
  final String link;
  final bool isActive;

  PaymentMethod({
    required this.id,
    required this.label,
    required this.phone,
    required this.link,
    this.isActive = true,
  });

  factory PaymentMethod.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentMethod(
      id: doc.id,
      label: data['label'] ?? '',
      phone: data['phone'] ?? '',
      link: data['link'] ?? '',
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'label': label,
      'phone': phone,
      'link': link,
      'isActive': isActive,
    };
  }
  
  // Pour la compatibilité Firedart (Desktop)
  factory PaymentMethod.fromMap(String id, Map<String, dynamic> data) {
    return PaymentMethod(
      id: id,
      label: data['label'] ?? '',
      phone: data['phone'] ?? '',
      link: data['link'] ?? '',
      isActive: data['isActive'] ?? true,
    );
  }
}
