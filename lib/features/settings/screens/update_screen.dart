import 'dart:io';
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

class _UpdateScreenState extends State<UpdateScreen> with SingleTickerProviderStateMixin {
  String _currentVersion = '';
  Map<String, dynamic>? _onlineInfo;
  bool _isLoading = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _initialFetch();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initialFetch() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
      final info = await UpdateService().checkForUpdateFlow();
      if (mounted) setState(() { _onlineInfo = info; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _platformLabel {
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Universal';
  }

  IconData get _platformIcon {
    if (Platform.isWindows) return IconsaxPlusBold.monitor;
    if (Platform.isMacOS) return IconsaxPlusBold.apple;
    if (Platform.isAndroid) return IconsaxPlusBold.mobile;
    if (Platform.isIOS) return IconsaxPlusBold.mobile;
    return IconsaxPlusBold.global;
  }

  bool get _isUpdateAvailable =>
      _onlineInfo != null &&
      (_onlineInfo!['version'] ?? '').toString().isNotEmpty &&
      _currentVersion.isNotEmpty &&
      _onlineInfo!['version'] != _currentVersion;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Premium color system
    const primary = Color(0xFF6366F1);      // Indigo
    const accent  = Color(0xFF8B5CF6);      // Violet
    const success = Color(0xFF10B981);      // Emerald
    const warning = Color(0xFFF59E0B);      // Amber

    final bgTop    = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F8FF);
    final bgBottom = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFEEEEFF);

    return Scaffold(
      backgroundColor: bgTop,
      body: Stack(
        children: [
          // Premium gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [bgTop, bgBottom],
                ),
              ),
            ),
          ),
          // Decorative glow blobs
          Positioned(top: -80, right: -80,
            child: _GlowBlob(color: primary.withOpacity(0.12), size: 280)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: 20, duration: 4.seconds)),
          Positioned(bottom: 100, left: -100,
            child: _GlowBlob(color: accent.withOpacity(0.10), size: 320)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveX(begin: 0, end: 25, duration: 5.seconds)),

          // Main content
          SafeArea(
            child: _isLoading
                ? _buildLoader(primary)
                : RefreshIndicator(
                    onRefresh: _initialFetch,
                    color: primary,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // Header
                        SliverToBoxAdapter(child: _buildTopBar(isDark, primary)),
                        // Hero
                        SliverToBoxAdapter(child: _buildHero(isDark, primary, accent, success, warning)),
                        // Live progress
                        SliverToBoxAdapter(
                          child: ValueListenableBuilder<UpdateState>(
                            valueListenable: updateStateNotifier,
                            builder: (_, state, __) {
                              if (state == UpdateState.idle || state == UpdateState.available) return const SizedBox.shrink();
                              return _buildProgressPanel(isDark, state, primary, success).animate().fadeIn().slideY(begin: 0.15);
                            },
                          ),
                        ),
                        // Status card
                        SliverToBoxAdapter(child: _buildStatusCard(isDark, primary, success, warning)),
                        // Action button
                        SliverToBoxAdapter(child: _buildActionButton(isDark, primary, success)),
                        // Platform chips
                        SliverToBoxAdapter(child: _buildPlatformRow(isDark, primary)),
                        // Author / release notes
                        if (_onlineInfo != null)
                          SliverToBoxAdapter(child: _buildReleaseCard(isDark, primary, success)),
                        const SliverToBoxAdapter(child: SizedBox(height: 60)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── widgets ───────────────────────────

  Widget _buildLoader(Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primary, strokeWidth: 2),
          const SizedBox(height: 16),
          Text('Checking for updates...', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isDark, Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: primary.withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: primary.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_platformIcon, color: primary, size: 14),
                const SizedBox(width: 6),
                Text(_platformLabel, style: GoogleFonts.outfit(color: primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _initialFetch,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(IconsaxPlusLinear.refresh, color: isDark ? Colors.white60 : Colors.black38, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(bool isDark, Color primary, Color accent, Color success, Color warning) {
    const isUpToDate = false; // will rely on _isUpdateAvailable logic
    final versionColor = isDark ? Colors.white : Colors.black87;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
      child: Column(
        children: [
          // Animated orbit icon
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) {
              final scale = 1.0 + (_pulseController.value * 0.06);
              final glowOpacity = 0.12 + (_pulseController.value * 0.08);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [primary, accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [
                      BoxShadow(color: primary.withOpacity(glowOpacity), blurRadius: 40, spreadRadius: 10),
                    ],
                  ),
                  child: const Icon(IconsaxPlusBold.refresh_circle, color: Colors.white, size: 48),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'v$_currentVersion',
            style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w800, color: versionColor, letterSpacing: -0.5),
          ).animate().fadeIn().slideY(begin: 0.2, delay: 100.ms),
          const SizedBox(height: 4),
          Text(
            'ebfic Business Manager — Current Build',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProgressPanel(bool isDark, UpdateState state, Color primary, Color success) {
    Color c = primary;
    IconData ic = IconsaxPlusLinear.cloud_change;
    String label = 'Processing…';

    switch (state) {
      case UpdateState.downloading:
        c = primary; ic = IconsaxPlusLinear.document_download; label = 'Downloading secure package';
        break;
      case UpdateState.validating:
        c = const Color(0xFFF59E0B); ic = IconsaxPlusLinear.security_safe; label = 'Verifying integrity';
        break;
      case UpdateState.readyToInstall:
        c = success; ic = IconsaxPlusBold.tick_circle; label = 'Package ready to install';
        break;
      case UpdateState.installing:
      case UpdateState.relaunching:
        c = success; ic = IconsaxPlusBold.setting_4; label = 'Applying update…';
        break;
      case UpdateState.error:
        c = Colors.redAccent; ic = IconsaxPlusLinear.close_circle; label = 'Update error';
        break;
      default: break;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.35)),
        boxShadow: [BoxShadow(color: c.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(ic, color: c, size: 18)
                    .animate(onPlay: (ctrl) => state == UpdateState.readyToInstall ? null : ctrl.repeat())
                    .shimmer(duration: 1200.ms, color: c),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: updateStatusNotifier,
                  builder: (_, msg, __) => Text(
                    msg.isEmpty ? label : msg,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
              if (state == UpdateState.downloading)
                ValueListenableBuilder<double>(
                  valueListenable: updateProgressNotifier,
                  builder: (_, p, __) => Text(
                    '${(p * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14, color: c),
                  ),
                ),
            ],
          ),
          if (state == UpdateState.downloading || state == UpdateState.validating || state == UpdateState.installing) ...[
            const SizedBox(height: 14),
            ValueListenableBuilder<double>(
              valueListenable: updateProgressNotifier,
              builder: (_, p, __) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (state == UpdateState.validating || state == UpdateState.installing) ? null : p,
                    minHeight: 6,
                    backgroundColor: c.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(c),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isDark, Color primary, Color success, Color warning) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: ValueListenableBuilder<UpdateState>(
        valueListenable: updateStateNotifier,
        builder: (_, state, __) {
          if (state == UpdateState.downloading || state == UpdateState.validating ||
              state == UpdateState.installing || state == UpdateState.relaunching) {
            return const SizedBox.shrink();
          }

          Color c; IconData ic; String title; String? sub;

          if (state == UpdateState.error) {
            c = Colors.redAccent; ic = IconsaxPlusBold.close_circle;
            title = 'Update failed. Please retry.'; sub = 'Check your internet connection.';
          } else if (state == UpdateState.readyToInstall) {
            c = success; ic = IconsaxPlusBold.magic_star;
            title = 'Ready to Install'; sub = 'Update downloaded in the background.';
          } else if (_isUpdateAvailable) {
            c = warning; ic = IconsaxPlusBold.notification_1;
            title = 'Update v${_onlineInfo!['version']} Available';
            sub = 'Size: ${_onlineInfo!['sizeMb']} MB';
          } else {
            c = success; ic = IconsaxPlusBold.shield_tick;
            title = 'Up to Date'; sub = 'You have the latest version installed.';
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: c.withOpacity(isDark ? 0.1 : 0.07),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.withOpacity(0.28)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: c.withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(ic, color: c, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
                      if (sub != null) Text(sub, style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.white60 : Colors.black45)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().scale(begin: const Offset(0.96, 0.96), duration: 350.ms, curve: Curves.easeOutBack);
        },
      ),
    );
  }

  Widget _buildActionButton(bool isDark, Color primary, Color success) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: ValueListenableBuilder<UpdateState>(
        valueListenable: updateStateNotifier,
        builder: (_, state, __) {
          final isBusy = state == UpdateState.checking || state == UpdateState.downloading ||
              state == UpdateState.validating || state == UpdateState.installing;
          final isReady = state == UpdateState.readyToInstall;
          final hasUpdate = _isUpdateAvailable || isReady;

          final btnColor = isReady ? success : (hasUpdate ? primary : primary.withOpacity(0.85));
          final btnLabel = isBusy ? 'Processing…' : (isReady ? 'Restart & Apply Update' : (hasUpdate ? 'Install Secure Update' : 'Check for Updates'));
          final btnIcon  = isBusy ? null : (isReady ? IconsaxPlusBold.refresh : (hasUpdate ? IconsaxPlusBold.document_download : IconsaxPlusLinear.refresh));

          return SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isBusy ? null : () async {
                if (hasUpdate || isReady) {
                  await UpdateService().startDirectUpdate(_onlineInfo!);
                } else {
                  _initialFetch();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isBusy)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  else if (btnIcon != null)
                    Icon(btnIcon, size: 20),
                  const SizedBox(width: 10),
                  Text(btnLabel, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlatformRow(bool isDark) {
    final platforms = [
      {'label': 'Android', 'icon': IconsaxPlusBold.mobile, 'color': const Color(0xFF10B981)},
      {'label': 'iOS', 'icon': IconsaxPlusBold.mobile, 'color': const Color(0xFF3B82F6)},
      {'label': 'Windows', 'icon': IconsaxPlusBold.monitor, 'color': const Color(0xFF6366F1)},
      {'label': 'macOS', 'icon': IconsaxPlusBold.apple, 'color': const Color(0xFF8B5CF6)},
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        children: platforms.map((p) {
          final isActive = (p['label'] as String) == _platformLabel;
          final c = p['color'] as Color;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isActive ? c.withOpacity(0.12) : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isActive ? c.withOpacity(0.4) : Colors.transparent),
              ),
              child: Column(
                children: [
                  Icon(p['icon'] as IconData, color: isActive ? c : Colors.grey, size: 18),
                  const SizedBox(height: 4),
                  Text(p['label'] as String, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: isActive ? c : Colors.grey)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReleaseCard(bool isDark, Color primary, Color success) {
    final version   = (_onlineInfo!['version'] ?? '').toString();
    final author    = (_onlineInfo!['author'] ?? 'atikrights').toString();
    final avatar    = (_onlineInfo!['author_avatar'] ?? '').toString();
    String notes    = (_onlineInfo!['notes'] ?? '').toString();

    // Strip markdown for now
    notes = notes
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'## ?'), '')
        .replaceAll(RegExp(r'`'), '')
        .replaceAll(RegExp(r'\|.*\|'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Row(
            children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text("What's New in v$version", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : primary.withOpacity(0.12)),
              boxShadow: [
                if (!isDark) BoxShadow(color: primary.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: primary.withOpacity(0.2),
                      backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                      child: avatar.isEmpty ? Icon(Icons.person, size: 16, color: primary) : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('@$author', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: primary)),
                        Text('Production Release · v$version', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: success.withOpacity(0.3)),
                      ),
                      child: Text('LIVE', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: success, letterSpacing: 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06), height: 1),
                const SizedBox(height: 16),
                // Changelog
                Text(
                  notes.isEmpty ? '• Performance & security improvements.\n• UI refinements.\n• Cross-platform stability updates.' : notes,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    height: 1.7,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }
}

// ─── Ambient glow blob ───────────────────────────────────────────────────────
class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 40)],
      ),
    );
  }
}
