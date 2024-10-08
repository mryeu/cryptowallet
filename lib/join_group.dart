import 'package:flutter/material.dart';

class JoinPage extends StatefulWidget {
  @override
  _JoinPageState createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  final TextEditingController sponsorController = TextEditingController();
  List<Map<String, dynamic>> wallets = [
    {
      'name': 'Wallet 1',
      'address': '0xAbc...1234',
      'bnb_balance': '0.1234',
      'usdt_balance': '100.50',
      'selected': false,
    },
    {
      'name': 'Wallet 2',
      'address': '0xDef...5678',
      'bnb_balance': '0.5678',
      'usdt_balance': '250.75',
      'selected': false,
    },
  ]; // Example wallets list. Replace with actual data if needed.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Member Play Now'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sponsor Text Field
            const Text(
              'Sponsor:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: sponsorController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter Sponsor',
              ),
            ),
            const SizedBox(height: 20),

            // Select Wallet Section
            const Text(
              'Select Wallet:',
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
                        ],
                      ),
                      value: wallets[index]['selected'],
                      onChanged: (bool? value) {
                        setState(() {
                          wallets[index]['selected'] = value ?? false;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Buttons: Cancel and Join Now
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
                    // Handle Join Now action
                    // You can process the selected wallets and sponsor here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Join Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
