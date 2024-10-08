import 'package:flutter/material.dart';

class ClaimSwapPlayGroupPage extends StatefulWidget {
  @override
  _ClaimSwapPlayGroupPageState createState() => _ClaimSwapPlayGroupPageState();
}

class _ClaimSwapPlayGroupPageState extends State<ClaimSwapPlayGroupPage> {
  List<Map<String, dynamic>> wallets = [
    {
      'name': 'Wallet 1',
      'address': '0xAbc...1234',
      'bnb_balance': '0.1234',
      'usdt_balance': '100.50',
      'status': 'Claim', // Default status
      'selected': false,
    },
    {
      'name': 'Wallet 2',
      'address': '0xDef...5678',
      'bnb_balance': '0.5678',
      'usdt_balance': '250.75',
      'status': 'Swap', // Default status
      'selected': false,
    },
  ]; // Example wallets list. Replace with actual data as needed.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claim-Swap-Play Group'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select Wallet Section
            const Text(
              'Select Wallet for Claim-Swap-Play:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Wallets List
            Expanded(
              child: ListView.builder(
                itemCount: wallets.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: CheckboxListTile(
                      title: Text(wallets[index]['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Address: ${wallets[index]['address']}'),
                          Text('Balance BNB: ${wallets[index]['bnb_balance']}'),
                          Text('Balance USDT: ${wallets[index]['usdt_balance']}'),
                          Text('Status: ${wallets[index]['status']}'),
                        ],
                      ),
                      value: wallets[index]['selected'],
                      onChanged: (bool? value) {
                        setState(() {
                          wallets[index]['selected'] = value ?? false;
                          // Update status based on selection
                          if (wallets[index]['selected']) {
                            wallets[index]['status'] = 'Claimed'; // Example update
                          } else {
                            wallets[index]['status'] = 'Claim'; // Reset if unchecked
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Buttons: Cancel and Claim-Swap-Play
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Handle Cancel action
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Handle Claim-Swap-Play action
                    // Implement the logic for claim, swap, or play based on selection
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Claim-Swap-Play'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
