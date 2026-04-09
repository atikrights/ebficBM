import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

enum NoteStatus { active, archived, draft }

class NoteModel {
  final String id;
  final String title;
  final String content;
  final Color color;
  final DateTime date;
  final bool isPinned;
  final NoteStatus status;
  final String author;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.color,
    required this.date,
    this.isPinned = false,
    this.status = NoteStatus.active,
    this.author = 'Unknown',
  });

  NoteModel copyWith({NoteStatus? status, bool? isPinned, String? author, String? title, String? content, Color? color, DateTime? date}) {
    return NoteModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      date: date ?? this.date,
      isPinned: isPinned ?? this.isPinned,
      status: status ?? this.status,
      author: author ?? this.author,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'color': color.value,
      'date': date.toIso8601String(),
      'isPinned': isPinned,
      'status': status.index,
      'author': author,
    };
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] ?? UniqueKey().toString(),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      color: Color(json['color'] ?? 0xFFFFFFFF),
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      isPinned: json['isPinned'] ?? false,
      status: NoteStatus.values.elementAt(json['status'] ?? 0),
      author: json['author'] ?? 'Unknown',
    );
  }
}

// Google Keep-like pastel color palette
final List<Color> keepColors = [
  const Color(0xFFFFFFFF), // Default White
  const Color(0xFFF28B82), // Red
  const Color(0xFFFBBC04), // Orange/Yellow
  const Color(0xFFFFF475), // Yellow
  const Color(0xFFCCFF90), // Green
  const Color(0xFFA7FFEB), // Teal
  const Color(0xFFCBF0F8), // Blue
  const Color(0xFFAFCBEE), // Dark Blue
  const Color(0xFFD7AEFB), // Purple
  const Color(0xFFFDCFE8), // Pink
  const Color(0xFFE6C9A8), // Brown
  const Color(0xFFE8EAED), // Gray
];

List<NoteModel> globalNotes = [
  NoteModel(
    id: '1',
    title: 'Project Strategy',
    content: 'Focus on implementing the new admin dashboard with real-time analytics. Ensure the UI is dynamic.',
    color: const Color(0xFFFFF475),
    date: DateTime.now(),
    isPinned: true,
    author: 'Admin Office',
  ),
];

class NoteService {
  static const String _prefsKey = 'saved_notes_data';

  static Future<void> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notesJson = prefs.getString(_prefsKey);
    if (notesJson != null && notesJson.isNotEmpty) {
      final List<dynamic> decodedList = jsonDecode(notesJson);
      globalNotes = decodedList.map((e) => NoteModel.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  static Future<void> saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(globalNotes.map((n) => n.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  static Future<bool> exportNotes({List<NoteModel>? notesToExport}) async {
    try {
      final listToExport = notesToExport ?? globalNotes;
      final String encoded = jsonEncode(listToExport.map((n) => n.toJson()).toList());
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Notes',
        fileName: 'ebfic_notes_backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile != null) {
        final File file = File(outputFile);
        await file.writeAsString(encoded);
        return true;
      }
    } catch (e) {
      debugPrint('Export Error: \$e');
    }
    return false;
  }

  static Future<bool> importNotes() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final File file = File(result.files.single.path!);
        final String content = await file.readAsString();
        final List<dynamic> decodedList = jsonDecode(content);
        final importedNotes = decodedList.map((e) => NoteModel.fromJson(e as Map<String, dynamic>)).toList();
        
        // Merge without duplicates based on ID
        for (var imported in importedNotes) {
          final index = globalNotes.indexWhere((n) => n.id == imported.id);
          if (index != -1) {
            globalNotes[index] = imported;
          } else {
            globalNotes.add(imported);
          }
        }
        await saveNotes();
        return true;
      }
    } catch (e) {
      debugPrint('Import Error: \$e');
    }
    return false;
  }
}
