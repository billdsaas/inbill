enum InvoiceStatus { draft, pending, paid, partial, cancelled }
enum DeliveryPlatform { direct, swiggy, zomato, delivery }

class InvoiceItem {
  final int? id;
  final int? invoiceId;
  final int? productId;
  final String productName;
  final String unit;
  final double quantity;
  final double rate;
  final double discount;
  final double gstPercent;
  final double gstAmount;
  final double total;

  const InvoiceItem({
    this.id,
    this.invoiceId,
    this.productId,
    required this.productName,
    this.unit = 'pcs',
    required this.quantity,
    required this.rate,
    this.discount = 0,
    this.gstPercent = 0,
    required this.gstAmount,
    required this.total,
  });

  double get subtotal => quantity * rate;
  double get discountAmount => subtotal * discount / 100;
  double get taxableAmount => subtotal - discountAmount;

  static InvoiceItem calculate({
    int? id,
    int? invoiceId,
    int? productId,
    required String productName,
    String unit = 'pcs',
    required double quantity,
    required double rate,
    double discount = 0,
    double gstPercent = 0,
  }) {
    final subtotal = quantity * rate;
    final discountAmt = subtotal * discount / 100;
    final taxable = subtotal - discountAmt;
    final gstAmt = taxable * gstPercent / 100;
    final total = taxable + gstAmt;
    return InvoiceItem(
      id: id,
      invoiceId: invoiceId,
      productId: productId,
      productName: productName,
      unit: unit,
      quantity: quantity,
      rate: rate,
      discount: discount,
      gstPercent: gstPercent,
      gstAmount: gstAmt,
      total: total,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'invoice_id': invoiceId,
        'product_id': productId,
        'product_name': productName,
        'unit': unit,
        'quantity': quantity,
        'rate': rate,
        'discount': discount,
        'gst_percent': gstPercent,
        'gst_amount': gstAmount,
        'total': total,
      };

  factory InvoiceItem.fromMap(Map<String, dynamic> map) => InvoiceItem(
        id: map['id'],
        invoiceId: map['invoice_id'],
        productId: map['product_id'],
        productName: map['product_name'],
        unit: map['unit'] ?? 'pcs',
        quantity: (map['quantity'] ?? 0).toDouble(),
        rate: (map['rate'] ?? 0).toDouble(),
        discount: (map['discount'] ?? 0).toDouble(),
        gstPercent: (map['gst_percent'] ?? 0).toDouble(),
        gstAmount: (map['gst_amount'] ?? 0).toDouble(),
        total: (map['total'] ?? 0).toDouble(),
      );

  InvoiceItem copyWith({
    double? quantity,
    double? rate,
    double? discount,
    double? gstPercent,
  }) {
    return InvoiceItem.calculate(
      id: id,
      invoiceId: invoiceId,
      productId: productId,
      productName: productName,
      unit: unit,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      discount: discount ?? this.discount,
      gstPercent: gstPercent ?? this.gstPercent,
    );
  }
}

class Invoice {
  final int? id;
  final int businessId;
  final String invoiceNumber;
  final int? customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final List<InvoiceItem> items;
  final double subtotal;
  final double totalDiscount;
  final double totalGst;
  final double grandTotal;
  final double amountPaid;
  final double amountDue;
  final InvoiceStatus status;
  final DeliveryPlatform platform;
  final String paymentMode;
  final String notes;
  final bool isCourier;
  final String courierDetails;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final DateTime createdAt;

  const Invoice({
    this.id,
    required this.businessId,
    required this.invoiceNumber,
    this.customerId,
    required this.customerName,
    this.customerPhone = '',
    this.customerAddress = '',
    required this.items,
    required this.subtotal,
    required this.totalDiscount,
    required this.totalGst,
    required this.grandTotal,
    this.amountPaid = 0,
    required this.amountDue,
    this.status = InvoiceStatus.pending,
    this.platform = DeliveryPlatform.direct,
    this.paymentMode = 'Cash',
    this.notes = '',
    this.isCourier = false,
    this.courierDetails = '',
    required this.invoiceDate,
    required this.dueDate,
    required this.createdAt,
  });

  static Invoice create({
    required int businessId,
    required String invoiceNumber,
    int? customerId,
    required String customerName,
    String customerPhone = '',
    String customerAddress = '',
    required List<InvoiceItem> items,
    double amountPaid = 0,
    InvoiceStatus status = InvoiceStatus.pending,
    DeliveryPlatform platform = DeliveryPlatform.direct,
    String paymentMode = 'Cash',
    String notes = '',
    bool isCourier = false,
    String courierDetails = '',
    DateTime? invoiceDate,
    DateTime? dueDate,
  }) {
    final subtotal = items.fold(0.0, (s, i) => s + i.subtotal);
    final totalDiscount = items.fold(0.0, (s, i) => s + i.discountAmount);
    final totalGst = items.fold(0.0, (s, i) => s + i.gstAmount);
    final grandTotal = items.fold(0.0, (s, i) => s + i.total);
    final amountDue = grandTotal - amountPaid;
    final now = DateTime.now();

    InvoiceStatus resolvedStatus = status;
    if (amountPaid >= grandTotal) {
      resolvedStatus = InvoiceStatus.paid;
    } else if (amountPaid > 0) {
      resolvedStatus = InvoiceStatus.partial;
    }

    return Invoice(
      businessId: businessId,
      invoiceNumber: invoiceNumber,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      items: items,
      subtotal: subtotal,
      totalDiscount: totalDiscount,
      totalGst: totalGst,
      grandTotal: grandTotal,
      amountPaid: amountPaid,
      amountDue: amountDue,
      status: resolvedStatus,
      platform: platform,
      paymentMode: paymentMode,
      notes: notes,
      isCourier: isCourier,
      courierDetails: courierDetails,
      invoiceDate: invoiceDate ?? now,
      dueDate: dueDate ?? now.add(const Duration(days: 30)),
      createdAt: now,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'business_id': businessId,
        'invoice_number': invoiceNumber,
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'customer_address': customerAddress,
        'subtotal': subtotal,
        'total_discount': totalDiscount,
        'total_gst': totalGst,
        'grand_total': grandTotal,
        'amount_paid': amountPaid,
        'amount_due': amountDue,
        'status': status.name,
        'platform': platform.name,
        'payment_mode': paymentMode,
        'notes': notes,
        'is_courier': isCourier ? 1 : 0,
        'courier_details': courierDetails,
        'invoice_date': invoiceDate.toIso8601String(),
        'due_date': dueDate.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory Invoice.fromMap(Map<String, dynamic> map, {List<InvoiceItem> items = const []}) => Invoice(
        id: map['id'],
        businessId: map['business_id'],
        invoiceNumber: map['invoice_number'],
        customerId: map['customer_id'],
        customerName: map['customer_name'],
        customerPhone: map['customer_phone'] ?? '',
        customerAddress: map['customer_address'] ?? '',
        items: items,
        subtotal: (map['subtotal'] ?? 0).toDouble(),
        totalDiscount: (map['total_discount'] ?? 0).toDouble(),
        totalGst: (map['total_gst'] ?? 0).toDouble(),
        grandTotal: (map['grand_total'] ?? 0).toDouble(),
        amountPaid: (map['amount_paid'] ?? 0).toDouble(),
        amountDue: (map['amount_due'] ?? 0).toDouble(),
        status: InvoiceStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => InvoiceStatus.pending,
        ),
        platform: DeliveryPlatform.values.firstWhere(
          (e) => e.name == map['platform'],
          orElse: () => DeliveryPlatform.direct,
        ),
        paymentMode: map['payment_mode'] ?? 'Cash',
        notes: map['notes'] ?? '',
        isCourier: map['is_courier'] == 1,
        courierDetails: map['courier_details'] ?? '',
        invoiceDate: DateTime.parse(map['invoice_date']),
        dueDate: DateTime.parse(map['due_date']),
        createdAt: DateTime.parse(map['created_at']),
      );
}
