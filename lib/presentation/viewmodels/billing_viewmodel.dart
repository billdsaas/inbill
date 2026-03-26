import 'package:flutter/material.dart';
import '../../data/models/invoice.dart';
import '../../data/models/product.dart';
import '../../data/models/customer.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/business_repository.dart';

class BillingViewModel extends ChangeNotifier {
  final InvoiceRepository _invoiceRepo = InvoiceRepository();
  final CustomerRepository _customerRepo = CustomerRepository();
  final BusinessRepository _businessRepo = BusinessRepository();

  final int businessId;

  BillingViewModel({required this.businessId});

  // Cart state
  final List<InvoiceItem> _items = [];
  Customer? _selectedCustomer;
  String _customerName = '';
  String _customerPhone = '';
  String _paymentMode = 'Cash';
  double _cashAmount = 0;
  double _upiAmount = 0;
  String _notes = '';
  bool _isCourier = false;
  String _courierDetails = '';
  DeliveryPlatform _platform = DeliveryPlatform.direct;
  bool _saving = false;
  String? _error;
  String? _successInvoiceNumber;

  // Totals
  double get subtotal => _items.fold(0.0, (s, i) => s + i.subtotal);
  double get totalDiscount => _items.fold(0.0, (s, i) => s + i.discountAmount);
  double get totalGst => _items.fold(0.0, (s, i) => s + i.gstAmount);
  double get grandTotal => _items.fold(0.0, (s, i) => s + i.total);
  double get amountPaid => _cashAmount + _upiAmount;
  double get amountDue => grandTotal - amountPaid;

  List<InvoiceItem> get items => List.unmodifiable(_items);
  Customer? get selectedCustomer => _selectedCustomer;
  String get customerName => _customerName;
  String get customerPhone => _customerPhone;
  String get paymentMode => _paymentMode;
  double get cashAmount => _cashAmount;
  double get upiAmount => _upiAmount;
  String get notes => _notes;
  bool get isCourier => _isCourier;
  String get courierDetails => _courierDetails;
  DeliveryPlatform get platform => _platform;
  bool get saving => _saving;
  String? get error => _error;
  String? get successInvoiceNumber => _successInvoiceNumber;
  bool get hasItems => _items.isNotEmpty;

  void setCustomer(Customer? customer) {
    _selectedCustomer = customer;
    if (customer != null) {
      _customerName = customer.name;
      _customerPhone = customer.phone;
    }
    notifyListeners();
  }

  void setCustomerName(String name) {
    _customerName = name;
    notifyListeners();
  }

  void setCustomerPhone(String phone) {
    _customerPhone = phone;
    notifyListeners();
  }

  void addItem(InvoiceItem item) {
    // If same product already in cart, increase quantity
    final idx = _items.indexWhere((i) => i.productId != null && i.productId == item.productId);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(quantity: _items[idx].quantity + item.quantity);
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void addProductToCart(Product product, {double quantity = 1}) {
    addItem(InvoiceItem.calculate(
      productId: product.id,
      productName: product.name,
      unit: product.unit,
      quantity: quantity,
      rate: product.price,
      gstPercent: product.gstPercent,
    ));
  }

  void updateItem(int index, InvoiceItem item) {
    _items[index] = item;
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void setPaymentMode(String mode) {
    _paymentMode = mode;
    if (mode == 'Cash') {
      _cashAmount = grandTotal;
      _upiAmount = 0;
    } else if (mode == 'UPI') {
      _upiAmount = grandTotal;
      _cashAmount = 0;
    } else if (mode == 'Credit') {
      _cashAmount = 0;
      _upiAmount = 0;
    }
    notifyListeners();
  }

  void setCashAmount(double amount) {
    _cashAmount = amount;
    notifyListeners();
  }

  void setUpiAmount(double amount) {
    _upiAmount = amount;
    notifyListeners();
  }

  void setNotes(String notes) {
    _notes = notes;
    notifyListeners();
  }

  void setIsCourier(bool value) {
    _isCourier = value;
    notifyListeners();
  }

  void setCourierDetails(String details) {
    _courierDetails = details;
    notifyListeners();
  }

  void setPlatform(DeliveryPlatform platform) {
    _platform = platform;
    notifyListeners();
  }

  Future<Invoice?> saveInvoice() async {
    if (_items.isEmpty) {
      _error = 'Add at least one item';
      notifyListeners();
      return null;
    }
    if (_customerName.trim().isEmpty) {
      _error = 'Enter customer name';
      notifyListeners();
      return null;
    }

    _saving = true;
    _error = null;
    _successInvoiceNumber = null;
    notifyListeners();

    try {
      final invoiceNumber = await _businessRepo.nextInvoiceNumber(businessId);
      final invoice = Invoice.create(
        businessId: businessId,
        invoiceNumber: invoiceNumber,
        customerId: _selectedCustomer?.id,
        customerName: _customerName,
        customerPhone: _customerPhone,
        items: _items,
        amountPaid: amountPaid,
        paymentMode: _paymentMode,
        notes: _notes,
        isCourier: _isCourier,
        courierDetails: _courierDetails,
        platform: _platform,
      );

      await _invoiceRepo.save(invoice);

      // Update customer balance if credit
      if (_selectedCustomer != null && invoice.amountDue > 0) {
        await _customerRepo.updateBalance(_selectedCustomer!.id!, invoice.amountDue);
      }

      _successInvoiceNumber = invoiceNumber;
      resetCart();
      return invoice.copyWith(invoiceNumber: invoiceNumber);
    } catch (e) {
      _error = 'Failed to save: $e';
      return null;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  void resetCart() {
    _items.clear();
    _selectedCustomer = null;
    _customerName = '';
    _customerPhone = '';
    _paymentMode = 'Cash';
    _cashAmount = 0;
    _upiAmount = 0;
    _notes = '';
    _isCourier = false;
    _courierDetails = '';
    _platform = DeliveryPlatform.direct;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _successInvoiceNumber = null;
    notifyListeners();
  }
}

extension on Invoice {
  Invoice copyWith({String? invoiceNumber}) => Invoice(
        id: id,
        businessId: businessId,
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
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
        status: status,
        platform: platform,
        paymentMode: paymentMode,
        notes: notes,
        isCourier: isCourier,
        courierDetails: courierDetails,
        invoiceDate: invoiceDate,
        dueDate: dueDate,
        createdAt: createdAt,
      );
}
