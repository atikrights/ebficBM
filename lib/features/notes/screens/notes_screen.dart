import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ebficBM/features/notes/models/note.dart';
import 'package:ebficBM/features/notes/screens/note_editor_screen.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isSelectionMode = false;
  Set<String> _selectedNoteIds = {};
  
  List<NoteModel> get _allNotes => globalNotes;
  NoteStatus _currentView = NoteStatus.active;
  String _searchQuery = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _initNotes();
  }

  Future<void> _initNotes() async {
    await NoteService.loadNotes();
    setState(() {
      _isLoading = false;
    });
  }

  void _openEditor({NoteModel? note}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          note: note,
          initialStatus: _currentView == NoteStatus.archived ? NoteStatus.active : _currentView,
          onSave: (savedNote) {
            setState(() {
              final index = _allNotes.indexWhere((n) => n.id == savedNote.id);
              if (index != -1) {
                _allNotes[index] = savedNote;
              } else {
                _allNotes.insert(0, savedNote);
              }
            });
            NoteService.saveNotes();
          },
        ),
      ),
    );
  }

  void _updateNoteStatus(String id, NoteStatus newStatus) {
    setState(() {
      final index = _allNotes.indexWhere((n) => n.id == id);
      if (index != -1) {
        _allNotes[index] = _allNotes[index].copyWith(status: newStatus);
        NoteService.saveNotes();
      }
    });
  }

  void _togglePin(String id) {
    setState(() {
      final index = _allNotes.indexWhere((n) => n.id == id);
      if (index != -1) {
        _allNotes[index] = _allNotes[index].copyWith(isPinned: !_allNotes[index].isPinned);
        NoteService.saveNotes();
      }
    });
  }

  List<NoteModel> get _filteredNotes {
    return _allNotes.where((note) {
      final matchesStatus = note.status == _currentView;
      final matchesSearch = note.content.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                           note.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDate = _selectedDate == null || 
                         (note.date.year == _selectedDate!.year && 
                          note.date.month == _selectedDate!.month && 
                          note.date.day == _selectedDate!.day);
      return matchesStatus && matchesSearch && matchesDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    int crossAxisCount = 2;
    if (screenWidth < 500) crossAxisCount = 2; // Enforce smaller boxes on mobile
    else if (screenWidth > 1400) crossAxisCount = 6; // Max columns on ultra wide desktop
    else if (screenWidth > 1100) crossAxisCount = 5;
    else if (screenWidth > 800) crossAxisCount = 4;
    else crossAxisCount = 3;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── ONE LINE HEADER: SEARCH & TABS ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(isMobile ? 12 : 32, isMobile ? 12 : 32, isMobile ? 12 : 32, 24),
              child: _buildOneLineHeader(isMobile, isDark, theme),
            ),
          ),

          // ─── UNIFORM FIXED GRID LAYOUT ─────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 32),
            sliver: _isLoading 
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              : _filteredNotes.isEmpty 
              ? SliverToBoxAdapter(child: _buildEmptyState(isDark, theme))
              : SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 220, // Strict uniform height for small elegant sticky notes
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final note = _filteredNotes[index];
                      return _PremiumNoteCard(
                        note: note,
                        isDark: isDark,
                        theme: theme,
                        isSelectionMode: _isSelectionMode,
                        isSelected: _selectedNoteIds.contains(note.id),
                        onSelect: () {
                          setState(() {
                            if (_selectedNoteIds.contains(note.id)) {
                              _selectedNoteIds.remove(note.id);
                            } else {
                              _selectedNoteIds.add(note.id);
                            }
                          });
                        },
                        onTap: () {
                          if (_isSelectionMode) {
                            setState(() {
                              if (_selectedNoteIds.contains(note.id)) {
                                _selectedNoteIds.remove(note.id);
                              } else {
                                _selectedNoteIds.add(note.id);
                              }
                            });
                            return;
                          }
                          _openEditor(note: note);
                        },
                        onActionTap: () {
                          if (_currentView == NoteStatus.active) {
                            _updateNoteStatus(note.id, NoteStatus.archived);
                          } else if (_currentView == NoteStatus.draft) {
                            _updateNoteStatus(note.id, NoteStatus.active);
                          } else {
                            _updateNoteStatus(note.id, NoteStatus.active);
                          }
                        },
                        onPinTap: () => _togglePin(note.id),
                        currentView: _currentView,
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
                    },
                    childCount: _filteredNotes.length,
                  ),
                ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        backgroundColor: theme.primaryColor,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(IconsaxPlusLinear.edit_2, color: Colors.white, size: 24),
      ).animate().scale(delay: 300.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildOneLineHeader(bool isMobile, bool isDark, ThemeData theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    // isCompact: tablet-size or lower — show icon only
    final bool isCompact = screenWidth < 900;

    return Row(
      children: [
        // ─── SEARCH BAR ───────────────────────────────────────────────────
        Expanded(
          flex: isCompact ? 2 : 3,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06)),
              boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(IconsaxPlusLinear.search_normal, size: 16, color: theme.primaryColor.withOpacity(0.7)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: isCompact ? 'Search...' : 'Search notes...',
                      hintStyle: GoogleFonts.outfit(color: isDark ? Colors.white30 : Colors.black38, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                    child: Icon(Icons.close_rounded, size: 16, color: isDark ? Colors.white38 : Colors.black38),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // ─── TAB PILLS ───────────────────────────────────────────────────
        Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTab(NoteStatus.active, 'Notes', IconsaxPlusLinear.document_text, isCompact, isDark, theme),
              _buildTab(NoteStatus.draft, 'Drafts', IconsaxPlusLinear.document_favorite, isCompact, isDark, theme),
              _buildTab(NoteStatus.archived, 'Archive', IconsaxPlusLinear.archive, isCompact, isDark, theme),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // ─── DATE FILTER ICON ─────────────────────────────────────────────────
        _buildIconBtn(
          IconsaxPlusLinear.calendar_1,
          _selectedDate != null ? 'Clear Date Filter' : 'Filter by Date',
          () async {
            if (_selectedDate != null) {
              setState(() => _selectedDate = null);
              return;
            }
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          isDark,
          theme,
          isActive: _selectedDate != null,
        ),

        // ─── DIVIDER ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(width: 1, height: 22, color: isDark ? Colors.white12 : Colors.black12),
        ),

        // ─── ACTION TOOLBAR ────────────────────────────────────────────────
        if (_isSelectionMode) ...[
          // Selection count badge
          if (!isCompact && _selectedNoteIds.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
              ),
              child: Text(
                '${_selectedNoteIds.length} selected',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: theme.primaryColor),
              ),
            ),
          _buildIconBtn(
            _selectedNoteIds.length == _filteredNotes.length && _filteredNotes.isNotEmpty
                ? IconsaxPlusLinear.minus_square
                : IconsaxPlusLinear.tick_square,
            'Select All',
            () {
              setState(() {
                if (_selectedNoteIds.length == _filteredNotes.length) {
                  _selectedNoteIds.clear();
                } else {
                  _selectedNoteIds.addAll(_filteredNotes.map((e) => e.id));
                }
              });
            },
            isDark, theme,
            isActive: _selectedNoteIds.length == _filteredNotes.length && _filteredNotes.isNotEmpty,
          ),
          const SizedBox(width: 4),
          _buildIconBtn(
            IconsaxPlusLinear.document_upload,
            'Export Selected',
            () async {
              if (_selectedNoteIds.isEmpty) return;
              final selected = _filteredNotes.where((n) => _selectedNoteIds.contains(n.id)).toList();
              bool success = await NoteService.exportNotes(notesToExport: selected);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${selected.length} notes exported')));
                setState(() { _isSelectionMode = false; _selectedNoteIds.clear(); });
              }
            },
            isDark, theme,
          ),
          const SizedBox(width: 4),
          _buildIconBtn(
            _currentView == NoteStatus.archived ? IconsaxPlusLinear.document_text : IconsaxPlusLinear.archive,
            _currentView == NoteStatus.archived ? 'Restore Selected' : 'Archive Selected',
            () {
              if (_selectedNoteIds.isEmpty) return;
              setState(() {
                final newStatus = _currentView == NoteStatus.archived ? NoteStatus.active : NoteStatus.archived;
                for (var id in _selectedNoteIds) {
                  final idx = globalNotes.indexWhere((n) => n.id == id);
                  if (idx != -1) globalNotes[idx] = globalNotes[idx].copyWith(status: newStatus);
                }
                NoteService.saveNotes();
                _isSelectionMode = false;
                _selectedNoteIds.clear();
              });
            },
            isDark, theme,
          ),
          const SizedBox(width: 4),
          _buildIconBtn(
            IconsaxPlusLinear.trash,
            'Delete Selected',
            () {
              if (_selectedNoteIds.isEmpty) return;
              setState(() {
                globalNotes.removeWhere((n) => _selectedNoteIds.contains(n.id));
                NoteService.saveNotes();
                _isSelectionMode = false;
                _selectedNoteIds.clear();
              });
            },
            isDark, theme,
          ),
          const SizedBox(width: 4),
          _buildIconBtn(
            IconsaxPlusLinear.close_circle,
            'Cancel',
            () => setState(() { _isSelectionMode = false; _selectedNoteIds.clear(); }),
            isDark, theme,
          ),
        ] else ...[
          _buildIconBtn(
            IconsaxPlusLinear.task_square,
            'Multi-Select',
            () => setState(() { _isSelectionMode = true; _selectedNoteIds.clear(); }),
            isDark, theme,
          ),
          const SizedBox(width: 4),
          _buildIconBtn(
            IconsaxPlusLinear.document_upload,
            'Export All',
            () async {
              bool success = await NoteService.exportNotes();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes exported!')));
              }
            },
            isDark, theme,
          ),
          const SizedBox(width: 4),
          _buildIconBtn(
            IconsaxPlusLinear.document_download,
            'Import Backup',
            () async {
              bool success = await NoteService.importNotes();
              if (success && context.mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes imported!')));
              }
            },
            isDark, theme,
          ),
        ],
      ],
    );
  }

  // Clean square icon button used throughout the toolbar
  Widget _buildIconBtn(IconData icon, String tooltip, VoidCallback onTap, bool isDark, ThemeData theme, {bool isActive = false}) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: isActive
                ? theme.primaryColor.withOpacity(0.15)
                : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? theme.primaryColor.withOpacity(0.4)
                  : (isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06)),
            ),
            boxShadow: [if (!isDark && !isActive) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Icon(icon, size: 18, color: isActive ? theme.primaryColor : (isDark ? Colors.white54 : Colors.black45)),
        ),
      ),
    );
  }

  Widget _buildTab(NoteStatus status, String label, IconData icon, bool isCompact, bool isDark, ThemeData theme) {
    final isSelected = _currentView == status;
    return GestureDetector(
      onTap: () => setState(() => _currentView = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 14),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected && !isDark
              ? [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black54)),
            if (!isCompact) ...[
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.02) : theme.primaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _currentView == NoteStatus.archived ? IconsaxPlusLinear.archive :
                _currentView == NoteStatus.draft ? IconsaxPlusLinear.document_favorite :
                IconsaxPlusLinear.document_text, 
                size: 64, color: isDark ? Colors.white24 : theme.primaryColor.withOpacity(0.4)
              ),
            ),
            const SizedBox(height: 24),
            Text(_getEmptyTitle(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87, fontSize: 18)),
            const SizedBox(height: 8),
            Text(_getEmptySubtitle(), style: GoogleFonts.outfit(color: isDark ? Colors.white38 : Colors.black45, fontSize: 15)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  String _getEmptyTitle() {
    if (_currentView == NoteStatus.archived) return 'Archive is empty';
    if (_currentView == NoteStatus.draft) return 'No drafts yet';
    return 'No notes here yet';
  }

  String _getEmptySubtitle() {
    if (_currentView == NoteStatus.archived) return 'Archived notes will appear here.';
    if (_currentView == NoteStatus.draft) return 'Unfinished notes will be saved as drafts.';
    return 'Start capturing your ideas and tasks.';
  }
}

class _PremiumNoteCard extends StatefulWidget {
  final NoteModel note;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onActionTap;
  final VoidCallback onPinTap;
  final NoteStatus currentView;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelect;

  const _PremiumNoteCard({
    required this.note,
    required this.isDark,
    required this.theme,
    required this.onTap,
    required this.onActionTap,
    required this.onPinTap,
    required this.currentView,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  State<_PremiumNoteCard> createState() => _PremiumNoteCardState();
}

class _PremiumNoteCardState extends State<_PremiumNoteCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = _isHovered || widget.isSelected;

    final Color cardColor = widget.isDark
        ? const Color(0xFF1A1B2E) // Deep elegant dark box
        : Colors.white; // Pure white box

    final Color borderColor = widget.isSelected
        ? widget.theme.primaryColor
        : widget.isDark
            ? widget.note.color.withOpacity(0.12)
            : widget.note.color.withOpacity(0.1);

    final Color textColor = widget.isDark ? Colors.white : Colors.black87;
    final Color subTextColor = widget.isDark ? Colors.white60 : Colors.black54;
    final Color iconColor = widget.isDark ? Colors.white38 : Colors.black38;

    final noteAccent = widget.note.color == Colors.white || widget.note.color.value == 0xFFFFFFFF
        ? widget.theme.primaryColor
        : widget.note.color;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.isSelectionMode ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.isSelectionMode ? null : widget.onSelect,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ─── AMBIENT BACKLIGHT GLOW ────────────────────────────────────
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: isActive ? 1.0 : 0.0,
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (_, __) => ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: SweepGradient(
                          center: FractionalOffset.center,
                          colors: [
                            noteAccent.withOpacity(0.35),
                            widget.theme.primaryColor.withOpacity(0.25),
                            Colors.purpleAccent.withOpacity(0.2),
                            noteAccent.withOpacity(0.35),
                          ],
                          stops: const [0.0, 0.33, 0.66, 1.0],
                          transform: GradientRotation(_glowController.value * 2 * 3.1415926535),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ─── MAIN CARD BODY ────────────────────────────────────────────
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: widget.isSelected ? 2.0 : 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(widget.isDark ? 0.28 : 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(widget.isDark ? 0.35 : 0.04),
                      blurRadius: isActive ? 28 : 10,
                      spreadRadius: isActive ? 2 : 0,
                      offset: Offset(0, isActive ? 10 : 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Content ──────────────────────────────────────
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.note.title.isNotEmpty)
                                    Expanded(
                                      child: Text(
                                        widget.note.title,
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14, color: textColor, height: 1.2),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  const SizedBox(width: 6),
                                  if (widget.currentView == NoteStatus.active)
                                    AnimatedOpacity(
                                      opacity: widget.note.isPinned || _isHovered ? 1.0 : 0.4,
                                      duration: const Duration(milliseconds: 200),
                                      child: GestureDetector(
                                        onTap: widget.isSelectionMode ? null : widget.onPinTap,
                                        child: Icon(
                                          widget.note.isPinned ? IconsaxPlusBold.location : IconsaxPlusLinear.location,
                                          size: 15,
                                          color: widget.note.isPinned ? Colors.redAccent : iconColor,
                                        ),
                                      ),
                                    ),
                                  if (widget.currentView != NoteStatus.active)
                                    Container(
                                      margin: const EdgeInsets.only(left: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: widget.isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        widget.currentView == NoteStatus.draft ? 'DRAFT' : 'ARCHIVED',
                                        style: GoogleFonts.outfit(fontSize: 7, fontWeight: FontWeight.w800, color: textColor.withOpacity(0.5), letterSpacing: 0.5),
                                      ),
                                    ),
                                ],
                              ),
                              if (widget.note.title.isNotEmpty) const SizedBox(height: 7),
                              Expanded(
                                child: Text(
                                  widget.note.content,
                                  style: GoogleFonts.outfit(fontSize: 12.5, height: 1.55, color: subTextColor, fontWeight: FontWeight.w400),
                                  maxLines: 6,
                                  overflow: TextOverflow.fade,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Footer ────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.isDark ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.03),
                          border: Border(top: BorderSide(color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06))),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 22,
                              width: 22,
                              decoration: BoxDecoration(
                                color: widget.theme.primaryColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: widget.theme.primaryColor.withOpacity(0.25)),
                              ),
                              child: Center(
                                child: Text(
                                  (widget.note.author.isNotEmpty ? widget.note.author[0] : 'U').toUpperCase(),
                                  style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.bold, color: widget.theme.primaryColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(DateFormat('MMM dd, yyyy').format(widget.note.date), style: GoogleFonts.outfit(fontSize: 9.5, color: textColor.withOpacity(0.8), fontWeight: FontWeight.w600)),
                                  Text(DateFormat('hh:mm a').format(widget.note.date), style: GoogleFonts.outfit(fontSize: 8.5, color: iconColor, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            if (widget.isSelectionMode)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 22,
                                width: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.isSelected ? widget.theme.primaryColor : Colors.transparent,
                                  border: Border.all(color: widget.isSelected ? widget.theme.primaryColor : iconColor, width: 1.5),
                                ),
                                child: widget.isSelected ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
                              )
                            else
                              AnimatedOpacity(
                                opacity: _isHovered || MediaQuery.of(context).size.width < 600 ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: GestureDetector(
                                  onTap: widget.onActionTap,
                                  child: Container(
                                    height: 26,
                                    width: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: widget.isDark ? Colors.white10 : Colors.white.withOpacity(0.8),
                                      border: Border.all(color: widget.isDark ? Colors.white12 : Colors.black12),
                                    ),
                                    child: Icon(
                                      widget.currentView == NoteStatus.active ? IconsaxPlusLinear.archive : IconsaxPlusLinear.refresh,
                                      size: 12,
                                      color: textColor.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // ── Bottom Color Flow Bar ─────────────────────────
                      AnimatedBuilder(
                        animation: _glowController,
                        builder: (_, __) => Container(
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(15),
                              bottomRight: Radius.circular(15),
                            ),
                            gradient: LinearGradient(
                              colors: [
                                noteAccent.withOpacity(isActive ? 0.9 : 0.45),
                                widget.theme.primaryColor.withOpacity(isActive ? 0.85 : 0.35),
                                Colors.purpleAccent.withOpacity(isActive ? 0.8 : 0.3),
                                noteAccent.withOpacity(isActive ? 0.9 : 0.45),
                              ],
                              stops: [
                                0.0,
                                (_glowController.value).clamp(0.1, 0.45),
                                (_glowController.value + 0.3).clamp(0.5, 0.9),
                                1.0,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── SELECTION RING ────────────────────────────────────────────
            if (widget.isSelected)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: widget.theme.primaryColor.withOpacity(0.5), width: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
