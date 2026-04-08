import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ModuleScreen extends StatelessWidget {
  const ModuleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primary = Color(0xFF6366F1);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F8FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F8FF),
            flexibleSpace: FlexibleSpaceBar(
              title: Text('App Modules', 
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                )
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroCard(isDark, primary),
                  const SizedBox(height: 30),
                  Text('Core Modules', 
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 16),
                  _buildModuleGrid(isDark, primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard(bool isDark, Color primary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primary, primary.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expand Your Features', 
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 8),
                Text('Manage and activate enterprise modules for your business ecosystem.', 
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)
                ),
              ],
            ),
          ),
          const Icon(IconsaxPlusBold.category, color: Colors.white, size: 48),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildModuleGrid(bool isDark, Color primary) {
    final modules = [
      {'name': 'Finance', 'icon': IconsaxPlusLinear.wallet_money, 'status': 'Active'},
      {'name': 'Inventory', 'icon': IconsaxPlusLinear.box_1, 'status': 'Coming Soon'},
      {'name': 'CRM', 'icon': IconsaxPlusLinear.user_octagon, 'status': 'Coming Soon'},
      {'name': 'Fleet', 'icon': IconsaxPlusLinear.bus, 'status': 'Development'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final m = modules[index];
        final isActive = m['status'] == 'Active';
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? primary.withOpacity(0.3) : Colors.transparent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(m['icon'] as IconData, color: isActive ? primary : Colors.grey, size: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m['name'] as String, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(m['status'] as String, 
                    style: GoogleFonts.outfit(fontSize: 11, color: isActive ? primary : Colors.grey)
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: (100 * index).ms).scale(begin: const Offset(0.9, 0.9));
      },
    );
  }
}
