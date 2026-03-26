import '../database/database_service.dart';
import '../models/customer.dart';

class CustomerRepository {
  final DatabaseService _db = DatabaseService.instance;

  Future<List<Customer>> getAll(int businessId, {String? search}) async {
    if (search != null && search.isNotEmpty) {
      final rows = await _db.rawQuery(
        '''SELECT * FROM customers WHERE business_id = ?
           AND (name LIKE ? OR phone LIKE ? OR customer_number LIKE ?)
           ORDER BY name ASC''',
        [businessId, '%$search%', '%$search%', '%$search%'],
      );
      return rows.map(Customer.fromMap).toList();
    }
    final rows = await _db.query(
      'customers',
      where: 'business_id = ?',
      whereArgs: [businessId],
      orderBy: 'name ASC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer?> getById(int id) async {
    final rows = await _db.query('customers', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Customer.fromMap(rows.first);
  }

  Future<Customer?> getByPhone(int businessId, String phone) async {
    final rows = await _db.query(
      'customers',
      where: 'business_id = ? AND phone = ?',
      whereArgs: [businessId, phone],
    );
    return rows.isEmpty ? null : Customer.fromMap(rows.first);
  }

  Future<int> save(Customer customer) async {
    if (customer.id == null) {
      return await _db.insert('customers', customer.toMap());
    } else {
      await _db.update('customers', customer.toMap(), customer.id!);
      return customer.id!;
    }
  }

  Future<void> updateBalance(int customerId, double delta) async {
    await _db.rawInsert(
      'UPDATE customers SET outstanding_balance = outstanding_balance + ? WHERE id = ?',
      [delta, customerId],
    );
  }

  Future<void> delete(int id) async {
    await _db.delete('customers', id);
  }

  Future<String> nextCustomerNumber(int businessId) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) as cnt FROM customers WHERE business_id = ?',
      [businessId],
    );
    final count = (rows.first['cnt'] as int?) ?? 0;
    return 'CUS-${(count + 1001).toString().padLeft(4, '0')}';
  }

  Future<List<Map<String, dynamic>>> exportCsv(int businessId) async {
    return await _db.rawQuery(
      '''SELECT c.customer_number, c.name, c.phone, c.email, c.address,
                c.outstanding_balance, c.credit_limit, c.created_at
         FROM customers c WHERE c.business_id = ?
         ORDER BY c.name ASC''',
      [businessId],
    );
  }
}
