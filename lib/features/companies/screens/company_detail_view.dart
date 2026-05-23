import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:ebficbm/core/theme/colors.dart';
import 'package:ebficbm/widgets/glass_container.dart';
import 'package:ebficbm/features/companies/models/company.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:ebficbm/features/projects/providers/project_provider.dart';
import 'package:ebficbm/features/projects/models/project.dart';

class CompanyDetailView extends StatefulWidget {
  final Company company;
  final VoidCallback? onBack; // For mobile

  const CompanyDetailView({super.key, required this.company, this.onBack});

  @override
  State<CompanyDetailView> createState() => _CompanyDetailViewState();
}

class _CompanyDetailViewState extends State<CompanyDetailView> {
  int _selectedTabIndex = 0;
  final TextEditingController _pidController = TextEditingController();
  Project? _searchedProject;
  bool _isSearching = false;
  bool _isActioning = false;

  @override
  void dispose() {
    _pidController.dispose();
    super.dispose();
  }

  void _searchProject() async {
    final pid = _pidController.text.trim();
    if (pid.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchedProject = null;
    });

    try {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      final project = await projectProvider.searchByPid(pid);
      if (mounted) {
        setState(() {
          _searchedProject = project;
          _isSearching = false;
        });
        if (project == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project not found or outside your team scope.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _attachProject() async {
    if (_searchedProject == null) return;

    setState(() {
      _isActioning = true;
    });

    try {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      final success = await projectProvider.attachToCompany(_searchedProject!.id, widget.company.id);
      if (mounted) {
        setState(() {
          _isActioning = false;
        });
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project attached successfully.'), backgroundColor: Colors.green),
          );
          _searchProject(); // Refresh the searched project
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to attach project.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isActioning = false;
        });
      }
    }
  }

  void _detachProject() async {
    if (_searchedProject == null) return;

    setState(() {
      _isActioning = true;
    });

    try {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      final success = await projectProvider.detachFromCompany(_searchedProject!.id);
      if (mounted) {
        setState(() {
          _isActioning = false;
        });
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project detached successfully.'), backgroundColor: Colors.green),
          );
          _searchProject(); // Refresh the searched project
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to detach project.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isActioning = false;
        });
      }
    }
  }

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
          _buildTabBar(isDark),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _selectedTabIndex == 0
                ? _buildOverviewTab(isDark, textColor, subTextColor)
                : _buildConfigureTab(isDark, textColor, subTextColor),
          ),
        ],
      ),
    ).animate(key: ValueKey(widget.company.id)).fadeIn().slideX(begin: 0.05); // Smooth transition when company changes
  }

  Widget _buildTabBar(bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.all(4),
      borderRadius: 12.0,
      child: Row(
        children: [
          Expanded(child: _buildTabItem('Overview', 0, isDark, IconsaxPlusLinear.element_3)),
          Expanded(child: _buildTabItem('Configure', 1, isDark, IconsaxPlusLinear.setting_2)),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index, bool isDark, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(bool isDark, Color textColor, Color subTextColor) {
    return Column(
      key: const ValueKey('Overview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHealthWidgets(isDark, textColor),
        const SizedBox(height: 24),
        _buildRevenueChart(isDark, textColor, subTextColor),
        const SizedBox(height: 24),
        _buildProjectsList(isDark, textColor),
      ],
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  Widget _buildConfigureTab(bool isDark, Color textColor, Color subTextColor) {
    return Column(
      key: const ValueKey('Configure'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Project Attachment Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Text('Search for a project by its PID to attach or detach it from this organization.', style: TextStyle(fontSize: 12, color: subTextColor)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                      ),
                      child: TextField(
                        controller: _pidController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: 'Enter Project PID (e.g. PRJ-XXX-XXXX)',
                          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                          prefixIcon: Icon(IconsaxPlusLinear.search_normal, size: 18, color: isDark ? Colors.white38 : Colors.black38),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _searchProject(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSearching ? null : _searchProject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSearching 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
        if (_searchedProject != null) ...[
          const SizedBox(height: 24),
          _buildProjectResultCard(isDark, textColor, subTextColor),
        ]
      ],
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  Widget _buildProjectResultCard(bool isDark, Color textColor, Color subTextColor) {
    final project = _searchedProject!;
    final bool isAttachedToCurrent = project.companyId == widget.company.id;
    final bool isAttachedToOther = project.companyId != null && project.companyId != widget.company.id;

    Color approvalColor = project.isApproved ? AppColors.success : AppColors.warning;
    String approvalText = project.isApproved ? 'LIVE' : 'PENDING';

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(project.pid, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: approvalColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: approvalColor.withOpacity(0.5)),
                ),
                child: Text(approvalText, style: TextStyle(color: approvalColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(project.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(IconsaxPlusLinear.status, size: 14, color: subTextColor),
              const SizedBox(width: 6),
              Text(
                isAttachedToCurrent 
                  ? 'Currently linked to ${widget.company.name}'
                  : isAttachedToOther 
                    ? 'Linked to another organization'
                    : 'Unlinked (Private)',
                style: TextStyle(color: subTextColor, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isAttachedToCurrent)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isActioning ? null : _detachProject,
                icon: _isActioning 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(IconsaxPlusLinear.link_square, color: Colors.white, size: 18),
                label: const Text('DETACH PROJECT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isActioning ? null : _attachProject,
                icon: _isActioning 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(IconsaxPlusLinear.link_1, color: Colors.white, size: 18),
                label: Text('ATTACH TO ${widget.company.name.toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scaleXY(begin: 0.95);
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color textColor, Color subTextColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 450;
        
        return GlassContainer(
          padding: EdgeInsets.all(isNarrow ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.onBack != null) ...[
                    IconButton(
                      icon: const Icon(IconsaxPlusLinear.arrow_left),
                      onPressed: widget.onBack,
                      color: textColor,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      'Organization Profile',
                      style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isNarrow ? 64 : 80,
                    height: isNarrow ? 64 : 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(isNarrow ? 16 : 20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ]
                    ),
                    child: Icon(IconsaxPlusLinear.building, size: isNarrow ? 32 : 40, color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.company.name, 
                          style: TextStyle(
                            fontSize: isNarrow ? 22 : 28, 
                            fontWeight: FontWeight.bold, 
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.company.categories.isNotEmpty ? widget.company.categories.first.toLowerCase() : "uncategorized", 
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Tooltip(
                              message: 'Copy CID',
                              child: InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: widget.company.id));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CID Copied!'), behavior: SnackBarBehavior.floating));
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)),
                                  child: Text(widget.company.id, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 10,
                children: [
                  _buildInfoItem(IconsaxPlusLinear.location, widget.company.location, subTextColor),
                  _buildInfoItem(IconsaxPlusLinear.global, widget.company.website, subTextColor),
                  _buildInfoItem(IconsaxPlusLinear.call, widget.company.phone, subTextColor),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.7)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color bColor;
    String txt;
    if (widget.company.status == CompanyStatus.active) {
      bColor = AppColors.success;
      txt = 'Active';
    } else if (widget.company.status == CompanyStatus.onHold) {
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
    final bool isCritical = widget.company.healthScore < 0.7;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    final healthScoreCard = GlassContainer(
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
          Text('${(widget.company.healthScore * 100).toInt()}%', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: isCritical ? AppColors.error : AppColors.success)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: widget.company.healthScore,
            backgroundColor: (isCritical ? AppColors.error : AppColors.success).withValues(alpha: 0.2),
            color: isCritical ? AppColors.error : AppColors.success,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          )
        ],
      ),
    );

    final budgetUtilCard = GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget Utilization', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(r'$' + '${(widget.company.budgetUtilized / 1000).toStringAsFixed(0)}k', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('of \$${(widget.company.annualRevenue / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: widget.company.budgetUtilized / widget.company.annualRevenue,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            color: AppColors.primary,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          )
        ],
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          healthScoreCard,
          const SizedBox(height: 16),
          budgetUtilCard,
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: healthScoreCard,
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: budgetUtilCard,
        ),
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
              Text('Linked Projects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text('${widget.company.projectIds.length}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.company.projectIds.isEmpty)
             const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No active projects linked'))),
          ...widget.company.projectIds.map((pid) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(IconsaxPlusLinear.folder, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('System Identifier', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(pid, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
                    ],
                  ),
                ),
                const Icon(IconsaxPlusLinear.arrow_right_3, size: 18, color: Colors.grey),
              ],
            )
          ))
        ],
      )
    );
  }
}
