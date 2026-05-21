import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';
import 'package:ebficbm/core/theme/colors.dart';
import 'package:ebficbm/widgets/glass_container.dart';
import 'package:ebficbm/features/companies/models/company.dart';
import 'package:ebficbm/features/companies/providers/company_provider.dart';
import 'package:ebficbm/features/companies/screens/company_manage_screen.dart';
import 'package:ebficbm/widgets/ebm_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CompanyMasterView extends StatelessWidget {
  final bool isMobile;
  const CompanyMasterView({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Consumer<CompanyProvider>(
      builder: (context, provider, child) {
        final companies = provider.companies;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchBar(context, provider, isDark),
            const SizedBox(height: 10),
            _buildFilters(provider, isDark),
            const SizedBox(height: 10),
            Expanded(
              child: companies.isEmpty
                  ? _buildEmptyState(isDark, textColor)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: companies.length,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemBuilder: (context, index) {
                        final comp = companies[index];
                        final isSelected =
                            comp.id == provider.selectedCompany?.id;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ErBlueprintCard(
                            company: comp,
                            isSelected: !isMobile && isSelected,
                            isDark: isDark,
                            onTap: () {
                              provider.selectCompany(comp.id);
                              if (isMobile) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CompanyManageScreen(companyId: comp.id),
                                  ),
                                );
                              }
                            },
                          ).animate(delay: Duration(milliseconds: 40 * index))
                            .fadeIn(duration: 300.ms)
                            .slideX(begin: -0.06, end: 0, duration: 300.ms, curve: Curves.easeOut),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(IconsaxPlusLinear.building_3,
                size: 40, color: AppColors.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 12),
          Text('No organizations found',
              style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
      BuildContext context, CompanyProvider provider, bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      borderRadius: 14,
      child: TextField(
        onChanged: provider.setSearchQuery,
        style: TextStyle(
            color: isDark ? Colors.white : Colors.black87, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search organizations...',
          hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
          prefixIcon: Icon(IconsaxPlusLinear.search_normal_1,
              size: 17, color: isDark ? Colors.white38 : Colors.black38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  Widget _buildFilters(CompanyProvider provider, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip(
              'All', provider.filterCategory == null,
              () => provider.setCategoryFilter(null), isDark),
          ...provider.categories.map(
            (cat) => _buildFilterChip(
              cat.toUpperCase(),
              provider.filterCategory == cat,
              () => provider.setCategoryFilter(cat),
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? Colors.white12 : Colors.black12, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white60 : Colors.black54),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ER Blueprint Compact Card
// ─────────────────────────────────────────────
class _ErBlueprintCard extends StatefulWidget {
  final Company company;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ErBlueprintCard({
    required this.company,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ErBlueprintCard> createState() => _ErBlueprintCardState();
}

class _ErBlueprintCardState extends State<_ErBlueprintCard> {
  bool _hovered = false;

  String get _facebookUrl {
    final fb = widget.company.socialLinks?['facebook'] ??
        widget.company.socialLinks?['Facebook'] ?? '';
    return fb;
  }

  String get _motto {
    return widget.company.shortDescription ?? '';
  }

  String get _primaryCategory {
    return widget.company.categories.isNotEmpty
        ? widget.company.categories.first
        : 'UNCATEGORIZED';
  }

  Color get _categoryColor {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      const Color(0xFF0EA5E9),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
    ];
    final hash = _primaryCategory.hashCode.abs() % colors.length;
    return colors[hash];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isSelected = widget.isSelected;
    final company = widget.company;
    final catColor = _categoryColor;

    final textColor = isDark ? Colors.white : AppColors.textDark;
    final subColor = isDark ? Colors.white54 : Colors.black45;
    final isWarning = company.healthScore < 0.7;

    final cardBg = isSelected
        ? AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.07)
        : (_hovered
            ? (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.025))
            : Colors.transparent);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.6)
                  : (isWarning
                      ? AppColors.error.withValues(alpha: 0.3)
                      : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06))),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── LOGO ──────────────────────────────
              _buildLogo(company, isDark),
              const SizedBox(width: 10),

              // ── MAIN CONTENT ──────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row 1: Name + Status dot
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            company.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: textColor,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildStatusDot(company.status),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Row 2: CID + Category chip
                    Row(
                      children: [
                        // CID Badge
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: company.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('CID ${company.id} copied!'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.25),
                                  width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(IconsaxPlusLinear.copy,
                                    size: 9, color: AppColors.primary),
                                const SizedBox(width: 3),
                                Text(
                                  company.id,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Category chip
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _primaryCategory.toUpperCase(),
                              style: TextStyle(
                                color: catColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Row 3: Motto (optional)
                    if (_motto.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _motto,
                        style: TextStyle(
                          color: subColor,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 5),

                    // Row 4: Facebook + Health bar
                    Row(
                      children: [
                        // Facebook icon link
                        if (_facebookUrl.isNotEmpty) ...[
                          _buildSocialIcon(
                            Icons.facebook_rounded,
                            const Color(0xFF1877F2),
                            isDark,
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Health mini bar
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: company.healthScore,
                                    minHeight: 4,
                                    backgroundColor:
                                        (isWarning ? AppColors.error : AppColors.success)
                                            .withValues(alpha: 0.15),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isWarning ? AppColors.error : AppColors.success,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${(company.healthScore * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: isWarning
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── ARROW ─────────────────────────────
              if (isSelected || _hovered)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      IconsaxPlusLinear.arrow_right_3,
                      size: 16,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white30 : Colors.black26),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(Company company, bool isDark) {
    const double size = 44;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: (company.logoUrl == null || company.logoUrl!.isEmpty)
            ? AppColors.primaryGradient
            : null,
        color: (company.logoUrl != null && company.logoUrl!.isNotEmpty)
            ? (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04))
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: company.logoUrl != null && company.logoUrl!.isNotEmpty
            ? EbmImage(
                source: company.logoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: Icon(IconsaxPlusLinear.building_3,
                    color: Colors.white, size: size * 0.45),
              )
            : Icon(IconsaxPlusLinear.building_3,
                color: Colors.white, size: size * 0.45),
      ),
    );
  }

  Widget _buildStatusDot(CompanyStatus status) {
    Color color;
    switch (status) {
      case CompanyStatus.active:
        color = AppColors.success;
        break;
      case CompanyStatus.onHold:
        color = AppColors.warning;
        break;
      case CompanyStatus.archived:
        color = Colors.grey;
        break;
      case CompanyStatus.pending:
        color = AppColors.primary;
        break;
      case CompanyStatus.declined:
        color = AppColors.error;
        break;
    }
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 4,
              spreadRadius: 1),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color, bool isDark) {
    return Tooltip(
      message: 'Facebook',
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}
