import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Community", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text(
            "Recent Activity",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _buildPostCard(
            name: "Ahmad Husin",
            time: "15 min ago",
            trail: "Telok Assam • Bako",
            content: "Saw a group of proboscis monkeys near the beach! 🐒",
            imageEmoji: "🐒",
            likes: 24,
          ),
          _buildPostCard(
            name: "Siti Nurhaliza",
            time: "2 hours ago",
            trail: "Rafflesia Trail • Gunung Gading",
            content: "The Rafflesia is blooming right now! Amazing sight 🌺",
            imageEmoji: "🌺",
            likes: 41,
          ),
          _buildPostCard(
            name: "John Tan",
            time: "Yesterday",
            trail: "Kubah National Park",
            content: "Trail after waterfall is quite slippery after rain. Be careful!",
            imageEmoji: "⚠️",
            likes: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard({
    required String name,
    required String time,
    required String trail,
    required String content,
    required String imageEmoji,
    required int likes,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(name[0])),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("$trail • $time", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(imageEmoji, style: const TextStyle(fontSize: 60))),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.red, size: 20),
                    const SizedBox(width: 6),
                    Text("$likes"),
                  ],
                ),
                const Icon(Icons.comment_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
