import 'package:cryptowallet/services/session_manager.dart';
import 'package:cryptowallet/wallet_create.dart';
import 'package:flutter/material.dart';
import 'check_balance.dart';

class ClaimSwapPlayGroupPage extends StatefulWidget {
  @override
  _ClaimSwapPlayGroupPageState createState() => _ClaimSwapPlayGroupPageState();
}

class _ClaimSwapPlayGroupPageState extends State<ClaimSwapPlayGroupPage> {
  List<Map<String, dynamic>> wallets = [];
  final TokenBalanceChecker _balanceChecker = TokenBalanceChecker();

  @override
  void initState() {
    super.initState();
    _loadWalletData(); // Load wallet data on initialization
  }

  // Load wallet data from JSON
  Future<void> _loadWalletData() async {
    try {
      final walletDataDecrypt = await loadWalletPINFromJson(SessionManager.userPin!);  // Gọi hàm load dữ liệu từ JSON
      if (walletDataDecrypt != null) {
        setState(() {
          // Clear existing wallets
          wallets.clear();

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
                'status': 'Claim', // Default status
              });
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

  String _shortenAddress(String address) {
    return '${address.substring(0, 5)}...${address.substring(address.length - 5)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claim-Swap-Play Group', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hiển thị tổng số ví sau "Total Claim-Swap-Play:"
            Text(
              'Total Claim-Swap-Play: ${wallets.length}',  // Hiển thị tổng số ví
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Wallets List
            Expanded(
              child: ListView.builder(
                itemCount: wallets.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.green, width: 1), // Green border
                    ),
                    child: ListTile(
                      title: Row(
                        children: [
                          // Tên ví
                          Text(
                            wallets[index]['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Địa chỉ ví
                          Expanded(
                            child: Text(
                              _shortenAddress(wallets[index]['address']),
                              style: const TextStyle(color: Colors.black54),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/bnb-bnb-logo.png',  // BNB logo
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 8),
                              Text('${wallets[index]['bnb_balance']}'),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/usdt_logo.png',  // USDT logo
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 8),
                              Text('${wallets[index]['usdt_balance']}'),
                            ],
                          ),
                          Text('Status: ${wallets[index]['status']}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Buttons: Cancel and Auto Now
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Handle Cancel action
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Nút Cancel màu đỏ
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Handle Auto Now action
                    // Thực hiện logic Auto Now
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Nút Auto Now màu xanh lá cây
                  ),
                  child: const Text(
                    'Auto Now',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
