import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../backend/backend.dart'; // ← correct path: lib/backend/backend.dart

// ═══════════════════════════════════════════════════════════════════
//  MESSAGES PAGE  (conversation list)
// ═══════════════════════════════════════════════════════════════════
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  late final String myUid;
  bool _authError = false;

  @override
  void initState() {
    super.initState();
    try {
      myUid = BackendService.currentUid;
    } catch (_) {
      _authError = true;
      myUid = '';
    }
  }

  void _openNewMessage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _NewMessageSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_authError) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view messages.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Messages',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square),
            tooltip: 'New Message',
            onPressed: _openNewMessage,
          ),
        ],
      ),
      body: StreamBuilder<List<Conversation>>(
        stream: BackendService.conversationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final convs = snapshot.data ?? [];
          if (convs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('No messages yet',
                      style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _openNewMessage,
                    icon: const Icon(Icons.add),
                    label: const Text('Start a conversation'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: convs.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 76),
            itemBuilder: (context, i) {
              final conv = convs[i];
              final otherId = conv.otherUid(myUid);
              return _ConversationTile(
                conv: conv,
                myUid: myUid,
                otherId: otherId,
                otherName: conv.participantNames[otherId] ?? 'Unknown',
                otherLogo: conv.participantLogos[otherId],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewMessage,
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CONVERSATION TILE
// ═══════════════════════════════════════════════════════════════════
class _ConversationTile extends StatelessWidget {
  final Conversation conv;
  final String myUid, otherId, otherName;
  final String? otherLogo;

  const _ConversationTile({
    required this.conv,
    required this.myUid,
    required this.otherId,
    required this.otherName,
    this.otherLogo,
  });

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat.jm().format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat.EEEE().format(dt);
    return DateFormat.MMMd().format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = conv.unreadCount > 0;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFF1976D2),
            backgroundImage:
                otherLogo != null ? NetworkImage(otherLogo!) : null,
            child: otherLogo == null
                ? Text(
                    otherName.isNotEmpty
                        ? otherName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold))
                : null,
          ),
          if (!conv.isMutual)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.person_add,
                    size: 12, color: Color(0xFFFF9800)),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherName,
              style: TextStyle(
                fontWeight:
                    isUnread ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          if (!conv.isMutual)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Non-mutual',
                  style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFFFF9800),
                      fontWeight: FontWeight.w600)),
            ),
          Text(
            _formatTime(conv.lastMessageTime),
            style: TextStyle(
              fontSize: 12,
              color: isUnread
                  ? const Color(0xFF1976D2)
                  : Colors.grey.shade500,
              fontWeight:
                  isUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conv.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isUnread ? Colors.black87 : Colors.grey.shade600,
                fontWeight:
                    isUnread ? FontWeight.w500 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
          if (isUnread)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                  color: Color(0xFF1976D2), shape: BoxShape.circle),
              child: Text(
                conv.unreadCount > 99 ? '99+' : '${conv.unreadCount}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            convId: conv.id,
            otherId: otherId,
            otherName: otherName,
            otherLogo: otherLogo,
            isMutual: conv.isMutual,
            myUid: myUid,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  NEW MESSAGE SHEET  (search users & start conversation)
// ═══════════════════════════════════════════════════════════════════
class _NewMessageSheet extends StatefulWidget {
  const _NewMessageSheet();

  @override
  State<_NewMessageSheet> createState() => _NewMessageSheetState();
}

class _NewMessageSheetState extends State<_NewMessageSheet> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

  // Resolve uid once so we don't call currentUid inside async gap
  final String _myUid = BackendService.currentUid;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    final results = await BackendService.searchUsers(query);
    if (mounted) {
      setState(() {
        _results = results;
        _searching = false;
      });
    }
  }

  Future<void> _startConversation(Map<String, dynamic> user) async {
    final otherId = user['uid'] as String;
    final convId = await BackendService.findOrCreateConversation(otherId);
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          convId: convId,
          otherId: otherId,
          otherName: user['name'] as String? ?? 'User',
          otherLogo: user['logoUrl'] as String?,
          isMutual: user['isMutual'] == true,
          myUid: _myUid, // ← reuse already-resolved uid
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('New Message',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search people...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _search,
              ),
            ),
            const SizedBox(height: 8),
            if (_searching)
              const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final u = _results[i];
                    final isMutual = u['isMutual'] == true;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1976D2),
                        backgroundImage: u['logoUrl'] != null
                            ? NetworkImage(u['logoUrl'])
                            : null,
                        child: u['logoUrl'] == null
                            ? Text(
                                (u['name'] as String? ?? '?')[0]
                                    .toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white))
                            : null,
                      ),
                      title: Text(u['name'] ?? ''),
                      subtitle: Text(
                        isMutual ? 'Mutual connection' : 'Non-mutual',
                        style: TextStyle(
                          color: isMutual
                              ? Colors.green.shade600
                              : Colors.orange.shade600,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Icon(
                        isMutual ? Icons.people : Icons.person_add,
                        color: isMutual
                            ? Colors.green.shade400
                            : Colors.orange.shade400,
                        size: 18,
                      ),
                      onTap: () => _startConversation(u),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CHAT PAGE
// ═══════════════════════════════════════════════════════════════════
class ChatPage extends StatefulWidget {
  final String convId, otherId, otherName, myUid;
  final String? otherLogo;
  final bool isMutual;

  const ChatPage({
    super.key,
    required this.convId,
    required this.otherId,
    required this.otherName,
    this.otherLogo,
    required this.isMutual,
    required this.myUid,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    BackendService.markConversationRead(widget.convId);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    await BackendService.sendTextMessage(widget.convId, text);
    if (mounted) setState(() => _sending = false);
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final xfile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    // readAsBytes() works on both web and mobile — no dart:io needed
    final bytes = await xfile.readAsBytes();
    final fileName = xfile.name.isNotEmpty
        ? xfile.name
        : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    setState(() => _sending = true);
    await BackendService.sendImageMessage(widget.convId, bytes, fileName);
    if (mounted) setState(() => _sending = false);
    _scrollToBottom();
  }

  Future<void> _pickFile() async {
    // withData: true ensures bytes are available on web
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.single.bytes == null) return;
    final f = result.files.single;
    setState(() => _sending = true);
    await BackendService.sendFileMessage(widget.convId, f.bytes!, f.name);
    if (mounted) setState(() => _sending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.image, color: Color(0xFF1976D2)),
              ),
              title: const Text('Photo / Image'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF3E5F5),
                child: Icon(Icons.attach_file, color: Colors.purple),
              ),
              title: const Text('File / Document'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(ChatMessage msg) {
    if (msg.deleted) return;
    final isMe = msg.senderId == widget.myUid;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.forward, color: Color(0xFF1976D2)),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(context);
                _showForwardSheet(msg);
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Colors.red),
                title: const Text('Delete',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  BackendService.deleteMessage(widget.convId, msg.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showForwardSheet(ChatMessage msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ForwardSheet(
        message: msg,
        currentConvId: widget.convId,
        myUid: widget.myUid,
        otherName: widget.otherName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF1976D2),
              backgroundImage: widget.otherLogo != null
                  ? NetworkImage(widget.otherLogo!)
                  : null,
              child: widget.otherLogo == null
                  ? Text(
                      widget.otherName.isNotEmpty
                          ? widget.otherName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13))
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                if (!widget.isMutual)
                  const Text('Non-mutual connection',
                      style: TextStyle(
                          fontSize: 10, color: Color(0xFFFF9800))),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!widget.isMutual)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              color: const Color(0xFFFFF8E1),
              child: Row(
                children: const [
                  Icon(Icons.info_outline,
                      size: 16, color: Color(0xFFFF9800)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are not mutually connected. Messages are still delivered.',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF795548)),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: BackendService.messagesStream(widget.convId),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final msgs = snapshot.data ?? [];
                if (msgs.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hello to ${widget.otherName}!',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  );
                }
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 16),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final msg = msgs[i];
                    final isMe = msg.senderId == widget.myUid;
                    final isRead = msg.isReadBy(widget.otherId);
                    return GestureDetector(
                      onLongPress: () => _showMessageOptions(msg),
                      child: _MessageBubble(
                        msg: msg,
                        isMe: isMe,
                        isRead: isRead,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 8),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file,
                        color: Color(0xFF1976D2)),
                    onPressed: _showAttachmentMenu,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _sending
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                              strokeWidth: 2))
                      : GestureDetector(
                          onTap: _sendText,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1976D2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send,
                                color: Colors.white, size: 20),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MESSAGE BUBBLE
// ═══════════════════════════════════════════════════════════════════
class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe, isRead;

  const _MessageBubble({
    required this.msg,
    required this.isMe,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: msg.deleted
              ? Colors.grey.shade200
              : isMe
                  ? const Color(0xFF1976D2)
                  : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              // withValues replaces deprecated withOpacity
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.forwardedFrom != null && !msg.deleted)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.forward,
                        size: 12,
                        color: isMe
                            ? Colors.white70
                            : Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'Fwd: ${msg.forwardedFrom}',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: isMe
                            ? Colors.white70
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

            if (msg.deleted)
              Text('This message was deleted',
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                      fontSize: 13))
            else if (msg.type == ChatMessageType.image &&
                msg.attachmentUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(msg.attachmentUrl!,
                    width: 200, fit: BoxFit.cover),
              )
            else if (msg.type == ChatMessageType.file &&
                msg.attachmentUrl != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insert_drive_file,
                      color: isMe
                          ? Colors.white70
                          : const Color(0xFF1976D2)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      msg.attachmentName ?? 'File',
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              )
            else
              Text(
                msg.text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 14.5,
                ),
              ),

            const SizedBox(height: 4),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg.timestamp != null
                      ? DateFormat.jm().format(msg.timestamp!)
                      : '',
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white60
                        : Colors.grey.shade400,
                  ),
                ),
                if (isMe && !msg.deleted) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 12,
                    color: isRead
                        ? Colors.lightBlueAccent
                        : Colors.white60,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  FORWARD SHEET
// ═══════════════════════════════════════════════════════════════════
class _ForwardSheet extends StatefulWidget {
  final ChatMessage message;
  final String currentConvId, myUid, otherName;

  const _ForwardSheet({
    required this.message,
    required this.currentConvId,
    required this.myUid,
    required this.otherName,
  });

  @override
  State<_ForwardSheet> createState() => _ForwardSheetState();
}

class _ForwardSheetState extends State<_ForwardSheet> {
  List<Conversation> _convs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await BackendService.fetchAllConversations();
    if (mounted) {
      setState(() {
        _convs =
            all.where((c) => c.id != widget.currentConvId).toList();
        _loading = false;
      });
    }
  }

  Future<void> _forward(Conversation conv) async {
    final otherId = conv.otherUid(widget.myUid);
    final senderName = widget.message.senderId == widget.myUid
        ? 'Me'
        : widget.otherName;

    await BackendService.forwardMessage(
      targetConvId: conv.id,
      message: widget.message,
      originalSenderName: senderName,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Forwarded to ${conv.participantNames[otherId] ?? 'User'}'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
        const Text('Forward to...',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator())
        else if (_convs.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No other conversations to forward to.'),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _convs.length,
              itemBuilder: (_, i) {
                final c = _convs[i];
                final otherId = c.otherUid(widget.myUid);
                final name = c.participantNames[otherId] ?? 'Unknown';
                final logo = c.participantLogos[otherId];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1976D2),
                    backgroundImage:
                        logo != null ? NetworkImage(logo) : null,
                    child: logo == null
                        ? Text(name[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white))
                        : null,
                  ),
                  title: Text(name),
                  onTap: () => _forward(c),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}