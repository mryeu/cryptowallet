import 'package:cryptowallet/services/member_service.dart';
import 'package:cryptowallet/services/session_manager.dart';
import 'package:cryptowallet/wallet_create.dart';
import 'package:flutter/material.dart';
import 'check_balance.dart';
import 'modules/member/claim_swap_play_widget.dart';
import 'modules/member/join_memeber_widget.dart';

class ClaimSwapPlayGroupPage extends StatefulWidget {
  @override
  _ClaimSwapPlayGroupPageState createState() => _ClaimSwapPlayGroupPageState();
}

class _ClaimSwapPlayGroupPageState extends State<ClaimSwapPlayGroupPage> {
  List<Map<String, dynamic>> wallets = [];
  final TokenBalanceChecker _balanceChecker = TokenBalanceChecker();
  bool isCheckingWallets = true; // Biến để theo dõi tiến trình kiểm tra ví

  @override
  void initState() {
    super.initState();
    _loadWalletData(); // Load wallet data on initialization
  }

  // Load wallet data từ JSON và hiển thị ngay lập tức
  Future<void> _loadWalletData() async {
    try {
      final walletDataDecrypt = await loadWalletPINFromJson(SessionManager.userPin!);  // Gọi hàm load dữ liệu từ JSON
      if (walletDataDecrypt != null) {
        List<Map<String, dynamic>> loadedWallets = [];
        if (walletDataDecrypt.containsKey('wallet_names') &&
            walletDataDecrypt.containsKey('addresses')) {
          List<String> walletNames = List<String>.from(walletDataDecrypt['wallet_names']);
          List<String> walletAddresses = List<String>.from(walletDataDecrypt['addresses']);

          // Thêm các ví vào danh sách với trạng thái mặc định
          for (int i = 0; i < walletNames.length; i++) {
            loadedWallets.add({
              'name': walletNames[i],
              'address': walletAddresses[i],
              'bnb_balance': 'Fetching...', // Placeholder for BNB balance
              'usdt_balance': 'Fetching...', // Placeholder for USDT balance
              'status': 'Pending', // Trạng thái mặc định là Pending
              'isEligible': false, // Ban đầu đặt là false
            });
          }
        }

        setState(() {
          wallets = loadedWallets; // Hiển thị danh sách ngay lập tức
        });

        // Sau khi hiển thị danh sách, kiểm tra từng ví
        await _checkWalletStatuses();
        await _fetchWalletBalances(wallets); // Fetch balances cho các ví

        // Khi đã kiểm tra xong trạng thái của tất cả ví
        setState(() {
          isCheckingWallets = false; // Đặt là false khi kiểm tra xong
        });
      }
    } catch (e) {
      print('Failed to load wallet data: $e');
    }
  }

  // Kiểm tra trạng thái của từng ví và cập nhật
  Future<void> _checkWalletStatuses() async {
    for (int i = 0; i < wallets.length; i++) {
      bool? isMember = await _checkIsMember(wallets[i]['address']);
      bool canPlay = await _checkPlayStatus(wallets[i]['address']);

      // Cập nhật trạng thái ví ngay sau khi kiểm tra
      setState(() {
        wallets[i]['status'] = (isMember! && canPlay) ? 'Claim' : 'Not Eligible';
        wallets[i]['isEligible'] = isMember && canPlay;
      });
    }
  }

  // Function to check if a wallet is a member
  Future<bool?> _checkIsMember(String walletAddress) async {
    return await MemberService().checkIsMember(walletAddress);
  }

  // Function to check if the wallet has Play status
  Future<bool> _checkPlayStatus(String walletAddress) async {
    return await getCheckPlay(walletAddress);
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

  void _onAutoClaimSwapPlay() {
    // Chỉ thực hiện Claim cho những ví đủ điều kiện (isEligible = true)
    List<Map<String, dynamic>> eligibleWallets = wallets.where((wallet) => wallet['isEligible'] == true).toList();

    if (eligibleWallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No eligible wallets found for Auto Claim-Swap-Play.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // Gọi hàm AutoClaimSwapPlayKitty với danh sách các ví đủ điều kiện
      print('Auto Claim Swap Play for eligible wallets:');
      for (var wallet in eligibleWallets) {
        print('Claiming for wallet: ${wallet['name']} (${wallet['address']})');
      }

      // Gọi hàm Auto Claim Swap Play thông qua Bloc hoặc các dịch vụ khác
      onAutoClaimSwapPlayKitty(context, eligibleWallets);

      // Thông báo rằng quá trình Claim Swap Play đã bắt đầu
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto Claim-Swap-Play started successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claim-Swap-Play Group', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  bool isEligible = wallets[index]['isEligible'] == true; // Kiểm tra xem ví có thể Claim hay không

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isEligible ? Colors.green : Colors.red, // Green border nếu đủ điều kiện, red border nếu không
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      title: Row(
                        children: [
                          Text(
                            wallets[index]['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isEligible ? Colors.green : Colors.red,
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
                  onPressed: isCheckingWallets
                      ? null // Vô hiệu hóa nút nếu vẫn đang kiểm tra ví
                      : _onAutoClaimSwapPlay, // Gọi hành động Auto Claim Swap Play
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCheckingWallets ? Colors.grey : Colors.green,  // Đổi màu nút nếu đang kiểm tra
                  ),
                  child: Text(
                    isCheckingWallets ? 'Checking...' : 'Auto Now', // Thay đổi text khi đang kiểm tra
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

