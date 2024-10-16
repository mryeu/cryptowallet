import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../check_balance.dart';
import '../../mixins/check_time_claim_mixin.dart';
import 'blocs/claim_swap_play_bloc.dart';
import 'join_memeber_widget.dart';

class ClaimSwapPlayWidget extends StatefulWidget {
  final List<Map<String, String>> members;
  const ClaimSwapPlayWidget({Key? key, required this.members});

  @override
  State<ClaimSwapPlayWidget> createState() => _claimSwapPlatWidget();
}


void onAutoClaimSwapPlayKitty (BuildContext context, members) {
  BlocProvider.of<ClaimSwapPlayBloc>(context).add(
    onAutoClaimSwapPlay(members: members),
  );
}

// Future<bool> getCheckPlay(String walletAddress) async {
//   bool checkplay = await checkPlay(walletAddress);
//   return checkplay;
// }

class _claimSwapPlatWidget extends State<ClaimSwapPlayWidget> {
  get walletChecked => null;
  bool isShowDialog = false;


  @override
  Widget build(BuildContext contextMain) {
    return BlocProvider(
        create: (_) => ClaimSwapPlayBloc()..add(onClaimSwapPlayInit(members: widget.members)),
        child: BlocConsumer<ClaimSwapPlayBloc, ClaimSwapPlayState>(
          // listenWhen: (previous, current) => previous.status != current.status,
            listener: (context,ClaimSwapPlayState state) {
              if(state.status == BlocStatus.processing ){

                if(isShowDialog){
                  Navigator.of(context).pop();
                }
                setState(() {
                  isShowDialog = true;
                });

                ConfirmDialog alert = ConfirmDialog(
                  title: state.title,
                  content: state.message,

                );
                showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context)=> alert
                );
              }
            },
            builder: (contextMain, state) {
              return StatefulBuilder(
                builder: (BuildContext context2, StateSetter setState) {
                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: 500,
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 50,
                            child: Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Center(
                                child: Text(
                                  'Auto Claim Swap Play',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const SizedBox(
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.only(left: 20.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Select Wallets Play:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 40,
                            child: Row(
                              children: [
                                Expanded(flex: 1, child: Text('  Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 4, child: Text('Address', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('BNB Balance', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('USDT Balance', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('KTR Balance', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                          const Divider(),
                          Expanded(
                            child: ListView.builder(
                              itemCount: state.members.length,
                              itemBuilder: (context, index) {
                                String walletName = state.members[index]["name"] ?? "Unknown Wallet";
                                String walletAddress = state.members[index]["address"] ?? "";

                                return FutureBuilder(
                                  future: Future.wait([
                                    _loadBalances(walletAddress),
                                    getCheckPlay(walletAddress),
                                  ]),
                                  builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return Container(
                                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: const Center(child: CircularProgressIndicator()),
                                      );
                                    } else if (snapshot.hasError) {
                                      return Container(
                                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.red),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: const Text('Error loading balances or status'),
                                      );
                                    } else {
                                      Map<String, double> balances = snapshot.data?[0] ?? {};
                                      bool isPlaying = snapshot.data?[1] ?? false;

                                      double bnbBalance = balances["bnb"] ?? 0.0;
                                      double usdtBalance = balances["usdt"] ?? 0.0;
                                      double ktrBalance = balances["ktr"] ?? 0.0;

                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                walletName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ),
                                            Expanded(flex: 4, child: Text(walletAddress)),
                                            Expanded(
                                              flex: 2,
                                              child: Row(
                                                children: [
                                                  Image.asset(
                                                    'assets/images/bnb-bnb-logo.png',
                                                    width: 15,
                                                    height: 15,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(bnbBalance.toStringAsFixed(4)),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Row(
                                                children: [
                                                  Image.asset(
                                                    'assets/images/usdt_logo.png',
                                                    width: 15,
                                                    height: 15,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(usdtBalance.toStringAsFixed(2)),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Row(
                                                children: [
                                                  Image.asset(
                                                    'assets/images/logo_ktr.png',
                                                    width: 15,
                                                    height: 15,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(ktrBalance.toStringAsFixed(2)),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(isPlaying ? "Play" : "Played"),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ),

                          SizedBox(
                            height: 50,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      onAutoClaimSwapPlayKitty(context2, widget.members);
                                    },

                                    child: const Text(
                                      'Auto Claim Swap Play Now',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            })
    );
  }
}

Future<Map<String, double>> _loadBalances(String walletAddress) async {
  TokenBalanceChecker checker = TokenBalanceChecker();
  double? bnb = await checker.getBnbBalance(walletAddress);
  double? usdt = await checker.getUsdtBalance(walletAddress);
  double? ktr = await checker.getKtrBalance(walletAddress);
  return {
    "bnb": bnb ?? 0.0,
    "usdt": usdt ?? 0.0,
    "ktr": ktr ?? 0.0,
  };
}

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? confirmText;
  // final VoidCallback continueCallBack;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    // required this.continueCallBack,
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
              Text(
                title,
                // style: Styling.text.titleLarge,
                textScaler: TextScaler.noScaling,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Text(
                  content,
                  // style: Styling.text.bodyMedium,
                  textScaler: TextScaler.noScaling,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(onPressed: () => Navigator.of(context).pop() , child: Text("Close")),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}