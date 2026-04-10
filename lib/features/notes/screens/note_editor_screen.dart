import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ebficBM/features/notes/models/note.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;
  final NoteStatus? initialStatus;
  final Function(NoteModel) onSave;

  const NoteEditorScreen({super.key, this.note, this.initialStatus, required this.onSave});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late Color _selectedColor;
  late DateTime _lastEdited;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _selectedColor = widget.note?.color ?? keepColors[0];
    _lastEdited = widget.note?.date ?? DateTime.now();

    // Add listeners to auto-update word/char counts and modified time
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _lastEdited = DateTime.now();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _handleSaveWithStatus(NoteStatus status) {
    if (_contentController.text.trim().isEmpty && _titleController.text.trim().isEmpty) {
      Navigator.pop(context);
      return;
    }

    final newNote = NoteModel(
      id: widget.note?.id ?? DateTime.now().toString(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      color: _selectedColor,
      date: _lastEdited,
      status: status,
    );

    widget.onSave(newNote);
    Navigator.pop(context);
  }

  void _handleSave() {
    _handleSaveWithStatus(widget.note?.status ?? widget.initialStatus ?? NoteStatus.active);
  }

  int get _wordCount {
    final text = _contentController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  int get _charCount {
    return _contentController.text.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    // The entire canvas takes the subtle tint of the selected color.
    // Extremely light tint for Light Mode, very deep subtle tint for Dark mode.
    final backgroundColor = isDark 
        ? const Color(0xFF0F0F1A) // Pure elegant dark background
        : Colors.white; // Clean pure white background

    return Scaffold(
      backgroundColor: backgroundColor,
      // Extends body behind app bar to make scroll fade effect look amazing
      extendBodyBehindAppBar: true, 
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: isDark ? const Color(0xFF0F0F1A).withOpacity(0.6) : Colors.white.withOpacity(0.6),
              elevation: 0,
              centerTitle: true,
              leadingWidth: 80,
              leading: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 18),
                  ),
                  onPressed: _handleSave,
                  tooltip: 'Save & Go Back',
                ),
              ),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.note == null ? 'Drafting New Note' : 'Editing Note',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Last edited: ${DateFormat('hh:mm a').format(_lastEdited)}',
                    style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Done', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 6),
                        const Icon(IconsaxPlusLinear.tick_circle, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // ─── MAIN EDITOR CANVAS ──────────────────────────────────────────────────
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              isMobile ? 24 : 64, 
              120, // push down below appbar
              isMobile ? 24 : 64, 
              160  // extreme padding at the bottom so text avoids toolbar
            ),
            children: [
                  // TITLE FIELD
                  TextField(
                    controller: _titleController,
                    maxLines: null,
                    textInputAction: TextInputAction.next,
                    style: GoogleFonts.outfit(
                      fontSize: isMobile ? 32 : 46, 
                      fontWeight: FontWeight.w900, 
                      height: 1.2,
                      color: isDark ? Colors.white : const Color(0xFF1A1A24)
                    ),
                    decoration: InputDecoration(
                      hintText: 'Note Title',
                      hintStyle: GoogleFonts.outfit(color: isDark ? Colors.white24 : Colors.black26),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
                  
                  const SizedBox(height: 16),
                  
                  // DIVIDER WITH STATS
                  Row(
                    children: [
                      Container(
                        height: 2,
                        width: 40,
                        decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(2)),
                      ),
                      const Spacer(),
                      Text(
                        '$_wordCount words  •  $_charCount chars',
                        style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms),
                  
                  const SizedBox(height: 32),
                  
                  // CONTENT FIELD
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    autofocus: widget.note == null,
                    style: GoogleFonts.outfit(
                      fontSize: isMobile ? 18 : 20, 
                      height: 1.8, 
                      color: isDark ? Colors.white.withOpacity(0.85) : Colors.black87.withOpacity(0.8),
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Start writing your Masterpiece...',
                      hintStyle: GoogleFonts.outfit(color: isDark ? Colors.white12 : Colors.black12),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
            ],
          ),
          
          // ─── GLASSMORPHIC MAC-STYLE DOCK (TOOLBAR) ──────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildMacStyleDock(isDark, theme, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildMacStyleDock(bool isDark, ThemeData theme, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.15) : Colors.white),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.08), blurRadius: 30, offset: const Offset(0, 10)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Hugs content perfectly like Mac Dock
              children: [
                _buildDockButton(
                  icon: IconsaxPlusLinear.color_swatch, 
                  tooltip: 'Change Note Color',
                  onTap: () => _showColorPicker(isDark, theme), 
                  isDark: isDark, 
                  isActive: true, 
                  activeColor: _selectedColor
                ),
                _buildVerticalDivider(isDark),
                _buildDockButton(icon: IconsaxPlusLinear.archive, tooltip: 'Archive', onTap: () => _handleSaveWithStatus(NoteStatus.archived), isDark: isDark),
                _buildDockButton(icon: IconsaxPlusLinear.document_favorite, tooltip: 'Make Draft', onTap: () => _handleSaveWithStatus(NoteStatus.draft), isDark: isDark),
                _buildDockButton(icon: IconsaxPlusLinear.text_block, tooltip: 'Formatting Options', onTap: () {}, isDark: isDark),
                _buildVerticalDivider(isDark),
                _buildDockButton(
                  icon: IconsaxPlusLinear.trash, 
                  tooltip: 'Delete Note',
                  onTap: () => Navigator.pop(context), 
                  isDark: isDark, 
                  hoverColor: Colors.redAccent
                ),
              ],
            ),
          ),
        ),
      ).animate().slideY(begin: 1.5, duration: 800.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isDark ? Colors.white24 : Colors.black12,
    );
  }

  Widget _buildDockButton({
    required IconData icon, 
    required VoidCallback onTap, 
    required bool isDark, 
    required String tooltip,
    bool isActive = false, 
    Color? activeColor, 
    Color? hoverColor
  }) {
    return Tooltip(
      message: tooltip,
      textStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 12),
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          hoverColor: hoverColor?.withOpacity(0.1) ?? (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          highlightColor: Colors.transparent,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? activeColor?.withOpacity(isDark ? 0.3 : 0.2) : Colors.transparent,
            ),
            child: Icon(
              icon, 
              color: isActive 
                  ? (isDark ? activeColor : activeColor?.withOpacity(0.9)) 
                  : (hoverColor ?? (isDark ? Colors.white70 : Colors.black54)), 
              size: 22
            ),
          ),
        ),
      ),
    );
  }

  void _showColorPicker(bool isDark, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 180,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16161E).withOpacity(0.9) : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            children: [
              Container(width: 48, height: 6, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(10))),
              const Spacer(),
              Text('Customize Note Vibe', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white70 : Colors.black87)),
              const Spacer(),
              SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: keepColors.length,
                  itemBuilder: (context, index) {
                    final color = keepColors[index];
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedColor = color);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDark ? color.withOpacity(0.3) : color,
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? theme.primaryColor : Colors.transparent, width: 3),
                          boxShadow: [
                            if (isSelected) BoxShadow(color: theme.primaryColor.withOpacity(0.4), blurRadius: 10),
                          ],
                        ),
                        child: isSelected ? Icon(Icons.check_rounded, size: 20, color: isDark ? Colors.white : Colors.black87) : null,
                      ),
                    );
                  },
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
