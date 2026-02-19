import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../backend/backend.dart';

class PostFeedPage extends StatefulWidget {
  const PostFeedPage({super.key});

  @override
  State<PostFeedPage> createState() => _PostFeedPageState();
}

class _PostFeedPageState extends State<PostFeedPage> {

  void _openCreatePost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CreatePostSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Feed", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.red),
            onPressed: _openCreatePost,
          ),
        ],
      ),
      body: StreamBuilder<List<Post>>(
        stream: BackendService.feedStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }
          final posts = snap.data ?? [];
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.feed_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text("No posts yet.\nFollow people or create your first post!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _openCreatePost,
                    icon: const Icon(Icons.edit),
                    label: const Text("Create Post"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _PostCard(post: posts[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePost,
        backgroundColor: Colors.red,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}

// ── CREATE POST BOTTOM SHEET ──────────────────────────────

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _controller = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageFileName = picked.name;
    });
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _imageBytes == null) return;

    setState(() => _isLoading = true);

    String? imageUrl;
    if (_imageBytes != null && _imageFileName != null) {
      imageUrl = await BackendService.uploadPostImage(_imageBytes!, _imageFileName!);
    }

    final result = await BackendService.createPost(
      content: text,
      imageUrl: imageUrl,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.success ? 'Post shared!' : result.message ?? 'Failed'),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Create Post",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 5,
            minLines: 3,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: "What's on your mind?",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          if (_imageBytes != null) ...[
            const SizedBox(height: 8),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_imageBytes!, height: 180,
                      width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 4, right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() { _imageBytes = null; _imageFileName = null; }),
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image, color: Colors.red),
                label: const Text("Photo", style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(100, 42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Post", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── POST CARD ─────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final Post post;
  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late bool _liked;
  late int _likesCount;
  bool _showComments = false;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _liked = widget.post.likedByMe;
    _likesCount = widget.post.likesCount;
  }

  Future<void> _toggleLike() async {
    setState(() {
      _liked = !_liked;
      _likesCount += _liked ? 1 : -1;
    });
    await BackendService.toggleLike(widget.post.id, !_liked);
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    _commentController.clear();
    await BackendService.addComment(postId: widget.post.id, content: text);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Row
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: post.authorLogoUrl != null
                    ? NetworkImage(post.authorLogoUrl!) as ImageProvider
                    : const AssetImage('assets/profile.jpg'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(_timeAgo(post.createdAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),

          // Content
          if (post.content.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(post.content, style: const TextStyle(fontSize: 14)),
          ],

          // Image
          if (post.imageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(post.imageUrl!, fit: BoxFit.cover,
                  width: double.infinity, height: 220),
            ),
          ],

          const SizedBox(height: 10),

          // Like/Comment counts
          if (_likesCount > 0 || post.comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  if (_likesCount > 0)
                    Row(children: [
                      const Icon(Icons.thumb_up, size: 14, color: Colors.red),
                      const SizedBox(width: 4),
                      Text('$_likesCount',
                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(width: 12),
                    ]),
                  if (post.comments.isNotEmpty)
                    Text('${post.comments.length} comments',
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),

          const Divider(height: 1),
          const SizedBox(height: 4),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionBtn(
                icon: _liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                label: 'Like',
                color: _liked ? Colors.red : Colors.grey,
                onTap: _toggleLike,
              ),
              _actionBtn(
                icon: Icons.chat_bubble_outline,
                label: 'Comment',
                color: Colors.grey,
                onTap: () => setState(() => _showComments = !_showComments),
              ),
              _actionBtn(
                icon: Icons.share_outlined,
                label: 'Share',
                color: Colors.grey,
                onTap: () {},
              ),
            ],
          ),

          // Comments Section
          if (_showComments) ...[
            const Divider(height: 16),
            ...post.comments.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(radius: 14,
                      backgroundImage: AssetImage('assets/profile.jpg')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.authorName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(c.content, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
            Row(
              children: [
                const CircleAvatar(radius: 14,
                    backgroundImage: AssetImage('assets/profile.jpg')),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: const TextStyle(fontSize: 13),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send, color: Colors.red, size: 18),
                        onPressed: _submitComment,
                      ),
                    ),
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}