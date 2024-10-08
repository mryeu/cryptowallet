import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../add_member.dart';
import '../../check_balance.dart';
import '../../services/member_service.dart';
import '../transaction/transaction_play_widget.dart';
import 'blocs/join_member_bloc.dart';
import 'blocs/list_member_bloc.dart';

class ListMemberWidget extends StatefulWidget {
  final List<Map<String, String>> walletList;
  const ListMemberWidget({Key? key, required this.walletList});

  @override
  State<ListMemberWidget> createState() => _ListMemberState();
}

void onClickAddDeposit(BuildContext context, String privateKey, String walletAddress) {
  BlocProvider.of<ListMemberBloc>(context).add(
    onAddDeposit(context: context, privateKey: privateKey, walletAddress: walletAddress),
  );
}

class _ListMemberState extends State<ListMemberWidget> {
  void navigateToTransactionPlay(BuildContext context, List<Map<String, String>> walletList) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionPlayWidget1(walletList: walletList),
      ),
    );
  }

  @override
  Widget build(BuildContext contextMain) {
    return BlocProvider(
      create: (_) => ListMemberBloc()..add(onListMemberInit(walletList: widget.walletList)),
      child: BlocBuilder<ListMemberBloc, ListMemberState>(
        builder: (contextMain, state) {
          return Expanded(
            child: ListView.builder(
              itemCount: widget.walletList.length,
              itemBuilder: (context, index) {
                TransactionServiceMember memberService = TransactionServiceMember();
                final wallet = widget.walletList[index];
                final walletName = wallet['name'] ?? 'Unknown Wallet';
                final privateKey = wallet['privateKey'] ?? '';
                final walletAddress = wallet['address'] ?? 'No Address';

                return FutureBuilder<bool?>(
                  future: memberService.checkIsMember(walletAddress),
                  builder: (context, snapshot) {
                    final isMember = snapshot.data ?? false;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 1),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Colors.green),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Cột 1
                              buildColumn1(walletName, walletAddress),
                              const SizedBox(width: 5),
                              // Cột 2
                              buildColumn2(walletAddress),
                              // Cột 3
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          // Icon button với dấu ba chấm dọc
                                          IconButton(
                                            icon: const Icon(
                                              Icons.more_vert,
                                              color: Colors.green,
                                            ),
                                            onPressed: () {
                                              // Điều hướng tới TransactionPlayWidget khi nhấn nút
                                              navigateToTransactionPlay(context, widget.walletList);
                                            },
                                          ),
                                          // Nút Auto Play
                                          ElevatedButton(
                                            onPressed: () async {
                                              onClickAddDeposit(contextMain, privateKey, walletAddress);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                            ),
                                            child: const Text(
                                              'Auto Play',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

Widget buildColumn1(String walletName, String address) {
  return Expanded(
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: AssetImage('assets/images/logo_ktr.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                walletName,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${address.substring(0, 5)}...${address.substring(address.length - 5)}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildColumn2(String walletAddress) {
  return Expanded(
    child: FutureBuilder<Map<String, dynamic>>(
      future: _loadBalances(walletAddress),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Text(
            'Error loading balance',
            style: TextStyle(color: Colors.red),
          );
        } else if (snapshot.hasData) {
          final balanceData = snapshot.data;
          double usdBalance = balanceData?['usdt'] ?? 0.0;
          final amount = balanceData?['amount'] ?? 0;
          final amounted = balanceData?['amounted'] ?? 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '\$$usdBalance',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '$amount/$amounted',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          return const Text('No balance available');
        }
      },
    ),
  );
}

Future<Map<String, double>> _loadBalances(String walletAddress) async {
  TokenBalanceChecker checker = TokenBalanceChecker();
  MemberService memberService = MemberService();
  double? bnb = await checker.getBnbBalance(walletAddress);
  double? usdt = await checker.getUsdtBalance(walletAddress);
  double? ktr = await checker.getKtrBalance(walletAddress);
  Map<String, int> dataPlay = await memberService.getPlayBalance(walletAddress);

  return {
    "bnb": bnb ?? 0.0,
    "usdt": usdt ?? 0.0,
    "ktr": ktr ?? 0.0,
    "amount": (dataPlay['amount'] ?? 0).toDouble(),
    "amounted": (dataPlay["amounted"] ?? 0).toDouble(),
  };
}
