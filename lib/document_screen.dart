import 'package:flutter/material.dart';

class DocumentScreen extends StatelessWidget {
  const DocumentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
         return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Document'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(8.0),
          children: <Widget>[
            _buildTreeItem(
              title: 'Section 1: How to Play KittyRun',
              content: 'Detailed instructions for playing KittyRun go here.',
            ),
            _buildTreeItem(
              title: 'Section 2: How to Claim',
              content: 'Instructions for claiming rewards or tokens.',
            ),
            _buildTreeItem(
              title: 'Section 3: How to Swap',
              content: 'Information on how to swap tokens or assets.',
            ),
            _buildTreeItem(
              title: 'Section 4: How to Invite',
              content: 'Details on inviting other users or friends.',
            ),
            _buildTreeItem(
              title: 'Section 5: How to Get Reward',
              content: 'Explanation on how users can earn rewards.',
            ),
            _buildTreeItem(
              title: 'Section 6: Star System',
              content: 'Details on the star system and its uses.',
            ),
            _buildTreeItem(
              title: 'Section 7: Play Game',
              content: 'General instructions for playing the game.',
            ),
            _buildTreeItem(
              title: 'Section 8: Claim Game',
              content: 'Instructions on how to claim rewards after a game.',
            ),
          ],
        ),
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
