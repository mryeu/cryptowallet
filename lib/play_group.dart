import 'package:cryptowallet/services/member_service.dart';
import 'package:cryptowallet/services/session_manager.dart';
import 'package:cryptowallet/wallet_create.dart';
import 'package:flutter/material.dart';
import 'check_balance.dart';
import 'modules/member/join_memeber_widget.dart';

class PlayGroupPage extends StatefulWidget {
  @override
  _PlayGroupPageState createState() => _PlayGroupPageState();
}

class _PlayGroupPageState extends State<PlayGroupPage> {
  List<Map<String, dynamic>> wallets = [];
  final TokenBalanceChecker _balanceChecker = TokenBalanceChecker();
  int selectedCount = 0; // Biến đếm số lượng ví được chọn
  bool isLoading = true; // Để hiển thị trạng thái checking cho nút Play
  bool allWalletsChecked = false; // Kiểm soát việc kiểm tra tất cả các ví

  @override
  void initState() {
    super.initState();
    _loadWalletData(); // Load wallet data on initialization
  }

  // Load wallet data từ JSON và hiển thị ngay danh sách thô
  Future<void> _loadWalletData() async {
    try {
      final walletDataDecrypt = await loadWalletPINFromJson(SessionManager.userPin!); // Gọi hàm load dữ liệu từ JSON
      if (walletDataDecrypt != null) {
        List<Map<String, dynamic>> loadedWallets = [];
        if (walletDataDecrypt.containsKey('wallet_names') && walletDataDecrypt.containsKey('addresses')) {
          List<String> walletNames = List<String>.from(walletDataDecrypt['wallet_names']);
          List<String> walletAddresses = List<String>.from(walletDataDecrypt['addresses']);

          for (int i = 0; i < walletNames.length; i++) {
            loadedWallets.add({
              'name': walletNames[i],
              'address': walletAddresses[i],
              'bnb_balance': 'Fetching...', // Placeholder for BNB balance
              'usdt_balance': 'Fetching...', // Placeholder for USDT balance
              'status': 'Checking...', // Đặt trạng thái thành "Checking..."
              'selected': false, // Default value for checkbox
              'canPlay': false, // Default giá trị khi chưa kiểm tra
              'isMember': false, // Default giá trị khi chưa kiểm tra
            });
          }
        }

        setState(() {
          wallets = loadedWallets;
          isLoading = true;
        });

        // Kiểm tra trạng thái thành viên và điều kiện chơi của từng ví
        _checkWalletStatuses(loadedWallets);
        _fetchWalletBalances(wallets); // Đồng thời tải số dư
      }
    } catch (e) {
      print('Failed to load wallet data: $e');
    }
  }

  // Kiểm tra trạng thái từng ví và cập nhật UI
  Future<void> _checkWalletStatuses(List<Map<String, dynamic>> loadedWallets) async {
    for (int i = 0; i < loadedWallets.length; i++) {
      String walletAddress = loadedWallets[i]['address'];
      bool canPlay = await getCheckPlay(walletAddress);
      bool? isMember = await _checkIsMember(walletAddress);

      setState(() {
        wallets[i]['canPlay'] = canPlay;
        wallets[i]['isMember'] = isMember;
        wallets[i]['status'] = (canPlay && isMember!) ? 'Play' : 'Not Eligible'; // Cập nhật trạng thái
      });
    }

    setState(() {
      allWalletsChecked = true; // Đánh dấu đã kiểm tra xong tất cả các ví
      isLoading = false;
    });
  }

  // Function to check if a wallet is a member
  Future<bool?> _checkIsMember(String walletAddress) async {
    return await MemberService().checkIsMember(walletAddress);
  }

  // Function to fetch wallet balances
  Future<void> _fetchWalletBalances(List<Map<String, dynamic>> wallets) async {
    for (var wallet in wallets) {
      try {
        double? bnbBalance = await _balanceChecker.getBnbBalance(wallet['address']);
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

  void _onPlayNow() {
    List<Map<String, dynamic>> selectedWallets = wallets.where((wallet) => wallet['selected']).toList();

    if (selectedWallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No wallets selected. Please select at least one wallet to play.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      print('Selected wallets for Play:');
      for (var wallet in selectedWallets) {
        print('Playing with wallet: ${wallet['name']} (${wallet['address']})');
        // Gọi hàm PlayNowKitty với danh sách ví được chọn
        onPlayNowKitty(context, selectedWallets, wallet['selected']);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Play action executed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
            Text(
              'Select Wallet Play: $selectedCount/${wallets.length}', // Hiển thị số lượng ví được chọn
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: wallets.length,
                itemBuilder: (context, index) {
                  bool canPlay = wallets[index]['canPlay']; // Lấy giá trị canPlay
                  bool isMember = wallets[index]['isMember']; // Lấy giá trị isMember

                  return Opacity(  // Thêm opacity nếu canPlay = false
                    opacity: canPlay && isMember ? 1.0 : 0.5,  // Giảm độ mờ cho các ví không thể Play hoặc không phải là Member
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: canPlay && isMember ? Colors.green : Colors.red, // Border màu xanh nếu có thể chơi và là thành viên, màu đỏ nếu không
                          width: 1,
                        ), // Green or Red border
                      ),
                      child: CheckboxListTile(
                        title: Row(
                          children: [
                            Text(
                              '${wallets[index]['name']}',
                              style: TextStyle(
                                color: canPlay && isMember ? Colors.green : Colors.red, // Màu chữ thay đổi theo trạng thái
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
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
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/bnb-bnb-logo.png',
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
                                  'assets/images/usdt_logo.png',
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
                        onChanged: (canPlay && isMember) ? (bool? value) {
                          setState(() {
                            wallets[index]['selected'] = value ?? false;
                            selectedCount = wallets.where((wallet) => wallet['selected']).length; // Cập nhật số ví đã chọn
                            wallets[index]['status'] = wallets[index]['selected'] ? 'Played' : 'Play';
                          });
                        } : null, // Nếu không đủ điều kiện Play hoặc không là thành viên thì checkbox bị vô hiệu hóa
                      ),
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
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: allWalletsChecked
                      ? _onPlayNow
                      : null,  // Vô hiệu hóa nút Play nếu đang kiểm tra
                  style: ElevatedButton.styleFrom(
                    backgroundColor: allWalletsChecked ? Colors.green : Colors.grey,
                  ),
                  child: Text(
                    allWalletsChecked ? 'Play' : 'Checking...',  // Hiển thị "Checking..." khi đang kiểm tra
                    style: const TextStyle(color: Colors.white),
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
