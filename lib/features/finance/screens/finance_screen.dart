import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:bizos_x_pro/core/theme/colors.dart';
import 'package:bizos_x_pro/widgets/glass_container.dart';
import 'package:responsive_framework/responsive_framework.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final subTextColor = isDark ? Colors.white54 : Colors.black54;
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildResponsiveBudgetSummary(isMobile, isDark, textColor, subTextColor),
            const SizedBox(height: 24),
            if (!isMobile)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildCashFlowChart(isDark, textColor, subTextColor)),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: _buildFinanceQuickAccess(isDark, textColor, subTextColor)),
                ],
              )
            else ...[
              _buildCashFlowChart(isDark, textColor, subTextColor),
              const SizedBox(height: 24),
              _buildFinanceQuickAccess(isDark, textColor, subTextColor),
            ],
            const SizedBox(height: 24),
            _buildRecentTransactions(isDark, textColor, subTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveBudgetSummary(bool isMobile, bool isDark, Color textColor, Color subTextColor) {
    final cards = [
      _BudgetCard(title: 'Total Income', value: r'$845.2k', color: AppColors.success, isDark: isDark, subTextColor: subTextColor),
      _BudgetCard(title: 'Total Expenses', value: r'$312.4k', color: AppColors.error, isDark: isDark, subTextColor: subTextColor),
      _BudgetCard(title: 'Net Profit', value: r'$532.8k', color: AppColors.primary, isDark: isDark, subTextColor: subTextColor),
    ];

    if (isMobile) {
      return Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList());
    }
    return Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: c))).toList());
  }

  Widget _buildCashFlowChart(bool isDark, Color textColor, Color subTextColor) {
    return GlassContainer(
      height: 350,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cash Flow Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Colors.white10 : Colors.black12, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Text(r'$' + '${value.toInt()}k', style: TextStyle(color: subTextColor, fontSize: 10)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][value.toInt() % 7], style: TextStyle(color: subTextColor, fontSize: 10)))),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: (i + 3) * 5.0, color: AppColors.primary, width: 12, borderRadius: BorderRadius.circular(4))])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceQuickAccess(bool isDark, Color textColor, Color subTextColor) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shortcuts', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 16),
          _ShortcutItem(icon: IconsaxPlusLinear.card, label: 'Pay Bills', color: AppColors.warning, textColor: textColor),
          _ShortcutItem(icon: IconsaxPlusLinear.document_upload, label: 'Invoices', color: AppColors.primary, textColor: textColor),
          _ShortcutItem(icon: IconsaxPlusLinear.graph, label: 'Tax Report', color: AppColors.success, textColor: textColor),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(bool isDark, Color textColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) {
            final isNegative = index % 2 == 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isNegative ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                      child: Icon(isNegative ? IconsaxPlusLinear.arrow_up_1 : IconsaxPlusLinear.arrow_down_1, color: isNegative ? AppColors.error : AppColors.success, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Transaction #${1024 + index}', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 13)),
                          Text('Mar 24, 2024', style: TextStyle(color: subTextColor, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text('${isNegative ? '-' : '+'}' + r'$' + '${(index + 1) * 1200}', style: TextStyle(fontWeight: FontWeight.bold, color: isNegative ? AppColors.error : AppColors.success, fontSize: 14)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final bool isDark;
  final Color subTextColor;

  const _BudgetCard({required this.title, required this.value, required this.color, required this.isDark, required this.subTextColor});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(colors: [color.withValues(alpha: 0.2), Colors.transparent], begin: Alignment.topLeft, end: Alignment.bottomRight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: subTextColor, fontSize: 12)),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _ShortcutItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  const _ShortcutItem({required this.icon, required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
