import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils.dart';

/// Constantes pour les catégories et sous-catégories de produits.
class ProductCategories {
  static const String cafe = 'Café';
  static const String the = 'Thé';

  static const List<String> mainCategories = [cafe, the];

  static const String subNespresso = 'Nespresso';
  static const String subDolceGusto = 'Dolce Gusto';
  static const String subClassique = 'Classique';

  static const List<String> cafeSubCategories = [
    subNespresso,
    subDolceGusto,
    subClassique,
  ];

  static const List<String> theSubCategories = [
    'Thé Noir',
    'Thé Vert',
    'Infusion',
    'Général',
  ];
}

class Product {
  final String id;
  final String name;
  final double price;
  final bool isAvailable;
  final String category;
  final String subCategory;
  final int stockBureau;
  final int stockReserve;
  final int alertThreshold;
  final bool trackStock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.isAvailable = true,
    this.category = ProductCategories.cafe,
    this.subCategory = ProductCategories.subNespresso,
    this.stockBureau = 0,
    this.stockReserve = 0,
    this.alertThreshold = 10,
    this.trackStock = true,
  });

  /// Stock total cumulé (Bureau + Réserve).
  int get totalStock => stockBureau + stockReserve;

  /// Indique si le produit est en rupture totale (ni au bureau ni en réserve).
  bool get isOutOfStock => trackStock && totalStock <= 0;

  /// Indique si le stock total global est faible (nécessite une commande fournisseur).
  bool get isLowStock => trackStock && totalStock > 0 && totalStock <= alertThreshold;

  /// Indique si le bureau est vide (mais la réserve peut en avoir).
  bool get isBureauEmpty => trackStock && stockBureau <= 0;

  /// Indique qu'il faut remonter du stock au bureau depuis la réserve.
  bool get needsDeskTransfer => trackStock && isBureauEmpty && stockReserve > 0;

  /// Taille standard d'une boîte ou barrette pour le produit.
  int get standardBoxSize {
    if (subCategory == ProductCategories.subDolceGusto) return 16;
    if (subCategory == ProductCategories.subNespresso) return 10;
    if (category == ProductCategories.the) return 20;
    return 10;
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Product.fromMap(doc.id, data);
  }

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    String category = data['category'] ?? ProductCategories.cafe;
    String subCategory = data['subCategory'] ?? '';

    // Rétrocompatibilité avec les anciennes données
    if (subCategory.isEmpty) {
      if (category == 'Nespresso' || category == 'Dolce Gusto') {
        subCategory = category;
        category = ProductCategories.cafe;
      } else if (category == ProductCategories.the) {
        subCategory = 'Général';
      } else {
        subCategory = ProductCategories.subNespresso;
      }
    }

    return Product(
      id: id,
      name: data['name'] ?? '',
      price: parseDouble(data['price']),
      isAvailable: data['isAvailable'] ?? true,
      category: category,
      subCategory: subCategory,
      stockBureau: parseInt(data['stockBureau'], 0),
      stockReserve: parseInt(data['stockReserve'], 0),
      alertThreshold: parseInt(data['alertThreshold'], 10),
      trackStock: data['trackStock'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'isAvailable': isAvailable,
      'category': category,
      'subCategory': subCategory,
      'stockBureau': stockBureau,
      'stockReserve': stockReserve,
      'alertThreshold': alertThreshold,
      'trackStock': trackStock,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    double? price,
    bool? isAvailable,
    String? category,
    String? subCategory,
    int? stockBureau,
    int? stockReserve,
    int? alertThreshold,
    bool? trackStock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      stockBureau: stockBureau ?? this.stockBureau,
      stockReserve: stockReserve ?? this.stockReserve,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      trackStock: trackStock ?? this.trackStock,
    );
  }
}
