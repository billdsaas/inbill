class Customer {
  final int? id;
  final int businessId;
  final String customerNumber;
  final String name;
  final String phone;
  final String email;
  final String address;
  final double creditLimit;
  final double outstandingBalance;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    this.id,
    required this.businessId,
    required this.customerNumber,
    required this.name,
    required this.phone,
    this.email = '',
    this.address = '',
    this.creditLimit = 0,
    this.outstandingBalance = 0,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'business_id': businessId,
        'customer_number': customerNumber,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'credit_limit': creditLimit,
        'outstanding_balance': outstandingBalance,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'],
        businessId: map['business_id'],
        customerNumber: map['customer_number'],
        name: map['name'],
        phone: map['phone'],
        email: map['email'] ?? '',
        address: map['address'] ?? '',
        creditLimit: (map['credit_limit'] ?? 0).toDouble(),
        outstandingBalance: (map['outstanding_balance'] ?? 0).toDouble(),
        notes: map['notes'] ?? '',
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
      );

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? creditLimit,
    double? outstandingBalance,
    String? notes,
  }) =>
      Customer(
        id: id ?? this.id,
        businessId: businessId,
        customerNumber: customerNumber,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
        creditLimit: creditLimit ?? this.creditLimit,
        outstandingBalance: outstandingBalance ?? this.outstandingBalance,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
