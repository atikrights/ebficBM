import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ebficbm/core/theme/colors.dart';
import 'package:ebficbm/widgets/ebm_image.dart';
import '../models/company.dart';

class PlatformDocViewScreen extends StatelessWidget {
  final Company company;
  final Map<String, String> platform;

  const PlatformDocViewScreen({
    super.key,
    required this.company,
    required this.platform,
  });

  Future<void> _openLink(String link) async {
    final uri = Uri.tryParse(link.startsWith('http') ? link : 'https://$link');
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = platform['title'] ?? 'Untitled Platform';
    final content = platform['doc'] ?? '';
    final link = platform['link'] ?? '';
    final iconSource = platform['icon'] ?? '';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1116) : const Color(0xFFF9FAFB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium App Bar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? const Color(0xFF16181D) : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(IconsaxPlusLinear.arrow_left, 
                   color: isDark ? Colors.white : Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark 
                      ? [AppColors.primary.withValues(alpha: 0.15), Colors.transparent]
                      : [AppColors.primary.withValues(alpha: 0.08), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // ── Content Area with Auto-Adjustment ───────────────────────────
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Platform Meta Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                                shape: BoxShape.circle,
                              ),
                              child: iconSource.startsWith('asset://')
                                ? ClipOval(child: EbmImage(source: iconSource, fit: BoxFit.cover))
                                : Icon(IconsaxPlusLinear.global, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'OFFICIAL PLATFORM',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white38 : Colors.black38,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    link.isNotEmpty ? link : 'No external link provided',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: link.isNotEmpty ? AppColors.primary : (isDark ? Colors.white24 : Colors.black26),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (link.isNotEmpty)
                              IconButton(
                                onPressed: () => _openLink(link),
                                icon: const Icon(IconsaxPlusLinear.export_1, size: 18),
                                color: AppColors.primary,
                                tooltip: 'Visit Platform',
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Documentation Header
                      Row(
                        children: [
                          Container(
                            width: 2,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'DOCUMENTATION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white38 : Colors.black38,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Content
                      content.isEmpty
                        ? _buildEmptyState(isDark)
                        : SelectableText(
                            content,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.8,
                              color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                              letterSpacing: 0.3,
                            ),
                          ),
                      
                      const SizedBox(height: 60),
                      
                      // Footer
                      Center(
                        child: Text(
                          'ebfic Group Limited Develop by atik islam',
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark ? Colors.white24 : Colors.black26,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(IconsaxPlusLinear.document_filter, 
               size: 40, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            'No documentation available for this platform.',
            style: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

}
