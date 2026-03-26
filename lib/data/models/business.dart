class Business {
  final int? id;
  final String name;
  final String ownerName;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String gstin;
  final String? logoPath;
  final String upiId;
  final String currency;
  final String timezone;
  final bool isActive;
  final DateTime createdAt;

  const Business({
    this.id,
    required this.name,
    required this.ownerName,
    required this.phone,
    this.email = '',
    required this.address,
    required this.city,
    this.state = 'Tamil Nadu',
    this.pincode = '',
    this.gstin = '',
    this.logoPath,
    this.upiId = '',
    this.currency = 'INR',
    this.timezone = 'Asia/Kolkata',
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'owner_name': ownerName,
        'phone': phone,
        'email': email,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'gstin': gstin,
        'logo_path': logoPath,
        'upi_id': upiId,
        'currency': currency,
        'timezone': timezone,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory Business.fromMap(Map<String, dynamic> map) => Business(
        id: map['id'],
        name: map['name'],
        ownerName: map['owner_name'],
        phone: map['phone'],
        email: map['email'] ?? '',
        address: map['address'],
        city: map['city'],
        state: map['state'] ?? 'Tamil Nadu',
        pincode: map['pincode'] ?? '',
        gstin: map['gstin'] ?? '',
        logoPath: map['logo_path'],
        upiId: map['upi_id'] ?? '',
        currency: map['currency'] ?? 'INR',
        timezone: map['timezone'] ?? 'Asia/Kolkata',
        isActive: map['is_active'] == 1,
        createdAt: DateTime.parse(map['created_at']),
      );

  Business copyWith({
    int? id,
    String? name,
    String? ownerName,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? gstin,
    String? logoPath,
    String? upiId,
    bool? isActive,
  }) =>
      Business(
        id: id ?? this.id,
        name: name ?? this.name,
        ownerName: ownerName ?? this.ownerName,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
        city: city ?? this.city,
        state: state ?? this.state,
        pincode: pincode ?? this.pincode,
        gstin: gstin ?? this.gstin,
        logoPath: logoPath ?? this.logoPath,
        upiId: upiId ?? this.upiId,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );
}
