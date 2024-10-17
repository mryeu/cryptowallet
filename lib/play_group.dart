import 'dart:ui';
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
  bool isProcessing = false; // Trạng thái đang xử lý cho dialog

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
          List<String> privateKeys = List<String>.from(walletDataDecrypt['decrypted_private_keys']);

          for (int i = 0; i < walletNames.length; i++) {
            loadedWallets.add({
              'name': walletNames[i],
              'address': walletAddresses[i],
              'privateKey': privateKeys[i],
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
      // Tạo danh sách các Map<String, String>
      List<Map<String, String>> stringifiedWallets = selectedWallets.map((wallet) {
        return wallet.map((key, value) => MapEntry(key, value.toString()));
      }).toList();
      List<bool> walletSelections = selectedWallets.map((wallet) => wallet['selected'] as bool).toList();

      // Hiển thị Dialog lần đầu tiên với thông tin của ví đầu tiên
      String currentWalletName = stringifiedWallets[0]['name']!;
      String currentWalletAddress = stringifiedWallets[0]['address']!;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return ConfirmDialog(
                title: 'Processing...',
                content: 'Playing wallet:\n\nName: $currentWalletName\nAddress: $currentWalletAddress',
              );
            },
          );
        },
      );

      // Bắt đầu vòng lặp xử lý từng ví
      Future.delayed(Duration.zero, () async {
        for (int i = 0; i < stringifiedWallets.length; i++) {
          final wallet = stringifiedWallets[i];

          // Cập nhật thông tin ví trong Dialog
          currentWalletName = wallet['name']!;
          currentWalletAddress = wallet['address']!;

          // Đóng Dialog hiện tại trước khi mở Dialog mới
          if (Navigator.canPop(context)) {
            Navigator.pop(context);  // Đóng Dialog hiện tại
          }

          // Cập nhật lại ConfirmDialog với thông tin ví mới
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return ConfirmDialog(
                title: 'Processing...',
                content: 'Playing wallet:\n\nName: $currentWalletName\nAddress: $currentWalletAddress',
              );
            },
          );

          // Xử lý ví hiện tại
          await onPlayNowKitty(context, [wallet], [walletSelections[i]]);

          // Đợi 7 giây trước khi xử lý ví tiếp theo
          await Future.delayed(const Duration(seconds: 7));
        }

        // Sau khi tất cả ví đã được xử lý, đóng Dialog hoặc hiển thị thông báo hoàn tất
        if (Navigator.canPop(context)) {
          Navigator.pop(context);  // Đóng Dialog cuối cùng
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return ConfirmDialog(
              title: 'Completed',
              content: 'All wallets have been played successfully!',
              confirmText: 'Close',
            );
          },
        );
      });
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
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Select Wallet Play: ', // Label
                    style: TextStyle(
                      color: Colors.green, // Green color for the label
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: '$selectedCount/${wallets.where((wallet) => wallet['canPlay'] && wallet['isMember']).length}', // Display only wallets that can play and are members
                    style: TextStyle(
                      color: Colors.red, // Red color for the value
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
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
                      : null, // Vô hiệu hóa nút Play nếu đang kiểm tra
                  style: ElevatedButton.styleFrom(
                    backgroundColor: allWalletsChecked ? Colors.green : Colors.grey,
                  ),
                  child: allWalletsChecked
                      ? const Text(
                    'Play',
                    style: TextStyle(color: Colors.white),
                  )
                      : Row(
                    mainAxisSize: MainAxisSize.min, // Để cho Row vừa với nội dung bên trong
                    children: const [
                      Text(
                        'Checking...',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(width: 10), // Khoảng cách giữa text và CircularProgressIndicator
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red), // Màu đỏ cho biểu tượng
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? confirmText;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            content,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (confirmText != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog khi bấm nút
              },
              child: Text(confirmText!),
            ),
        ],
      ),
    );
  }
}