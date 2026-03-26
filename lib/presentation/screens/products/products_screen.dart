import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';
import '../../viewmodels/app_viewmodel.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchCtrl = TextEditingController();
  final _repo = ProductRepository();
  List<Product> _products = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _loading = true;
  late int _businessId;

  @override
  void initState() {
    super.initState();
    _businessId = context.read<AppViewModel>().activeBusiness?.id ?? 1;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _repo.getAll(_businessId, search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(), category: _selectedCategory),
      _repo.getCategories(_businessId),
    ]);
    setState(() {
      _products = results[0] as List<Product>;
      _categories = results[1] as List<String>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _buildGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text('${_products.length} items', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 260,
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search or scan barcode...',
                prefixIcon: Icon(Icons.search, size: 16),
                isDense: true,
              ),
              onChanged: (_) => _load(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showForm(null),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Product'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: AppColors.bgCard,
      child: Row(
        children: [
          const Text('Category:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = null);
              _load();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: _selectedCategory == null ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _selectedCategory == null ? AppColors.primary : AppColors.border),
              ),
              child: Text('All',
                  style: TextStyle(
                    color: _selectedCategory == null ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: _selectedCategory == null ? FontWeight.w600 : FontWeight.normal,
                  )),
            ),
          ),
          ..._categories.map((cat) {
            final selected = _selectedCategory == cat;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = cat);
                _load();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                ),
                child: Text(cat,
                    style: TextStyle(
                      color: selected ? AppColors.primary : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    )),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    if (_products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('No products found', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _products.length,
      itemBuilder: (context, i) {
        final p = _products[i];
        return _ProductCard(
          product: p,
          onEdit: () => _showForm(p),
          onDelete: () => _deleteProduct(p),
        );
      },
    );
  }

  void _showForm(Product? product) {
    showDialog(
      context: context,
      builder: (_) => _ProductFormDialog(
        product: product,
        businessId: _businessId,
        repo: _repo,
        onSaved: _load,
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    await _repo.delete(product.id!);
    _load();
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({required this.product, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.stockQuantity <= product.lowStockAlert && product.stockQuantity > 0;
    final isOutOfStock = product.stockQuantity == 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOutOfStock
              ? AppColors.error.withValues(alpha: 0.4)
              : isLowStock
                  ? AppColors.warning.withValues(alpha: 0.4)
                  : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  product.name[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              const Spacer(),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, size: 16, color: AppColors.textMuted),
                color: AppColors.bgPage,
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                ],
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(product.name,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(product.category, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const Spacer(),
          Text(CurrencyFormatter.format(product.price),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('GST ${product.gstPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isOutOfStock
                      ? AppColors.error.withValues(alpha: 0.12)
                      : isLowStock
                          ? AppColors.warning.withValues(alpha: 0.12)
                          : AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isOutOfStock
                      ? 'Out'
                      : '${product.stockQuantity.toStringAsFixed(0)} ${product.unit}',
                  style: TextStyle(
                    color: isOutOfStock
                        ? AppColors.error
                        : isLowStock
                            ? AppColors.warning
                            : AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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

class _ProductFormDialog extends StatefulWidget {
  final Product? product;
  final int businessId;
  final ProductRepository repo;
  final VoidCallback onSaved;

  const _ProductFormDialog({
    this.product,
    required this.businessId,
    required this.repo,
    required this.onSaved,
  });

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _barcode;
  late final TextEditingController _category;
  late final TextEditingController _price;
  late final TextEditingController _costPrice;
  late final TextEditingController _gst;
  late final TextEditingController _stock;
  late final TextEditingController _unit;
  PricingType _pricingType = PricingType.unit;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _sku = TextEditingController(text: p?.sku ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? '');
    _category = TextEditingController(text: p?.category ?? 'General');
    _price = TextEditingController(text: p?.price.toStringAsFixed(2) ?? '');
    _costPrice = TextEditingController(text: p?.costPrice.toStringAsFixed(2) ?? '0');
    _gst = TextEditingController(text: p?.gstPercent.toStringAsFixed(0) ?? '18');
    _stock = TextEditingController(text: p?.stockQuantity.toStringAsFixed(0) ?? '0');
    _unit = TextEditingController(text: p?.unit ?? 'pcs');
    _pricingType = p?.pricingType ?? PricingType.unit;
  }

  @override
  void dispose() {
    for (final ctrl in [_name, _sku, _barcode, _category, _price, _costPrice, _gst, _stock, _unit]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(widget.product == null ? 'Add Product' : 'Edit Product',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(child: TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Name *'),
                          validator: (v) => v?.trim().isEmpty == true ? 'Required' : null)),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: _category, decoration: const InputDecoration(labelText: 'Category'))),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: TextFormField(controller: _price, decoration: const InputDecoration(labelText: 'Selling Price ₹ *'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => (double.tryParse(v ?? '') ?? -1) <= 0 ? 'Enter valid price' : null)),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: _costPrice, decoration: const InputDecoration(labelText: 'Cost Price ₹'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: TextFormField(controller: _gst, decoration: const InputDecoration(labelText: 'GST %'),
                          keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: _unit, decoration: const InputDecoration(labelText: 'Unit (pcs/kg/ltr)'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: _stock, decoration: const InputDecoration(labelText: 'Stock Qty'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: TextFormField(controller: _sku, decoration: const InputDecoration(labelText: 'SKU'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: _barcode, decoration: const InputDecoration(labelText: 'Barcode'))),
                      ]),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Pricing Type:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(width: 8),
                          ...PricingType.values.map((t) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(t.name),
                                  selected: _pricingType == t,
                                  onSelected: (_) => setState(() => _pricingType = t),
                                  selectedColor: AppColors.primary,
                                  backgroundColor: AppColors.bgPage,
                                  labelStyle: TextStyle(
                                    color: _pricingType == t ? Colors.white : AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    const Spacer(),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving...' : 'Save')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final product = Product(
      id: widget.product?.id,
      businessId: widget.businessId,
      name: _name.text.trim(),
      sku: _sku.text.trim(),
      barcode: _barcode.text.trim(),
      category: _category.text.trim().isEmpty ? 'General' : _category.text.trim(),
      price: double.tryParse(_price.text) ?? 0,
      costPrice: double.tryParse(_costPrice.text) ?? 0,
      gstPercent: double.tryParse(_gst.text) ?? 18,
      pricingType: _pricingType,
      unit: _unit.text.trim().isEmpty ? 'pcs' : _unit.text.trim(),
      stockQuantity: double.tryParse(_stock.text) ?? 0,
      createdAt: widget.product?.createdAt ?? DateTime.now(),
    );

    await widget.repo.save(product);
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
    widget.onSaved();
  }
}
