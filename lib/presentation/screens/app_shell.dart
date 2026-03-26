import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../viewmodels/app_viewmodel.dart';
import '../widgets/sidebar.dart';
import 'dashboard/dashboard_screen.dart';
import 'billing/billing_screen.dart';
import 'invoices/invoices_screen.dart';
import 'customers/customers_screen.dart';
import 'products/products_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: AppColors.bgPage,
          body: Row(
            children: [
              const AppSidebar(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _buildScreen(vm.currentScreen),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScreen(AppScreen screen) {
    return switch (screen) {
      AppScreen.dashboard => const DashboardScreen(key: ValueKey('dashboard')),
      AppScreen.billing => const BillingScreen(key: ValueKey('billing')),
      AppScreen.invoices => const InvoicesScreen(key: ValueKey('invoices')),
      AppScreen.customers => const CustomersScreen(key: ValueKey('customers')),
      AppScreen.products => const ProductsScreen(key: ValueKey('products')),
      AppScreen.reports => const ReportsScreen(key: ValueKey('reports')),
      AppScreen.settings => const SettingsScreen(key: ValueKey('settings')),
    };
  }
}
