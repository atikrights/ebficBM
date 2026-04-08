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

  @override
  void initState() {
    super.initState();
    _initialFetch();
  }

  Future<void> _initialFetch() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
      
      final info = await UpdateService().checkForUpdateFlow();
      if (mounted) {
        setState(() {
          _onlineInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
                      SliverToBoxAdapter(child: _buildHeroHeader(primaryColor, isDark)),
                      
                      // Live Update State Visualizer
                      SliverToBoxAdapter(
                        child: ValueListenableBuilder<UpdateState>(
                          valueListenable: updateStateNotifier,
                          builder: (context, state, _) {
                            if (state == UpdateState.idle || state == UpdateState.available) {
                              return const SizedBox.shrink();
                            }
                            return _buildLiveStateVisualizer(primaryColor, isDark, state).animate().fadeIn().slideY(begin: 0.1);
                          },
                        ),
                      ),

                      // Status Banner
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: ValueListenableBuilder<UpdateState>(
                            valueListenable: updateStateNotifier,
                            builder: (context, state, _) {
                               return _buildDynamicBanner(primaryColor, isDark, state);
                            }
                          ),
                        ),
                      ),

                      // Action Controls
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildActionCard(primaryColor, isDark),
                        ),
                      ),

                      // Release Details & Author
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                        sliver: SliverToBoxAdapter(
                          child: _buildReleaseDetails(primaryColor, isDark),
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
            boxShadow: [BoxShadow(color: primary.withOpacity(0.1), blurRadius: 40, spreadRadius: 5)],
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
          style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildLiveStateVisualizer(Color primary, bool isDark, UpdateState state) {
    IconData statusIcon = IconsaxPlusLinear.cloud_change;
    Color statusColor = primary;

    if (state == UpdateState.validating) {
      statusIcon = IconsaxPlusLinear.security_safe;
      statusColor = Colors.orangeAccent;
    } else if (state == UpdateState.readyToInstall) {
      statusIcon = IconsaxPlusLinear.tick_circle;
      statusColor = Colors.green;
    } else if (state == UpdateState.installing || state == UpdateState.relaunching) {
      statusIcon = IconsaxPlusLinear.setting_4;
      statusColor = Colors.greenAccent;
    } else if (state == UpdateState.error) {
      statusIcon = IconsaxPlusLinear.close_circle;
      statusColor = Colors.redAccent;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: statusColor.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor)
                  .animate(onPlay: (c) => state == UpdateState.readyToInstall ? c : c.repeat())
                  .shimmer(duration: 1500.ms),
              const SizedBox(width: 12),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: updateStatusNotifier,
                  builder: (context, statusMsg, _) {
                    return Text(statusMsg, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13));
                  },
                ),
              ),
              if (state == UpdateState.downloading)
                ValueListenableBuilder<double>(
                  valueListenable: updateProgressNotifier,
                  builder: (context, progress, _) {
                    return Text('${(progress * 100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: statusColor));
                  },
                ),
            ],
          ),
          if (state == UpdateState.downloading || state == UpdateState.validating || state == UpdateState.installing) ...[
            const SizedBox(height: 15),
            ValueListenableBuilder<double>(
              valueListenable: updateProgressNotifier,
              builder: (context, progress, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (state == UpdateState.validating || state == UpdateState.installing) ? null : progress,
                    minHeight: 8,
                    backgroundColor: statusColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                );
              },
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildDynamicBanner(Color primary, bool isDark, UpdateState state) {
    if (state == UpdateState.error) {
      return ValueListenableBuilder<String>(
        valueListenable: updateStatusNotifier,
        builder: (context, errMsg, _) {
          return _banner(label: errMsg.isNotEmpty ? errMsg : 'An error occurred.', icon: IconsaxPlusLinear.info_circle, color: Colors.redAccent, isDark: isDark);
        }
      );
    }
    if (state == UpdateState.checking) {
      return _banner(label: 'Checking securely for updates...', icon: IconsaxPlusLinear.search_zoom_in_1, color: Colors.orangeAccent, isDark: isDark);
    }
    
    if (state == UpdateState.readyToInstall) {
      return _banner(label: 'Update downloaded! Ready to install.', icon: IconsaxPlusBold.magic_star, color: Colors.green, isDark: isDark);
    }

    final isUpdateAvailable = _onlineInfo != null && _onlineInfo!['version'] != null && _currentVersion.isNotEmpty && _onlineInfo!['version'] != _currentVersion;

    if (isUpdateAvailable) {
      return _banner(
        label: 'Version v${_onlineInfo!['version']} is available',
        detail: 'Package size: ${_onlineInfo!['sizeMb']} MB',
        icon: IconsaxPlusLinear.info_circle,
        color: Colors.greenAccent,
        isDark: isDark,
      );
    }

    return _banner(label: 'Your system is fully protected & up to date', detail: 'Local Version: $_currentVersion', icon: IconsaxPlusBold.shield_tick, color: primary, isDark: isDark);
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
                 if (detail != null) Text(detail, style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black54, fontSize: 11)),
               ],
             ),
          ),
        ],
      ),
    ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildActionCard(Color primary, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ValueListenableBuilder<UpdateState>(
        valueListenable: updateStateNotifier,
        builder: (context, state, _) {
          bool isBusy = (state == UpdateState.checking || state == UpdateState.downloading || state == UpdateState.validating || state == UpdateState.installing);
          bool isReady = state == UpdateState.readyToInstall;

          final isUpdateAvailable = _onlineInfo != null && _onlineInfo!['version'] != null && _currentVersion.isNotEmpty && _onlineInfo!['version'] != _currentVersion;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('System Controls', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Initiate cross-platform secure update process.', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 20),
              
              if (isUpdateAvailable || isReady) ...[
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: isBusy ? null : () async => await UpdateService().startDirectUpdate(_onlineInfo!),
                    icon: isBusy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(isReady ? IconsaxPlusBold.refresh : IconsaxPlusLinear.document_download),
                    label: Text(isBusy ? 'Processing...' : (isReady ? 'Restart & Apply Update' : 'Install Secure Update Now')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReady ? Colors.green : Colors.blueAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                )
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: isBusy ? null : _initialFetch,
                    icon: isBusy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(IconsaxPlusLinear.refresh),
                    label: Text(isBusy ? 'Verifying...' : 'Check System Updates'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ],
          );
        }
      ),
    );
  }

  Widget _buildReleaseDetails(Color primary, bool isDark) {
    if (_onlineInfo == null) return const SizedBox.shrink();

    final releaseVersion = _onlineInfo!['version'] as String;
    String notes = (_onlineInfo!['notes'] ?? '').toString();
    notes = notes.replaceAll('**', '').replaceAll('##', '').replaceAll('`', '').replaceAll('|', '').trim();
    
    final authorName = _onlineInfo!['author'] as String;
    final authorAvatar = _onlineInfo!['author_avatar'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('What\'s Changed v$releaseVersion', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const Icon(IconsaxPlusLinear.status, size: 18, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 16),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withOpacity(0.2)),
            boxShadow: [
              if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author Section
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: primary.withOpacity(0.2),
                    backgroundImage: authorAvatar.isNotEmpty ? NetworkImage(authorAvatar) : null,
                    child: authorAvatar.isEmpty ? Icon(Icons.person, size: 12, color: primary) : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Released by @$authorName',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: primary),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Changelog
              Text(
                notes.isEmpty ? 'Performance and security updates.' : notes,
                style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.grey[700], height: 1.6),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
      ],
    );
  }
}
