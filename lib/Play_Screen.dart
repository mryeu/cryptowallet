import 'package:cryptowallet/mixins/check_time_claim_mixin.dart';
import 'package:cryptowallet/play_group.dart';
import 'package:cryptowallet/services/member_service.dart';
import 'package:cryptowallet/services/session_manager.dart';
import 'package:cryptowallet/wallet_create.dart'; // Import wallet creation functions
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import 'WalletDetailsPage.dart';
import 'add_member.dart';
import 'check_balance.dart';
import 'claim_swap_play_group.dart';
import 'join_group.dart';
import 'modules/member/blocs/claim_swap_play_bloc.dart';
import 'modules/member/blocs/join_member_bloc.dart';
import 'wallet_create.dart';

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
            List<String> privateKeys = List<String>.from(walletDataDecrypt['decrypted_private_keys']);

            for (int i = 0; i < walletNames.length; i++) {
              wallets.add({
                'name': walletNames[i],
                'address': walletAddresses[i],
                'privateKey': privateKeys[i],
                'bnb_balance': 'Fetching...', // Placeholder for BNB balance
                'usdt_balance': 'Fetching...', // Placeholder for USDT balance
                'isMember': false, // Thêm isMember để kiểm tra
              });
              walletFilterOptions.add(walletNames[i]);
            }
          }

          // Fetch wallet balances and check membership status
          _fetchWalletBalances(wallets);
          _checkWalletMembership(wallets); // Kiểm tra trạng thái thành viên
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

  // Function to check membership status for each wallet
  Future<void> _checkWalletMembership(List<Map<String, dynamic>> wallets) async {
    for (var wallet in wallets) {
      bool? isMember = await MemberService().checkIsMember(wallet['address']);
      setState(() {
        wallet['isMember'] = isMember ?? false;
      });
    }
  }

  Future<void> _onAddAutoPlay(Map<String, dynamic> wallet) async {
    try {
      bool can_play = await checkPlay(wallet['address']) ?? false;
      TokenBalanceChecker checker = TokenBalanceChecker();
      MemberService memberService = MemberService();
      double? usdt = await checker.getUsdtBalance(wallet['address']);

      if (can_play) {
        if (usdt! >= 480) {
            String txHash = await memberService.addDeposit(context, wallet['privateKey'], wallet['address']);  
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Add auto play success $txHash',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please deposit money to address!',
              ),
              backgroundColor: Colors.yellow,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please waiting play after add auto play',
              ),
              backgroundColor: Colors.yellow,
            ),
          );
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Add atuo play error $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Trả về false để vô hiệu hóa nút back
        return false;
      },
      child: Scaffold(
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
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (context) => JoinMemberBloc(), // Khởi tạo Bloc ở đây
                              child: JoinPage(),
                            ),
                          ),
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
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (context) => JoinMemberBloc(),
                              child: PlayGroupPage(),
                            ),
                          ),
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
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (context) => ClaimSwapPlayBloc(),
                              child: ClaimSwapPlayGroupPage(),
                            ),
                          ),
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
                        onLongPress: () {
                          _showWalletOptions(context, wallets[index]);
                        },
                        onTap: () {
                          // Show full-screen popup when wallet is tapped
                          print('=====tap ${wallets[index]}');
                          showFullScreenModal(context, wallets[index]);
                        },
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Colors.green, width: 1),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Row for wallet name, shortened address, and copy button
                                Row(
                                  children: [
                                    // Wallet name
                                    Text(
                                      wallets[index]['name'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green, // Tên ví màu xanh
                                      ),
                                    ),
                                    const Text(" : "),

                                    // Shortened address
                                    Expanded(
                                      child: Text(
                                        _shortenAddress(wallets[index]['address']), // Rút gọn địa chỉ
                                        style: const TextStyle(color: Colors.black54),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    // Copy button
                                    IconButton(
                                      icon: const Icon(Icons.copy, color: Colors.grey), // Nút sao chép
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: wallets[index]['address'])); // Sao chép địa chỉ vào clipboard
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Address copied to clipboard')), // Thông báo khi sao chép thành công
                                        );
                                      },
                                    ),
                                  ],
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

                                    // Check if the wallet is a member to show the appropriate button
                                    ElevatedButton(
                                      onPressed: wallets[index]['isMember']
                                          ? () async {
                                        // Hành động khi nhấn nút
                                        _onAddAutoPlay(wallets[index]);
                                        try {
                                          TransactionServiceMember memberService = TransactionServiceMember();
                                        } catch (e) {
                                        }
                                      }
                                          : () {
                                        // Handle Join action for this wallet
                                      },
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.green,
                                      ),
                                      child: Text(wallets[index]['isMember'] ? 'Auto Play' : 'Join'),
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
      ),
    );
  }

  String _shortenAddress(String address) {
    if (address.length > 10) {
      return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
    }
    return address; // Nếu địa chỉ quá ngắn, không cần rút gọn
  }

  // Function to show wallet options when long pressed
  void _showWalletOptions(BuildContext context, Map<String, dynamic> wallet) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Wallet'),
              onTap: () {
                deleteWallet(wallet['address']);
                setState(() {

                  wallets.remove(wallet); // Remove the wallet from the list
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> deleteWallet(String walletAddress) async {
    try {
      // Tải dữ liệu ví hiện tại từ file JSON
      final walletData = await loadWalletFromJson();

      if (walletData == null) {
        print('Không tìm thấy dữ liệu ví.');
        return;
      }

      // Tìm vị trí của địa chỉ ví để xóa
      List<String> addresses = List<String>.from(walletData['addresses']);
      List<String> walletNames = List<String>.from(walletData['wallet_names']);
      List<String> encryptedPrivateKeys = List<String>.from(walletData['encrypted_private_keys']);

      int walletIndex = addresses.indexOf(walletAddress);
      if (walletIndex == -1) {
        print('Không tìm thấy địa chỉ ví để xóa.');
        return;
      }

      // Xóa địa chỉ, tên ví và private key tương ứng
      addresses.removeAt(walletIndex);
      walletNames.removeAt(walletIndex);
      encryptedPrivateKeys.removeAt(walletIndex);

      // Lưu dữ liệu đã cập nhật vào file JSON
      final updatedWalletData = {
        'encrypted_mnemonic': walletData['encrypted_mnemonic'],
        'encrypted_private_keys': encryptedPrivateKeys,
        'addresses': addresses,
        'wallet_names': walletNames,
      };

      await saveWalletToJson(updatedWalletData);
      print('Đã xóa ví thành công.');
    } catch (e) {
      print('Lỗi khi xóa ví: $e');
    }
  }

  // Function to show the wallet details in a full-screen modal
  void showFullScreenModal(BuildContext context, Map<String, dynamic> wallet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WalletDetailsPage(wallet: wallet),
      ),
    );
  }
}
