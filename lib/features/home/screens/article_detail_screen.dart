import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ArticleDetailScreen extends StatelessWidget {
  final DocumentSnapshot article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final data = article.data() as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1F18),
      body: CustomScrollView(
        slivers: [
          // Image header
          SliverAppBar(
            expandedHeight: data['imageUrl'] != null ? 260 : 0,
            pinned: true,
            backgroundColor: const Color(0xFF0A1F18),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: data['imageUrl'] != null
                ? FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          data['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF112D24),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                const Color(0xFF0A1F18).withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Category chip
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data['category'] ?? 'Nature',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2ECC71),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${data['readTime'] ?? 5} min read',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Text(
                  data['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 20),

                Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),

                const SizedBox(height: 20),

                Text(
                  data['content'] ?? 'No content available.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[300],
                    height: 1.7,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
