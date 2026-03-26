import '../database/database_service.dart';
import '../models/invoice.dart';

class InvoiceRepository {
  final DatabaseService _db = DatabaseService.instance;

  Future<int> save(Invoice invoice) async {
    final db = await _db.database;
    late int invoiceId;
    await db.transaction((txn) async {
      final map = invoice.toMap();
      map.remove('id');
      if (invoice.id == null) {
        invoiceId = await txn.insert('invoices', map);
      } else {
        invoiceId = invoice.id!;
        await txn.update('invoices', map, where: 'id = ?', whereArgs: [invoiceId]);
        await txn.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
      }
      for (final item in invoice.items) {
        final itemMap = item.toMap();
        itemMap['invoice_id'] = invoiceId;
        itemMap.remove('id');
        await txn.insert('invoice_items', itemMap);
      }
    });
    return invoiceId;
  }

  Future<Invoice?> getById(int id) async {
    final rows = await _db.query('invoices', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final items = await _getItems(id);
    return Invoice.fromMap(rows.first, items: items);
  }

  Future<Invoice?> getByNumber(String number) async {
    final rows = await _db.query('invoices', where: 'invoice_number = ?', whereArgs: [number]);
    if (rows.isEmpty) return null;
    final items = await _getItems(rows.first['id'] as int);
    return Invoice.fromMap(rows.first, items: items);
  }

  Future<List<Invoice>> getAll(
    int businessId, {
    String? search,
    String? status,
    String? platform,
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  }) async {
    String where = 'business_id = ?';
    List<Object?> args = [businessId];

    if (status != null && status.isNotEmpty) {
      where += ' AND status = ?';
      args.add(status);
    }
    if (platform != null && platform.isNotEmpty) {
      where += ' AND platform = ?';
      args.add(platform);
    }
    if (from != null) {
      where += ' AND invoice_date >= ?';
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where += ' AND invoice_date <= ?';
      args.add(to.toIso8601String());
    }
    if (search != null && search.isNotEmpty) {
      where += ' AND (invoice_number LIKE ? OR customer_name LIKE ? OR customer_phone LIKE ?)';
      args.addAll(['%$search%', '%$search%', '%$search%']);
    }

    final rows = await _db.query(
      'invoices',
      where: where,
      whereArgs: args,
      orderBy: 'invoice_date DESC, id DESC',
      limit: limit,
      offset: offset,
    );
    // Load items for each invoice
    return Future.wait(rows.map((row) async {
      final id = row['id'] as int;
      final items = await _getItems(id);
      return Invoice.fromMap(row, items: items);
    }));
  }

  Future<List<InvoiceItem>> _getItems(int invoiceId) async {
    final rows = await _db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    return rows.map(InvoiceItem.fromMap).toList();
  }

  Future<void> updateStatus(int id, InvoiceStatus status, {double? amountPaid}) async {
    final updates = {'status': status.name};
    if (amountPaid != null) {
      updates['amount_paid'] = amountPaid.toString();
    }
    await _db.update('invoices', updates, id);
  }

  Future<void> delete(int id) async {
    await _db.delete('invoices', id);
  }

  // ─── Analytics Queries ───────────────────────────────────────────────────

  Future<Map<String, double>> getSummary(int businessId, DateTime from, DateTime to) async {
    final rows = await _db.rawQuery(
      '''SELECT
           SUM(grand_total) as revenue,
           SUM(amount_paid) as collected,
           SUM(amount_due) as outstanding,
           COUNT(*) as count
         FROM invoices
         WHERE business_id = ? AND status != 'cancelled'
           AND invoice_date BETWEEN ? AND ?''',
      [businessId, from.toIso8601String(), to.toIso8601String()],
    );
    if (rows.isEmpty) return {};
    final r = rows.first;
    return {
      'revenue': (r['revenue'] ?? 0.0) as double,
      'collected': (r['collected'] ?? 0.0) as double,
      'outstanding': (r['outstanding'] ?? 0.0) as double,
      'count': ((r['count'] ?? 0) as int).toDouble(),
    };
  }

  Future<List<Map<String, dynamic>>> getTopProducts(int businessId, DateTime from, DateTime to, {int limit = 10}) async {
    return await _db.rawQuery(
      '''SELECT ii.product_name, SUM(ii.quantity) as total_qty, SUM(ii.total) as total_revenue
         FROM invoice_items ii
         JOIN invoices inv ON inv.id = ii.invoice_id
         WHERE inv.business_id = ? AND inv.status != 'cancelled'
           AND inv.invoice_date BETWEEN ? AND ?
         GROUP BY ii.product_name
         ORDER BY total_revenue DESC
         LIMIT ?''',
      [businessId, from.toIso8601String(), to.toIso8601String(), limit],
    );
  }

  Future<List<Map<String, dynamic>>> getDailyRevenue(int businessId, DateTime from, DateTime to) async {
    return await _db.rawQuery(
      '''SELECT DATE(invoice_date) as date, SUM(grand_total) as revenue, COUNT(*) as count
         FROM invoices
         WHERE business_id = ? AND status != 'cancelled'
           AND invoice_date BETWEEN ? AND ?
         GROUP BY DATE(invoice_date)
         ORDER BY date ASC''',
      [businessId, from.toIso8601String(), to.toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>> getByPlatform(int businessId, DateTime from, DateTime to) async {
    return await _db.rawQuery(
      '''SELECT platform, SUM(grand_total) as revenue, COUNT(*) as count
         FROM invoices
         WHERE business_id = ? AND status != 'cancelled'
           AND invoice_date BETWEEN ? AND ?
         GROUP BY platform''',
      [businessId, from.toIso8601String(), to.toIso8601String()],
    );
  }

  Future<int> getCount(int businessId) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) as cnt FROM invoices WHERE business_id = ?',
      [businessId],
    );
    return (rows.first['cnt'] as int?) ?? 0;
  }
}
