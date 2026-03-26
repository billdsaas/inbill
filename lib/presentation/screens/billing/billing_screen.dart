import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/invoice.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../viewmodels/billing_viewmodel.dart';
import '../../viewmodels/app_viewmodel.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  late BillingViewModel _vm;
  final _productSearchCtrl = TextEditingController();
  final _productFocus = FocusNode();
  List<Product> _productSuggestions = [];
  String? _selectedCategory;
  List<Product> _allProducts = [];
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    final businessId = context.read<AppViewModel>().activeBusiness?.id ?? 1;
    _vm = BillingViewModel(businessId: businessId);
    _loadProducts();
  }

  @override
  void dispose() {
    _productSearchCtrl.dispose();
    _productFocus.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({String? search, String? category}) async {
    final businessId = context.read<AppViewModel>().activeBusiness?.id ?? 1;
    final results = await ProductRepository().getAll(businessId, search: search, category: category);
    final cats = await ProductRepository().getCategories(businessId);
    if (mounted) {
      setState(() {
        _allProducts = results;
        _categories = cats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<BillingViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: AppColors.bgPage,
            body: Focus(
              onKeyEvent: (_, event) {
                if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f2) {
                  _productFocus.requestFocus();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Column(
                children: [
                  _buildHeader(vm),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Product catalog
                        Expanded(
                          flex: 3,
                          child: _ProductCatalog(
                            searchCtrl: _productSearchCtrl,
                            searchFocus: _productFocus,
                            products: _productSuggestions.isNotEmpty ? _productSuggestions : _allProducts,
                            categories: _categories,
                            selectedCategory: _selectedCategory,
                            onCategoryChanged: (cat) {
                              setState(() => _selectedCategory = cat);
                              _loadProducts(category: cat);
                            },
                            onSearch: (q) {
                              if (q.trim().isEmpty) {
                                setState(() => _productSuggestions = []);
                                _loadProducts(category: _selectedCategory);
                              } else {
                                final businessId = context.read<AppViewModel>().activeBusiness?.id ?? 1;
                                ProductRepository().getAll(businessId, search: q, category: _selectedCategory).then((r) {
                                  if (mounted) setState(() => _productSuggestions = r);
                                });
                              }
                            },
                            onAddProduct: vm.addProductToCart,
                          ),
                        ),
                        // Right: Cart + Checkout
                        SizedBox(
                          width: 340,
                          child: _CheckoutPanel(vm: vm),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BillingViewModel vm) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Checkout Dashboard', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text('Press F2 to search products', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          if (vm.successInvoiceNumber != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 14),
                  const SizedBox(width: 6),
                  Text('Invoice ${vm.successInvoiceNumber} saved!',
                      style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          if (vm.error != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(vm.error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ),
          const SizedBox(width: 12),
          if (vm.hasItems)
            OutlinedButton.icon(
              onPressed: vm.resetCart,
              icon: const Icon(Icons.close, size: 14),
              label: const Text('Clear Cart'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Product Catalog (left panel) ────────────────────────────────────────────

class _ProductCatalog extends StatelessWidget {
  final TextEditingController searchCtrl;
  final FocusNode searchFocus;
  final List<Product> products;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String> onSearch;
  final ValueChanged<Product> onAddProduct;

  const _ProductCatalog({
    required this.searchCtrl,
    required this.searchFocus,
    required this.products,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onSearch,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search + category filter bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          color: AppColors.bgCard,
          child: Column(
            children: [
              TextField(
                controller: searchCtrl,
                focusNode: searchFocus,
                decoration: InputDecoration(
                  hintText: 'Search products, SKUs, or categories...',
                  prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textMuted),
                  suffixIcon: GestureDetector(
                    onTap: () {},
                    child: const Tooltip(
                      message: 'Scan barcode',
                      child: Icon(Icons.qr_code_scanner, size: 16, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                onChanged: onSearch,
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _CatChip(label: 'All Items', selected: selectedCategory == null, onTap: () => onCategoryChanged(null)),
                    ...categories.map((cat) => _CatChip(
                          label: cat,
                          selected: selectedCategory == cat,
                          onTap: () => onCategoryChanged(cat),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: products.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textMuted),
                      SizedBox(height: 8),
                      Text('No products found', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(14),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, i) => _ProductTile(
                    product: products[i],
                    onAdd: () => onAddProduct(products[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CatChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.bgPage,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;

  const _ProductTile({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isOut = product.stockQuantity <= 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: isOut ? null : onAdd,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image placeholder
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
              ),
              alignment: Alignment.center,
              child: Text(
                product.name[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('SKU: ${product.sku.isEmpty ? '-' : product.sku}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(CurrencyFormatter.format(product.price),
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                      GestureDetector(
                        onTap: isOut ? null : onAdd,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isOut ? AppColors.border : AppColors.secondary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isOut ? Icons.block : Icons.add,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Checkout Panel (right) ───────────────────────────────────────────────────

class _CheckoutPanel extends StatefulWidget {
  final BillingViewModel vm;
  const _CheckoutPanel({required this.vm});

  @override
  State<_CheckoutPanel> createState() => _CheckoutPanelState();
}

class _CheckoutPanelState extends State<_CheckoutPanel> {
  // Controllers managed here — NOT recreated in build
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  final _phoneLayerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.vm.customerName);
    _phoneCtrl = TextEditingController(text: widget.vm.customerPhone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _onPhoneChanged(String value) async {
    widget.vm.setCustomerPhone(value);
    if (value.trim().length < 2) {
      _removeOverlay();
      return;
    }
    final businessId = context.read<AppViewModel>().activeBusiness?.id ?? 1;
    final results = await CustomerRepository().getAll(businessId, search: value.trim());
    if (!mounted) return;

    _removeOverlay();
    if (results.isEmpty) return;

    _overlayEntry = _buildOverlay(results);
    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _onNameChanged(String value) async {
    widget.vm.setCustomerName(value);
    if (value.trim().length < 2) {
      _removeOverlay();
      return;
    }
    final businessId = context.read<AppViewModel>().activeBusiness?.id ?? 1;
    final results = await CustomerRepository().getAll(businessId, search: value.trim());
    if (!mounted) return;
    _removeOverlay();
    if (results.isEmpty) return;
    _overlayEntry = _buildOverlay(results);
    Overlay.of(context).insert(_overlayEntry!);
  }

  OverlayEntry _buildOverlay(List<Customer> customers) {
    return OverlayEntry(
      builder: (ctx) => Positioned(
        width: 310,
        child: CompositedTransformFollower(
          link: _phoneLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 46),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(10),
            color: AppColors.bgCard,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                    child: Row(
                      children: [
                        const Icon(Icons.person_search, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text('${customers.length} customer${customers.length > 1 ? 's' : ''} found',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: customers.length,
                      itemBuilder: (_, i) => _CustomerSuggestionTile(
                        customer: customers[i],
                        onTap: () {
                          _selectCustomer(customers[i]);
                          _removeOverlay();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectCustomer(Customer customer) {
    widget.vm.setCustomer(customer);
    // Sync controllers without triggering rebuild loop
    _nameCtrl.text = customer.name;
    _phoneCtrl.text = customer.phone;
    // Move cursor to end
    _nameCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _nameCtrl.text.length));
    _phoneCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _phoneCtrl.text.length));
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // Cart header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Text('Current Cart', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                if (vm.hasItems)
                  TextButton.icon(
                    onPressed: vm.resetCart,
                    icon: const Icon(Icons.close, size: 12),
                    label: const Text('Clear Cart', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          // Customer section
          _buildCustomerSection(vm),
          const Divider(height: 1),
          // Cart items
          Expanded(
            child: vm.hasItems
                ? ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: vm.items.length,
                    itemBuilder: (_, i) => _CartItemRow(
                      item: vm.items[i],
                      onUpdate: (updated) => vm.updateItem(i, updated),
                      onRemove: () => vm.removeItem(i),
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 40, color: AppColors.textMuted),
                        SizedBox(height: 8),
                        Text('Cart is empty', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        SizedBox(height: 2),
                        Text('Tap a product to add it', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
          ),
          // Totals + payment
          _buildCheckout(vm),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(BillingViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          // Phone field with autocomplete overlay
          CompositedTransformTarget(
            link: _phoneLayerLink,
            child: TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Phone number',
                prefixIcon: const Icon(Icons.phone, size: 15, color: AppColors.textMuted),
                suffixIcon: vm.selectedCustomer != null
                    ? const Icon(Icons.check_circle, size: 15, color: AppColors.success)
                    : null,
              ),
              onChanged: _onPhoneChanged,
              onTap: () {
                if (_phoneCtrl.text.length >= 2) {
                  _onPhoneChanged(_phoneCtrl.text);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              hintText: 'Customer name *',
              prefixIcon: Icon(Icons.person_outline, size: 15, color: AppColors.textMuted),
            ),
            onChanged: _onNameChanged,
          ),
          if (vm.selectedCustomer != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      vm.selectedCustomer!.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vm.selectedCustomer!.name,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                        if (vm.selectedCustomer!.outstandingBalance > 0)
                          Text('Due: ${CurrencyFormatter.format(vm.selectedCustomer!.outstandingBalance)}',
                              style: const TextStyle(color: AppColors.warning, fontSize: 10)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      vm.setCustomer(null);
                      _nameCtrl.clear();
                      _phoneCtrl.clear();
                    },
                    child: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckout(BillingViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // Totals
          if (vm.hasItems) ...[
            _TotalRow('Subtotal', CurrencyFormatter.format(vm.subtotal)),
            if (vm.totalDiscount > 0)
              _TotalRow('Discount', '-${CurrencyFormatter.format(vm.totalDiscount)}', valueColor: AppColors.secondary),
            if (vm.totalGst > 0)
              _TotalRow('Tax (GST)', CurrencyFormatter.format(vm.totalGst)),
            const Divider(height: 12),
            _TotalRow('TOTAL AMOUNT', CurrencyFormatter.format(vm.grandTotal), isBold: true, large: true),
            const SizedBox(height: 12),
          ],
          // Payment mode
          Row(
            children: ['Cash', 'UPI', 'Credit', 'Hybrid'].map((mode) {
              final selected = vm.paymentMode == mode;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: GestureDetector(
                    onTap: () => vm.setPaymentMode(mode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.bgPage,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: Text(mode,
                          style: TextStyle(
                            color: selected ? Colors.white : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          )),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (vm.paymentMode == 'Hybrid') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(
                  decoration: const InputDecoration(labelText: 'Cash ₹'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => vm.setCashAmount(double.tryParse(v) ?? 0),
                )),
                const SizedBox(width: 8),
                Expanded(child: TextField(
                  decoration: const InputDecoration(labelText: 'UPI ₹'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => vm.setUpiAmount(double.tryParse(v) ?? 0),
                )),
              ],
            ),
          ],
          const SizedBox(height: 10),
          // PAY NOW button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: vm.saving || !vm.hasItems
                  ? null
                  : () async {
                      // Auto-save new customer if not existing
                      if (vm.selectedCustomer == null && _nameCtrl.text.trim().isNotEmpty && _phoneCtrl.text.trim().isNotEmpty) {
                        final businessId = context.read<AppViewModel>().activeBusiness?.id ?? 1;
                        final repo = CustomerRepository();
                        final existing = await repo.getByPhone(businessId, _phoneCtrl.text.trim());
                        if (existing == null) {
                          final customerNumber = await repo.nextCustomerNumber(businessId);
                          final now = DateTime.now();
                          final newCustomer = Customer(
                            businessId: businessId,
                            customerNumber: customerNumber,
                            name: _nameCtrl.text.trim(),
                            phone: _phoneCtrl.text.trim(),
                            createdAt: now,
                            updatedAt: now,
                          );
                          final id = await repo.save(newCustomer);
                          final saved = await repo.getById(id);
                          if (saved != null) vm.setCustomer(saved);
                        } else {
                          vm.setCustomer(existing);
                        }
                      }
                      final invoice = await vm.saveInvoice();
                      if (invoice != null && mounted) {
                        _nameCtrl.clear();
                        _phoneCtrl.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Invoice ${invoice.invoiceNumber} created!'),
                            action: SnackBarAction(label: 'Print', onPressed: () {}),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (vm.saving)
                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  else
                    const Icon(Icons.credit_card, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    vm.saving ? 'Processing...' : 'PAY NOW${vm.hasItems ? ' — ${CurrencyFormatter.format(vm.grandTotal)}' : ''}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: vm.hasItems ? () {} : null,
                  icon: const Icon(Icons.save_outlined, size: 14),
                  label: const Text('Save Cart', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: vm.hasItems ? () {} : null,
                  icon: const Icon(Icons.print_outlined, size: 14),
                  label: const Text('Print Quote', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerSuggestionTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const _CustomerSuggestionTile({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(customer.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 10, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(customer.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      if (customer.email.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(customer.email, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (customer.outstandingBalance > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warningSurface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Due ${CurrencyFormatter.compact(customer.outstandingBalance)}',
                  style: const TextStyle(color: AppColors.warning, fontSize: 9, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Cart item row ─────────────────────────────────────────────────────────────

class _CartItemRow extends StatefulWidget {
  final InvoiceItem item;
  final ValueChanged<InvoiceItem> onUpdate;
  final VoidCallback onRemove;

  const _CartItemRow({required this.item, required this.onUpdate, required this.onRemove});

  @override
  State<_CartItemRow> createState() => _CartItemRowState();
}

class _CartItemRowState extends State<_CartItemRow> {
  late TextEditingController _qtyCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _discCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: _fmtQty(widget.item.quantity));
    _rateCtrl = TextEditingController(text: widget.item.rate.toStringAsFixed(2));
    _discCtrl = TextEditingController(text: widget.item.discount > 0 ? widget.item.discount.toStringAsFixed(0) : '');
  }

  @override
  void didUpdateWidget(_CartItemRow old) {
    super.didUpdateWidget(old);
    // Only update if the value changed externally (not from user typing)
    if (old.item.quantity != widget.item.quantity && _qtyCtrl.text != _fmtQty(widget.item.quantity)) {
      _qtyCtrl.text = _fmtQty(widget.item.quantity);
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    _discCtrl.dispose();
    super.dispose();
  }

  String _fmtQty(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

  void _update() {
    widget.onUpdate(widget.item.copyWith(
      quantity: double.tryParse(_qtyCtrl.text) ?? widget.item.quantity,
      rate: double.tryParse(_rateCtrl.text) ?? widget.item.rate,
      discount: double.tryParse(_discCtrl.text) ?? 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgPage,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.item.productName,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Text(CurrencyFormatter.format(widget.item.total),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: widget.onRemove,
                child: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _FieldCol(label: 'QTY (${widget.item.unit})', child: SizedBox(
                width: 65,
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                  onChanged: (_) => _update(),
                ),
              )),
              const SizedBox(width: 6),
              _FieldCol(label: 'Rate ₹', child: SizedBox(
                width: 85,
                child: TextField(
                  controller: _rateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                  onChanged: (_) => _update(),
                ),
              )),
              const SizedBox(width: 6),
              _FieldCol(label: 'Disc%', child: SizedBox(
                width: 52,
                child: TextField(
                  controller: _discCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(hintText: '0', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                  onChanged: (_) => _update(),
                ),
              )),
              const SizedBox(width: 8),
              _FieldCol(
                label: 'GST',
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${widget.item.gstPercent.toStringAsFixed(0)}%',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldCol extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldCol({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        const SizedBox(height: 2),
        child,
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool large;
  final Color? valueColor;

  const _TotalRow(this.label, this.value, {this.isBold = false, this.large = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: large ? 13 : 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            letterSpacing: isBold ? 0.3 : 0,
          )),
          Text(value, style: TextStyle(
            color: valueColor ?? (isBold ? AppColors.textPrimary : AppColors.textSecondary),
            fontSize: large ? 18 : 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
          )),
        ],
      ),
    );
  }
}
