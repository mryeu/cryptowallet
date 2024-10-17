import 'dart:ui';
import 'package:cryptowallet/services/member_service.dart';
import 'package:cryptowallet/services/session_manager.dart';
import 'package:cryptowallet/wallet_create.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'check_balance.dart';
import 'modules/member/blocs/claim_swap_play_bloc.dart';
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

  // Load wallet data và trạng thái của ví
  Future<void> _loadWalletData() async {
    try {
      final walletDataDecrypt = await loadWalletPINFromJson(
          SessionManager.userPin!);
      if (walletDataDecrypt != null) {
        List<Map<String, dynamic>> loadedWallets = [];
        if (walletDataDecrypt.containsKey('wallet_names') &&
            walletDataDecrypt.containsKey('addresses') &&
            walletDataDecrypt.containsKey('decrypted_private_keys')) {
          List<String> walletNames = List<String>.from(
              walletDataDecrypt['wallet_names']);
          List<String> walletAddresses = List<String>.from(
              walletDataDecrypt['addresses']);
          List<String> privateKeys = List<String>.from(
              walletDataDecrypt['decrypted_private_keys']);

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

  // Kiểm tra trạng thái của từng ví
  Future<void> _checkWalletStatuses() async {
    for (int i = 0; i < wallets.length; i++) {
      bool? isMember = await _checkIsMember(wallets[i]['address']);
      bool canPlay = await _checkPlayStatus(wallets[i]['address']);

      if (mounted) {
        setState(() {
          wallets[i]['status'] =
          (isMember! && canPlay) ? 'Claim' : 'Not Eligible';
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

  // Lấy số dư của ví
  Future<void> _fetchWalletBalances(List<Map<String, dynamic>> wallets) async {
    for (var wallet in wallets) {
      try {
        double? bnbBalance = await _balanceChecker.getBnbBalance(
            wallet['address']);
        double? usdtBalance = await _balanceChecker.getUsdtBalance(
            wallet['address']);

        if (mounted) {
          setState(() {
            wallet['bnb_balance'] =
            bnbBalance != null ? bnbBalance.toStringAsFixed(4) : 'Error';
            wallet['usdt_balance'] =
            usdtBalance != null ? usdtBalance.toStringAsFixed(2) : 'Error';
          });
        }
      } catch (e) {
        print('Error fetching wallet balances: $e');
      }
    }
  }

  // Rút ngắn địa chỉ ví
  String _shortenAddress(String address) {
    return '${address.substring(0, 5)}...${address.substring(
        address.length - 5)}';
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
      // Access the current bloc instance before calling the dialog
      final bloc = BlocProvider.of<ClaimSwapPlayBloc>(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return BlocProvider.value(
            value: bloc, // Pass the existing Bloc instance
            child: BlocBuilder<ClaimSwapPlayBloc, ClaimSwapPlayState>(
              builder: (context, state) {
                return AlertDialog(
                  title: Text(state.title ?? 'Processing...'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.message ?? 'Auto Claim-Swap-Play is in progress...'),
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );

      // Trigger the event to start processing
      bloc.add(onAutoClaimSwapPlay(members: eligibleWallets));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ClaimSwapPlayBloc(),
      child: BlocConsumer<ClaimSwapPlayBloc, ClaimSwapPlayState>(
        listener: (context, state) {
          if (state.status == BlocStatus.success || state.status == BlocStatus.failure) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(); // Close the dialog
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.status == BlocStatus.success
                      ? 'Auto Claim-Swap-Play completed successfully!'
                      : 'Auto Claim-Swap-Play failed!',
                ),
                backgroundColor: state.status == BlocStatus.success ? Colors.green : Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Claim-Swap-Play Group',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
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
          );
        },
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
