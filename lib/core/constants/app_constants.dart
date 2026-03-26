class AppConstants {
  static const String appName = 'Inbill';
  static const String appVersion = '1.0.0';
  static const String dbName = 'inbill.db';
  static const int dbVersion = 1;

  // Invoice
  static const String invoicePrefix = 'INV';
  static const int invoiceStartNumber = 1001;

  // GST rates
  static const List<double> gstRates = [0, 5, 12, 18, 28];

  // Paper sizes
  static const List<String> paperSizes = ['A4', 'A5', '80mm Thermal', '58mm Thermal'];

  // Payment modes
  static const String cashPayment = 'Cash';
  static const String upiPayment = 'UPI';
  static const String creditPayment = 'Credit';
  static const String cardPayment = 'Card';

  // Delivery platforms
  static const String swiggy = 'Swiggy';
  static const String zomato = 'Zomato';
  static const String direct = 'Direct';

  // Languages
  static const Map<String, String> supportedLocales = {
    'en': 'English',
    'ta': 'Tamil',
  };

  // Subscription plans
  static const Map<String, int> plans = {
    'basic': 999,
    'pro': 1999,
    'enterprise': 4999,
  };
}
