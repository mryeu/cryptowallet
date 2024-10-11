import 'package:cryptowallet/services/session_manager.dart';
import 'package:cryptowallet/wallet_create.dart';
import 'package:flutter/material.dart';
import 'check_balance.dart';

class JoinPage extends StatefulWidget {
  @override
  _JoinPageState createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  final TextEditingController sponsorController = TextEditingController();
  List<Map<String, dynamic>> wallets = [];
  final TokenBalanceChecker _balanceChecker = TokenBalanceChecker();
  int selectedCount = 0;  // Biến đếm số ví được chọn

  @override
  void initState() {
    super.initState();
    _loadWalletData(); // Load wallet data on initialization
  }

  // Load wallet data from JSON
  Future<void> _loadWalletData() async {
    try {
      String? pin = SessionManager.userPin;  // Lấy pin từ SessionManager hoặc nơi lưu trữ khác
      final walletDataDecrypt = await loadWalletPINFromJson(pin!);  // Gọi hàm load dữ liệu từ JSON
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
          'Join Member Play Now',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
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
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter Sponsor',
              ),
            ),
            const SizedBox(height: 20),

            // Select Wallet Section
            Text(
              'Select Wallet: $selectedCount/${wallets.length}',  // Hiển thị số ví đã chọn / tổng số ví
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
                      title: Row( // Sử dụng Row để đặt name và address cùng hàng
                        children: [
                          // Tên ví
                          Text(
                            '${wallets[index]['name']}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10), // Khoảng cách giữa tên ví và địa chỉ
                          // Địa chỉ ví
                          Expanded(
                            child: Text(
                              _shortenAddress(wallets[index]['address']), // Địa chỉ ví được rút gọn
                              style: const TextStyle(color: Colors.black54), // Màu xám cho địa chỉ
                              overflow: TextOverflow.ellipsis,  // Xử lý khi địa chỉ quá dài
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
                          selectedCount = wallets.where((wallet) => wallet['selected'] == true).length; // Cập nhật số ví đã chọn
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
                    backgroundColor: Colors.red,  // Nút Cancel màu đỏ
                  ),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white),),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Handle Join Now action
                    // You can process the selected wallets and sponsor here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Join Now',
                    style: TextStyle(color: Colors.white),  // Nút Join Now màu trắng
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
