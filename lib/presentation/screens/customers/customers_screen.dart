import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../viewmodels/app_viewmodel.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchCtrl = TextEditingController();
  final _repo = CustomerRepository();
  List<Customer> _customers = [];
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
    final results = await _repo.getAll(
      _businessId,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
    setState(() {
      _customers = results;
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
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _buildContent(),
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
              const Text('Customers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text('${_customers.length} customers', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 260,
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search name, phone...',
                prefixIcon: Icon(Icons.search, size: 16),
                isDense: true,
              ),
              onChanged: (_) => _load(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showForm(null),
            icon: const Icon(Icons.person_add, size: 16),
            label: const Text('Add Customer'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_customers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('No customers found', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _customers.length,
      itemBuilder: (context, index) {
        final c = _customers[index];
        return _CustomerCard(
          customer: c,
          onEdit: () => _showForm(c),
          onDelete: () => _deleteCustomer(c),
        );
      },
    );
  }

  void _showForm(Customer? customer) {
    showDialog(
      context: context,
      builder: (_) => _CustomerFormDialog(
        customer: customer,
        businessId: _businessId,
        repo: _repo,
        onSaved: _load,
      ),
    );
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _repo.delete(customer.id!);
      _load();
    }
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({required this.customer, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              customer.name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(customer.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    if (customer.email.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.email, size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(customer.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(customer.customerNumber,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(width: 16),
          if (customer.outstandingBalance > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Due: ${CurrencyFormatter.format(customer.outstandingBalance)}',
                style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit, size: 16, color: AppColors.textSecondary)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete, size: 16, color: AppColors.error)),
        ],
      ),
    );
  }
}

class _CustomerFormDialog extends StatefulWidget {
  final Customer? customer;
  final int businessId;
  final CustomerRepository repo;
  final VoidCallback onSaved;

  const _CustomerFormDialog({
    this.customer,
    required this.businessId,
    required this.repo,
    required this.onSaved,
  });

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _credit;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _name = TextEditingController(text: c?.name ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _address = TextEditingController(text: c?.address ?? '');
    _credit = TextEditingController(text: c?.creditLimit.toStringAsFixed(0) ?? '0');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _credit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(widget.customer == null ? 'Add Customer' : 'Edit Customer',
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
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Name *'),
                      validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      decoration: const InputDecoration(labelText: 'Phone *'),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address,
                      decoration: const InputDecoration(labelText: 'Address'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _credit,
                      decoration: const InputDecoration(labelText: 'Credit Limit ₹'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving...' : 'Save'),
                    ),
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

    final now = DateTime.now();
    final customerNumber = widget.customer?.customerNumber ??
        await widget.repo.nextCustomerNumber(widget.businessId);

    final customer = Customer(
      id: widget.customer?.id,
      businessId: widget.businessId,
      customerNumber: customerNumber,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
      creditLimit: double.tryParse(_credit.text) ?? 0,
      outstandingBalance: widget.customer?.outstandingBalance ?? 0,
      createdAt: widget.customer?.createdAt ?? now,
      updatedAt: now,
    );

    await widget.repo.save(customer);
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
    widget.onSaved();
  }
}
