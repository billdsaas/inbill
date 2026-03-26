enum PaymentMethod { cash, upi, card, credit, cheque, netBanking }

class Payment {
  final int? id;
  final int businessId;
  final int? invoiceId;
  final String invoiceNumber;
  final int? customerId;
  final String customerName;
  final PaymentMethod method;
  final double amount;
  final String referenceNumber;
  final String upiTransactionId;
  final String notes;
  final DateTime paidAt;
  final DateTime createdAt;

  const Payment({
    this.id,
    required this.businessId,
    this.invoiceId,
    required this.invoiceNumber,
    this.customerId,
    required this.customerName,
    required this.method,
    required this.amount,
    this.referenceNumber = '',
    this.upiTransactionId = '',
    this.notes = '',
    required this.paidAt,
    required this.createdAt,
  });

  String get methodLabel {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI / GPay';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.credit:
        return 'Credit';
      case PaymentMethod.cheque:
        return 'Cheque';
      case PaymentMethod.netBanking:
        return 'Net Banking';
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'business_id': businessId,
        'invoice_id': invoiceId,
        'invoice_number': invoiceNumber,
        'customer_id': customerId,
        'customer_name': customerName,
        'method': method.name,
        'amount': amount,
        'reference_number': referenceNumber,
        'upi_transaction_id': upiTransactionId,
        'notes': notes,
        'paid_at': paidAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
        id: map['id'],
        businessId: map['business_id'],
        invoiceId: map['invoice_id'],
        invoiceNumber: map['invoice_number'],
        customerId: map['customer_id'],
        customerName: map['customer_name'],
        method: PaymentMethod.values.firstWhere(
          (e) => e.name == map['method'],
          orElse: () => PaymentMethod.cash,
        ),
        amount: (map['amount'] ?? 0).toDouble(),
        referenceNumber: map['reference_number'] ?? '',
        upiTransactionId: map['upi_transaction_id'] ?? '',
        notes: map['notes'] ?? '',
        paidAt: DateTime.parse(map['paid_at']),
        createdAt: DateTime.parse(map['created_at']),
      );
}
