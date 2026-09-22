import 'package:flutter_test/flutter_test.dart';
import 'package:boutique_bda/models/product.dart';

void main() {
  group('Product Stock Logic Tests', () {
    test('Calculates totalStock correctly', () {
      final p = Product(
        id: '1',
        name: 'Ristretto',
        price: 0.50,
        category: ProductCategories.cafe,
        subCategory: ProductCategories.subNespresso,
        stockBureau: 5,
        stockReserve: 20,
        alertThreshold: 10,
      );

      expect(p.totalStock, 25);
      expect(p.isOutOfStock, false);
      expect(p.isBureauEmpty, false);
      expect(p.needsDeskTransfer, false);
      expect(p.isLowStock, false);
      expect(p.standardBoxSize, 10);
    });

    test('Detects needsDeskTransfer when bureau is empty but reserve has stock', () {
      final p = Product(
        id: '2',
        name: 'Dolce Gusto Cappuccino',
        price: 0.80,
        category: ProductCategories.cafe,
        subCategory: ProductCategories.subDolceGusto,
        stockBureau: 0,
        stockReserve: 16,
        alertThreshold: 10,
      );

      expect(p.totalStock, 16);
      expect(p.isOutOfStock, false);
      expect(p.isBureauEmpty, true);
      expect(p.needsDeskTransfer, true);
      expect(p.isLowStock, false);
      expect(p.standardBoxSize, 16);
    });

    test('Detects isLowStock based on total of bureau and reserve', () {
      final p = Product(
        id: '3',
        name: 'Thé Vert',
        price: 0.60,
        category: ProductCategories.the,
        subCategory: 'Thé Vert',
        stockBureau: 2,
        stockReserve: 5,
        alertThreshold: 10,
      );

      expect(p.totalStock, 7);
      expect(p.isLowStock, true);
      expect(p.isOutOfStock, false);
      expect(p.isBureauEmpty, false);
      expect(p.standardBoxSize, 20);
    });

    test('Detects isOutOfStock when both bureau and reserve are 0', () {
      final p = Product(
        id: '4',
        name: 'Roma',
        price: 0.50,
        category: ProductCategories.cafe,
        subCategory: ProductCategories.subNespresso,
        stockBureau: 0,
        stockReserve: 0,
        alertThreshold: 10,
      );

      expect(p.totalStock, 0);
      expect(p.isOutOfStock, true);
      expect(p.isBureauEmpty, true);
      expect(p.needsDeskTransfer, false);
      expect(p.isLowStock, false);
    });

    test('Serialization and backward compatibility', () {
      final map = {
        'name': 'Lungo',
        'price': 0.50,
        'category': 'Nespresso', // Ancienne valeur sans subCategory
      };

      final p = Product.fromMap('123', map);
      expect(p.category, ProductCategories.cafe);
      expect(p.subCategory, ProductCategories.subNespresso);
      expect(p.stockBureau, 0);
      expect(p.stockReserve, 0);
      expect(p.alertThreshold, 10);
    });
  });
}
