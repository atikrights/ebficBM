import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:ebficBM/core/theme/colors.dart';
import 'package:ebficBM/widgets/glass_container.dart';
import 'package:ebficBM/features/companies/models/company.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CompanyDetailView extends StatelessWidget {
  final Company company;
  final VoidCallback? onBack; // For mobile

  const CompanyDetailView({super.key, required this.company, this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, isDark, textColor, subTextColor),
          const SizedBox(height: 24),
          _buildHealthWidgets(isDark, textColor),
          const SizedBox(height: 24),
          _buildRevenueChart(isDark, textColor, subTextColor),
          const SizedBox(height: 24),
          _buildProjectsList(isDark, textColor),
        ],
      ),
    ).animate(key: ValueKey(company.id)).fadeIn().slideX(begin: 0.05); // Smooth transition when company changes
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color textColor, Color subTextColor) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null) ...[
            IconButton(
              icon: const Icon(IconsaxPlusLinear.arrow_left),
              onPressed: onBack,
              color: textColor,
            ),
            const SizedBox(width: 8),
          ],
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ]
            ),
            child: const Icon(IconsaxPlusLinear.building, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(company.name, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor), overflow: TextOverflow.ellipsis),
                    ),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(company.categories.isNotEmpty ? company.categories.first.toUpperCase() : "UNCATEGORIZED", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(IconsaxPlusLinear.location, size: 14, color: subTextColor),
                    const SizedBox(width: 4),
                    Text(company.location, style: TextStyle(color: subTextColor, fontSize: 13)),
                    const SizedBox(width: 16),
                    Icon(IconsaxPlusLinear.global, size: 14, color: subTextColor),
                    const SizedBox(width: 4),
                    Text(company.website, style: TextStyle(color: subTextColor, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bColor;
    String txt;
    if (company.status == CompanyStatus.active) {
      bColor = AppColors.success;
      txt = 'Active';
    } else if (company.status == CompanyStatus.onHold) {
       bColor = AppColors.warning;
       txt = 'On Hold';
    } else {
       bColor = Colors.grey;
       txt = 'Archived';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bColor.withValues(alpha: 0.5)),
      ),
      child: Text(txt, style: TextStyle(color: bColor, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildHealthWidgets(bool isDark, Color textColor) {
    final bool isCritical = company.healthScore < 0.7;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: GlassContainer(
            padding: const EdgeInsets.all(24),
            border: isCritical ? Border.all(color: AppColors.error, width: 2) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Health Score', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
                    Icon(isCritical ? IconsaxPlusLinear.warning_2 : IconsaxPlusLinear.shield_tick, color: isCritical ? AppColors.error : AppColors.success),
                  ],
                ),
                const SizedBox(height: 16),
                Text('${(company.healthScore * 100).toInt()}%', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: isCritical ? AppColors.error : AppColors.success)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: company.healthScore,
                  backgroundColor: (isCritical ? AppColors.error : AppColors.success).withValues(alpha: 0.2),
                  color: isCritical ? AppColors.error : AppColors.success,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Budget Utilization', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(r'$' + '${(company.budgetUtilized / 1000).toStringAsFixed(0)}k', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('of \$${(company.annualRevenue / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: company.budgetUtilized / company.annualRevenue,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  color: AppColors.primary,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildRevenueChart(bool isDark, Color textColor, Color subTextColor) {
    return GlassContainer(
      height: 300,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Financial Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true, 
                  drawVerticalLine: false, 
                  getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05), strokeWidth: 1, dashArray: [5, 5]),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: TextStyle(color: subTextColor, fontSize: 11)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Padding(padding: const EdgeInsets.only(top: 10), child: Text(['Q1', 'Q2', 'Q3', 'Q4'][value.toInt() % 4], style: TextStyle(color: subTextColor, fontSize: 11))))),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: AppColors.secondary,
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppColors.secondary.withValues(alpha: 0.3), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                    spots: const [FlSpot(0, 2), FlSpot(1, 3.5), FlSpot(2, 3), FlSpot(3, 5)],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList(bool isDark, Color textColor) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Linked Projects (${company.projectIds.length})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              TextButton(
                onPressed: () {}, 
                child: const Text('Manage', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (company.projectIds.isEmpty)
             const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No active projects linked'))),
          ...company.projectIds.map((pid) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))
            ),
            child: Row(
              children: [
                const Icon(IconsaxPlusLinear.folder, color: AppColors.primary),
                const SizedBox(width: 16),
                Expanded(child: Text('Project Identifier: $pid', style: TextStyle(fontWeight: FontWeight.w600, color: textColor))),
                const Icon(IconsaxPlusLinear.arrow_right_3, size: 16, color: Colors.grey),
              ],
            )
          ))
        ],
      )
    );
  }
}
