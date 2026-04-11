import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';
import 'package:ebficbm/core/theme/colors.dart';
import 'package:ebficbm/widgets/glass_container.dart';
import 'package:ebficbm/features/companies/models/company.dart';
import 'package:ebficbm/features/companies/providers/company_provider.dart';
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
            const SizedBox(height: 16),
            _buildFilters(provider, isDark),
            const SizedBox(height: 20),
            Expanded(
              child: companies.isEmpty
                  ? Center(child: Text('No companies found', style: TextStyle(color: textColor)))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: companies.length,
                      itemBuilder: (context, index) {
                        final comp = companies[index];
                        final isSelected = comp.id == provider.selectedCompany?.id;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CompanyListTile(
                            company: comp,
                            isSelected: !isMobile && isSelected,
                            isDark: isDark,
                            onTap: () {
                              provider.selectCompany(comp.id);
                              if (isMobile) {
                                // For mobile, we would push to a detail route here
                                // Navigator.push(context, MaterialPageRoute(...))
                                // but for now, we'll implement the Adaptive layout below
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context, CompanyProvider provider, bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: 16,
      child: TextField(
        onChanged: provider.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search companies...',
          hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
          prefixIcon: const Icon(IconsaxPlusLinear.search_normal_1, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
          _buildFilterChip('All', provider.filterCategory == null, () => provider.setCategoryFilter(null), isDark),
          ...provider.categories.map(
            (cat) => _buildFilterChip(
              cat.toUpperCase(), 
              provider.filterCategory == cat, 
              () => provider.setCategoryFilter(cat), 
              isDark
            ),
          ),
        ],
      )
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }
}

class _CompanyListTile extends StatelessWidget {
  final Company company;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CompanyListTile({
    required this.company,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final isWarning = company.healthScore < 0.7; // Warning threshold
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: isSelected ? BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ]
        ) : null,
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          gradient: isSelected ? LinearGradient(
            colors: [AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1), AppColors.primary.withValues(alpha: 0.05)],
          ) : null,
          border: isSelected ? Border.all(color: AppColors.primary, width: 2) 
            : (isWarning ? Border.all(color: AppColors.error.withValues(alpha: 0.5), width: 1.5) : null), // Red glow for warnings
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(IconsaxPlusLinear.building, color: isSelected ? Colors.white : AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(company.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${company.categories.isNotEmpty ? company.categories.first.toUpperCase() : "UNCATEGORIZED"} • ${company.activeEmployees} Employees', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: isWarning ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Text(
                       '${(company.healthScore * 100).toInt()}% Health',
                       style: TextStyle(
                         color: isWarning ? AppColors.error : AppColors.success,
                         fontSize: 10,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                   ),
                   const SizedBox(height: 8),
                   Text(r'$' + '${(company.annualRevenue / 1000).toStringAsFixed(0)}k', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                ],
              )
            ],
          ),
        ),
      ),
    ).animate().fade().slideX();
  }
}
