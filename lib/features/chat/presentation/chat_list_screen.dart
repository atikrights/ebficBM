import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../../core/providers/auth_provider.dart';
import 'chat_detail_screen.dart';
import 'chat_settings_screen.dart';
import 'chat_profile_setup_screen.dart';
import 'new_chat_screen.dart';
import '../../../core/theme/colors.dart';
import 'dart:ui';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadSessions();
      // Load initial messages for AI and Self to get last message status
      context.read<ChatProvider>().loadMessages('ai');
      context.read<ChatProvider>().loadMessages('self');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatProvider = context.watch<ChatProvider>();
    final authState = context.watch<AuthProvider>();

    // FORCE Profile Setup if nickname is not set (Just like EBM Central)
    if (authState.chatNickname == null || authState.chatNickname!.isEmpty) {
      return const ChatProfileSetupScreen();
    }
    
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    // Get last messages for official chats
    final aiMsgs = chatProvider.getMessages('ai');
    final selfMsgs = chatProvider.getMessages('self');
    final aiLastMsg = aiMsgs.isNotEmpty ? aiMsgs.last : null;
    final selfLastMsg = selfMsgs.isNotEmpty ? selfMsgs.last : null;

    return Scaffold(
      backgroundColor: Colors.transparent, // Allow layout background to show
      body: RefreshIndicator(
        onRefresh: () async {
          await chatProvider.loadSessions();
          await chatProvider.loadMessages('ai');
          await chatProvider.loadMessages('self');
        },
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              floating: true,
              pinned: true,
              elevation: 0,
              title: Text(
                'Messages',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor, fontSize: 20),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.search_rounded, color: textColor.withOpacity(0.6)),
                  onPressed: () {},
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: textColor.withOpacity(0.6)),
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'settings') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChatSettingsScreen()),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined, color: textColor.withOpacity(0.8), size: 20),
                          const SizedBox(width: 12),
                          Text('Settings', style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildOfficialChatTile(
                    context, 
                    isDark, 
                    textColor,
                    name: 'AI Assistant', 
                    lastMsg: aiLastMsg,
                    defaultSubtitle: 'How can I help you today?', 
                    icon: Icons.auto_awesome, 
                    color: Colors.amber,
                    receiverType: 'ai',
                  ),
                  _buildOfficialChatTile(
                    context, 
                    isDark, 
                    textColor,
                    name: 'Notes (You)', 
                    lastMsg: selfLastMsg,
                    defaultSubtitle: 'Message yourself anything.', 
                    icon: Icons.person_pin_circle_rounded, 
                    color: AppColors.primary,
                    receiverType: 'self',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Divider(color: isDark ? Colors.white10 : Colors.black12),
                  ),
                ],
              ),
            ),
            if (chatProvider.isLoading && chatProvider.sessions.isEmpty)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (chatProvider.sessions.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 60, color: isDark ? Colors.white10 : Colors.black12),
                      const SizedBox(height: 16),
                      Text('No messages yet. Start a new chat!', style: GoogleFonts.outfit(color: textColor.withOpacity(0.3), fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final session = chatProvider.sessions[index];
                    return _buildChatTile(context, session, isDark, textColor);
                  },
                  childCount: chatProvider.sessions.length,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewChatScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_comment_rounded, color: Colors.white),
      ),
    );
  }

  String _formatDateTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final msgDate = DateTime(date.year, date.month, date.day);

      if (msgDate == today) {
        final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
        final minute = date.minute.toString().padLeft(2, '0');
        final period = date.hour >= 12 ? 'PM' : 'AM';
        return "$hour:$minute $period";
      } else if (msgDate == yesterday) {
        return "Yesterday";
      } else if (now.difference(date).inDays < 7) {
        final weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
        return weekdays[date.weekday - 1];
      } else {
        return "${date.day}/${date.month}/${date.year.toString().substring(2)}";
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildOfficialChatTile(
    BuildContext context,
    bool isDark, 
    Color textColor,
    {
    required String name,
    Map<String, dynamic>? lastMsg,
    required String defaultSubtitle,
    required IconData icon,
    required Color color,
    required String receiverType,
  }) {
    final String message = lastMsg?['message'] ?? defaultSubtitle;
    final String time = lastMsg != null ? _formatDateTime(lastMsg['created_at']) : ''; 
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name, 
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)
              ),
            ),
            const SizedBox(width: 8),
            if (time.isNotEmpty)
              Text(
                time,
                style: GoogleFonts.outfit(color: textColor.withOpacity(0.4), fontSize: 10),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            message, 
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(fontSize: 12, color: textColor.withOpacity(0.6))
          ),
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                receiverType: receiverType,
                chatName: name,
                chatColor: color,
              ),
            ),
          );
          if (mounted) {
            context.read<ChatProvider>().loadSessions();
          }
        },
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'read':
        return const Icon(Icons.done_all, size: 16, color: Color(0xFF34B7F1));
      case 'delivered':
        return const Icon(Icons.done_all, size: 16, color: Colors.white38);
      case 'sent':
      default:
        return const Icon(Icons.done, size: 16, color: Colors.white38);
    }
  }

  Widget _buildChatTile(BuildContext context, Map<String, dynamic> session, bool isDark, Color textColor) {
    final name = session['chat_name'] ?? 'Unknown';
    final lastMsg = session['last_message'] ?? 'No messages yet';
    final lastMsgObj = session['last_msg_obj'] ?? {};
    final String status = lastMsgObj['status'] ?? 'sent';
    final bool isMine = lastMsgObj['is_mine'] ?? false;
    final receiverType = session['receiver_type']?.toString() ?? '';
    final color = session['chat_color'] != null ? Color(int.parse(session['chat_color'].toString().replaceAll('#', '0xFF'))) : AppColors.primary;
    final unread = session['unread_count'] ?? 0;
    final timeStr = session['updated_at']?.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: color.withOpacity(0.2),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF0F1117) : Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.outfit(
                        color: textColor,
                        fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatDateTime(timeStr),
                    style: GoogleFonts.outfit(
                      color: unread > 0 ? AppColors.primary : textColor.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    if (isMine)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _buildStatusIcon(status),
                      ),
                    Expanded(
                      child: Text(
                        lastMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: unread > 0 ? textColor : textColor.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (unread > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, spreadRadius: 1),
                          ],
                        ),
                        child: Text(
                          unread.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(
                      receiverType: receiverType,
                      chatName: name,
                      chatColor: color,
                    ),
                  ),
                );
                if (mounted) {
                  context.read<ChatProvider>().loadSessions();
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
