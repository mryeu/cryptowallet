import 'package:cryptowallet/services/session_manager.dart';
import 'package:cryptowallet/wallet_create.dart';
import 'package:flutter/material.dart';
import 'check_balance.dart';

class PlayGroupPage extends StatefulWidget {
  @override
  _PlayGroupPageState createState() => _PlayGroupPageState();
}

class _PlayGroupPageState extends State<PlayGroupPage> {
  List<Map<String, dynamic>> wallets = [];
  final TokenBalanceChecker _balanceChecker = TokenBalanceChecker();
  int selectedCount = 0; // Biến đếm số lượng ví được chọn

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
                'status': 'Play', // Default status
                'selected': false,  // Default value for checkbox
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
        title: const Text(
          'Play Group',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select Wallet Play Section
            Text(
              'Select Wallet Play: $selectedCount/${wallets.length}',  // Hiển thị số lượng ví được chọn
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
                    child: CheckboxListTile(
                      title: Row( // Đặt name và address cùng hàng
                        children: [
                          // Tên ví
                          Text(
                            '${wallets[index]['name']}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10), // Khoảng cách giữa name và address
                          // Địa chỉ ví rút gọn
                          Expanded(
                            child: Text(
                              _shortenAddress(wallets[index]['address']),
                              style: const TextStyle(color: Colors.black54), // Màu xám cho address
                              overflow: TextOverflow.ellipsis, // Xử lý địa chỉ dài
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          // Row for BNB Balance with logo
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/bnb-bnb-logo.png', // BNB Logo asset
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 8),
                              Text('${wallets[index]['bnb_balance']}'),
                            ],
                          ),
                          const SizedBox(height: 5),
                          // Row for USDT Balance with logo
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/usdt_logo.png', // USDT Logo asset
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 8),
                              Text('${wallets[index]['usdt_balance']}'),
                            ],
                          ),
                        ],
                      ),
                      value: wallets[index]['selected'],
                      onChanged: (bool? value) {
                        setState(() {
                          wallets[index]['selected'] = value ?? false;
                          selectedCount = wallets.where((wallet) => wallet['selected']).length;  // Cập nhật số ví đã chọn
                          // Toggle status based on selection
                          wallets[index]['status'] = wallets[index]['selected'] ? 'Played' : 'Play';
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Buttons: Cancel and Play
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Handle Cancel action
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,  // Nút Cancel màu đỏ
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),  // Text màu trắng
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Handle Play action
                    // Thực hiện logic Play
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,  // Nút Play màu xanh lá cây
                  ),
                  child: const Text(
                    'Play',
                    style: TextStyle(color: Colors.white),  // Text màu trắng
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
