import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:bizos_x_pro/core/theme/colors.dart';
import 'package:bizos_x_pro/widgets/glass_container.dart';
import 'package:responsive_framework/responsive_framework.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

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
            _buildQuickActionAndStats(isMobile, isDark, textColor),
            const SizedBox(height: 24),
            Text('Recent Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isMobile ? 1.4 : 1.6,
              ),
              itemCount: 4,
              itemBuilder: (context, index) => _NoteCard(index: index, isDark: isDark, textColor: textColor),
            ),
            const SizedBox(height: 24),
            Text('Documents & Invoices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 16),
            _buildDocumentList(isDark, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionAndStats(bool isMobile, bool isDark, Color textColor) {
    final widgets = [
      Expanded(
        child: GlassContainer(
          padding: const EdgeInsets.all(20),
          gradient: AppColors.primaryGradient,
          child: const Column(
            children: [
              Icon(IconsaxPlusLinear.document_upload, color: Colors.white, size: 28),
              SizedBox(height: 12),
              Text('Quick Upload', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('PDF, IMAGES, DOC', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      ),
      const SizedBox(width: 16, height: 16),
      Expanded(
        child: GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('Total Storage', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)),
              const SizedBox(height: 8),
              Text('2.4 GB', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: 0.45, backgroundColor: isDark ? Colors.white10 : Colors.black12, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary), minHeight: 6),
            ],
          ),
        ),
      ),
    ];

    if (isMobile) {
      return Column(children: widgets);
    }
    return Row(children: widgets);
  }

  Widget _buildDocumentList(bool isDark, Color textColor) {
    final subTextColor = isDark ? Colors.white54 : Colors.black54;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              const Icon(IconsaxPlusLinear.document, color: AppColors.info),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invoice-Q3-MAR.pdf', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 13)),
                    Text('Uploaded 2 days ago • 1.2 MB', style: TextStyle(color: subTextColor, fontSize: 11)),
                  ],
                ),
              ),
              IconButton(onPressed: () {}, icon: Icon(IconsaxPlusLinear.import_3, color: subTextColor, size: 20)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final int index;
  final bool isDark;
  final Color textColor;
  const _NoteCard({required this.index, required this.isDark, required this.textColor});

  @override
  Widget build(BuildContext context) {
    final subTextColor = isDark ? Colors.white70 : Colors.black87;
    final dateColor = isDark ? Colors.white54 : Colors.black54;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(['Project Alpha', 'Team Meeting', 'Budget Review', 'Feedback'][index % 4], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
              Icon(IconsaxPlusLinear.edit_2, color: dateColor.withValues(alpha: 0.3), size: 14),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              'The discussion was centered around the new UI components and how to integrate glassmorphism effectively...',
              style: TextStyle(color: subTextColor, fontSize: 11, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(IconsaxPlusLinear.calendar, color: dateColor, size: 12),
              const SizedBox(width: 4),
              const Text('Oct 24, 2026', style: TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
