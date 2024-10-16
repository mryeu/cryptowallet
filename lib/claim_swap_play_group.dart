import 'dart:ui';
import 'package:cryptowallet/services/member_service.dart';
import 'package:cryptowallet/services/session_manager.dart';
import 'package:cryptowallet/wallet_create.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'check_balance.dart';
import 'modules/member/blocs/claim_swap_play_bloc.dart';
import 'modules/member/claim_swap_play_widget.dart';
import 'modules/member/join_memeber_widget.dart';

class ClaimSwapPlayGroupPage extends StatefulWidget {
  @override
  _ClaimSwapPlayGroupPageState createState() => _ClaimSwapPlayGroupPageState();
}

class _ClaimSwapPlayGroupPageState extends State<ClaimSwapPlayGroupPage> {
  List<Map<String, dynamic>> wallets = [];
  final TokenBalanceChecker _balanceChecker = TokenBalanceChecker();
  bool isCheckingWallets = true;
  bool isShowDialog = false;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  @override
  void dispose() {
    super.dispose();
    // Cleanup nếu cần
  }

  Future<void> _loadWalletData() async {
    try {
      final walletDataDecrypt = await loadWalletPINFromJson(SessionManager.userPin!);
      if (walletDataDecrypt != null) {
        List<Map<String, dynamic>> loadedWallets = [];
        if (walletDataDecrypt.containsKey('wallet_names') &&
            walletDataDecrypt.containsKey('addresses') &&
            walletDataDecrypt.containsKey('decrypted_private_keys')) {
          List<String> walletNames = List<String>.from(walletDataDecrypt['wallet_names']);
          List<String> walletAddresses = List<String>.from(walletDataDecrypt['addresses']);
          List<String> privateKeys = List<String>.from(walletDataDecrypt['decrypted_private_keys']);

          for (int i = 0; i < walletNames.length; i++) {
            loadedWallets.add({
              'name': walletNames[i],
              'address': walletAddresses[i],
              'privateKey': privateKeys[i],
              'bnb_balance': 'Fetching...',
              'usdt_balance': 'Fetching...',
              'status': 'Pending',
              'isEligible': false,
            });
          }
        }

        if (mounted) {
          setState(() {
            wallets = loadedWallets;
          });
        }

        await _checkWalletStatuses();
        await _fetchWalletBalances(wallets);

        if (mounted) {
          setState(() {
            isCheckingWallets = false;
          });
        }
      }
    } catch (e) {
      print('Failed to load wallet data: $e');
    }
  }

  Future<void> _checkWalletStatuses() async {
    for (int i = 0; i < wallets.length; i++) {
      bool? isMember = await _checkIsMember(wallets[i]['address']);
      bool canPlay = await _checkPlayStatus(wallets[i]['address']);

      if (mounted) {
        setState(() {
          wallets[i]['status'] = (isMember! && canPlay) ? 'Claim' : 'Not Eligible';
          wallets[i]['isEligible'] = isMember && canPlay;
        });
      }
    }
  }

  Future<bool?> _checkIsMember(String walletAddress) async {
    return await MemberService().checkIsMember(walletAddress);
  }

  Future<bool> _checkPlayStatus(String walletAddress) async {
    return await getCheckPlay(walletAddress);
  }

  Future<void> _fetchWalletBalances(List<Map<String, dynamic>> wallets) async {
    for (var wallet in wallets) {
      try {
        double? bnbBalance = await _balanceChecker.getBnbBalance(wallet['address']);
        double? usdtBalance = await _balanceChecker.getUsdtBalance(wallet['address']);

        if (mounted) {
          setState(() {
            wallet['bnb_balance'] = bnbBalance != null ? bnbBalance.toStringAsFixed(4) : 'Error';
            wallet['usdt_balance'] = usdtBalance != null ? usdtBalance.toStringAsFixed(2) : 'Error';
          });
        }
      } catch (e) {
        print('Error fetching wallet balances: $e');
      }
    }
  }

  String _shortenAddress(String address) {
    return '${address.substring(0, 5)}...${address.substring(address.length - 5)}';
  }

  void _onAutoClaimSwapPlay() {
    List<Map<String, String>> eligibleWallets = wallets
        .where((wallet) => wallet['isEligible'] == true)
        .map((wallet) => wallet.map((key, value) => MapEntry(key, value.toString())))
        .toList();

    if (eligibleWallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No eligible wallets found for Auto Claim-Swap-Play.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // Bắt đầu hiển thị Dialog trước khi gọi hàm xử lý chính
      _showProcessingDialog();

      // Gọi hàm thực hiện và xử lý kết quả
      onAutoClaimSwapPlayKitty(context, eligibleWallets).then((_) {
        Navigator.of(context).pop(); // Đóng dialog khi hoàn thành
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto Claim-Swap-Play started successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }).catchError((error) {
        Navigator.of(context).pop(); // Đóng dialog khi có lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start Auto Claim-Swap-Play.'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  Future<void> onAutoClaimSwapPlayKitty(BuildContext context, List<Map<String, String>> members) async {
    // Gọi hàm xử lý trong Bloc
    BlocProvider.of<ClaimSwapPlayBloc>(context).add(onAutoClaimSwapPlay(members: members));
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ClaimSwapPlayBloc()..add(onClaimSwapPlayInit(members: [])),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Claim-Swap-Play Group',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Claim-Swap-Play: ${wallets.length}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: wallets.length,
                  itemBuilder: (context, index) {
                    bool isEligible = wallets[index]['isEligible'] == true;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isEligible ? Colors.green : Colors.red,
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
                                _shortenAddress(wallets[index]['address']!),
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
                    onPressed: isCheckingWallets ? null : _onAutoClaimSwapPlay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
        ),
        content: SizedBox(
          height: 150,
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title),
              const SizedBox(height: 20),
              Expanded(
                child: Text(content),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Close")),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
