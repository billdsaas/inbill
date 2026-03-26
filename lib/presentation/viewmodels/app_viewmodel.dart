import 'package:flutter/material.dart';
import '../../data/models/business.dart';
import '../../data/repositories/business_repository.dart';

enum AppScreen { dashboard, billing, invoices, customers, products, reports, settings }

class AppViewModel extends ChangeNotifier {
  final BusinessRepository _businessRepo = BusinessRepository();

  Business? _activeBusiness;
  List<Business> _businesses = [];
  AppScreen _currentScreen = AppScreen.dashboard;
  bool _loading = true;
  String? _error;
  Locale _locale = const Locale('en');

  Business? get activeBusiness => _activeBusiness;
  List<Business> get businesses => _businesses;
  AppScreen get currentScreen => _currentScreen;
  bool get loading => _loading;
  String? get error => _error;
  Locale get locale => _locale;
  bool get hasBusinesses => _businesses.isNotEmpty;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      _businesses = await _businessRepo.getAll();
      _activeBusiness = await _businessRepo.getActive() ?? _businesses.firstOrNull;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void navigate(AppScreen screen) {
    _currentScreen = screen;
    notifyListeners();
  }

  Future<void> selectBusiness(int id) async {
    await _businessRepo.setActive(id);
    _activeBusiness = await _businessRepo.getById(id);
    notifyListeners();
  }

  Future<void> createBusiness(Business business) async {
    final id = await _businessRepo.save(business);
    await _businessRepo.setActive(id);
    await init();
  }

  Future<void> updateBusiness(Business business) async {
    await _businessRepo.save(business);
    await init();
  }

  void setLocale(String code) {
    _locale = Locale(code);
    notifyListeners();
  }
}
