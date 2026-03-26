import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/invoice.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../viewmodels/app_viewmodel.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _searchCtrl = TextEditingController();
  List<Invoice> _invoices = [];
  bool _loading = true;
  String? _statusFilter;
  String? _platformFilter;
  late int _businessId;

  @override
  void initState() {
    super.initState();
    _businessId = context.read<AppViewModel>().activeBusiness?.id ?? 1;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await InvoiceRepository().getAll(
      _businessId,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      status: _statusFilter,
      platform: _platformFilter,
    );
    setState(() {
      _invoices = results;
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
                : _buildTable(),
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invoices', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text('Manage and track all invoices', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 280,
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search by number, customer...',
                prefixIcon: Icon(Icons.search, size: 16),
                isDense: true,
              ),
              onChanged: (_) => _load(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => context.read<AppViewModel>().navigate(AppScreen.billing),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Invoice'),
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
          const Text('Status:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(width: 8),
          ...[null, 'paid', 'pending', 'partial', 'cancelled'].map((s) {
            final label = s == null ? 'All' : s[0].toUpperCase() + s.substring(1);
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterChip(
                label: label,
                selected: _statusFilter == s,
                onTap: () {
                  setState(() => _statusFilter = s);
                  _load();
                },
              ),
            );
          }),
          const SizedBox(width: 16),
          const Text('Platform:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(width: 8),
          ...[null, 'direct', 'swiggy', 'zomato'].map((p) {
            final label = p == null ? 'All' : p[0].toUpperCase() + p.substring(1);
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterChip(
                label: label,
                selected: _platformFilter == p,
                onTap: () {
                  setState(() => _platformFilter = p);
                  _load();
                },
              ),
            );
          }),
          const Spacer(),
          Text('${_invoices.length} invoices', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_invoices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('No invoices found', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _invoices.length,
      itemBuilder: (context, index) {
        final inv = _invoices[index];
        return _InvoiceRow(invoice: inv, onTap: () => _showDetail(inv));
      },
    );
  }

  void _showDetail(Invoice invoice) {
    showDialog(
      context: context,
      builder: (_) => _InvoiceDetailDialog(invoice: invoice, onRefresh: _load),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;

  const _InvoiceRow({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (invoice.status) {
      InvoiceStatus.paid => AppColors.success,
      InvoiceStatus.partial => AppColors.warning,
      InvoiceStatus.pending => AppColors.primary,
      InvoiceStatus.cancelled => AppColors.error,
      _ => AppColors.textMuted,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(invoice.invoiceNumber,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(DateFormatter.formatDate(invoice.invoiceDate),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(invoice.customerName,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                  Text(invoice.customerPhone,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                invoice.platform.name[0].toUpperCase() + invoice.platform.name.substring(1),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                CurrencyFormatter.format(invoice.grandTotal),
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                invoice.status.name.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _InvoiceDetailDialog extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onRefresh;

  const _InvoiceDetailDialog({required this.invoice, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(invoice.invoiceNumber,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow('Customer', invoice.customerName),
                    _DetailRow('Phone', invoice.customerPhone),
                    _DetailRow('Date', DateFormatter.formatDate(invoice.invoiceDate)),
                    _DetailRow('Payment', invoice.paymentMode),
                    _DetailRow('Platform', invoice.platform.name),
                    const SizedBox(height: 16),
                    const Text('Items', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...invoice.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(child: Text(item.productName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                              Text('${item.quantity} × ${CurrencyFormatter.format(item.rate)}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              const SizedBox(width: 16),
                              Text(CurrencyFormatter.format(item.total),
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        )),
                    const Divider(),
                    _DetailRow('Grand Total', CurrencyFormatter.format(invoice.grandTotal), bold: true),
                    if (invoice.amountDue > 0)
                      _DetailRow('Balance Due', CurrencyFormatter.format(invoice.amountDue),
                          valueColor: AppColors.warning),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Print'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('WhatsApp'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      await InvoiceRepository().delete(invoice.id!);
                      if (context.mounted) Navigator.pop(context);
                      onRefresh();
                    },
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    child: const Text('Delete'),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _DetailRow(this.label, this.value, {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
