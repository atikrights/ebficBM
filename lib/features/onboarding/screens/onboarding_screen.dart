import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ebficbm/core/services/storage_service.dart';
import 'package:ebficbm/core/theme/colors.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isAgreed = false;
  String? _selectedPath;

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickFolder() async {
    String? result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        _selectedPath = result;
      });
    }
  }

  Future<void> _finishOnboarding({bool useDefault = false, String? manualPath}) async {
    final storage = context.read<StorageService>();
    final path = manualPath ?? _selectedPath;
    
    await storage.setAgreed(true);
    if (path != null) {
      await storage.setDataPath(path);
    }
    await storage.setFirstRunComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.05),
                  Colors.transparent,
                  AppColors.primary.withOpacity(0.1),
                ],
              ),
            ),
          ),
          
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _buildWelcomeStep(),
              _buildAgreementStep(),
              _buildConfigStep(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(IconsaxPlusBold.flash_1, size: 100, color: AppColors.primary)
              .animate()
              .scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack)
              .fadeIn(),
          const SizedBox(height: 24),
          Text(
            "ebfic Business Manager",
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBackground,
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
          const SizedBox(height: 12),
          Text(
            "Empowering your business with speed and security.",
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: AppColors.darkBackground.withOpacity(0.6),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Get Started", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                const Icon(IconsaxPlusLinear.arrow_right_3),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms).scale(),
        ],
      ),
    );
  }

  Widget _buildAgreementStep() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Icon(IconsaxPlusBold.shield_security, size: 60, color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            "License Agreement",
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Text(
                  "By using ebfic Business Manager, you agree to the following:\n\n"
                  "1. Security: We prioritize your device security. This app is designed to work within sandboxed environments when possible.\n\n"
                  "2. Data Responsibility: You are responsible for the data stored in your selected folder.\n\n"
                  "3. Confidentiality: Business data handled by this app is locally stored. We do not transmit sensitive data to external servers without your explicit consent.\n\n"
                  "4. User Interface: The software is provided as-is, with tools designed for professional multi-platform management.\n\n"
                  "5. Professional Use: This application is intended for business management and optimization.",
                  style: GoogleFonts.outfit(fontSize: 15, height: 1.6, color: Colors.black87),
                ),
              ),
            ),
          ).animate().fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Checkbox(
                value: _isAgreed,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _isAgreed = v ?? false),
              ),
              Text(
                "I have read and agree to the terms.",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _previousPage,
                child: Text("Back", style: GoogleFonts.outfit(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: _isAgreed ? _nextPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Continue"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigStep() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(IconsaxPlusBold.folder_open, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            "Workspace Setup",
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Choose how you want to manage your business data.",
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              Expanded(
                child: _ConfigOption(
                  icon: IconsaxPlusBold.folder_add,
                  title: "Create New",
                  subtitle: "Select a clean folder",
                  isSelected: _selectedPath != null,
                  onTap: _pickFolder,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _ConfigOption(
                  icon: IconsaxPlusBold.folder_favorite,
                  title: "Load Existing",
                  subtitle: "Import your previous data",
                  isSelected: false, // Just for visual
                  onTap: _pickFolder, // Same mechanism, but user picks their old folder
                ),
              ),
            ],
          ),
          if (_selectedPath != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(IconsaxPlusLinear.folder_open, size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Selected: $_selectedPath",
                      style: GoogleFonts.outfit(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _previousPage,
                child: Text("Back", style: GoogleFonts.outfit(color: Colors.grey)),
              ),
              Row(
                children: [
                  if (_selectedPath == null)
                    TextButton(
                      onPressed: () => _finishOnboarding(useDefault: true),
                      child: Text(
                        "Use Default Location",
                        style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _selectedPath != null ? () => _finishOnboarding() : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Complete Setup"),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfigOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConfigOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isSelected ? AppColors.primary : Colors.grey),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
