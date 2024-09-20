import 'package:flutter/material.dart';

class DocumentScreen extends StatelessWidget {
  const DocumentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: <Widget>[
          _buildTreeItem(
            title: 'Section 1: How to Play KittyRun',
            content: 'hiển thị nội dung chi tiết ở đây đoạn này dùng multilanguage để dịch các phiên bản các nước.',
          ),
          _buildTreeItem(
            title: 'Section 2: How to Claim',
            content: 'hiển thị nội dung chi tiết ở đây',
          ),
          _buildTreeItem(
            title: 'Section 3: How to Swap',
            content: 'hiển thị nội dung chi tiết ở đây',
          ),
          _buildTreeItem(
            title: 'Section 4: How to invite',
            content: 'hiển thị nội dung chi tiết ở đây.',
          ),
          _buildTreeItem(
            title: 'Section 5: How to get Reward',
            content: 'hiển thị nội dung chi tiết ở đây',
          ),
          _buildTreeItem(
            title: 'Section 6: star ',
            content: 'hiển thị nội dung chi tiết ở đây',
          ),
          _buildTreeItem(
            title: 'Section 7: Play game',
            content: 'hiển thị nội dung chi tiết ở đây',
          ),
          _buildTreeItem(
            title: 'Section 8: Claim Game',
            content: 'hiển thị nội dung chi tiết ở đây',
          ),
        ],
      ),
    );
  }

  // Helper method to build an ExpansionTile for each tree item
  Widget _buildTreeItem({required String title, required String content}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(content, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
