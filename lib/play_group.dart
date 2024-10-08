import 'package:flutter/material.dart';

class PlayGroupPage extends StatefulWidget {
  @override
  _PlayGroupPageState createState() => _PlayGroupPageState();
}

class _PlayGroupPageState extends State<PlayGroupPage> {
  List<Map<String, dynamic>> wallets = [
    {
      'name': 'Wallet 1',
      'address': '0xAbc...1234',
      'bnb_balance': '0.1234',
      'usdt_balance': '100.50',
      'status': 'Play', // Default status
      'selected': false,
    },
    {
      'name': 'Wallet 2',
      'address': '0xDef...5678',
      'bnb_balance': '0.5678',
      'usdt_balance': '250.75',
      'status': 'Play', // Default status
      'selected': false,
    },
  ]; // Example wallets list. Replace with actual data if needed.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Play Group'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select Wallet Play Section
            const Text(
              'Select Wallet Play:',
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
                          // Toggle status based on selection
                          wallets[index]['status'] =
                          wallets[index]['selected'] ? 'Played' : 'Play';
                        });
                      },
                    ),
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
