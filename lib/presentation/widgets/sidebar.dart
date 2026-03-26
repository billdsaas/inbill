import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../viewmodels/app_viewmodel.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppViewModel>(
      builder: (context, vm, _) {
        return Container(
          width: 210,
          color: AppColors.bgSidebar,
          child: Column(
            children: [
              _buildHeader(context, vm),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard', screen: AppScreen.dashboard, current: vm.currentScreen, onTap: () => vm.navigate(AppScreen.dashboard)),
                    _NavItem(icon: Icons.point_of_sale_outlined, activeIcon: Icons.point_of_sale, label: 'Checkout', screen: AppScreen.billing, current: vm.currentScreen, onTap: () => vm.navigate(AppScreen.billing)),
                    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Sales', screen: AppScreen.invoices, current: vm.currentScreen, onTap: () => vm.navigate(AppScreen.invoices)),
                    _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Inventory', screen: AppScreen.products, current: vm.currentScreen, onTap: () => vm.navigate(AppScreen.products)),
                    _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Customers', screen: AppScreen.customers, current: vm.currentScreen, onTap: () => vm.navigate(AppScreen.customers)),
                    _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Reports', screen: AppScreen.reports, current: vm.currentScreen, onTap: () => vm.navigate(AppScreen.reports)),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(color: Colors.white12, height: 1),
                    ),
                    const SizedBox(height: 8),
                    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings', screen: AppScreen.settings, current: vm.currentScreen, onTap: () => vm.navigate(AppScreen.settings)),
                  ],
                ),
              ),
              _buildFooter(context, vm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text('I', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
              ),
              const SizedBox(width: 9),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Inbill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
            ],
          ),
          if (vm.activeBusiness != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showBusinessPicker(context, vm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        vm.activeBusiness!.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vm.activeBusiness!.name,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Station 01',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.unfold_more, color: Colors.white.withValues(alpha: 0.5), size: 14),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AppViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              (vm.activeBusiness?.ownerName ?? 'A')[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vm.activeBusiness?.ownerName ?? 'Admin',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text('Administrator', style: TextStyle(color: Colors.white54, fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBusinessPicker(BuildContext context, AppViewModel vm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Switch Business'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...vm.businesses.map((b) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 18,
                      child: Text(b.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                    title: Text(b.name),
                    subtitle: Text(b.city),
                    trailing: vm.activeBusiness?.id == b.id
                        ? const Icon(Icons.check_circle, color: AppColors.secondary)
                        : null,
                    onTap: () {
                      vm.selectBusiness(b.id!);
                      Navigator.pop(context);
                    },
                  )),
              const Divider(),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Business'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final AppScreen screen;
  final AppScreen current;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = screen == current;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? Colors.white12 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.white10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 17,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
