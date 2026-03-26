import 'package:flutter/material.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/product_repository.dart';

enum DashboardPeriod { today, week, month, year }

class DashboardViewModel extends ChangeNotifier {
  final InvoiceRepository _invoiceRepo = InvoiceRepository();
  final ProductRepository _productRepo = ProductRepository();

  final int businessId;
  DashboardViewModel({required this.businessId});

  DashboardPeriod _period = DashboardPeriod.month;
  bool _loading = false;

  double _revenue = 0;
  double _collected = 0;
  double _outstanding = 0;
  int _invoiceCount = 0;
  double _prevRevenue = 0;
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _dailyRevenue = [];
  List<Map<String, dynamic>> _byPlatform = [];
  int _lowStockCount = 0;

  DashboardPeriod get period => _period;
  bool get loading => _loading;
  double get revenue => _revenue;
  double get collected => _collected;
  double get outstanding => _outstanding;
  int get invoiceCount => _invoiceCount;
  double get revenueGrowth => _prevRevenue > 0 ? ((_revenue - _prevRevenue) / _prevRevenue) * 100 : 0;
  List<Map<String, dynamic>> get topProducts => _topProducts;
  List<Map<String, dynamic>> get dailyRevenue => _dailyRevenue;
  List<Map<String, dynamic>> get byPlatform => _byPlatform;
  int get lowStockCount => _lowStockCount;

  DateTimeRange get _range {
    final now = DateTime.now();
    switch (_period) {
      case DashboardPeriod.today:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: now,
        );
      case DashboardPeriod.week:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case DashboardPeriod.month:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case DashboardPeriod.year:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
    }
  }

  DateTimeRange get _prevRange {
    final r = _range;
    final diff = r.end.difference(r.start);
    return DateTimeRange(
      start: r.start.subtract(diff),
      end: r.start,
    );
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final r = _range;
    final prev = _prevRange;

    final results = await Future.wait([
      _invoiceRepo.getSummary(businessId, r.start, r.end),
      _invoiceRepo.getSummary(businessId, prev.start, prev.end),
      _invoiceRepo.getTopProducts(businessId, r.start, r.end),
      _invoiceRepo.getDailyRevenue(businessId, r.start, r.end),
      _invoiceRepo.getByPlatform(businessId, r.start, r.end),
      _productRepo.getLowStock(businessId),
    ]);

    final summary = results[0] as Map<String, double>;
    final prevSummary = results[1] as Map<String, double>;

    _revenue = summary['revenue'] ?? 0;
    _collected = summary['collected'] ?? 0;
    _outstanding = summary['outstanding'] ?? 0;
    _invoiceCount = (summary['count'] ?? 0).toInt();
    _prevRevenue = prevSummary['revenue'] ?? 0;
    _topProducts = results[2] as List<Map<String, dynamic>>;
    _dailyRevenue = results[3] as List<Map<String, dynamic>>;
    _byPlatform = results[4] as List<Map<String, dynamic>>;
    _lowStockCount = (results[5] as List).length;

    _loading = false;
    notifyListeners();
  }

  void setPeriod(DashboardPeriod period) {
    _period = period;
    load();
  }
}
