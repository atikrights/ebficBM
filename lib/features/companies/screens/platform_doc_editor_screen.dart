import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:ebficbm/core/theme/colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PlatformDocEditorScreen extends StatefulWidget {
  final String platformTitle;
  final String initialContent;
  final void Function(String content) onSave;

  const PlatformDocEditorScreen({
    super.key,
    required this.platformTitle,
    required this.initialContent,
    required this.onSave,
  });

  @override
  State<PlatformDocEditorScreen> createState() =>
      _PlatformDocEditorScreenState();
}

class _PlatformDocEditorScreenState extends State<PlatformDocEditorScreen> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasChanges = false;
  bool _saving = false;
  int _wordCount = 0;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
    _focusNode = FocusNode();
    _updateCounts(widget.initialContent);
    _controller.addListener(() {
      final text = _controller.text;
      _updateCounts(text);
      if (!_hasChanges) setState(() => _hasChanges = true);
    });
  }

  void _updateCounts(String text) {
    final words = text.trim().isEmpty
        ? 0
        : text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    setState(() {
      _wordCount = words;
      _charCount = text.length;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 300));
    widget.onSave(_controller.text);
    if (mounted) {
      setState(() {
        _saving = false;
        _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(IconsaxPlusLinear.tick_circle,
                  color: Colors.white, size: 16),
              const SizedBox(width: 10),
              Text('Document saved for "${widget.platformTitle}"'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(IconsaxPlusLinear.info_circle,
                  color: AppColors.warning, size: 20),
              const SizedBox(width: 10),
              Text('Unsaved Changes',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 16)),
            ],
          ),
          content: Text(
            'You have unsaved changes. Leave without saving?',
            style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Stay',
                  style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Discard',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx, false);
                await _save();
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save & Exit',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Full width on all devices as requested
    final double contentMaxWidth = double.infinity;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF111318) : const Color(0xFFF8F9FB),
        appBar: _buildAppBar(isDark, isMobile),
        body: Column(
          children: [
            // ── Toolbar strip ───────────────────────────────────────────────
            _buildToolbar(isDark),
            // ── Editor body ─────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 32,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Document title
                        Text(
                          widget.platformTitle,
                          style: TextStyle(
                            fontSize: isMobile ? 22 : 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ).animate().fadeIn(duration: 300.ms),
                        const SizedBox(height: 4),
                        Text(
                          'Platform Documentation',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Divider(
                            color:
                                isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.07),
                            height: 1),
                        const SizedBox(height: 24),

                        // ── Main text editor ─────────────────────────────────
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.02)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.06),
                            ),
                            boxShadow: isDark
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                          ),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            maxLines: null,
                            minLines: 30,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 15,
                              color: isDark ? Colors.white.withOpacity(0.87) : Colors.black87,
                              height: 1.8,
                              fontFamily: 'Georgia',
                              letterSpacing: 0.1,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Start writing your documentation here...\n\nDescribe this platform, its purpose, API endpoints, usage guidelines, or any other details relevant to your team.',
                              hintStyle: TextStyle(
                                fontSize: isMobile ? 14 : 15,
                                color:
                                    isDark ? Colors.white24 : Colors.black26,
                                height: 1.8,
                                fontStyle: FontStyle.italic,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(isMobile ? 16 : 24),
                            ),
                          ),
                        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // ── Status bar ──────────────────────────────────────────────────
            _buildStatusBar(isDark, isMobile),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, bool isMobile) {
    return AppBar(
      backgroundColor:
          isDark ? const Color(0xFF161A22) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () async {
          if (_hasChanges) {
            final shouldPop = await _onWillPop();
            if (shouldPop && mounted) Navigator.pop(context);
          } else {
            Navigator.pop(context);
          }
        },
        icon: Icon(
          IconsaxPlusLinear.arrow_left,
          color: isDark ? Colors.white70 : Colors.black54,
          size: 20,
        ),
        tooltip: 'Back',
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(IconsaxPlusLinear.document_text_1,
                        size: 12, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(
                      'DOC',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  widget.platformTitle,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Save indicator
        if (_hasChanges)
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Unsaved',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.warning,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().fadeIn(duration: 200.ms),

        // Save button
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.5),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(IconsaxPlusLinear.tick_circle,
                    size: isMobile ? 14 : 16),
            label: Text(
              _saving ? 'Saving...' : 'Save',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.07),
        ),
      ),
    );
  }

  Widget _buildToolbar(bool isDark) {
    final btnColor = isDark ? Colors.white54 : Colors.black45;
    final toolbarBg = isDark ? const Color(0xFF161A22) : Colors.white;

    return Container(
      height: 44,
      color: toolbarBg,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _toolbarBtn(
              IconsaxPlusLinear.text, 'Bold', btnColor, () {
            _insertAround('**', '**');
          }),
          _toolbarBtn(
              IconsaxPlusLinear.text, 'Italic', btnColor, () {
            _insertAround('_', '_');
          }),
          _toolbarDivider(isDark),
          _toolbarBtn(
              IconsaxPlusLinear.document_text, 'Heading', btnColor, () {
            _insertAtLineStart('## ');
          }),
          _toolbarBtn(
              IconsaxPlusLinear.element_3, 'List', btnColor, () {
            _insertAtLineStart('- ');
          }),
          _toolbarBtn(
              IconsaxPlusLinear.link, 'Link', btnColor, () {
            _insertText('[text](url)');
          }),
          _toolbarDivider(isDark),
          _toolbarBtn(
              IconsaxPlusLinear.refresh, 'Clear', btnColor, () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) {
                final dark =
                    Theme.of(ctx).brightness == Brightness.dark;
                return AlertDialog(
                  backgroundColor: dark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Text('Clear document?',
                      style: TextStyle(
                          color: dark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold)),
                  content: Text(
                      'This will erase all content. Continue?',
                      style: TextStyle(
                          color: dark ? Colors.white54 : Colors.black54,
                          fontSize: 13)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('Cancel',
                            style: TextStyle(
                                color: dark
                                    ? Colors.white54
                                    : Colors.black45))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10))),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Clear'),
                    ),
                  ],
                );
              },
            );
            if (confirm == true) _controller.clear();
          }),
          const Spacer(),
          // Word count chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_wordCount words',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbarBtn(
      IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _toolbarDivider(bool isDark) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: isDark ? Colors.white12 : Colors.black12,
    );
  }

  void _insertAround(String before, String after) {
    final selection = _controller.selection;
    if (!selection.isValid) return;
    final text = _controller.text;
    final selected = selection.textInside(text);
    final replacement = '$before$selected$after';
    _controller.value = _controller.value.replaced(
      selection,
      replacement,
    );
  }

  void _insertAtLineStart(String prefix) {
    final sel = _controller.selection;
    if (!sel.isValid) return;
    final text = _controller.text;
    final lineStart = text.lastIndexOf('\n', sel.start - 1) + 1;
    final newText = text.substring(0, lineStart) +
        prefix +
        text.substring(lineStart);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
          offset: sel.start + prefix.length),
    );
  }

  void _insertText(String snippet) {
    final sel = _controller.selection;
    if (!sel.isValid) return;
    _controller.value = _controller.value.replaced(sel, snippet);
  }

  Widget _buildStatusBar(bool isDark, bool isMobile) {
    return Container(
      height: 32,
      color: isDark
          ? const Color(0xFF161A22)
          : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Divider(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.07)),
          Icon(IconsaxPlusLinear.document_text,
              size: 11,
              color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(width: 6),
          Text(
            '${widget.platformTitle} · $_wordCount words · $_charCount chars',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white24 : Colors.black38,
            ),
          ),
          const Spacer(),
          if (_hasChanges)
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Modified',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.warning,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Saved',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white24 : Colors.black38,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
