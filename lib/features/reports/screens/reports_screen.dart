import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:ebficbm/core/theme/colors.dart';
import 'package:ebficbm/widgets/glass_container.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Financial Insights', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: isMobile ? 1 : 2,
                  child: _buildCompanyDistributionChart(isDark, textColor, isMobile),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: _buildSummaryWidgets(isDark, textColor),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            _buildDailySummaryCharts(isDark, textColor, isMobile),
            const SizedBox(height: 24),
            _buildProjectPerformanceList(isDark, textColor, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyDistributionChart(bool isDark, Color textColor, bool isMobile) {
    return GlassContainer(
      height: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Company Distribution', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(value: 40, color: AppColors.primary, title: '40%', radius: isMobile ? 35 : 45, titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        PieChartSectionData(value: 30, color: AppColors.secondary, title: '30%', radius: isMobile ? 35 : 45, titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        PieChartSectionData(value: 30, color: AppColors.accent, title: '30%', radius: isMobile ? 35 : 45, titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                      centerSpaceRadius: isMobile ? 30 : 40,
                    ),
                  ),
                ),
                if (!isMobile)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LegendItem(color: AppColors.primary, label: 'Tech Corp', isDark: isDark),
                        _LegendItem(color: AppColors.secondary, label: 'Marketing', isDark: isDark),
                        _LegendItem(color: AppColors.accent, label: 'Logistics', isDark: isDark),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryWidgets(bool isDark, Color textColor) {
    return Column(
      children: [
        _QuickMetric(title: 'ROI Rate', value: '24.5%', color: AppColors.success, isDark: isDark),
        const SizedBox(height: 16),
        _QuickMetric(title: 'Growth', value: '+18%', color: AppColors.primary, isDark: isDark),
      ],
    );
  }

  Widget _buildDailySummaryCharts(bool isDark, Color textColor, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: GlassContainer(
            height: 220,
            child: Column(
              children: [
                Text('Daily Revenue', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)),
                const SizedBox(height: 12),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: AppColors.success,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          spots: const [FlSpot(0, 2), FlSpot(1, 3.5), FlSpot(2, 2.5), FlSpot(3, 4), FlSpot(4, 3)],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassContainer(
            height: 220,
            child: Column(
              children: [
                Text('Active Leads', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)),
                const SizedBox(height: 12),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(5, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: (i + 2) * 2.0, color: AppColors.secondary, width: 12, borderRadius: BorderRadius.circular(4))])),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectPerformanceList(bool isDark, Color textColor, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Performance Ranking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('Project #${index + 1} Alpha', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13))),
                  Expanded(
                    flex: 3,
                    child: LinearProgressIndicator(
                      value: 0.2 * (index + 1),
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('${(index + 1) * 20}%', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;
  const _LegendItem({required this.color, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }
}

class _QuickMetric extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final bool isDark;
  const _QuickMetric({required this.title, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
