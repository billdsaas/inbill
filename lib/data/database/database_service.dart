import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _db;

  DatabaseService._();
  static DatabaseService get instance => _instance ??= DatabaseService._();

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDir.path, 'inbill', AppConstants.dbName);

    return await openDatabase(
      dbPath,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      await txn.execute(_createBusinesses);
      await txn.execute(_createCustomers);
      await txn.execute(_createProducts);
      await txn.execute(_createInvoices);
      await txn.execute(_createInvoiceItems);
      await txn.execute(_createPayments);
      await txn.execute(_createTransactions);
      await txn.execute(_createAnalyticsCache);
      await txn.execute(_createSettings);
      await _createIndexes(txn);
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations
  }

  // ─── Table Schemas ──────────────────────────────────────────────────────────

  static const _createBusinesses = '''
    CREATE TABLE businesses (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      name        TEXT    NOT NULL,
      owner_name  TEXT    NOT NULL,
      phone       TEXT    NOT NULL,
      email       TEXT    DEFAULT '',
      address     TEXT    NOT NULL,
      city        TEXT    NOT NULL,
      state       TEXT    DEFAULT 'Tamil Nadu',
      pincode     TEXT    DEFAULT '',
      gstin       TEXT    DEFAULT '',
      logo_path   TEXT,
      upi_id      TEXT    DEFAULT '',
      currency    TEXT    DEFAULT 'INR',
      timezone    TEXT    DEFAULT 'Asia/Kolkata',
      is_active   INTEGER DEFAULT 1,
      created_at  TEXT    NOT NULL
    )
  ''';

  static const _createCustomers = '''
    CREATE TABLE customers (
      id                  INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id         INTEGER NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
      customer_number     TEXT    NOT NULL,
      name                TEXT    NOT NULL,
      phone               TEXT    NOT NULL,
      email               TEXT    DEFAULT '',
      address             TEXT    DEFAULT '',
      credit_limit        REAL    DEFAULT 0,
      outstanding_balance REAL    DEFAULT 0,
      notes               TEXT    DEFAULT '',
      created_at          TEXT    NOT NULL,
      updated_at          TEXT    NOT NULL
    )
  ''';

  static const _createProducts = '''
    CREATE TABLE products (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id     INTEGER NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
      name            TEXT    NOT NULL,
      sku             TEXT    DEFAULT '',
      barcode         TEXT    DEFAULT '',
      category        TEXT    DEFAULT 'General',
      price           REAL    NOT NULL,
      cost_price      REAL    DEFAULT 0,
      gst_percent     REAL    DEFAULT 18,
      pricing_type    TEXT    DEFAULT 'unit',
      unit            TEXT    DEFAULT 'pcs',
      stock_quantity  REAL    DEFAULT 0,
      low_stock_alert REAL    DEFAULT 5,
      description     TEXT    DEFAULT '',
      is_active       INTEGER DEFAULT 1,
      created_at      TEXT    NOT NULL
    )
  ''';

  static const _createInvoices = '''
    CREATE TABLE invoices (
      id               INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id      INTEGER NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
      invoice_number   TEXT    NOT NULL UNIQUE,
      customer_id      INTEGER REFERENCES customers(id),
      customer_name    TEXT    NOT NULL,
      customer_phone   TEXT    DEFAULT '',
      customer_address TEXT    DEFAULT '',
      subtotal         REAL    NOT NULL,
      total_discount   REAL    DEFAULT 0,
      total_gst        REAL    DEFAULT 0,
      grand_total      REAL    NOT NULL,
      amount_paid      REAL    DEFAULT 0,
      amount_due       REAL    DEFAULT 0,
      status           TEXT    DEFAULT 'pending',
      platform         TEXT    DEFAULT 'direct',
      payment_mode     TEXT    DEFAULT 'Cash',
      notes            TEXT    DEFAULT '',
      is_courier       INTEGER DEFAULT 0,
      courier_details  TEXT    DEFAULT '',
      invoice_date     TEXT    NOT NULL,
      due_date         TEXT    NOT NULL,
      created_at       TEXT    NOT NULL
    )
  ''';

  static const _createInvoiceItems = '''
    CREATE TABLE invoice_items (
      id           INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_id   INTEGER NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
      product_id   INTEGER REFERENCES products(id),
      product_name TEXT    NOT NULL,
      unit         TEXT    DEFAULT 'pcs',
      quantity     REAL    NOT NULL,
      rate         REAL    NOT NULL,
      discount     REAL    DEFAULT 0,
      gst_percent  REAL    DEFAULT 0,
      gst_amount   REAL    DEFAULT 0,
      total        REAL    NOT NULL
    )
  ''';

  static const _createPayments = '''
    CREATE TABLE payments (
      id                 INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id        INTEGER NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
      invoice_id         INTEGER REFERENCES invoices(id),
      invoice_number     TEXT    NOT NULL,
      customer_id        INTEGER REFERENCES customers(id),
      customer_name      TEXT    NOT NULL,
      method             TEXT    NOT NULL,
      amount             REAL    NOT NULL,
      reference_number   TEXT    DEFAULT '',
      upi_transaction_id TEXT    DEFAULT '',
      notes              TEXT    DEFAULT '',
      paid_at            TEXT    NOT NULL,
      created_at         TEXT    NOT NULL
    )
  ''';

  static const _createTransactions = '''
    CREATE TABLE transactions (
      id             INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id    INTEGER NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
      type           TEXT    NOT NULL,
      category       TEXT    DEFAULT '',
      amount         REAL    NOT NULL,
      description    TEXT    DEFAULT '',
      reference_id   INTEGER,
      reference_type TEXT    DEFAULT '',
      created_at     TEXT    NOT NULL
    )
  ''';

  static const _createAnalyticsCache = '''
    CREATE TABLE analytics_cache (
      id           INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id  INTEGER NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
      cache_key    TEXT    NOT NULL,
      cache_value  TEXT    NOT NULL,
      expires_at   TEXT    NOT NULL,
      created_at   TEXT    NOT NULL,
      UNIQUE(business_id, cache_key)
    )
  ''';

  static const _createSettings = '''
    CREATE TABLE settings (
      id           INTEGER PRIMARY KEY AUTOINCREMENT,
      business_id  INTEGER NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
      key          TEXT    NOT NULL,
      value        TEXT    NOT NULL,
      updated_at   TEXT    NOT NULL,
      UNIQUE(business_id, key)
    )
  ''';

  Future<void> _createIndexes(Transaction txn) async {
    await txn.execute('CREATE INDEX idx_invoices_business ON invoices(business_id, invoice_date)');
    await txn.execute('CREATE INDEX idx_invoices_customer ON invoices(customer_id)');
    await txn.execute('CREATE INDEX idx_invoices_status ON invoices(status)');
    await txn.execute('CREATE INDEX idx_customers_business ON customers(business_id)');
    await txn.execute('CREATE INDEX idx_customers_phone ON customers(phone)');
    await txn.execute('CREATE INDEX idx_products_business ON products(business_id)');
    await txn.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    await txn.execute('CREATE INDEX idx_payments_business ON payments(business_id, paid_at)');
    await txn.execute('CREATE INDEX idx_invoice_items_invoice ON invoice_items(invoice_id)');
  }

  // ─── Generic CRUD helpers ───────────────────────────────────────────────────

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(String table, Map<String, dynamic> data, int id) async {
    final db = await database;
    return await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    final db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? args]) async {
    final db = await database;
    return await db.rawQuery(sql, args);
  }

  Future<int> rawInsert(String sql, [List<Object?>? args]) async {
    final db = await database;
    return await db.rawInsert(sql, args);
  }

  Future<void> close() async {
    _db?.close();
    _db = null;
  }
}
