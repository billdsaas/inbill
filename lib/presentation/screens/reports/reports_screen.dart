import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../viewmodels/app_viewmodel.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late int _businessId;
  late DateTimeRange _range;
  Map<String, double> _summary = {};
  List<Map<String, dynamic>> _daily = [];
  List<Map<String, dynamic>> _topProducts = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _businessId = context.read<AppViewModel>().activeBusiness?.id ?? 1;
    final now = DateTime.now();
    _range = DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = InvoiceRepository();
    final results = await Future.wait([
      repo.getSummary(_businessId, _range.start, _range.end),
      repo.getDailyRevenue(_businessId, _range.start, _range.end),
      repo.getTopProducts(_businessId, _range.start, _range.end, limit: 10),
    ]);
    setState(() {
      _summary = results[0] as Map<String, double>;
      _daily = results[1] as List<Map<String, dynamic>>;
      _topProducts = results[2] as List<Map<String, dynamic>>;
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
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCards(),
                        const SizedBox(height: 24),
                        _buildBarChart(),
                        const SizedBox(height: 24),
                        _buildTopProductsTable(),
                      ],
                    ),
                  ),
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
              Text('Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text('Detailed sales and revenue analysis', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _range,
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(primary: AppColors.primary),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setState(() => _range = picked);
                _load();
              }
            },
            icon: const Icon(Icons.date_range, size: 16),
            label: Text('${DateFormatter.formatShort(_range.start)} - ${DateFormatter.formatShort(_range.end)}'),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final revenue = _summary['revenue'] ?? 0;
    final collected = _summary['collected'] ?? 0;
    final outstanding = _summary['outstanding'] ?? 0;
    final count = (_summary['count'] ?? 0).toInt();

    return Row(
      children: [
        Expanded(child: _SummaryCard(title: 'Total Revenue', value: CurrencyFormatter.format(revenue), icon: Icons.trending_up, color: AppColors.primary)),
        const SizedBox(width: 16),
        Expanded(child: _SummaryCard(title: 'Collected', value: CurrencyFormatter.format(collected), icon: Icons.account_balance_wallet, color: AppColors.primary)),
        const SizedBox(width: 16),
        Expanded(child: _SummaryCard(title: 'Outstanding', value: CurrencyFormatter.format(outstanding), icon: Icons.pending, color: AppColors.warning)),
        const SizedBox(width: 16),
        Expanded(child: _SummaryCard(title: 'Invoices', value: count.toString(), icon: Icons.receipt_long, color: AppColors.chart3)),
      ],
    );
  }

  Widget _buildBarChart() {
    if (_daily.isEmpty) return const SizedBox();
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
          const Text('Daily Revenue', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                barGroups: _daily.asMap().entries.map((e) {
                  final revenue = (e.value['revenue'] ?? 0.0) as double;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: revenue,
                        color: AppColors.primary,
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
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
                      interval: (_daily.length / 8).ceilToDouble().clamp(1, double.infinity),
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i >= _daily.length) return const SizedBox();
                        final date = _daily[i]['date'] as String? ?? '';
                        return Text(date.length >= 5 ? date.substring(5) : date,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 9));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsTable() {
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
          const Text('Top 10 Products', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          if (_topProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No data', style: TextStyle(color: AppColors.textMuted))),
            )
          else
            ...(_topProducts.asMap().entries.map((e) {
              final p = e.value;
              final maxRevenue = (_topProducts.first['total_revenue'] ?? 1) as num;
              final revenue = (p['total_revenue'] ?? 0) as num;
              final ratio = revenue / maxRevenue;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: Text('${e.key + 1}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['product_name'] as String? ?? '',
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: ratio.toDouble(),
                              backgroundColor: AppColors.border,
                              color: AppColors.primary,
                              minHeight: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${(p['total_qty'] ?? 0)} units',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 100,
                      child: Text(
                        CurrencyFormatter.format(revenue.toDouble()),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            })),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
