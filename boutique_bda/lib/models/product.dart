import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final bool isAvailable;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.isAvailable = true,
    this.category = 'Café',
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      isAvailable: data['isAvailable'] ?? true,
      category: data['category'] ?? 'Café',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'isAvailable': isAvailable,
      'category': category,
    };
  }
}
