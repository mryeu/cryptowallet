import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WalletDetailsPage extends StatelessWidget {
  final Map<String, dynamic> wallet;

  const WalletDetailsPage({Key? key, required this.wallet}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Card 1: Wallet Status
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Last Play: ${wallet['last_play_time'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Text('Next Play: ${wallet['next_play_time'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Text('Sponsor: ${wallet['sponsor'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Text('Total Ref: ${wallet['total_ref'] ?? 0}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Referrer Link: ${wallet['referrer_link'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            // Copy referrer link to clipboard
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Button 1: Play/WaitPlay
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF56AB2F),Color(0xFFA8E063) ], // Light green to dark green gradient
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                // Handle Play/WaitPlay action
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              child: Text(
                                wallet['is_playing'] == true ? 'WaitPlay' : 'Play',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),

                        // Button 2: Auto Play
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFA8E063), Color(0xFF56AB2F)], // Light green to dark green gradient
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                // Handle Auto Play action
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              child: const Text(
                                'Auto Play',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Card 2: Team Management
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Team Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: (wallet['team'] ?? []).length,
                      itemBuilder: (context, index) {
                        var member = wallet['team'][index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Index: ${member['index']}, Played: ${member['played']}, Commission: ${member['commission']}'),
                              const SizedBox(height: 5),
                              Text('Time Countdown: ${member['countdown']}'),
                              const SizedBox(height: 5),
                              ElevatedButton(
                                onPressed: () {
                                  // Handle button action based on state
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: member['state'] == 'claimed'
                                      ? Colors.grey
                                      : member['state'] == 'active'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                child: Text(member['state'] == 'claimed'
                                    ? 'Claimed'
                                    : member['state'] == 'active'
                                    ? 'Active'
                                    : 'Interactive'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Card 3: My Members
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('My Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: (wallet['members'] ?? []).length,
                      itemBuilder: (context, index) {
                        var member = wallet['members'][index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Index: ${member['index']}, Address: ${member['address']}, Ref1: ${member['ref1']}, Ref2: ${member['ref2']}, Ref3: ${member['ref3']}'),
                              const SizedBox(height: 5),
                              Text('Total Play: ${member['total_play']}, Play Month: ${member['play_month']}'),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
