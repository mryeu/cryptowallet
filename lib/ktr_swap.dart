import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class KtrSwapTab extends StatelessWidget {
  final Map<String, dynamic> walletData;
  final String mnemonic;
  final String password;
  final String mainWalletPrivateKey;

  const KtrSwapTab({
    super.key,
    required this.walletData,
    required this.mnemonic,
    required this.password,
    required this.mainWalletPrivateKey,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> walletAddresses = List<String>.from(walletData['addresses'] ?? []);

    if (walletAddresses.isEmpty) {
      return const Center(child: Text("No wallet addresses found."));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KTRSwap',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Swap your KTR tokens with other cryptocurrencies directly within your wallet.',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          _buildSwapActionButton(context, walletAddresses[0]), // Swap action button
          const SizedBox(height: 10),
          _buildKtrSwapHistory(), // Swap history or related information
        ],
      ),
    );
  }

  Widget _buildSwapActionButton(BuildContext context, String walletAddress) {
    return ElevatedButton(
      onPressed: () {
        // Logic to perform KTRSwap can be added here
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green, // Background color
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
      child: const Text('Swap Now', style: TextStyle(fontSize: 18)),
    );
  }

  Widget _buildKtrSwapHistory() {
    // Placeholder widget to display swap history
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            _buildKtrSwapHistoryHeader(),
            const SizedBox(height: 10),
            _buildKtrSwapHistoryListView(),
          ],
        ),
      ),
    );
  }

  Widget _buildKtrSwapHistoryHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(0),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Swap Hash', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          Text('Pair', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          Text('Value', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          Text('Status', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          Text('Age', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildKtrSwapHistoryListView() {
    // Placeholder for swap history items
    return Expanded(
      child: ListView.builder(
        itemCount: 10, // Replace with actual swap history count
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.swap_horizontal_circle),
            title: Text('Swap $index'),
            subtitle: const Text('KTR -> USDT'),
            trailing: const Text('Completed'),
          );
        },
      ),
    );
  }
}
