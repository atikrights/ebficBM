import 'dart:ui';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:ebficBM/core/theme/colors.dart';
import 'package:ebficBM/widgets/glass_container.dart';
import 'package:ebficBM/features/companies/models/company.dart';
import 'package:ebficBM/features/companies/providers/company_provider.dart';
import 'package:ebficBM/features/companies/screens/company_manage_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CompanyListScreen extends StatelessWidget {
  const CompanyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAdaptiveHeader(context, isDark, textColor, isMobile),
          const SizedBox(height: 8),
          Expanded(
            child: _buildCompanyGrid(context, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveHeader(BuildContext context, bool isDark, Color textColor, bool isMobile) {
    final provider = context.watch<CompanyProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // One-line Header: Search (Expanded) + Draft Icon + Create Button
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                borderRadius: 14,
                child: TextField(
                  onChanged: provider.setSearchQuery,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                  decoration: InputDecoration(
                     hintText: 'Search organizations...',
                     hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
                     prefixIcon: Icon(IconsaxPlusLinear.search_normal_1, size: 18, color: isDark ? Colors.white54 : Colors.black54),
                     border: InputBorder.none,
                     contentPadding: const EdgeInsets.symmetric(vertical: 14), // Smaller and compact
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Draft / Recovery Box Icon
            Tooltip(
              message: 'Drafts & Recovery',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showRecoveryPopup(context, isDark, textColor),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Icon(IconsaxPlusLinear.box, color: textColor, size: 24),
                        if (provider.archivedCompanies.isNotEmpty)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                              child: Text(
                                '${provider.archivedCompanies.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Create Button (Icon only on mobile)
            _buildCreateButton(context, isMobile, isDark, textColor),
          ],
        ),
        const SizedBox(height: 16),
        // Filter Chips row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChip('All', provider.filterCategory == null, () => provider.setCategoryFilter(null), null, isDark),
              ...provider.categories.map(
                (cat) => _buildFilterChip(
                  cat.toUpperCase(), 
                  provider.filterCategory == cat, 
                  () => provider.setCategoryFilter(cat), 
                  () => _showCategoryManagePopup(context, isDark, textColor, existingCategory: cat),
                  isDark
                ),
              ),
              // ADD CATEGORY BUTTON
              GestureDetector(
                onTap: () => _showCategoryManagePopup(context, isDark, textColor),
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Row(
                     children: [
                        const Icon(IconsaxPlusLinear.add, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        const Text('New Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                     ]
                  )
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton(BuildContext context, bool isMobile, bool isDark, Color textColor) {
    if (isMobile) {
      return ElevatedButton(
        onPressed: () => _showCreateCompanyPopup(context, isDark, textColor),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 8,
          shadowColor: AppColors.primary.withValues(alpha: 0.5),
        ),
        child: const Icon(IconsaxPlusLinear.add, size: 24),
      );
    }
    return ElevatedButton.icon(
      onPressed: () => _showCreateCompanyPopup(context, isDark, textColor),
      icon: const Icon(IconsaxPlusLinear.add, size: 18),
      label: const Text('Create Company', style: TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
        shadowColor: AppColors.primary.withValues(alpha: 0.5),
      ),
    );
  }

  // RECOVERY POPUP UI
  void _showRecoveryPopup(BuildContext context, bool isDark, Color textColor) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Recovery',
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: GlassContainer(
              width: 450,
              padding: const EdgeInsets.all(24),
              borderRadius: 24,
              child: Consumer<CompanyProvider>(
                builder: (context, provider, child) {
                  final archived = provider.archivedCompanies;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(IconsaxPlusLinear.box, color: AppColors.warning),
                              const SizedBox(width: 8),
                              Text('Drafts & Logs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                            ],
                          ),
                          IconButton(icon: Icon(IconsaxPlusLinear.close_circle, color: textColor), onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (archived.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(child: Text('No archived organizations found.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54))),
                        )
                      else
                        SizedBox(
                          height: 300,
                          child: ListView.builder(
                            itemCount: archived.length,
                            itemBuilder: (context, index) {
                              final comp = archived[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(comp.name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
                                          Text('Archived', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => provider.restoreCompany(comp.id),
                                      icon: const Icon(IconsaxPlusLinear.refresh, size: 14),
                                      label: const Text('Restore', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success.withValues(alpha: 0.2),
                                        foregroundColor: AppColors.success,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(IconsaxPlusLinear.trash, size: 16, color: AppColors.error),
                                      onPressed: () => provider.deleteCompany(comp.id),
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppColors.error.withValues(alpha: 0.1),
                                        padding: const EdgeInsets.all(8),
                                      ),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                    ],
                  );
                }
              ),
            ),
          ),
        ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms).fadeIn();
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, VoidCallback? onDoubleTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Tooltip(
        message: onDoubleTap != null ? 'Double Click to Modify' : '',
        waitDuration: const Duration(milliseconds: 500),
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
      ),
    );
  }

  Widget _buildCompanyGrid(BuildContext context, bool isDark) {
    final provider = context.watch<CompanyProvider>();
    final companies = provider.companies;

    if (companies.isEmpty) {
      return Center(child: Text('No companies found in the database.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)));
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 280, // Fixed card height
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: companies.length,
      itemBuilder: (context, index) {
        return _PremiumCompanyCard(company: companies[index], isDark: isDark)
            .animate()
            .fade(delay: Duration(milliseconds: 50 * index))
            .slideY(begin: 0.1, end: 0, delay: Duration(milliseconds: 50 * index));
      },
    );
  }

  // CATEGORY MANAGE & MULTI-ASSIGN POPUP
  void _showCategoryManagePopup(BuildContext context, bool isDark, Color textColor, {String? existingCategory}) {
    final provider = context.read<CompanyProvider>();
    String categoryName = existingCategory ?? '';
    
    // Find companies that ALREADY have this category
    List<String> assignedCompanyIds = provider.allCompanies
        .where((c) => existingCategory != null && c.categories.contains(existingCategory))
        .map((c) => c.id).toList();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Manage Category',
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: StatefulBuilder(
              builder: (context, setState) {
                return GlassContainer(
                  width: 450,
                  padding: const EdgeInsets.all(24),
                  borderRadius: 24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(existingCategory == null ? 'Create Category' : 'Modify Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                          IconButton(icon: Icon(IconsaxPlusLinear.close_circle, color: textColor), onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextFormField(
                          initialValue: categoryName,
                          onChanged: (val) => categoryName = val,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: 'e.g., Artificial Intelligence',
                            hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                            prefixIcon: Icon(IconsaxPlusLinear.folder_add, color: isDark ? Colors.white54 : Colors.black54, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Assign Active Organizations:', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
                      const SizedBox(height: 8),
                      // Companies List Checkboxes
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black12)
                        ),
                        child: ListView.builder(
                          itemCount: provider.allCompanies.length,
                          itemBuilder: (context, i) {
                            final c = provider.allCompanies[i];
                            final isAssigned = assignedCompanyIds.contains(c.id);
                            return CheckboxListTile(
                              value: isAssigned,
                              activeColor: AppColors.primary,
                              title: Text(c.name, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: Text(c.categories.join(', '), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    assignedCompanyIds.add(c.id);
                                  } else {
                                    assignedCompanyIds.remove(c.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          if (existingCategory != null) ...[
                            IconButton(
                              onPressed: () {
                                provider.deleteCategory(existingCategory);
                                Navigator.pop(context);
                              },
                              icon: const Icon(IconsaxPlusLinear.trash, color: AppColors.error),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.error.withValues(alpha: 0.1),
                                padding: const EdgeInsets.all(12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                   if (categoryName.isNotEmpty) {
                                     provider.manageCategory(existingCategory, categoryName, assignedCompanyIds);
                                   }
                                   Navigator.pop(context);
                                },
                                child: Text(existingCategory == null ? 'Create & Assign' : 'Update & Assign', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              }
            ),
          ),
        ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms).fadeIn();
      },
    );
  }

  // CREATE POPUP UI
  void _showCreateCompanyPopup(BuildContext context, bool isDark, Color textColor) {
    final nameController = TextEditingController();
    final websiteController = TextEditingController();
    String? selectedCategory;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Create Company',
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: GlassContainer(
              width: 500,
              padding: const EdgeInsets.all(32),
              borderRadius: 24,
              child: Consumer<CompanyProvider>(
                builder: (context, provider, child) {
                  selectedCategory ??= provider.categories.first;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Deploy Sandbox Team', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                          IconButton(icon: Icon(IconsaxPlusLinear.close_circle, color: textColor), onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(isDark, 'Organization Name', IconsaxPlusLinear.building, controller: nameController),
                      const SizedBox(height: 16),
                      _buildTextField(isDark, 'Business Website', IconsaxPlusLinear.global, controller: websiteController),
                      const SizedBox(height: 16),
                      Text('Select Category', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      // Dropdown for Category
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                        ),
                        child: StatefulBuilder(
                          builder: (context, setPopupState) {
                            return DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCategory,
                                isExpanded: true,
                                dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                style: TextStyle(color: textColor, fontSize: 14),
                                items: provider.categories.map((String cat) {
                                  return DropdownMenuItem<String>(
                                    value: cat,
                                    child: Text(cat),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                   if (value != null) {
                                     setPopupState(() => selectedCategory = value);
                                   }
                                },
                              ),
                            );
                          }
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                             if (nameController.text.trim().isEmpty) return;
                             
                             final newCompany = Company(
                               id: 'CID-${100000 + Random().nextInt(900000)}',
                               name: nameController.text.trim(),
                               website: websiteController.text.trim(),
                               categories: [selectedCategory!],
                               status: CompanyStatus.active,
                               activeEmployees: 0,
                               annualRevenue: 0,
                               healthScore: 1.0,
                               primaryEmail: 'contact@${websiteController.text.trim().isEmpty ? "ebfic.com" : websiteController.text.trim()}',
                               phone: 'System Authorized',
                               location: 'Global Registry',
                             );
                             
                             provider.addCompany(newCompany);
                             Navigator.pop(context);
                             
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                 content: Text('Strategic Network "${newCompany.name}" Deployed Successfully!'),
                                 behavior: SnackBarBehavior.floating,
                                 backgroundColor: AppColors.success,
                               )
                             );
                          },
                          child: const Text('Deploy Network', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  );
                }
              ),
            ),
          ),
        ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms).fadeIn();
      },
    );
  }

  Widget _buildTextField(bool isDark, String hint, IconData icon, {TextEditingController? controller}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
          prefixIcon: Icon(icon, color: isDark ? Colors.white54 : Colors.black54, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _PremiumCompanyCard extends StatelessWidget {
  final Company company;
  final bool isDark;

  const _PremiumCompanyCard({required this.company, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final subTextColor = isDark ? Colors.white54 : Colors.black54;
    final isCritical = company.healthScore < 0.7;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      gradient: isCritical ? LinearGradient(colors: [AppColors.error.withValues(alpha: 0.1), Colors.transparent]) : null,
      border: isCritical ? Border.all(color: AppColors.error.withValues(alpha: 0.5), width: 1.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP BAR: Logo & Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: const Icon(IconsaxPlusLinear.building_3, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: 'Copy CID',
                child: InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: company.id));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CID Copied to Clipboard!'), behavior: SnackBarBehavior.floating));
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(IconsaxPlusLinear.copy, size: 10, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(company.id, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 16),
          
          // CORE INFO
          Text(company.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(IconsaxPlusLinear.briefcase, size: 14, color: subTextColor),
              const SizedBox(width: 4),
              Expanded(child: Text('${company.categories.join(', ').toUpperCase()} • ${company.activeEmployees} Staff', style: TextStyle(color: subTextColor, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          
          const Spacer(),
          
          // VISUAL STATS (Health & Projects count)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Health index', style: TextStyle(color: subTextColor, fontSize: 12)),
              Text('${(company.healthScore * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: isCritical ? AppColors.error : AppColors.success, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: company.healthScore,
            backgroundColor: (isCritical ? AppColors.error : AppColors.success).withValues(alpha: 0.1),
            color: isCritical ? AppColors.error : AppColors.success,
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
          
          const SizedBox(height: 20),
          
          // ACTION BUTTONS (Manage, Assign, Remove)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => CompanyManageScreen(companyId: company.id)));
                  },
                  icon: const Icon(IconsaxPlusLinear.setting_2, size: 16),
                  label: const Text('Manage'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildIconButton(context, IconsaxPlusLinear.user_add, 'Assign User', () {
                  // Show assign popup
              }),
              const SizedBox(width: 8),
              _buildIconButton(context, IconsaxPlusLinear.trash, 'Remove', () {
                 _showRemovePopup(context, textColor);
              }, isDanger: true),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bColor = company.status == CompanyStatus.active ? AppColors.success : (company.status == CompanyStatus.onHold ? AppColors.warning : Colors.grey);
    String txt = company.status == CompanyStatus.active ? 'Active' : (company.status == CompanyStatus.onHold ? 'On Hold' : 'Archived');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bColor.withValues(alpha: 0.4)),
      ),
      child: Text(txt, style: TextStyle(color: bColor, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Widget _buildIconButton(BuildContext context, IconData icon, String tooltip, VoidCallback onTap, {bool isDanger = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDanger ? AppColors.error.withValues(alpha: 0.1) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: isDanger ? AppColors.error : (isDark ? Colors.white : Colors.black87)),
        ),
      ),
    );
  }

  // 3D REMOVE POPUP WARNING
  void _showRemovePopup(BuildContext context, Color textColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Remove',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      pageBuilder: (context, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: GlassContainer(
              width: 350,
              padding: const EdgeInsets.all(24),
              borderRadius: 20,
              border: Border.all(color: AppColors.error.withValues(alpha: 0.5), width: 2),
              gradient: LinearGradient(
                colors: [isDark ? Colors.black87 : Colors.white, AppColors.error.withValues(alpha: 0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(IconsaxPlusLinear.danger, color: AppColors.error, size: 40),
                  ),
                  const SizedBox(height: 20),
                  Text('Eradicate Organization?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text('Are you completely sure you want to permanently delete "${company.name}"? This action irreversibly severs all linked projects and ledgers.', 
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                             final provider = context.read<CompanyProvider>();
                             provider.archiveCompany(company.id);
                             Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Eradicate'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms).fadeIn();
      }
    );
  }
}
