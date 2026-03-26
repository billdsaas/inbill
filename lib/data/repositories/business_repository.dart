import '../database/database_service.dart';
import '../models/business.dart';

class BusinessRepository {
  final DatabaseService _db = DatabaseService.instance;

  Future<List<Business>> getAll() async {
    final rows = await _db.query('businesses', orderBy: 'name ASC');
    return rows.map(Business.fromMap).toList();
  }

  Future<Business?> getById(int id) async {
    final rows = await _db.query('businesses', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Business.fromMap(rows.first);
  }

  Future<Business?> getActive() async {
    final rows = await _db.query('businesses', where: 'is_active = 1', limit: 1);
    return rows.isEmpty ? null : Business.fromMap(rows.first);
  }

  Future<int> save(Business business) async {
    if (business.id == null) {
      return await _db.insert('businesses', business.toMap());
    } else {
      await _db.update('businesses', business.toMap(), business.id!);
      return business.id!;
    }
  }

  Future<void> setActive(int id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.execute('UPDATE businesses SET is_active = 0');
      await txn.execute('UPDATE businesses SET is_active = 1 WHERE id = ?', [id]);
    });
  }

  Future<void> delete(int id) async {
    await _db.delete('businesses', id);
  }

  // ─── Next Invoice Number ─────────────────────────────────────────────────
  Future<String> nextInvoiceNumber(int businessId) async {
    final rows = await _db.rawQuery(
      "SELECT invoice_number FROM invoices WHERE business_id = ? ORDER BY id DESC LIMIT 1",
      [businessId],
    );
    if (rows.isEmpty) {
      return 'INV-1001';
    }
    final last = rows.first['invoice_number'] as String;
    final match = RegExp(r'(\d+)$').firstMatch(last);
    if (match == null) return 'INV-1001';
    final nextNum = int.parse(match.group(1)!) + 1;
    return 'INV-$nextNum';
  }

  // ─── Settings ──────────────────────────────────────────────────────────────
  Future<String?> getSetting(int businessId, String key) async {
    final rows = await _db.query(
      'settings',
      where: 'business_id = ? AND key = ?',
      whereArgs: [businessId, key],
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setSetting(int businessId, String key, String value) async {
    final db = await _db.database;
    await db.execute(
      '''INSERT INTO settings(business_id, key, value, updated_at)
         VALUES(?, ?, ?, ?)
         ON CONFLICT(business_id, key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at''',
      [businessId, key, value, DateTime.now().toIso8601String()],
    );
  }
}
