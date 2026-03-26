import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/app_viewmodel.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DashboardViewModel _vm;

  @override
  void initState() {
    super.initState();
    final businessId = context.read<AppViewModel>().activeBusiness?.id ?? 1;
    _vm = DashboardViewModel(businessId: businessId);
    _vm.load();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<DashboardViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: AppColors.bgPage,
            body: Column(
              children: [
                _buildHeader(vm),
                Expanded(
                  child: vm.loading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : _buildBody(vm),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(DashboardViewModel vm) {
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
              Text('Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text('Overview of your business performance', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          _PeriodSelector(
            current: vm.period,
            onChanged: vm.setPeriod,
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: vm.load,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(DashboardViewModel vm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Net Revenue',
                  value: CurrencyFormatter.compact(vm.revenue),
                  subtitle: CurrencyFormatter.format(vm.revenue),
                  icon: Icons.trending_up,
                  iconColor: AppColors.primary,
                  growth: vm.revenueGrowth,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Collected',
                  value: CurrencyFormatter.compact(vm.collected),
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Outstanding',
                  value: CurrencyFormatter.compact(vm.outstanding),
                  icon: Icons.pending_actions_outlined,
                  iconColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Active Invoices',
                  value: vm.invoiceCount.toString(),
                  icon: Icons.receipt_long_outlined,
                  iconColor: AppColors.chart3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Charts row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _RevenueChart(data: vm.dailyRevenue),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _PlatformBreakdown(data: vm.byPlatform),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Top products + Low stock
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _TopProductsTable(products: vm.topProducts),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _LowStockCard(count: vm.lowStockCount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final DashboardPeriod current;
  final ValueChanged<DashboardPeriod> onChanged;

  const _PeriodSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPage,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: DashboardPeriod.values.map((p) {
          final label = switch (p) {
            DashboardPeriod.today => 'Today',
            DashboardPeriod.week => 'Week',
            DashboardPeriod.month => 'Month',
            DashboardPeriod.year => 'Year',
          };
          final selected = p == current;
          return GestureDetector(
            onTap: () => onChanged(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
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
          );
        }).toList(),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue Trend', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Daily revenue overview', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: data.isEmpty
                ? const Center(child: Text('No data', style: TextStyle(color: AppColors.textMuted)))
                : LineChart(_buildChart()),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChart() {
    final spots = data.asMap().entries.map((e) {
      final revenue = (e.value['revenue'] ?? 0.0) as double;
      return FlSpot(e.key.toDouble(), revenue);
    }).toList();

    final maxY = data.isEmpty ? 10.0 : data.map((d) => (d['revenue'] ?? 0.0) as double).reduce((a, b) => a > b ? a : b);

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (v, _) => Text(
              CurrencyFormatter.compact(v),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (data.length / 6).ceilToDouble().clamp(1, double.infinity),
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i >= data.length) return const SizedBox();
              final date = data[i]['date'] as String? ?? '';
              return Text(date.length >= 5 ? date.substring(5) : date,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 9));
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minY: 0,
      maxY: maxY * 1.2,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primary.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }
}

class _PlatformBreakdown extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _PlatformBreakdown({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.primary, AppColors.warning, AppColors.error, AppColors.primary];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sales by Platform', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: data.isEmpty
                ? const Center(child: Text('No data', style: TextStyle(color: AppColors.textMuted)))
                : PieChart(
                    PieChartData(
                      sections: data.asMap().entries.map((e) {
                        final total = data.fold(0.0, (s, d) => s + ((d['revenue'] ?? 0) as num).toDouble());
                        final rev = ((e.value['revenue'] ?? 0) as num).toDouble();
                        return PieChartSectionData(
                          color: colors[e.key % colors.length],
                          value: rev,
                          title: '${(rev / total * 100).toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                          radius: 50,
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          ...data.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      (e.value['platform'] as String? ?? '').toUpperCase(),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    const Spacer(),
                    Text(
                      CurrencyFormatter.compact(((e.value['revenue'] ?? 0) as num).toDouble()),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _TopProductsTable extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  const _TopProductsTable({required this.products});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Products', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No data', style: TextStyle(color: AppColors.textMuted))),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
              },
              children: [
                const TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Product', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Qty Sold', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Revenue', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                ...products.take(8).map((p) => TableRow(
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(p['product_name'] as String? ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('${((p['total_qty'] ?? 0) as num).toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            CurrencyFormatter.compact(((p['total_revenue'] ?? 0) as num).toDouble()),
                            style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    )),
              ],
            ),
        ],
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  final int count;
  const _LowStockCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: count > 0 ? AppColors.warning.withValues(alpha: 0.5) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: count > 0 ? AppColors.warning : AppColors.textMuted, size: 20),
              const SizedBox(width: 8),
              const Text('Low Stock Alert', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          if (count == 0)
            const Text('All products are well stocked', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
          else ...[
            Text(
              '$count product${count > 1 ? 's' : ''} running low',
              style: const TextStyle(color: AppColors.warning, fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('Go to Products to restock', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
