import 'package:cryptowallet/play_group.dart';
import 'package:cryptowallet/services/session_manager.dart';
import 'package:cryptowallet/wallet_create.dart'; // Import wallet creation functions
import 'package:flutter/material.dart';

import 'WalletDetailsPage.dart';
import 'check_balance.dart';
import 'claim_swap_play_group.dart';
import 'join_group.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  _PlayScreenState createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  String? selectedWallet = 'All Wallets'; // Default selected wallet
  List<String> walletFilterOptions = ['All Wallets']; // Wallet filter options
  List<Map<String, dynamic>> wallets = []; // Store wallet data dynamically

  // Instance of TokenBalanceChecker to fetch balances
  final TokenBalanceChecker _balanceChecker = TokenBalanceChecker();

  @override
  void initState() {
    super.initState();
    _loadWalletData(); // Load wallet data on initialization
  }

  // Load wallet data from JSON
  Future<void> _loadWalletData() async {
    try {
      String? pin = SessionManager.userPin;
      final walletDataDecrypt = await loadWalletPINFromJson(pin!);
      if (walletDataDecrypt != null) {
        setState(() {
          // Clear existing wallets
          wallets.clear();
          walletFilterOptions = ['All Wallets'];

          // Read wallet names and addresses from JSON
          if (walletDataDecrypt.containsKey('wallet_names') &&
              walletDataDecrypt.containsKey('addresses')) {
            List<String> walletNames = List<String>.from(walletDataDecrypt['wallet_names']);
            List<String> walletAddresses = List<String>.from(walletDataDecrypt['addresses']);

            for (int i = 0; i < walletNames.length; i++) {
              wallets.add({
                'name': walletNames[i],
                'address': walletAddresses[i],
                'bnb_balance': 'Fetching...', // Placeholder for BNB balance
                'usdt_balance': 'Fetching...', // Placeholder for USDT balance
              });
              walletFilterOptions.add(walletNames[i]);
            }
          }

          // Fetch wallet balances
          _fetchWalletBalances(wallets);
        });
      }
    } catch (e) {
      print('Failed to load wallet data: $e');
    }
  }

  // Function to fetch wallet balances
  Future<void> _fetchWalletBalances(List<Map<String, dynamic>> wallets) async {
    for (var wallet in wallets) {
      try {
        // Fetch BNB balance
        double? bnbBalance = await _balanceChecker.getBnbBalance(wallet['address']);
        // Fetch USDT balance
        double? usdtBalance = await _balanceChecker.getUsdtBalance(wallet['address']);

        setState(() {
          wallet['bnb_balance'] = bnbBalance != null ? bnbBalance.toStringAsFixed(4) : 'Error';
          wallet['usdt_balance'] = usdtBalance != null ? usdtBalance.toStringAsFixed(2) : 'Error';
        });
      } catch (e) {
        print('Error fetching wallet balances: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and filtering options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Play Screen',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  DropdownButton<String>(
                    dropdownColor: Colors.green[100],
                    value: selectedWallet,
                    icon: const Icon(Icons.filter_list, color: Colors.green),
                    underline: Container(height: 2, color: Colors.greenAccent),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedWallet = newValue;
                      });
                    },
                    items: walletFilterOptions.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(color: Colors.green)),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action buttons (Join, Play, Claim-Swap-Play)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => JoinPage()),
                      );
                    },
                    icon: const Icon(Icons.group_add),
                    label: const Text('Join'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                    ),
                  ),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PlayGroupPage()),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ClaimSwapPlayGroupPage()),
                      );
                    },
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Claim-Swap-Play'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Wallets section header
              Text(
                'Your Wallets',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 10),

              // Wallet cards
              Expanded(
                child: ListView.builder(
                  itemCount: wallets.length,
                  itemBuilder: (context, index) {
                    // Check if the selected wallet filter applies
                    if (selectedWallet != 'All Wallets' &&
                        wallets[index]['name'] != selectedWallet) {
                      return Container(); // Skip rendering this wallet
                    }
                    return GestureDetector(
                      onTap: () {
                        // Show full-screen popup when wallet is tapped
                        showFullScreenModal(context, wallets[index]);
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Thiết lập BorderRadius là 5
                          side: const BorderSide(color: Colors.green, width: 1),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                wallets[index]['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Row for both BNB and USDT balances
                              Row(
                                children: [
                                  // BNB balance
                                  Image.asset(
                                    'assets/images/bnb-bnb-logo.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${wallets[index]['bnb_balance']}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 16),

                                  // USDT balance
                                  Image.asset(
                                    'assets/images/usdt_logo.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${wallets[index]['usdt_balance']}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  // Spacer to push the button to the right
                                  const Spacer(),
                                  // Join button aligned to the right
                                  ElevatedButton(
                                    onPressed: () {
                                      // Handle Join action for this wallet
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text('Join'),
                                  ),
                                ],
                              ),

                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showFullScreenModal(BuildContext context, Map<String, dynamic> wallet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WalletDetailsPage(wallet: wallet),
      ),
    );
  }
}
