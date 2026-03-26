import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/business.dart';
import '../../viewmodels/app_viewmodel.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _ownerName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _gstin = TextEditingController();
  final _upiId = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _ownerName, _phone, _email, _address, _city, _gstin, _upiId]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Center(
        child: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Text('I', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 36)),
              ),
              const SizedBox(height: 16),
              const Text('Welcome to Inbill', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Set up your first business to get started', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(child: TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(labelText: 'Business Name *'),
                          validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(
                          controller: _ownerName,
                          decoration: const InputDecoration(labelText: 'Your Name *'),
                          validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                        )),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: TextFormField(
                          controller: _phone,
                          decoration: const InputDecoration(labelText: 'Phone *'),
                          keyboardType: TextInputType.phone,
                          validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.]{2,}$').hasMatch(v.trim())) {
                              return 'Invalid email';
                            }
                            return null;
                          },
                        )),
                      ]),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _address,
                        decoration: const InputDecoration(labelText: 'Business Address *'),
                        validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: TextFormField(
                          controller: _city,
                          decoration: const InputDecoration(labelText: 'City *'),
                          validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(
                          controller: _gstin,
                          decoration: const InputDecoration(labelText: 'GSTIN (optional)'),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(
                          controller: _upiId,
                          decoration: const InputDecoration(labelText: 'UPI ID (optional)'),
                        )),
                      ]),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _submit,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: Text(
                            _saving ? 'Setting up...' : 'Get Started',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final vm = context.read<AppViewModel>();
    await vm.createBusiness(Business(
      name: _name.text.trim(),
      ownerName: _ownerName.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
      city: _city.text.trim(),
      gstin: _gstin.text.trim(),
      upiId: _upiId.text.trim(),
      createdAt: DateTime.now(),
    ));

    setState(() => _saving = false);
  }
}
