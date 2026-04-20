import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:ebficbm/core/theme/colors.dart';
import 'package:ebficbm/widgets/ebm_image.dart';
import 'package:ebficbm/widgets/glass_container.dart';
import '../models/asset_model.dart';
import '../providers/asset_provider.dart';
import '../../../core/config/app_config.dart';
import 'asset_editor_screen.dart';
import 'dart:math';

class AssetLibraryScreen extends StatefulWidget {
  const AssetLibraryScreen({super.key});

  @override
  State<AssetLibraryScreen> createState() => _AssetLibraryScreenState();
}

class _AssetLibraryScreenState extends State<AssetLibraryScreen> {
  String _searchQuery = '';
  String _selectedFolderId = 'all'; // 'all', 'trash', or Folder ID

  final ScrollController _scrollController = ScrollController();
  bool _showDrafts = false; // Toggle between active and draft assets

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<AssetProvider>();
      final filtered = _getFiltered(_showDrafts ? provider.draftAssets : provider.activeAssets);
      if (provider.hasMore(filtered)) {
        provider.loadMore();
      }
    }
  }

  List<AssetModel> _getFiltered(List<AssetModel> all) {
    return all.where((a) {
      // 1. Filter by Custom Folder (if a folder is selected)
      if (_selectedFolderId != 'all' && _selectedFolderId != 'trash') {
        final provider = context.read<AssetProvider>();
        final folder = provider.folders.firstWhere(
          (f) => f.id == _selectedFolderId,
          orElse: () => AssetFolderModel(id: '', name: '', assetIds: []),
        );
        if (!folder.assetIds.contains(a.id)) return false;
      }

      // 2. Filter by Search Query
      final matchesSearch =
          a.name.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssetProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _getFiltered(_showDrafts ? provider.draftAssets : provider.activeAssets);
    final paged = provider.pagedAssets(filtered);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header bar
            _buildHeaderBar(isDark, provider),

            const SizedBox(height: 24),

            // ── Stats row (Dynamic Badges)
            _buildStatsRow(provider, isDark),

            const SizedBox(height: 16),

            // ── Filter tabs
            _buildFilterTabs(isDark),

            const SizedBox(height: 24),

            // ── Upload Progress
            if (provider.isUploading) ...[
              _buildUploadProgress(provider, isDark),
              const SizedBox(height: 16),
            ],

            // ── Main grid
            Expanded(
              child: provider.isLoading
                  ? _buildLoadingSkeleton()
                  : filtered.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildAssetGrid(paged, filtered, isDark, provider),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeaderBar(bool isDark, AssetProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          _buildStorageBadge(isDark, provider),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildSearchBox(isDark),
              _buildDraftsToggle(isDark, provider),
              if (!ResponsiveBreakpoints.of(context).largerThan(TABLET))
                _buildIconUploadButton(provider)
              else
                _buildUploadButton(provider),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconUploadButton(AssetProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: provider.isUploading ? null : () => provider.pickAndImportAssets(),
        icon: const Icon(IconsaxPlusLinear.document_upload,
            color: Colors.white, size: 20),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildUploadButton(AssetProvider provider) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: provider.isUploading ? null : () => provider.pickAndImportAssets(),
      icon: const Icon(IconsaxPlusLinear.document_upload, size: 20),
      label: const Text('Upload Media',
          style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  // ── Dynamic Dynamic Stats Bar ──────────────────────────────────────────────
  
  Widget _buildStatsRow(AssetProvider provider, bool isDark) {
    // 1. Calculate statistics dynamically
    final assets = provider.activeAssets;
    final Map<String, int> extCounts = {};
    for (var a in assets) {
      final ext = a.path.split('.').last.toUpperCase();
      if (ext.length < 5) { // Sanity check for valid extensions
         extCounts[ext] = (extCounts[ext] ?? 0) + 1;
      }
    }

    // Sort extensions alphabetically
    final sortedExts = extCounts.keys.toList()..sort();

    final savedMB = (provider.totalBytesSaved / (1024 * 1024));
    final savedStr = savedMB >= 1
        ? '${savedMB.toStringAsFixed(1)} MB saved'
        : '${(provider.totalBytesSaved / 1024).toStringAsFixed(0)} KB saved';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // Total Badge
          _buildStatPill(
            '${assets.length} Total Assets',
            IconsaxPlusLinear.category_2,
            AppColors.primary,
            isDark,
          ),
          const SizedBox(width: 10),

          // Dynamic Type Badges
          ...sortedExts.map((ext) {
            final count = extCounts[ext];
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _buildStatPill(
                '$count $ext',
                _getIconForExt(ext),
                _getColorForExt(ext),
                isDark,
              ),
            );
          }),

          // Savings Badge
          if (provider.totalBytesSaved > 0)
            _buildStatPill(
              savedStr,
              IconsaxPlusLinear.flash_1,
              Colors.green,
              isDark,
            ),
        ],
      ),
    );
  }

  IconData _getIconForExt(String ext) {
    if (['PNG', 'JPG', 'JPEG', 'WEBP', 'SVG'].contains(ext)) return IconsaxPlusLinear.gallery;
    if (['PDF', 'DOC', 'DOCX', 'TXT'].contains(ext)) return IconsaxPlusLinear.document_text;
    if (['MP4', 'MOV', 'AVI'].contains(ext)) return IconsaxPlusLinear.video_square;
    if (['ZIP', 'RAR', '7Z'].contains(ext)) return IconsaxPlusLinear.archive_1;
    return IconsaxPlusLinear.document;
  }

  Color _getColorForExt(String ext) {
    if (ext == 'PNG' || ext == 'JPG' || ext == 'JPEG') return Colors.blue;
    if (ext == 'SVG') return Colors.orange;
    if (ext == 'PDF') return Colors.redAccent;
    if (ext == 'MP4') return Colors.purple;
    if (ext == 'ZIP') return Colors.teal;
    return Colors.grey;
  }

  Widget _buildStatPill(
      String label, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Upload Progress ───────────────────────────────────────────────────────

  Widget _buildUploadProgress(AssetProvider provider, bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      borderRadius: 12,
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              provider.uploadStatus ?? 'Processing…',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: -0.3, duration: 300.ms);
  }

  // ── Filter Tabs ───────────────────────────────────────────────────────────

  Widget _buildFilterTabs(bool isDark) {
    final provider = context.watch<AssetProvider>();
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // ── All Assets Tab
          _buildTabItem('All Assets', 'all', IconsaxPlusLinear.grid_1, isDark),
          
          // ── Vertical Divider
          Container(
            height: 20,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: isDark ? Colors.white12 : Colors.black12,
          ),

          // ── Custom Folders
          ...provider.folders.map((folder) => _buildTabItem(
            folder.name, 
            folder.id, 
            IconsaxPlusLinear.folder_2, 
            isDark,
            onLongPress: () => _confirmDeleteFolder(folder),
          )),

          // ── Add Folder Button
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: IconButton(
              onPressed: () => _showCreateFolderDialog(),
              icon: Icon(IconsaxPlusLinear.add_square, 
                size: 22, color: AppColors.primary),
              tooltip: 'New Folder',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, String id, IconData icon, bool isDark, {VoidCallback? onLongPress}) {
    final isSelected = _selectedFolderId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedFolderId = id),
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(30),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : (isDark ? Colors.white10 : Colors.black12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black54)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter folder name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<AssetProvider>().createFolder(controller.text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFolder(AssetFolderModel folder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${folder.name}"?'),
        content: const Text('This will only remove the folder, not the assets inside.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<AssetProvider>().deleteFolder(folder.id);
              if (_selectedFolderId == folder.id) {
                setState(() => _selectedFolderId = 'all');
              }
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Loading skeleton ──────────────────────────────────────────────────────

  Widget _buildLoadingSkeleton() {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: 10,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.1)),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(IconsaxPlusLinear.folder_cross,
              size: 80,
              color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 16),
          Text('No Assets Found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          Text('Upload media or documents to populate the library.',
              style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54)),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  // ── Storage Badge ─────────────────────────────────────────────────────────

  Widget _buildStorageBadge(bool isDark, AssetProvider provider) {
    final usedStr = _formatBytes(provider.totalStorageBytes, 2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.03),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(IconsaxPlusLinear.cloud_change,
                size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Storage Capacity',
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: '$usedStr ',
                    style: TextStyle(
                        color:
                            isDark ? Colors.white : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: '/ 10 GB',
                    style: TextStyle(
                        color: isDark
                            ? Colors.white54
                            : Colors.black54,
                        fontSize: 12),
                  ),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Search box ────────────────────────────────────────────────────────────

  Widget _buildSearchBox(bool isDark) {
    return Container(
      width: ResponsiveBreakpoints.of(context).isMobile ? double.infinity : 300,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: TextField(
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search stored assets…',
          hintStyle: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 13),
          prefixIcon: Icon(IconsaxPlusLinear.search_normal,
              color: isDark ? Colors.white54 : Colors.black54,
              size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDraftsToggle(bool isDark, AssetProvider provider) {
    final draftCount = provider.draftAssets.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _showDrafts = !_showDrafts;
                  // If switching to trash, clear folder filter
                  if (_showDrafts) _selectedFolderId = 'all';
                });
              },
              icon: Icon(
                _showDrafts
                    ? IconsaxPlusLinear.document_favorite
                    : IconsaxPlusLinear.trash,
                color: _showDrafts
                    ? AppColors.success
                    : (isDark ? Colors.white54 : Colors.black54),
              ),
              tooltip: _showDrafts ? 'View Active Assets' : 'View Drafts/Trash',
            ),
            if (draftCount > 0 && !_showDrafts)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      '$draftCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ).animate().scale(delay: 200.ms),
          ],
        ),
        if (_showDrafts && draftCount > 0)
          TextButton.icon(
            onPressed: () => provider.emptyTrash(),
            icon: const Icon(IconsaxPlusLinear.trash, size: 16),
            label: const Text('Empty Trash'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
      ],
    );
  }

  // ── Asset Grid ────────────────────────────────────────────────────────────

  Widget _buildAssetGrid(
    List<AssetModel> paged,
    List<AssetModel> filtered,
    bool isDark,
    AssetProvider provider,
  ) {
    final bp = ResponsiveBreakpoints.of(context);
    int crossAxisCount = 3;
    if (bp.largerThan(MOBILE)) crossAxisCount = 6;
    if (bp.largerThan(TABLET)) crossAxisCount = 8;
    if (bp.largerThan(DESKTOP)) crossAxisCount = 10;

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            cacheExtent: 1200,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: paged.length,
            itemBuilder: (context, index) {
              final asset = paged[index];
              return _AssetCard(
                asset: asset,
                isDark: isDark,
                provider: provider,
                isDraftMode: _showDrafts,
                onShowDetails: () =>
                    _showAssetDetails(context, asset, provider),
              )
                  .animate()
                  .fade(delay: (30 * index).ms)
                  .slideY(begin: 0.08, curve: Curves.easeOutQuart);
            },
          ),
        ),

        // ── Load More button
        if (provider.hasMore(filtered))
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextButton.icon(
              onPressed: () => provider.loadMore(),
              icon: const Icon(IconsaxPlusLinear.arrow_down_2, size: 16),
              label: Text(
                'Load More (${filtered.length - paged.length} remaining)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ),
      ],
    );
  }

  // ── Asset Details popup (AppConfig domain-aware) ─────────────────────────

  void _showAssetDetails(
      BuildContext context, AssetModel asset, AssetProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: asset.name);

    // ✅ Unified Universal Link
    final String liveLink = 'asset://${asset.id}';
    final String sharedLink = AppConfig.instance.sharedLink(asset.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: GlassContainer(
          borderRadius: 24,
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Asset Details',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black)),
                      if (asset.isCompressed)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(IconsaxPlusLinear.flash_1,
                                  size: 12, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                '${asset.compressionSavingPercent}% smaller',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(IconsaxPlusLinear.close_square,
                        color: isDark
                            ? Colors.white54
                            : Colors.black54),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Rename (Locked if deleted)
              IgnorePointer(
                ignoring: asset.isDeleted,
                child: Opacity(
                  opacity: asset.isDeleted ? 0.5 : 1.0,
                  child: _buildDetailField(
                    'Rename Asset ${asset.isDeleted ? "(Locked in Trash)" : ""}',
                    TextField(
                      controller: nameController,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      decoration: _inputDecoration(isDark, 'Enter asset name'),
                      onChanged: (val) =>
                          provider.updateAssetName(asset.id, val),
                    ),
                    isDark,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Asset ID
              _buildDetailField(
                'Asset ID',
                _buildCopyRow(asset.id, isDark,
                    IconsaxPlusLinear.finger_scan),
                isDark,
              ),

              const SizedBox(height: 16),

              // 📂 Folder Assignment (Locked if deleted)
              if (provider.folders.isNotEmpty) ...[
                IgnorePointer(
                  ignoring: asset.isDeleted,
                  child: Opacity(
                    opacity: asset.isDeleted ? 0.5 : 1.0,
                    child: _buildDetailField(
                      'Assign to Folders ${asset.isDeleted ? "(Locked)" : ""}',
                      StatefulBuilder(
                        builder: (ctx, setPopupState) => SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: provider.folders.map((folder) {
                              final isInFolder =
                                  folder.assetIds.contains(asset.id);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(folder.name),
                                  selected: isInFolder,
                                  onSelected: (_) {
                                    provider.toggleAssetInFolder(
                                        asset.id, folder.id);
                                    setPopupState(() {}); // Refresh local UI
                                  },
                                  selectedColor:
                                      AppColors.primary.withValues(alpha: 0.2),
                                  checkmarkColor: AppColors.primary,
                                  labelStyle: TextStyle(
                                    fontSize: 11,
                                    color: isInFolder
                                        ? AppColors.primary
                                        : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                    fontWeight: isInFolder
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      isDark,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Live Link (AppConfig auto-domain)
              _buildDetailField(
                'Live Link  •  ${AppConfig.instance.isLocalhost ? "🟡 Localhost (dev)" : "🟢 Production"}',
                _buildCopyRow(liveLink, isDark, IconsaxPlusLinear.link),
                isDark,
              ),

              const SizedBox(height: 16),

              // Shared Link
              _buildDetailField(
                'Shared Public Link',
                _buildCopyRow(sharedLink, isDark,
                    IconsaxPlusLinear.share),
                isDark,
              ),

              const SizedBox(height: 24),

              // Done button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailField(String label, Widget child, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black54,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildCopyRow(String text, bool isDark, IconData icon) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : Colors.black87,
                        fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: text));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Icon(IconsaxPlusLinear.copy,
                size: 16, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(bool isDark, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          color: isDark ? Colors.white24 : Colors.black26, fontSize: 13),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.black.withValues(alpha: 0.03),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? Colors.white10 : Colors.black12)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? Colors.white10 : Colors.black12)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ── Responsive helper ─────────────────────────────────────────────────────────

class ResponseBreakWrapper {
  static bool isMobile(BuildContext context) =>
      ResponsiveBreakpoints.of(context).isMobile;
}

// ── Asset Card ───────────────────────────────────────────────────────────────

class _AssetCard extends StatelessWidget {
  final AssetModel asset;
  final bool isDark;
  final AssetProvider provider;
  final VoidCallback onShowDetails;
  final bool isDraftMode;

  const _AssetCard({
    required this.asset,
    required this.isDark,
    required this.provider,
    required this.onShowDetails,
    this.isDraftMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = !kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    return GestureDetector(
      onTap: () {
        if (asset.type == AssetType.image) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssetEditorScreen(asset: asset),
            ),
          );
        }
      },
      onLongPress: isDesktop ? null : onShowDetails,
      child: GlassContainer(
        padding: const EdgeInsets.all(0),
        borderRadius: 16,
        border: Border.all(
          color: isDark
              ? Colors.white10
              : Colors.black.withValues(alpha: 0.05),
        ),
        child: Stack(
          children: [
            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Preview
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: _buildPreview(),
                  ),
                ),

                // Footer info
                Container(
                  height: 50,
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  child: Row(
                    children: [
                      Icon(_getIconForType(asset.type),
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              asset.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatBytes(asset.sizeBytes, 1),
                              style: TextStyle(
                                fontSize: 9,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Desktop action buttons
            Positioned(
              top: 6,
              right: 6,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDraftMode) ...[
                    _buildActionBtn(
                      onTap: () => provider.restoreAsset(asset.id),
                      icon: IconsaxPlusLinear.refresh,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 5),
                    _buildActionBtn(
                      onTap: () => provider.permanentDeleteAsset(asset.id),
                      icon: IconsaxPlusLinear.trash,
                      color: AppColors.error,
                    ),
                  ] else ...[
                    if (isDesktop) ...[
                      _buildActionBtn(
                        onTap: onShowDetails,
                        icon: IconsaxPlusLinear.setting_4,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                    ],
                    _buildActionBtn(
                      onTap: () => provider.removeAsset(asset.id),
                      icon: IconsaxPlusLinear.trash,
                      color: AppColors.error,
                    ),
                  ],
                ],
              ),
            ),

            // Compressed badge
            if (asset.isCompressed && asset.compressionSavingPercent > 0)
              Positioned(
                bottom: 50,
                left: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-${asset.compressionSavingPercent}%',
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.88),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6),
          ],
        ),
        child: Icon(icon, size: 10, color: Colors.white),
      ),
    );
  }

  Widget _buildPreview() {
    return EbmImage(
      source: 'asset://${asset.id}',
      fit: BoxFit.cover,
      isThumbnail: true, // Lightweight memory footprint
      errorWidget: _fallback(),
      placeholder: _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      color: isDark
          ? Colors.white.withValues(alpha: 0.02)
          : Colors.black.withValues(alpha: 0.02),
      child: Center(
        child: Icon(
          _getIconForType(asset.type),
          size: 24,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
      ),
    );
  }

  IconData _getIconForType(AssetType type) {
    switch (type) {
      case AssetType.image:
        return IconsaxPlusLinear.gallery;
      case AssetType.document:
        return IconsaxPlusLinear.document_text;
      case AssetType.video:
        return IconsaxPlusLinear.video_square;
      default:
        return IconsaxPlusLinear.document;
    }
  }
}

// ── Global helpers ─────────────────────────────────────────────────────────────

String _formatBytes(int bytes, int decimals) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  var i = (log(bytes) / log(1024)).floor();
  return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
}
