enum PricingType { unit, weight, custom }

class Product {
  final int? id;
  final int businessId;
  final String name;
  final String sku;
  final String barcode;
  final String category;
  final double price;
  final double costPrice;
  final double gstPercent;
  final PricingType pricingType;
  final String unit; // kg, g, pcs, ltr, etc.
  final double stockQuantity;
  final double lowStockAlert;
  final String description;
  final bool isActive;
  final DateTime createdAt;

  const Product({
    this.id,
    required this.businessId,
    required this.name,
    this.sku = '',
    this.barcode = '',
    this.category = 'General',
    required this.price,
    this.costPrice = 0,
    this.gstPercent = 18,
    this.pricingType = PricingType.unit,
    this.unit = 'pcs',
    this.stockQuantity = 0,
    this.lowStockAlert = 5,
    this.description = '',
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'business_id': businessId,
        'name': name,
        'sku': sku,
        'barcode': barcode,
        'category': category,
        'price': price,
        'cost_price': costPrice,
        'gst_percent': gstPercent,
        'pricing_type': pricingType.name,
        'unit': unit,
        'stock_quantity': stockQuantity,
        'low_stock_alert': lowStockAlert,
        'description': description,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'],
        businessId: map['business_id'],
        name: map['name'],
        sku: map['sku'] ?? '',
        barcode: map['barcode'] ?? '',
        category: map['category'] ?? 'General',
        price: (map['price'] ?? 0).toDouble(),
        costPrice: (map['cost_price'] ?? 0).toDouble(),
        gstPercent: (map['gst_percent'] ?? 18).toDouble(),
        pricingType: PricingType.values.firstWhere(
          (e) => e.name == map['pricing_type'],
          orElse: () => PricingType.unit,
        ),
        unit: map['unit'] ?? 'pcs',
        stockQuantity: (map['stock_quantity'] ?? 0).toDouble(),
        lowStockAlert: (map['low_stock_alert'] ?? 5).toDouble(),
        description: map['description'] ?? '',
        isActive: map['is_active'] == 1,
        createdAt: DateTime.parse(map['created_at']),
      );

  double get priceWithGst => price + (price * gstPercent / 100);

  Product copyWith({
    int? id,
    String? name,
    String? sku,
    String? barcode,
    String? category,
    double? price,
    double? costPrice,
    double? gstPercent,
    PricingType? pricingType,
    String? unit,
    double? stockQuantity,
    double? lowStockAlert,
    String? description,
    bool? isActive,
  }) =>
      Product(
        id: id ?? this.id,
        businessId: businessId,
        name: name ?? this.name,
        sku: sku ?? this.sku,
        barcode: barcode ?? this.barcode,
        category: category ?? this.category,
        price: price ?? this.price,
        costPrice: costPrice ?? this.costPrice,
        gstPercent: gstPercent ?? this.gstPercent,
        pricingType: pricingType ?? this.pricingType,
        unit: unit ?? this.unit,
        stockQuantity: stockQuantity ?? this.stockQuantity,
        lowStockAlert: lowStockAlert ?? this.lowStockAlert,
        description: description ?? this.description,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );
}
