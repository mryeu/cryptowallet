import 'package:cryptowallet/services/member_service.dart';
import 'package:cryptowallet/services/session_manager.dart';
import 'package:cryptowallet/wallet_create.dart';
import 'package:flutter/material.dart';
import 'check_balance.dart';
import 'modules/member/join_memeber_widget.dart';

class JoinPage extends StatefulWidget {
  @override
  JoinPageState createState() => JoinPageState();
}

class JoinPageState extends State<JoinPage> {
  final TextEditingController sponsorController = TextEditingController();
  List<Map<String, dynamic>> wallets = [];
  List<bool> walletChecked = [];
  final TokenBalanceChecker _balanceChecker = TokenBalanceChecker();
  int selectedCount = 0;
  bool isLoading = true; // Thêm biến để quản lý trạng thái loading

  @override
  void initState() {
    super.initState();
    _loadWalletData(); // Load wallet data on initialization
  }

  // Load wallet data from JSON
  Future<void> _loadWalletData() async {
    try {
      String? pin = SessionManager.userPin; // Lấy pin từ SessionManager hoặc nơi lưu trữ khác
      final walletDataDecrypt = await loadWalletPINFromJson(pin!); // Gọi hàm load dữ liệu từ JSON
      if (walletDataDecrypt != null) {
        List<Map<String, dynamic>> loadedWallets = [];
        // Đọc tên ví và địa chỉ từ JSON
        if (walletDataDecrypt.containsKey('wallet_names') &&
            walletDataDecrypt.containsKey('addresses')) {
          List<String> walletNames = List<String>.from(walletDataDecrypt['wallet_names']);
          List<String> walletAddresses = List<String>.from(walletDataDecrypt['addresses']);
          List<String> privateKeys = List<String>.from(walletDataDecrypt['decrypted_private_keys']);

          // Kiểm tra trạng thái thành viên của từng ví
          for (int i = 0; i < walletNames.length; i++) {
            bool? isMemberStatus = await isMember(walletAddresses[i]);
            if (!isMemberStatus!) {  // Nếu không phải là thành viên thì thêm vào danh sách
              loadedWallets.add({
                'name': walletNames[i],
                'address': walletAddresses[i],
                'privateKey': privateKeys[i],
                'bnb_balance': 'Fetching...', // Placeholder for BNB balance
                'usdt_balance': 'Fetching...', // Placeholder for USDT balance
              });
              walletChecked.add(false); // Tất cả checkbox ban đầu là false
            }
          }
        }
        // Cập nhật danh sách ví chưa là thành viên vào state và dừng trạng thái loading
        setState(() {
          wallets = loadedWallets;
          isLoading = false; // Tắt trạng thái loading sau khi dữ liệu đã được tải
        });

        // Fetch wallet balances cho các ví chưa là thành viên
        _fetchWalletBalances(wallets);
      }
    } catch (e) {
      print('Failed to load wallet data: $e');
      setState(() {
        isLoading = false; // Dừng loading ngay cả khi có lỗi
      });
    }
  }

  // Kiểm tra xem ví có phải là thành viên hay không
  Future<bool?> isMember(String walletAddress) async {
    try {
      bool? result = await MemberService().checkIsMember(walletAddress);
      return result;
    } catch (e) {
      print("Error checking membership status: $e");
      return false;
    }
  }

  // Lấy thông tin số dư
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

  // Rút gọn địa chỉ ví
  String _shortenAddress(String address) {
    return '${address.substring(0, 5)}...${address.substring(address.length - 5)}';
  }


  Future<void> _onJoinMember(BuildContext context) async {
    List<Map<String, dynamic>> selectedWallets = [];
    for (int i = 0; i < wallets.length; i++) {
      if (walletChecked[i]) {
        bool? isAlreadyMember = await isMember(wallets[i]['address']);
        if (isAlreadyMember == false) {
          selectedWallets.add(wallets[i]);
        }
      }
    }

    String sponsorWallet = sponsorController.text;
    if (sponsorWallet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sponsor wallet cannot be empty.'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (!RegExp(r"^0x[a-fA-F0-9]{40}$").hasMatch(sponsorWallet)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid sponsor wallet address.'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (selectedWallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No wallets selected or all are already members.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // Chuyển đổi danh sách selectedWallets từ Map<String, dynamic> sang Map<String, String>
      List<Map<String, String>> convertedWallets = selectedWallets.map((wallet) {
        return wallet.map((key, value) => MapEntry(key, value.toString()));
      }).toList();

      // Gọi hàm onJoinMemberKitty với các ví đã chuyển đổi
      print('Calling onJoinMemberKitty...');
      onJoinMemberKitty(context, convertedWallets, sponsorWallet, walletChecked);
    }
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
              onChanged: (value) {
                // Kiểm tra nếu URL chứa "https://" hoặc "kittyrun.io"
                if (value.contains('https://') || value.contains('kittyrun.io')) {
                  // Tách chuỗi tại dấu '=' và lấy phần sau dấu '='
                  final parts = value.split('=');
                  if (parts.length > 1 && parts[1].isNotEmpty) {
                    // Nếu có phần địa chỉ ví sau dấu "="
                    final address = parts[1];
                    // Cập nhật giá trị vào sponsorController với địa chỉ sau dấu '='
                    sponsorController.text = address;
                    sponsorController.selection = TextSelection.fromPosition(
                      TextPosition(offset: sponsorController.text.length),
                    );
                  } else {
                    // Nếu không có địa chỉ sau dấu "=" (ví dụ "kittyrun.io/?ref=")
                    // Hiển thị thông báo hoặc bỏ qua việc cập nhật
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid or empty sponsor address.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 20),

            // Select Wallet Section
            Text(
              'Select Wallet: $selectedCount/${wallets.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Hiển thị trạng thái Loading nếu danh sách đang được tải
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator()) // Hiển thị loading khi dữ liệu đang được tải
                  : ListView.builder(
                itemCount: wallets.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.green, width: 1),
                    ),
                    child: CheckboxListTile(
                      title: Row(
                        children: [
                          Text(
                            wallets[index]['name'],
                            style: const TextStyle(
                              color: Colors.green,
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
                      value: walletChecked[index],
                      onChanged: (bool? value) {
                        setState(() {
                          walletChecked[index] = value ?? false;
                          selectedCount = walletChecked.where((e) => e).length;
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
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () {
                    _onJoinMember(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Join Now',
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

