import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../../core/theme/colors.dart';

class ChatDetailScreen extends StatefulWidget {
  final String receiverType;
  final String chatName;
  final Color chatColor;

  const ChatDetailScreen({
    super.key,
    required this.receiverType,
    required this.chatName,
    required this.chatColor,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChatProvider>();
      provider.setActiveChat(widget.receiverType);
      provider.loadMessages(widget.receiverType);
    });
  }

  @override
  void dispose() {
    // We can't use context.read here easily if the widget is already being disposed in some cases,
    // but typically it works if the provider is higher in the tree.
    try {
      context.read<ChatProvider>().clearActiveChat();
    } catch (e) {}
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    // Immediate scroll to show the optimistic message added by the provider
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      await context.read<ChatProvider>().sendMessage(widget.receiverType, text);
      // Final scroll after server confirmation
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (mounted) {
        _messageController.text = text; // Restore text on failure
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.redAccent)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatProvider = context.watch<ChatProvider>();
    final messages = chatProvider.getMessages(widget.receiverType);

    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: widget.chatColor.withOpacity(0.2),
              child: Text(
                widget.chatName[0].toUpperCase(),
                style: GoogleFonts.outfit(color: widget.chatColor, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatName,
                    style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    'Online',
                    style: GoogleFonts.outfit(color: AppColors.success, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.videocam_outlined, color: textColor.withOpacity(0.6)), onPressed: () {}),
          IconButton(icon: Icon(Icons.call_outlined, color: textColor.withOpacity(0.6)), onPressed: () {}),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textColor.withOpacity(0.6)),
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            onSelected: (value) {
              if (value == 'clear') {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clear chat coming soon')));
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, size: 18, color: textColor.withOpacity(0.8)),
                    const SizedBox(width: 10),
                    Text('Clear Chat', style: GoogleFonts.outfit(fontSize: 13, color: textColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Column(
                  children: [
                    if (_shouldShowDateHeader(messages, index))
                      _buildDateHeader(_getDateHeader(msg['created_at'])),
                    _buildMessageBubble(msg, isDark, textColor),
                  ],
                );
              },
            ),
          ),
          _buildInputArea(isDark, textColor),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isDark, Color textColor) {
    final bool isMe = msg['isMe'] == true;
    final String status = msg['status'] ?? 'sent';
    final String time = _formatMessageTime(msg['created_at']);
    
    final bubbleColor = isMe 
      ? AppColors.primary 
      : (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final msgTextColor = isMe ? Colors.white : (isDark ? Colors.white.withOpacity(0.9) : Colors.black87);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: (status == 'failed' && isMe) 
          ? () => context.read<ChatProvider>().resendMessage(widget.receiverType, msg['id'])
          : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8, top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            border: status == 'failed' ? Border.all(color: Colors.redAccent.withOpacity(0.5)) : null,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                msg['message'] ?? '',
                style: GoogleFonts.outfit(color: msgTextColor, fontSize: 13.5, height: 1.3),
              ),
              if (status == 'failed')
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text('Tap to retry', style: TextStyle(color: isMe ? Colors.white70 : Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (time.isNotEmpty)
                    Text(
                      time,
                      style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 9),
                    ),
                  if (isMe) ...[
                    const SizedBox(width: 5),
                    _buildStatusIcon(status),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'sending':
        return const Icon(Icons.access_time, size: 10, color: Colors.white70);
      case 'failed':
        return const Icon(Icons.error_outline, size: 13, color: Colors.redAccent);
      case 'read':
        return const Icon(Icons.done_all, size: 13, color: Colors.cyanAccent);
      case 'delivered':
        return const Icon(Icons.done_all, size: 13, color: Colors.white70);
      case 'sent':
      default:
        return const Icon(Icons.done, size: 13, color: Colors.white70);
    }
  }

  String _formatMessageTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return "$hour:$minute $period";
    } catch (e) {
      return '';
    }
  }

  Widget _buildDateHeader(String dateStr) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          dateStr,
          style: GoogleFonts.outfit(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  bool _shouldShowDateHeader(List<Map<String, dynamic>> messages, int index) {
    if (index == 0) return true;
    final curr = messages[index]['created_at'];
    final prev = messages[index - 1]['created_at'];
    if (curr == null || prev == null) return false;
    try {
      final d1 = DateTime.parse(curr).toLocal();
      final d2 = DateTime.parse(prev).toLocal();
      return d1.year != d2.year || d1.month != d2.month || d1.day != d2.day;
    } catch (e) { return false; }
  }

  String _getDateHeader(String? timestamp) {
    if (timestamp == null) return 'Messages';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final msgDate = DateTime(date.year, date.month, date.day);
      if (msgDate == today) return "Today";
      if (msgDate == yesterday) return "Yesterday";
      return "${date.day} ${_getMonthName(date.month)} ${date.year}";
    } catch (e) { return ''; }
  }

  String _getMonthName(int month) {
    const names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return names[month - 1];
  }

  Widget _buildInputArea(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightSurface,
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary), onPressed: () {}),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.outfit(color: textColor, fontSize: 13),
                decoration: const InputDecoration(hintText: 'Message...', border: InputBorder.none),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              height: 48,
              width: 48,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
