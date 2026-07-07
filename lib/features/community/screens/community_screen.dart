import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/comments_sheet.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _postController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _postController.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'userName': user.displayName ?? user.email?.split('@').first ?? 'Hiker',
        'content': _postController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': <String>[],
        'commentsCount': 0,
      });
      _postController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _toggleLike(String postId, List<String> likedBy) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final isLiked = likedBy.contains(uid);
    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'likes': FieldValue.increment(isLiked ? -1 : 1),
      'likedBy': isLiked ? FieldValue.arrayRemove([uid]) : FieldValue.arrayUnion([uid]),
    });
  }

  void _showComments(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1F18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CommentsSheet(postId: postId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1F18),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Text(
                    'Community',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Composer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF112D24),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _postController,
                        maxLines: 3,
                        minLines: 1,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "What's happening on the trail?",
                          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 8),
                      child: GestureDetector(
                        onTap: _isSending ? null : _createPost,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ECC71),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _isSending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.black),
                                )
                              : const Icon(Icons.arrow_upward_rounded,
                                  color: Colors.black, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Feed
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState();
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF2ECC71), strokeWidth: 2),
                    );
                  }

                  final posts = snapshot.data?.docs ?? [];
                  if (posts.isEmpty) {
                    return Center(
                      child: Text(
                        'No posts yet. Be the first to share!',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                    itemCount: posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final doc = posts[index];
                      final post = doc.data() as Map<String, dynamic>;
                      final postId = doc.id;
                      final likedBy = List<String>.from(post['likedBy'] ?? []);
                      final isLiked =
                          likedBy.contains(FirebaseAuth.instance.currentUser?.uid);
                      final initials =
                          (post['userName'] as String? ?? 'H')[0].toUpperCase();

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF112D24),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author row
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      const Color(0xFF2ECC71).withValues(alpha: 0.15),
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Color(0xFF2ECC71),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post['userName'] ?? 'Hiker',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Borneo Trails',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Content
                            Text(
                              post['content'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[200],
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Actions
                            Row(
                              children: [
                                _ActionBtn(
                                  icon: isLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  label: '${post['likes'] ?? 0}',
                                  color: isLiked ? Colors.redAccent : Colors.grey[600]!,
                                  onTap: () => _toggleLike(postId, likedBy),
                                ),
                                const SizedBox(width: 20),
                                _ActionBtn(
                                  icon: Icons.chat_bubble_outline_rounded,
                                  label: '${post['commentsCount'] ?? 0}',
                                  color: Colors.grey[600]!,
                                  onTap: () => _showComments(postId),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => Share.share(post['content'] ?? ''),
                                  child: Icon(Icons.share_outlined,
                                      color: Colors.grey[600], size: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 48, color: Colors.grey[700]),
            const SizedBox(height: 16),
            const Text(
              'Permission Denied',
              style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Update your Firebase Rules to allow reading the posts collection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Button ────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
