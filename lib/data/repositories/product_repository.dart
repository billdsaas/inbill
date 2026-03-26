import '../database/database_service.dart';
import '../models/product.dart';

class ProductRepository {
  final DatabaseService _db = DatabaseService.instance;

  Future<List<Product>> getAll(int businessId, {String? search, String? category}) async {
    String where = 'business_id = ? AND is_active = 1';
    List<Object?> args = [businessId];

    if (search != null && search.isNotEmpty) {
      where += ' AND (name LIKE ? OR sku LIKE ? OR barcode LIKE ?)';
      args.addAll(['%$search%', '%$search%', '%$search%']);
    }
    if (category != null && category.isNotEmpty) {
      where += ' AND category = ?';
      args.add(category);
    }

    final rows = await _db.query('products', where: where, whereArgs: args, orderBy: 'name ASC');
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> getById(int id) async {
    final rows = await _db.query('products', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Product.fromMap(rows.first);
  }

  Future<Product?> getByBarcode(int businessId, String barcode) async {
    final rows = await _db.query(
      'products',
      where: 'business_id = ? AND barcode = ? AND is_active = 1',
      whereArgs: [businessId, barcode],
    );
    return rows.isEmpty ? null : Product.fromMap(rows.first);
  }

  Future<List<String>> getCategories(int businessId) async {
    final rows = await _db.rawQuery(
      'SELECT DISTINCT category FROM products WHERE business_id = ? AND is_active = 1 ORDER BY category',
      [businessId],
    );
    return rows.map((r) => r['category'] as String).toList();
  }

  Future<int> save(Product product) async {
    if (product.id == null) {
      return await _db.insert('products', product.toMap());
    } else {
      await _db.update('products', product.toMap(), product.id!);
      return product.id!;
    }
  }

  Future<void> adjustStock(int productId, double delta) async {
    await _db.rawInsert(
      'UPDATE products SET stock_quantity = stock_quantity + ? WHERE id = ?',
      [delta, productId],
    );
  }

  Future<List<Product>> getLowStock(int businessId) async {
    final rows = await _db.rawQuery(
      'SELECT * FROM products WHERE business_id = ? AND is_active = 1 AND stock_quantity <= low_stock_alert',
      [businessId],
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<void> delete(int id) async {
    await _db.update('products', {'is_active': 0}, id);
  }
}
