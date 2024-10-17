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
      Map<String, dynamic> info = await _getUserInfo(wallets[i]['address']);
      int unixClaim = await _checkHasClaim(wallets[i]['address']);
      print('=====can play ${wallets[i]['address']} -- $info $unixClaim');

      if (mounted) {
        setState(() {
          wallets[i]['status'] =
          (isMember! && canPlay) ? 'Play' : 'Played';
          wallets[i]['isEligible'] = isMember && canPlay;
          wallets[i]['info'] = info;
          wallets[i]['statusClaim'] = unixClaim > 0 ? 'Has claim' : 'Not found';
          wallets[i]['unixClaim'] = unixClaim;
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

  Future<Map<String, dynamic>> _getUserInfo(String walletAddress) async {
    MemberService memberService = MemberService();
    return await memberService.getUserInfo(walletAddress);
  }

  Future<int> _checkHasClaim(String? walletAddress) async {
    int unixTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int unixCheck = (unixTime / 86400).floor() - 50;
    MemberService memberService = MemberService();
    int times = 15;
    int resultUnix = 0;

    for (int i = 0; i <= times; i++) {
      final Map<String, dynamic> checkPlay = await memberService.getVote(walletAddress ?? '', unixCheck - i);

      // Assuming you want to check if 'checkPlay' contains some claimable condition
      print('$walletAddress: ${checkPlay}');

      // Example condition, modify according to your actual use case
      if (checkPlay['percent'] > 0  && checkPlay['claimed'] == false) {
        resultUnix = unixCheck - i;
        break;
      }
    }

    return resultUnix;  // Return 1 if can claim, otherwise 0
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
                if (state.status == BlocStatus.success) {
                  // Close the dialog when the process is done
                  Navigator.of(context).pop();
                  _loadWalletData();
                }
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
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Total Claim-Swap-Play: ',
                          style: TextStyle(
                            color: Colors.green, // Green color for the label
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: '${wallets.where((wallet) => wallet['status'] == 'Play').length}',
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
                                    const SizedBox(width: 8),
                                    Image.asset(
                                      'assets/images/usdt_logo.png',
                                      width: 24,
                                      height: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${wallets[index]['usdt_balance']}'),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Status: ', // "Status" text in black
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      TextSpan(
                                        text: wallets[index]['status'], // The status value (e.g., "Play" or "Played")
                                        style: TextStyle(
                                          color: wallets[index]['status'] == 'Play' ? Colors.green : Colors.red, // Green for "Play", Red for "Played"
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Total Played: ', // "Total Played" label in black
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      TextSpan(
                                        text: '${wallets[index]['info']?['totalVote']}', // The value of "Total Played"
                                        style: const TextStyle(color: Colors.red), // Red color for the value
                                      ),
                                      const TextSpan(
                                        text: ', Claimed: ', // "Claimed" label in black
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      TextSpan(
                                        text: '${wallets[index]['info']?['totalClaim']}', // The value of "Claimed"
                                        style: const TextStyle(color: Colors.red), // Red color for the value
                                      ),
                                    ],
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Find claim: ', // "Find claim" label in black
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      TextSpan(
                                        text: wallets[index]['statusClaim'], // The value of "statusClaim"
                                        style: TextStyle(
                                          color: wallets[index]['statusClaim'] == 'Has claim' ? Colors.green : Colors.red, // Green for "Has claim", red for "Not found"
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

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
                        onPressed: isCheckingWallets ? null : _onAutoClaimSwapPlay, // Disable button when scanning
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCheckingWallets ? Colors.grey : Colors.green, // Change background color when disabled
                        ),
                        child: isCheckingWallets
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('Scanning', style: TextStyle(color: Colors.white)), // Show "Scanning" when disabled
                            SizedBox(width: 10), // Spacing between text and progress indicator
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.red), // Spinner color is red
                              ),
                            ),
                          ],
                        )
                            : const Text(
                          'Auto Now',
                          style: TextStyle(color: Colors.white), // Show "Auto Now" when enabled
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