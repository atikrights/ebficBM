import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ebficBM/core/services/update_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  String _currentVersion = '';
  Map<String, dynamic>? _onlineInfo;
  bool _isLoading = true;
  bool _isChecking = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialFetch();
  }

  Future<void> _initialFetch() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final info = await UpdateService().getLatestVersionInfo();
      if (mounted) {
        setState(() {
          _currentVersion = packageInfo.version;
          _onlineInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Connection Error: Check your internet and retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Colors.blueAccent;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('System Update', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
              ),
            ),
          ),
          
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _initialFetch,
                  displacement: 100,
                  color: primaryColor,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.top + 60)),
                      
                      // Hero Header Section
                      SliverToBoxAdapter(
                        child: _buildHeroHeader(primaryColor, isDark),
                      ),

                      // Real-time Progress Section (Sticky if updating)
                      SliverToBoxAdapter(
                        child: ValueListenableBuilder<bool>(
                          valueListenable: isUpdatingNotifier,
                          builder: (context, isUpdating, _) {
                            if (!isUpdating) return const SizedBox.shrink();
                            return _buildLiveUpdateProgress(primaryColor, isDark).animate().fadeIn().slideY(begin: 0.1);
                          },
                        ),
                      ),

                      // Update Status Banner
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: _buildStatusBanner(primaryColor, isDark),
                        ),
                      ),

                      // Actions Section
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildActionCard(primaryColor, isDark),
                        ),
                      ),

                      // Changelog/Activity Section
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                        sliver: SliverToBoxAdapter(
                          child: _buildActivitySection(primaryColor, isDark),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(Color primary, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withOpacity(0.1),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.1),
                blurRadius: 40,
                spreadRadius: 5,
              )
            ],
          ),
          child: Icon(IconsaxPlusLinear.refresh_circle, size: 80, color: primary),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2000.ms),
        const SizedBox(height: 16),
        Text(
          'v$_currentVersion',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          'Current System Version',
          style: GoogleFonts.outfit(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildLiveUpdateProgress(Color primary, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(IconsaxPlusLinear.document_download, color: Colors.blueAccent),
              const SizedBox(width: 12),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: updateStatusNotifier,
                  builder: (context, status, _) {
                    return Text(
                      status,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                    );
                  },
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: updateProgressNotifier,
                builder: (context, progress, _) {
                  return Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: primary),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 15),
          ValueListenableBuilder<double>(
            valueListenable: updateProgressNotifier,
            builder: (context, progress, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: primary.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(Color primary, bool isDark) {
    if (_errorMessage != null) {
      return _banner(
        label: _errorMessage!,
        icon: IconsaxPlusLinear.info_circle,
        color: Colors.redAccent,
        isDark: isDark,
      );
    }

    final isUpdateAvailable = _onlineInfo != null &&
        _onlineInfo!['version'] != null &&
        _currentVersion.isNotEmpty &&
        _onlineInfo!['version'] != _currentVersion;

    if (isUpdateAvailable) {
      return _banner(
        label: 'Version v${_onlineInfo!['version']} is available for download',
        detail: 'Package size: ${_onlineInfo!['sizeMb']} MB',
        icon: IconsaxPlusLinear.info_circle,
        color: Colors.greenAccent,
        isDark: isDark,
      );
    }

    return _banner(
      label: 'Your system is up to date',
      detail: 'Last checked: just now',
      icon: IconsaxPlusLinear.tick_circle,
      color: primary,
      isDark: isDark,
    );
  }

  Widget _banner({required String label, String? detail, required IconData icon, required Color color, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87, fontSize: 13)),
                if (detail != null)
                  Text(detail, style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black54, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(Color primary, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Controls', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Check manually or start installation if available.', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isChecking
                  ? null
                  : () async {
                      if (!mounted) return;
                      setState(() => _isChecking = true);
                      try {
                        await UpdateService().checkForUpdate(context, showNoUpdate: true);
                        await _initialFetch();
                      } catch (_) {}
                      if (mounted) {
                        setState(() => _isChecking = false);
                      }
                    },
              icon: _isChecking
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(IconsaxPlusLinear.refresh),
              label: Text(_isChecking ? 'Verifying...' : 'Check System Updates'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection(Color primary, bool isDark) {
    final releases = _onlineInfo?['all_releases'] as List?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Update History', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const Icon(IconsaxPlusLinear.status, size: 18, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 16),
        if (releases == null || releases.isEmpty)
          const Center(child: Text('No activity data.', style: TextStyle(color: Colors.grey)))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: releases.length.clamp(0, 8),
            itemBuilder: (context, index) {
              final release = releases[index];
              final tag = (release['tag_name'] ?? '').toString();
              final isCurrent = tag == 'v$_currentVersion' || tag == _currentVersion;
              
              String notes = (release['body'] ?? '').toString();
              // Format notes for preview
              notes = notes
                  .replaceAll('**', '')
                  .replaceAll('##', '')
                  .replaceAll('`', '')
                  .replaceAll('|', '')
                  .replaceAll('\n', ' ')
                  .trim();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: isCurrent ? Border.all(color: primary.withOpacity(0.5), width: 1) : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCurrent ? primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCurrent ? IconsaxPlusBold.tick_circle : IconsaxPlusLinear.clock, 
                        size: 16, 
                        color: isCurrent ? primary : Colors.grey
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(tag, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(6)),
                                  child: Text('Active', style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notes.isEmpty ? 'Performance improvements and security patches.' : notes,
                            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey, height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.05);
            },
          ),
      ],
    );
  }
}
