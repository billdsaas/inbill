import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/business.dart';
import '../../viewmodels/app_viewmodel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            decoration: const BoxDecoration(
              color: AppColors.bgCard,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabCtrl,
                  tabs: const [
                    Tab(text: 'Business'),
                    Tab(text: 'Invoice'),
                    Tab(text: 'Language'),
                    Tab(text: 'Subscription'),
                  ],
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _BusinessSettingsTab(),
                const _InvoiceSettingsTab(),
                _LanguageSettingsTab(),
                const _SubscriptionTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessSettingsTab extends StatefulWidget {
  @override
  State<_BusinessSettingsTab> createState() => _BusinessSettingsTabState();
}

class _BusinessSettingsTabState extends State<_BusinessSettingsTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name, _ownerName, _phone, _email, _address, _city, _gstin, _upiId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final b = context.read<AppViewModel>().activeBusiness;
    _name = TextEditingController(text: b?.name ?? '');
    _ownerName = TextEditingController(text: b?.ownerName ?? '');
    _phone = TextEditingController(text: b?.phone ?? '');
    _email = TextEditingController(text: b?.email ?? '');
    _address = TextEditingController(text: b?.address ?? '');
    _city = TextEditingController(text: b?.city ?? '');
    _gstin = TextEditingController(text: b?.gstin ?? '');
    _upiId = TextEditingController(text: b?.upiId ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _ownerName, _phone, _email, _address, _city, _gstin, _upiId]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AppViewModel>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Business Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('This information appears on your invoices', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            _SettingsCard(
              children: [
                Row(children: [
                  Expanded(child: TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Business Name *'),
                    validator: (v) => v?.trim().isEmpty == true ? 'Required' : null)),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _ownerName, decoration: const InputDecoration(labelText: 'Owner Name *'),
                    validator: (v) => v?.trim().isEmpty == true ? 'Required' : null)),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone *'),
                    validator: (v) => v?.trim().isEmpty == true ? 'Required' : null)),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress)),
                ]),
                const SizedBox(height: 16),
                TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Address *'),
                  validator: (v) => v?.trim().isEmpty == true ? 'Required' : null),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'City *'),
                    validator: (v) => v?.trim().isEmpty == true ? 'Required' : null)),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _gstin, decoration: const InputDecoration(labelText: 'GSTIN'))),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _upiId, decoration: const InputDecoration(labelText: 'UPI ID'))),
                ]),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : () => _save(vm),
              child: Text(_saving ? 'Saving...' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(AppViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final b = vm.activeBusiness;
    final updated = Business(
      id: b?.id,
      name: _name.text.trim(),
      ownerName: _ownerName.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
      city: _city.text.trim(),
      gstin: _gstin.text.trim(),
      upiId: _upiId.text.trim(),
      createdAt: b?.createdAt ?? DateTime.now(),
    );

    await vm.updateBusiness(updated);
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business settings saved!')),
      );
    }
  }
}

class _InvoiceSettingsTab extends StatelessWidget {
  const _InvoiceSettingsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Invoice Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          _SettingsCard(
            children: [
              _SettingRow(
                title: 'Default Paper Size',
                subtitle: 'Paper size for printing',
                trailing: DropdownButton<String>(
                  value: 'A4',
                  dropdownColor: AppColors.bgPage,
                  items: AppConstants.paperSizes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (_) {},
                ),
              ),
              const Divider(height: 1),
              _SettingRow(
                title: 'Default GST Rate',
                subtitle: 'Applied to new products',
                trailing: DropdownButton<double>(
                  value: 18.0,
                  dropdownColor: AppColors.bgPage,
                  items: AppConstants.gstRates.map((r) => DropdownMenuItem(value: r, child: Text('${r.toStringAsFixed(0)}%'))).toList(),
                  onChanged: (_) {},
                ),
              ),
              const Divider(height: 1),
              _SettingRow(
                title: 'Show GST Breakdown',
                subtitle: 'Display GST separately on invoice',
                trailing: Switch(value: true, onChanged: (_) {}, activeColor: AppColors.primary),
              ),
              const Divider(height: 1),
              _SettingRow(
                title: 'Auto-print after save',
                subtitle: 'Print invoice automatically on save',
                trailing: Switch(value: false, onChanged: (_) {}, activeColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Bill Templates', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(10, (i) => _TemplateCard(number: i + 1, selected: i == 0)),
          ),
        ],
      ),
    );
  }
}

class _LanguageSettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.read<AppViewModel>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          _SettingsCard(
            children: AppConstants.supportedLocales.entries.map((e) {
              final isSelected = vm.locale.languageCode == e.key;
              return _SettingRow(
                title: e.value,
                subtitle: e.key == 'ta' ? 'தமிழ்' : 'English',
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () => vm.setLocale(e.key),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionTab extends StatelessWidget {
  const _SubscriptionTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Subscription Plans', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Choose the right plan for your business', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _PlanCard(name: 'Basic', price: 999, features: ['1 Business', '500 Invoices/mo', 'Basic Reports', 'PDF Export'])),
              const SizedBox(width: 16),
              Expanded(child: _PlanCard(name: 'Pro', price: 1999, features: ['3 Businesses', 'Unlimited Invoices', 'Advanced Reports', 'WhatsApp Integration', 'AI Voice Billing'], highlighted: true)),
              const SizedBox(width: 16),
              Expanded(child: _PlanCard(name: 'Enterprise', price: 4999, features: ['Unlimited Businesses', 'Multi-branch', 'All Pro Features', 'Priority Support', 'Custom Templates', 'API Access'])),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final int price;
  final List<String> features;
  final bool highlighted;

  const _PlanCard({required this.name, required this.price, required this.features, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primary : AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? AppColors.primary : AppColors.border,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlighted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Most Popular', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: '₹$price', style: const TextStyle(color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.w700)),
                const TextSpan(text: '/year', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: AppColors.primary, size: 14),
                    const SizedBox(width: 8),
                    Text(f, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: highlighted ? null : OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: AppColors.border),
              ),
              child: const Text('Get Started'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final int number;
  final bool selected;

  const _TemplateCard({required this.number, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 130,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, color: selected ? AppColors.primary : AppColors.textMuted, size: 24),
          const SizedBox(height: 8),
          Text('Template $number',
              style: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary, fontSize: 11),
              textAlign: TextAlign.center),
          if (selected) ...[
            const SizedBox(height: 4),
            const Icon(Icons.check_circle, color: AppColors.primary, size: 14),
          ],
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingRow({required this.title, required this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
