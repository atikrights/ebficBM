import 'dart:ui';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:ebficbm/core/theme/colors.dart';
import 'package:ebficbm/widgets/glass_container.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ebficbm/features/companies/models/company.dart';
import 'package:ebficbm/features/companies/providers/company_provider.dart';
import 'package:ebficbm/features/companies/screens/company_manage_screen.dart';
import 'package:ebficbm/core/utils/clipboard_helper.dart';
import 'package:ebficbm/widgets/ebm_image.dart';
import 'package:ebficbm/features/companies/providers/company_provider.dart';
import 'package:ebficbm/features/companies/screens/company_detail_view.dart';
import 'package:ebficbm/core/providers/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CompanyListScreen extends StatelessWidget {
  const CompanyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 7), // Exact 7px top space
          _buildAdaptiveHeader(context, isDark, textColor, !isDesktop),
          const SizedBox(height: 12),
          Expanded(
            child: _buildCompanyGrid(context, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveHeader(BuildContext context, bool isDark, Color textColor, bool isMobile) {
    final provider = context.watch<CompanyProvider>();
    final auth = context.watch<AuthProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── LINE 1: Search + Draft Icon + Create Button ──────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                  ),
                  child: TextField(
                    onChanged: provider.setSearchQuery,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'Search organizations...',
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12),
                      prefixIcon: Icon(IconsaxPlusLinear.search_normal_1, size: 16, color: isDark ? Colors.white38 : Colors.black38),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Draft / Recovery Icon Button
              Tooltip(
                message: 'Drafts & Recovery',
                child: InkWell(
                  onTap: () => _showRecoveryPopup(context, isDark, textColor),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Icon(IconsaxPlusLinear.box, color: isDark ? Colors.white70 : Colors.black87, size: 16),
                        if (provider.archivedCompanies.isNotEmpty)
                          Positioned(
                            right: -3,
                            top: -3,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                              child: Center(
                                child: Text('${provider.archivedCompanies.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (auth.isAdmin || auth.isManager)
                _buildCreateButton(context, isMobile, isDark, textColor),
            ],
          ),
        ),
        // ── LINE 2: Category Filter Chips ─────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                ...provider.categories.map(
                  (cat) => _buildFilterChip(
                    cat.toLowerCase(), // Small lowercase text
                    provider.filterCategory == null ? (cat == 'All') : (provider.filterCategory == cat),
                    () => provider.setCategoryFilter(cat == 'All' ? null : cat),
                    cat == 'All' ? null : () => _showCategoryManagePopup(context, isDark, textColor, existingCategory: cat),
                    isDark,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showCategoryManagePopup(context, isDark, textColor),
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.03) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.35), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Icon(IconsaxPlusLinear.add, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('New Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ],
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

  Widget _buildCreateButton(BuildContext context, bool isMobile, bool isDark, Color textColor) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showCreateCompanyPopup(context, isDark, textColor),
        icon: const Icon(IconsaxPlusLinear.add, size: 15),
        label: Text(
          isMobile ? 'Create' : 'Create Company',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
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
        message: onDoubleTap != null ? 'Double tap to Modify' : '',
        waitDuration: const Duration(milliseconds: 500),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
    final width = MediaQuery.of(context).size.width;

    if (companies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(IconsaxPlusLinear.building_3, size: 56,
                  color: isDark ? Colors.white10 : Colors.black12),
            ),
            const SizedBox(height: 20),
            Text('No companies found.',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white38 : Colors.black38)),
          ],
        ),
      );
    }

    // Responsive columns
    int crossAxisCount;
    if (width < 650) {
      crossAxisCount = 1;
    } else if (width < 1100) {
      crossAxisCount = 2;
    } else if (width < 1600) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 4;
    }
    
    final cardHeight = width < 600 ? 245.0 : 255.0;

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24), // Vertical spacing
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisExtent: cardHeight,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: companies.length,
      itemBuilder: (context, index) {
        final company = companies[index];
        return _PremiumCompanyCard(company: company, isDark: isDark)
            .animate()
            .fade(delay: Duration(milliseconds: 40 * index))
            .slideY(begin: 0.08, end: 0, delay: Duration(milliseconds: 40 * index));
      },
    );
  }

  // CATEGORY MANAGE & MULTI-ASSIGN POPUP
  void _showCategoryManagePopup(BuildContext context, bool isDark, Color textColor, {String? existingCategory}) {
    final provider = context.read<CompanyProvider>();
    String categoryName = existingCategory ?? '';
    String popupSearchQuery = '';
    
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
          child: SingleChildScrollView(
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return GlassContainer(
                    width: ResponsiveBreakpoints.of(context).isMobile ? MediaQuery.of(context).size.width * 0.9 : 450,
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
                        
                        // Real-Time Search Field
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            onChanged: (val) => setState(() => popupSearchQuery = val),
                            style: TextStyle(color: textColor, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Search by Name or CID...',
                              hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11),
                              prefixIcon: Icon(IconsaxPlusLinear.search_normal_1, color: isDark ? Colors.white54 : Colors.black54, size: 16),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              isDense: true,
                            ),
                          ),
                        ),

                        // Companies List Checkboxes
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black12)
                          ),
                          child: Builder(
                            builder: (context) {
                              final query = popupSearchQuery.toLowerCase();
                              final filtered = provider.allCompanies.where((c) => 
                                c.name.toLowerCase().contains(query) || c.id.toLowerCase().contains(query)).toList();
                                
                              if (filtered.isEmpty) {
                                return Center(child: Text("No items match your search", style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)));
                              }

                              return ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (context, i) {
                                  final c = filtered[i];
                                  final isAssigned = assignedCompanyIds.contains(c.id);
                                  return CheckboxListTile(
                                    contentPadding: const EdgeInsets.all(5),
                                    value: isAssigned,
                                    activeColor: AppColors.primary,
                                    dense: true,
                                    title: Row(
                                      children: [
                                        Expanded(child: Text(c.name, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                          child: Text(c.id, style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(c.categories.join(', '), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 10)),
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
                              );
                            }
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
          ),
        ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms).fadeIn();
      },
    );
  }

  // CREATE POPUP UI
  void _showCreateCompanyPopup(BuildContext context, bool isDark, Color textColor) {
    final nameController = TextEditingController();
    final websiteController = TextEditingController();
    List<String> selectedCategories = [];

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
                      Text('Select Categories', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                        ),
                        child: provider.allCategories.isEmpty
                          ? Text('No categories available.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12))
                          : StatefulBuilder(
                              builder: (context, setPopupState) {
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: provider.allCategories.map((String cat) {
                                    final isSelected = selectedCategories.contains(cat);
                                    return FilterChip(
                                      label: Text(cat, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : textColor)),
                                      selected: isSelected,
                                      selectedColor: AppColors.primary,
                                      backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                      checkmarkColor: Colors.white,
                                      onSelected: (bool selected) {
                                        setPopupState(() {
                                          if (selected) {
                                            selectedCategories.add(cat);
                                          } else {
                                            selectedCategories.remove(cat);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
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
                             
                             int randomId = 100000 + Random().nextInt(900000);
                             while(provider.allCompanies.any((c) => c.id == randomId.toString())) {
                               randomId = 100000 + Random().nextInt(900000);
                             }
                             final newCompany = Company(
                               id: randomId.toString(),
                               name: nameController.text.trim(),
                               website: websiteController.text.trim(),
                               categories: selectedCategories,
                               status: CompanyStatus.pending,
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

  Widget _defaultIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Icon(IconsaxPlusLinear.building_3, color: Colors.white, size: size * 0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final subColor = isDark ? Colors.white54 : Colors.black54;
    final isCritical = company.healthScore < 0.7;
    final healthColor = isCritical ? AppColors.error : AppColors.success;
    
    final auth = context.watch<AuthProvider>();
    final canDelete = auth.isAdmin || (auth.isManager && company.status != CompanyStatus.active);

    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      border: isCritical
          ? Border.all(color: AppColors.error.withOpacity(0.4), width: 1.5)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TOP ROW: Logo + Name + Status ───────────────────
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              context.read<CompanyProvider>().selectCompany(company.id);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    body: SafeArea(
                      child: CompanyDetailView(
                        company: company,
                        onBack: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: company.logoUrl != null && company.logoUrl!.isNotEmpty
                      ? ClipOval(child: EbmImage(source: company.logoUrl!, width: 40, height: 40, fit: BoxFit.cover, errorWidget: const Icon(IconsaxPlusLinear.building_3, color: Colors.white, size: 20)))
                      : const Icon(IconsaxPlusLinear.building_3, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                // Name
                Expanded(
                  child: Text(
                    company.name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -0.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── CID ROW ─────────────────────────────────────────
          Row(
            children: [
              InkWell(
                onTap: () => ClipboardHelper.copy(context, 'CID-${company.id}'),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(IconsaxPlusLinear.copy, size: 9, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text('CID-${company.id}',
                          style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Icon(IconsaxPlusLinear.location, size: 10, color: subColor),
              const SizedBox(width: 4),
              Text(company.location, style: TextStyle(color: subColor, fontSize: 9, fontWeight: FontWeight.w500)),
            ],
          ),

          const SizedBox(height: 10),

          // ── CATEGORIES + TEAM COUNTS ─────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: company.categories.isEmpty
                    ? const SizedBox.shrink()
                    : Wrap(
                        spacing: 4, runSpacing: 4,
                        children: company.categories.take(2).map((cat) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                          ),
                          child: Text(cat, style: TextStyle(color: subColor, fontSize: 9, fontWeight: FontWeight.w600)),
                        )).toList(),
                      ),
              ),
              const SizedBox(width: 6),
              // Manager badge
              _TeamBadge(icon: IconsaxPlusLinear.personalcard, count: company.managerCount, label: 'Mgr', color: const Color(0xFF818CF8), isDark: isDark),
              const SizedBox(width: 4),
              // Staff badge
              _TeamBadge(icon: IconsaxPlusLinear.profile_2user, count: company.activeEmployees, label: 'Staff', color: AppColors.success, isDark: isDark),
            ],
          ),

          const Spacer(),

          // ── HEALTH BAR ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Health', style: TextStyle(color: subColor, fontSize: 10, fontWeight: FontWeight.w600)),
              Text('${(company.healthScore * 100).toInt()}%',
                  style: TextStyle(color: healthColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: company.healthScore,
              backgroundColor: healthColor.withOpacity(0.1),
              color: healthColor,
              minHeight: 5,
            ),
          ),

          const SizedBox(height: 14),

          // ── ACTION BUTTONS ───────────────────────────────────
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => CompanyManageScreen(companyId: company.id))),
                    icon: const Icon(IconsaxPlusLinear.setting_2, size: 14),
                    label: Text(
                      company.status == CompanyStatus.pending ? 'Review Team' : 'Manage Network',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: company.status == CompanyStatus.pending ? AppColors.warning : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildIconButton(context, IconsaxPlusLinear.user_add, 'Assign', () {}, isDanger: false),
              if (canDelete) ...[
                const SizedBox(width: 8),
                _buildIconButton(context, IconsaxPlusLinear.trash, 'Delete', () => _showRemovePopup(context, textColor), isDanger: true),
              ],
              const SizedBox(width: 8),
              // Copy CID quick action
              _buildIconButton(context, IconsaxPlusLinear.copy, 'Copy CID', () => ClipboardHelper.copy(context, 'CID-${company.id}'), isDanger: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bColor;
    String txt;
    
    switch (company.status) {
      case CompanyStatus.active:
        bColor = AppColors.success;
        txt = 'Active';
        break;
      case CompanyStatus.onHold:
        bColor = AppColors.warning;
        txt = 'On Hold';
        break;
      case CompanyStatus.archived:
        bColor = Colors.grey;
        txt = 'Archived';
        break;
      case CompanyStatus.pending:
        bColor = Colors.amber;
        txt = 'Pending Approval';
        break;
      case CompanyStatus.declined:
        bColor = Colors.redAccent;
        txt = 'Declined';
        break;
    }
    
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
                             provider.deleteCompany(company.id);
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

// ────────────────────────────────────────────────────────────────────────────────
// ✔ TEAM BADGE widget — shared mini count chip
// ────────────────────────────────────────────────────────────────────────────────
class _TeamBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;
  final bool isDark;

  const _TeamBadge({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 3),
          Text('$count $label',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}
