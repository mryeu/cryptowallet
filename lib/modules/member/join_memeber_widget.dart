import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:web3dart/web3dart.dart';
import '../../check_balance.dart';
import '../../mixins/check_time_claim_mixin.dart';
import '../../services/member_service.dart';
import 'blocs/join_member_bloc.dart';
import 'claim_swap_play_widget.dart';





class BuildWidget extends StatefulWidget {
  @override
  _BuildWidgetState createState() => _BuildWidgetState();
}

class _BuildWidgetState extends State<BuildWidget> {
  final MemberService memberService = MemberService(); // Create an instance of MemberService
  TextEditingController privateKeyController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  // Example: Function to call the addMember method
  Future<void> addMember() async {
    String privateKey = privateKeyController.text;
    String address = addressController.text;

    if (privateKey.isEmpty || address.isEmpty) {
      _showErrorToast('Private key and address cannot be empty.');
      return;
    }

    try {
      EthereumAddress accountAddress = EthereumAddress.fromHex(address);
      EthereumAddress refAddress = EthereumAddress.fromHex('0xSponsorAddressHere');

      String txHash = await memberService.addMember(privateKey, accountAddress, refAddress);
      _showSuccessToast('Transaction successful with hash: $txHash');
    } catch (e) {
      _showErrorToast('Error adding member: $e');
    }
  }

  // Example: Function to call the claim-swap-play actions
  Future<void> claimSwapPlay() async {
    String privateKey = privateKeyController.text;
    String address = addressController.text;
    double? amount = double.tryParse(amountController.text);

    if (privateKey.isEmpty || address.isEmpty || amount == null || amount <= 0) {
      _showErrorToast('Please provide valid private key, address, and amount.');
      return;
    }

    try {
      List<Map<String, String>> wallets = [
        {'address': address, 'privateKey': privateKey},
      ];
      await memberService.executeActionsForWallets(wallets, amount);
      _showSuccessToast('Claim-Swap-Play actions executed successfully.');
    } catch (e) {
      _showErrorToast('Error executing actions: $e');
    }
  }

  // Function to show success toast
  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // Function to show error toast
  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Build Widget Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: privateKeyController,
              decoration: const InputDecoration(labelText: 'Private Key'),
            ),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Wallet Address'),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: addMember,
              child: const Text('Add Member'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: claimSwapPlay,
              child: const Text('Claim-Swap-Play'),
            ),
          ],
        ),
      ),
    );
  }
}


class JoinMemeberWidget extends StatefulWidget {
  final List<Map<String, String>> walletList;
  const JoinMemeberWidget({Key? key, required this.walletList}) : super(key: key);

  @override
  State<JoinMemeberWidget> createState() => _JoinMemeberState();
}

void onJoinMemberKitty(BuildContext context, selectedMember, String refCode, walletChecked) {
  BlocProvider.of<JoinMemberBloc>(context).add(
    onJoinMember(context: context, selectedMember: selectedMember, refCode: refCode, checked: walletChecked),
  );
}

void onPlayNowKitty(BuildContext context, selectedMember, walletChecked) {
  BlocProvider.of<JoinMemberBloc>(context).add(
    onPlayNow(context: context, checkedMember: selectedMember, checked: walletChecked),
  );
}

Future<bool> getCheckPlay(String walletAddress) async {
  bool checkplay = await checkPlay(walletAddress);
  return checkplay;
}

class _JoinMemeberState extends State<JoinMemeberWidget> {
  TextEditingController amountController = TextEditingController();

  final MemberService memberService = MemberService(); // Tạo một instance của MemberService
  TextEditingController privateKeyController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  Future<void> executeClaimSwapPlay(List<Map<String, String>> wallets, double amount) async {
    if (wallets.isEmpty || amount <= 0) {
      _showErrorToast('Wallet null');
      return;
    }

    try {
      await memberService.executeActionsForWallets(wallets, amount);
      _showSuccessToast('Claim-Swap-Play success.');
    } catch (e) {
      _showErrorToast('Error Claim-Swap-Play: $e');
    }
  }


  // Hàm hiển thị thông báo thành công
  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // Hàm hiển thị thông báo lỗi
  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  List<bool> walletChecked = [];

  @override
  void initState() {
    super.initState();
    // Khởi tạo danh sách checkbox
    walletChecked = List<bool>.filled(widget.walletList.length, false);
  }


  @override
  Widget build(BuildContext mainContext) {
    return BlocProvider(
      create: (_) => JoinMemberBloc()..add(onJoinMemberInit(walletList: widget.walletList)),
      child: BlocBuilder<JoinMemberBloc, JoinMemberState>(
        builder: (mainContext, state) {
          print('state join member $state');
          return  Container(
              child: BlocBuilder<JoinMemberBloc, JoinMemberState>(builder: (context, state){
                if (state.status == BlocStatus.success) {
                  // sử dụng state o day
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Phần bên trái: Text
                      Row(
                        children: [
                          const Text(
                            'Played Wallet list',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${state.members.length}/${state.data.length}', // Hiển thị số ví đã dùng so với tổng số
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      // Phần bên phải: Các nút và dropdown
                      Row(
                        children: [
                          const SizedBox(width: 10),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              // Thực hiện hành động khi nhấn vào nút Play
                              showDialog(
                                context: context,
                                builder: (BuildContext context1) {
                                  print('Check not member ${state.members}');
                                  List<bool> walletChecked = List<bool>.filled(state.members.length, false);
                                  return StatefulBuilder(
                                    builder: (BuildContext context2, StateSetter setState) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.0),
                                        ),
                                        child: SizedBox(
                                          width: MediaQuery.of(context).size.width * 0.8, // Mở rộng chiều rộng thành 80% của màn hình
                                          height: 500, // Đặt chiều cao bằng 700
                                          child: Column(
                                            children: [
                                              // Tiêu đề chiếm 50
                                              const SizedBox(
                                                height: 50,
                                                child: Padding(
                                                  padding: EdgeInsets.all(10.0),
                                                  child: Center(
                                                    child: Text(
                                                      'Play',
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
                                              // Tiêu đề danh sách ví chiếm 20
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
                                              // Header cho danh sách ví chiếm 40
                                              const SizedBox(
                                                height: 40,
                                                child: Row(
                                                  children: [
                                                    Expanded(flex: 1, child: Text('  Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                                    Expanded(flex: 4, child: Text('Address', style: TextStyle(fontWeight: FontWeight.bold))),
                                                    Expanded(flex: 2, child: Text('BNB Balance', style: TextStyle(fontWeight: FontWeight.bold))),
                                                    Expanded(flex: 2, child: Text('USDT Balance', style: TextStyle(fontWeight: FontWeight.bold))),
                                                    Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                                    Expanded(flex: 1, child: Text('Select', style: TextStyle(fontWeight: FontWeight.bold))),
                                                  ],
                                                ),
                                              ),
                                              const Divider(),
                                              // Danh sách ví (phủ phần còn lại)
                                              Expanded(
                                                child: ListView.builder(
                                                  itemCount: state.members.length,
                                                  itemBuilder: (context, index) {
                                                    String walletName = state.members[index]["name"] ?? "Unknown Wallet";
                                                    String walletAddress = state.members[index]["address"] ?? "";

                                                    return FutureBuilder<Map<String, double>>(
                                                      future: _loadBalances(walletAddress),  // Fetching balances for the wallet
                                                      builder: (context, balanceSnapshot) {
                                                        if (balanceSnapshot.connectionState == ConnectionState.waiting) {
                                                          return Container(
                                                            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                                            padding: const EdgeInsets.all(8.0),
                                                            decoration: BoxDecoration(
                                                              border: Border.all(color: Colors.grey),
                                                              borderRadius: BorderRadius.circular(5),
                                                            ),
                                                            child: const Center(child: CircularProgressIndicator()), // Loading indicator while fetching balances
                                                          );
                                                        } else if (balanceSnapshot.hasError) {
                                                          return Container(
                                                            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                                            padding: const EdgeInsets.all(8.0),
                                                            decoration: BoxDecoration(
                                                              border: Border.all(color: Colors.red),
                                                              borderRadius: BorderRadius.circular(5),
                                                            ),
                                                            child: const Text('Error loading balances'), // Error fetching balances
                                                          );
                                                        } else {
                                                          // Balances successfully loaded
                                                          double bnbBalance = balanceSnapshot.data?["bnb"] ?? 0.0;
                                                          double usdtBalance = balanceSnapshot.data?["usdt"] ?? 0.0;

                                                          // Now fetch the play status
                                                          return FutureBuilder<bool>(
                                                            future: getCheckPlay(walletAddress),  // Fetching play status
                                                            builder: (context, playSnapshot) {
                                                              if (playSnapshot.connectionState == ConnectionState.waiting) {
                                                                return Container(
                                                                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                                                  padding: const EdgeInsets.all(8.0),
                                                                  decoration: BoxDecoration(
                                                                    border: Border.all(color: Colors.grey),
                                                                    borderRadius: BorderRadius.circular(5),
                                                                  ),
                                                                  child: const Center(child: CircularProgressIndicator()),  // Loading indicator for play status
                                                                );
                                                              } else if (playSnapshot.hasError) {
                                                                return Container(
                                                                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                                                  padding: const EdgeInsets.all(8.0),
                                                                  decoration: BoxDecoration(
                                                                    border: Border.all(color: Colors.red),
                                                                    borderRadius: BorderRadius.circular(5),
                                                                  ),
                                                                  child: const Text('Error loading play status'),  // Error fetching play status
                                                                );
                                                              } else {
                                                                bool isPlayed = playSnapshot.data ?? false;

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
                                                                      // Play status (Played or Play)
                                                                      Expanded(
                                                                        flex: 1,
                                                                        child: Text(isPlayed ? 'Play' : 'Played'),
                                                                      ),
                                                                      Expanded(
                                                                        flex: 1,
                                                                        child: Checkbox(
                                                                          value: walletChecked[index],
                                                                          onChanged: isPlayed ? (bool? value) {
                                                                            setState(() {
                                                                              walletChecked[index] = value ?? false;
                                                                            });
                                                                          } : null,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              }
                                                            },
                                                          );
                                                        }
                                                      },
                                                    );
                                                  },
                                                ),
                                              ),

                                              // Nút Cancel và Play Now chiếm 50
                                              SizedBox(
                                                height: 50,
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context).pop(); // Đóng popup
                                                        },
                                                        child: const Text(
                                                          'Cancel',
                                                          style: TextStyle(color: Colors.red),
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () async {
                                                          onPlayNowKitty(mainContext, state.members, walletChecked);
                                                        },
                                                        child: const Text(
                                                          'Play Now',
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
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: const Text(
                              'Play',
                              style: TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context1) {
                                  print('Check not member ${state.notMembers}');
                                  TextEditingController sponsorWalletController = TextEditingController();
                                  List<bool> walletChecked = List<bool>.filled(state.notMembers.length, false);
                                  return StatefulBuilder(
                                    builder: (BuildContext context2, StateSetter setState) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.0),
                                        ),
                                        child: SizedBox(
                                          width: MediaQuery.of(context).size.width * 0.8,
                                          height: 500, // Đặt chiều cao của dialog là 700
                                          child: Column(
                                            children: [
                                              // Tiêu đề chiếm 50
                                              const SizedBox(
                                                height: 50,
                                                child: Padding(
                                                  padding: EdgeInsets.all(10.0),
                                                  child: Center(
                                                    child: Text(
                                                      'Join Member Play Now',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 24,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Text "Sponsor" chiếm 20 (10 cho Text và 10 cho TextField)
                                              const SizedBox(
                                                height: 20,
                                                child: Padding(
                                                  padding: EdgeInsets.only(left: 20.0),
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text(
                                                      'Sponsor',
                                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: 40,
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                                  child: TextField(
                                                    controller: sponsorWalletController,
                                                    decoration: const InputDecoration(
                                                      labelText: 'Enter Sponsor Wallet',
                                                      border: OutlineInputBorder(),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Tiêu đề danh sách ví chiếm 20
                                              const SizedBox(
                                                height: 20,
                                                child: Padding(
                                                  padding: EdgeInsets.only(left: 20.0),
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text(
                                                      'Select Wallets:',
                                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Header cho danh sách ví chiếm 40
                                              const SizedBox(
                                                height: 40,
                                                child: Row(
                                                  children: [
                                                    Expanded(flex: 1, child: Text('  Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                                    Expanded(flex: 4, child: Text('Address', style: TextStyle(fontWeight: FontWeight.bold))),
                                                    Expanded(flex: 2, child: Text('BNB Balance', style: TextStyle(fontWeight: FontWeight.bold))),
                                                    Expanded(flex: 2, child: Text('USDT Balance', style: TextStyle(fontWeight: FontWeight.bold))),
                                                    Expanded(flex: 1, child: Text('Select', style: TextStyle(fontWeight: FontWeight.bold))),
                                                  ],
                                                ),
                                              ),
                                              const Divider(),
                                              // Danh sách ví (phủ phần còn lại)
                                              Expanded(
                                                child: ListView.builder(
                                                  itemCount: state.notMembers.length,
                                                  itemBuilder: (context, index) {
                                                    String walletName = state.notMembers[index]["name"] ?? "Unknown Wallet";
                                                    String walletAddress = state.notMembers[index]["address"] ?? "";
                                                    return FutureBuilder<Map<String, double>>(
                                                      future: _loadBalances(walletAddress),
                                                      builder: (context, snapshot) {
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
                                                            child: const Text('Error loading balances'),
                                                          );
                                                        } else {
                                                          double bnbBalance = snapshot.data?["bnb"] ?? 0.0;
                                                          double usdtBalance = snapshot.data?["usdt"] ?? 0.0;

                                                          return Container(
                                                            decoration: BoxDecoration(
                                                              border: Border.all(color: Colors.grey),
                                                              borderRadius: BorderRadius.circular(5),
                                                            ),
                                                            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                                            padding: const EdgeInsets.all(8.0),
                                                            child: Row(
                                                              children: [
                                                                Expanded(flex: 1, child: Text(walletName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
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
                                                                  flex: 1,
                                                                  child: Checkbox(
                                                                    value: walletChecked[index],
                                                                    onChanged: (bool? value) {
                                                                      setState(() {
                                                                        walletChecked[index] = value ?? false;
                                                                      });
                                                                    },
                                                                  ),
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
                                              // Nút Cancel và Join Now chiếm 50
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
                                                          String sponsorWallet = sponsorWalletController.text;
                                                          print('sponsorWalletController $sponsorWalletController $sponsorWallet');
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
                                                          } else {
                                                            onJoinMemberKitty(mainContext, state.notMembers, sponsorWallet, walletChecked);
                                                          }
                                                        },
                                                        child: const Text(
                                                          'Join Now',
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
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: const Text(
                              'Join',
                              style: TextStyle(color: Colors.white, fontSize: 10),

                            ),

                          )   ,
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              // Show dialog for Play
                              showDialog(
                                context: context,
                                builder: (BuildContext context1) {
                                  return ClaimSwapPlayWidget(members: state.members);
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: const Text(
                              'Claim-Swap-Play',
                              style: TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 50),
                        ],
                      ),
                    ],
                  );
                }

                return const SizedBox.shrink();


              }),

          );
        },
      ),
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

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }






