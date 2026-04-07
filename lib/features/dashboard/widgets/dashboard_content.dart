import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:ebficBM/core/theme/colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ebficBM/widgets/glass_container.dart';
import 'package:responsive_framework/responsive_framework.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop || ResponsiveBreakpoints.of(context).largerThan(TABLET);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildResponsiveStats(context, isDark, textColor, subTextColor),
            const SizedBox(height: 24),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildMainAnalytics(context, isDark, textColor, subTextColor).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 24),
                        _buildActiveProjects(context, isDark, textColor, subTextColor),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildRecentActivity(isDark, textColor, subTextColor).animate().fade().slideX(begin: 0.1, end: 0),
                        const SizedBox(height: 24),
                        _buildUpcomingTasks(isDark, textColor, subTextColor).animate().fade(delay: 100.ms).slideX(begin: 0.1, end: 0),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMainAnalytics(context, isDark, textColor, subTextColor).animate().fade().slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 24),
                  _buildActiveProjects(context, isDark, textColor, subTextColor),
                  const SizedBox(height: 24),
                  if (isTablet)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: RepaintBoundary(child: _buildRecentActivity(isDark, textColor, subTextColor))),
                        const SizedBox(width: 24),
                        Expanded(child: RepaintBoundary(child: _buildUpcomingTasks(isDark, textColor, subTextColor))),
                      ],
                    )
                  else ...[
                    RepaintBoundary(child: _buildRecentActivity(isDark, textColor, subTextColor)),
                    const SizedBox(height: 24),
                    RepaintBoundary(child: _buildUpcomingTasks(isDark, textColor, subTextColor)),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveStats(BuildContext context, bool isDark, Color textColor, Color subTextColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stats = [
          _StatCard(
            title: 'Net Balance',
            value: r'$1,248k',
            trend: '+12.5%',
            icon: IconsaxPlusLinear.wallet,
            color: AppColors.primary,
            isDark: isDark,
            textColor: textColor,
          ),
          _StatCard(
            title: 'Active Projects',
            value: '24',
            trend: '+3',
            icon: IconsaxPlusLinear.activity,
            color: AppColors.secondary,
            isDark: isDark,
            textColor: textColor,
          ),
          _StatCard(
            title: 'Tasks Done',
            value: '182',
            trend: '+18',
            icon: IconsaxPlusLinear.task,
            color: AppColors.success,
            isDark: isDark,
            textColor: textColor,
          ),
        ];

        // If width is too small, stack them vertically (Increased threshold to 600)
        if (constraints.maxWidth < 600) {
          return Column(
            children: stats.map((stat) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: stat,
            )).toList(),
          ).animate().fade().slideY(begin: 0.1, end: 0);
        }

        return Row(
          children: stats.asMap().entries.map((entry) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: entry.key == stats.length - 1 ? 0 : 16),
                child: entry.value,
              ),
            );
          }).toList(),
        ).animate().fade().slideX(begin: -0.05, end: 0);
      }
    );
  }

  Widget _buildMainAnalytics(BuildContext context, bool isDark, Color textColor, Color subTextColor) {
    return GlassContainer(
      height: 380,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final bool narrow = constraints.maxWidth < 350;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Revenue Insights', style: TextStyle(fontSize: narrow ? 16 : 18, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 4),
                        Text('Monthly performance overview', style: TextStyle(fontSize: 11, color: subTextColor), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (constraints.maxWidth > 300) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text('This Year', style: TextStyle(fontSize: narrow ? 10 : 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Icon(IconsaxPlusLinear.arrow_down_1, size: narrow ? 12 : 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 32),
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
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text(r'$' + '${value.toInt()}k', style: TextStyle(color: subTextColor, fontSize: 11)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Padding(padding: const EdgeInsets.only(top: 10), child: Text(['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'][value.toInt() % 6], style: TextStyle(color: subTextColor, fontSize: 11))))),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: AppColors.primary)),
                    belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.3), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                    spots: const [FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 3.5), FlSpot(3, 5), FlSpot(4, 4), FlSpot(5, 6)],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveProjects(BuildContext context, bool isDark, Color textColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Projects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            TextButton(
              onPressed: () {}, 
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('See All', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) => _ProjectTile(index: index, isDark: isDark, textColor: textColor, subTextColor: subTextColor),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(bool isDark, Color textColor, Color subTextColor) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(IconsaxPlusLinear.activity, color: AppColors.secondary, size: 16)),
              const SizedBox(width: 12),
              Text('Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 10, height: 10, 
                  decoration: BoxDecoration(color: index == 0 ? AppColors.primary : Colors.grey.withValues(alpha: 0.5), shape: BoxShape.circle, border: Border.all(color: isDark ? Colors.black : Colors.white, width: 2)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Task completed by Alex', style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('${index + 1} hours ago', style: TextStyle(fontSize: 11, color: subTextColor)),
                    ],
                  )
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildUpcomingTasks(bool isDark, Color textColor, Color subTextColor) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(IconsaxPlusLinear.clock, color: AppColors.warning, size: 16)),
              const SizedBox(width: 12),
              Text('Upcoming', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(2, (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Text('1${index + 2}:00', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(index == 0 ? 'Client Meeting' : 'Team Sync', style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;
  final bool isDark;
  final Color textColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return GlassContainer(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(isMobile ? 8 : 12)),
                child: Icon(icon, color: color, size: isMobile ? 16 : 22),
              ),
              if (!isMobile) const SizedBox(width: 8),
              if (!isMobile)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(IconsaxPlusLinear.arrow_up_1, color: AppColors.success, size: 12),
                          const SizedBox(width: 4),
                          Text(trend, style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 20),
          Text(title, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: isMobile ? 10 : 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(fontSize: isMobile ? 18 : 28, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -0.5))),
          if (isMobile) ...[
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(IconsaxPlusLinear.arrow_up_1, color: AppColors.success, size: 10),
                    const SizedBox(width: 4),
                    Text(trend, style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final int index;
  final bool isDark;
  final Color textColor;
  final Color subTextColor;

  const _ProjectTile({required this.index, required this.isDark, required this.textColor, required this.subTextColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(IconsaxPlusLinear.document_text, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Project ${index + 1} - Premium Design', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('Development', style: TextStyle(color: subTextColor, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(r'$' + '${(index + 1) * 15}k', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Icon(IconsaxPlusLinear.arrow_right_3, color: Colors.grey, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(delay: (index * 100).ms).slideX(begin: 0.05, end: 0);
  }
}
