import 'package:cryptowallet/transaction_usdt_service.dart';
import 'package:flutter/material.dart';
import 'package:cryptowallet/services/session_manager.dart';
import 'package:cryptowallet/wallet_create.dart'; // Import wallet creation functions
import 'package:web3dart/web3dart.dart';
import 'check_balance.dart'; // Import check balance service

class SendAllScreen extends StatefulWidget {
  const SendAllScreen({Key? key}) : super(key: key);

  @override
  _SendAllScreenState createState() => _SendAllScreenState();
}

class _SendAllScreenState extends State<SendAllScreen> {
  Map<String, bool> _selectedWallets = {}; // Tracks which wallets are selected
  String _selectedToken = 'BNB'; // Default selected token
  int _selectedCount = 0; // Counter for selected wallets
  List<Map<String, dynamic>> wallets = []; // Placeholder for wallet data
  String? mainWalletAddress; // The main wallet address
  bool isLoading = false; // Tracks if a send operation is in progress
  String? mainWalletPrivateKey;
  TextEditingController amountController = TextEditingController(); // Input field controller
  double perWalletAmount = 0.0; // Amount each selected wallet will receive
  final TokenBalanceChecker _balanceChecker = TokenBalanceChecker(); // Balance checker

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  // Load the wallet data using the stored PIN and fetch balances
  Future<void> _loadWalletData() async {
    String? pin = SessionManager.userPin;
    if (pin != null) {
      final walletDataDecrypt = await loadWalletPINFromJson(pin);
      if (walletDataDecrypt != null) {
        setState(() {
          // Clear previous data
          wallets.clear();
          _selectedWallets.clear();

          // Read wallet names, addresses, and private keys
          List<String> walletNames = walletDataDecrypt['wallet_names'];
          List<String> walletAddresses = walletDataDecrypt['addresses'];
          List<
              String> privateKeys = walletDataDecrypt['decrypted_private_keys'];

          mainWalletAddress = walletAddresses[0];
          mainWalletPrivateKey =
          privateKeys[0]; // Retrieve the private key for the main wallet

          for (int i = 1; i < walletAddresses.length; i++) {
            wallets.add({
              'name': walletNames[i],
              'address': walletAddresses[i],
              'privateKey': privateKeys[i],
              // Include private keys for other wallets
              'bnbBalance': 'Fetching...',
              // Placeholder for BNB balance
              'usdtBalance': 'Fetching...',
              // Placeholder for USDT balance
              'ktrBalance': 'Fetching...'
              // Placeholder for KTR balance
            });
            _selectedWallets[walletAddresses[i]] =
            true; // Select all wallets by default
          }

          _selectedCount = _selectedWallets.length; // Set the initial count
          _calculatePerWalletAmount(); // Calculate the initial per wallet amount

          // Fetch wallet balances (BNB, USDT, KTR)
          _fetchWalletBalances(wallets);
        });
      } else {
        print('Failed to load or decrypt wallet data.');
      }
    }
  }

  // Fetch the real-time balances (BNB, USDT, KTR)
  Future<void> _fetchWalletBalances(List<Map<String, dynamic>> wallets) async {
    for (var wallet in wallets) {
      try {
        // Fetch BNB balance
        double? bnbBalance = await _balanceChecker.getBnbBalance(
            wallet['address']);
        // Fetch USDT balance
        double? usdtBalance = await _balanceChecker.getUsdtBalance(
            wallet['address']);
        // Fetch KTR balance (you can implement the balance fetch for KTR)
        double? ktrBalance = await _balanceChecker.getKtrBalance(
            wallet['address']);

        setState(() {
          wallet['bnbBalance'] =
          bnbBalance != null ? bnbBalance.toStringAsFixed(4) : 'Error';
          wallet['usdtBalance'] =
          usdtBalance != null ? usdtBalance.toStringAsFixed(2) : 'Error';
          wallet['ktrBalance'] =
          ktrBalance != null ? ktrBalance.toStringAsFixed(2) : 'Error';
        });
      } catch (e) {
        print('Error fetching balances for ${wallet['address']}: $e');
      }
    }
  }

  // Calculate the amount each wallet will receive
  void _calculatePerWalletAmount() {
    double totalAmount = double.tryParse(amountController.text) ?? 0.0;
    if (_selectedCount > 0) {
      setState(() {
        perWalletAmount = totalAmount / _selectedCount;
      });
    } else {
      setState(() {
        perWalletAmount = 0.0;
      });
    }
  }

  // Perform the send operation
  Future<void> _performSend() async {
    List<Map<String, dynamic>> selectedWallets = wallets.where((wallet) {
      return _selectedWallets[wallet['address']] == true;
    }).toList();

    print('Selected wallets for $_selectedToken send: $selectedWallets');

    if (selectedWallets.isNotEmpty && perWalletAmount > 0) {
      setState(() {
        isLoading = true;
      });

      // Show the countdown dialog
      _showCountdownDialog(context, selectedWallets.length * 7);

      // Initialize the transaction service
      TransactionServiceSend action = TransactionServiceSend();

      for (var wallet in selectedWallets) {
        String toAddress = wallet['address'];

        try {
          if (_selectedToken == 'BNB') {
            print(
                'Sending $perWalletAmount BNB from $mainWalletAddress to $toAddress');
            await action.sendBNB(
                mainWalletPrivateKey!, EthereumAddress.fromHex(toAddress),
                perWalletAmount);
          } else if (_selectedToken == 'USDT') {
            BigInt amountToSend = BigInt.from(perWalletAmount * 1e18);
            print(
                'Sending $perWalletAmount USDT from $mainWalletAddress to $toAddress');
            await action.sendallUsdtBep20(
                mainWalletPrivateKey!, EthereumAddress.fromHex(toAddress),
                amountToSend);
          } else if (_selectedToken == 'KTR') {
            BigInt amountToSend = BigInt.from(perWalletAmount * 1e18);
            print(
                'Sending $perWalletAmount KTR from $mainWalletAddress to $toAddress');
            await action.sendallKtrBep20(
                mainWalletPrivateKey!, EthereumAddress.fromHex(toAddress),
                amountToSend);
          }
        } catch (e) {
          print('Error sending to $toAddress: $e');
        }

        // Wait for 7 seconds before sending to the next wallet
        await Future.delayed(const Duration(seconds: 7));
      }

      setState(() {
        isLoading = false;
      });

      Navigator.of(context).pop(); // Close the dialog after processing
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid amount or no wallet selected.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send All Wallet List', style: TextStyle(color: Colors.white,  ),),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Token selection with logo and amount input
            Row(
              children: [
                Text(
                  'From: (${mainWalletAddress != null && mainWalletAddress!.length > 10
                      ? '${mainWalletAddress!.substring(0, 5)}...${mainWalletAddress!.substring(mainWalletAddress!.length - 5)}'
                      : mainWalletAddress})',
                  style: const TextStyle(color: Colors.green, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Image.asset(
                      _selectedToken == 'USDT'
                          ? 'assets/images/usdt_logo.png'
                          : _selectedToken == 'BNB'
                          ? 'assets/images/bnb-bnb-logo.png'
                          : 'assets/images/logo_ktr.png',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedToken,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedToken = newValue!;
                          _calculatePerWalletAmount(); // Recalculate per wallet amount
                        });
                      },
                      items: <String>['USDT', 'BNB', 'KTR'].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Enter total amount',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _calculatePerWalletAmount();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Row for Selected and Check/Uncheck All button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Display the selected wallets count
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Selected: ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green, // Màu xanh cho từ "Selected"
                        ),
                      ),
                      TextSpan(
                        text: '$_selectedCount / ${_selectedWallets.length}',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedCount < _selectedWallets.length ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                // TextButton for Check All / Uncheck All
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedCount == _selectedWallets.length) {
                        // Nếu đã chọn tất cả, thì Uncheck tất cả
                        _selectedWallets.updateAll((key, value) => false);
                        _selectedCount = 0;
                      } else {
                        // Nếu chưa chọn tất cả, thì Check tất cả
                        _selectedWallets.updateAll((key, value) => true);
                        _selectedCount = _selectedWallets.length;
                      }
                      _calculatePerWalletAmount();
                    });
                  },
                  child: Text(
                    _selectedCount == _selectedWallets.length ? 'Uncheck All' : 'Check All',
                    style: TextStyle(
                      color: _selectedCount == _selectedWallets.length ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Display the amount per wallet
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Amount per wallet: ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green, // Màu xanh cho từ "Amount per wallet"
                    ),
                  ),
                  TextSpan(
                    text: '$perWalletAmount $_selectedToken',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red, // Màu đỏ cho giá trị perWalletAmount
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // List of wallets with checkboxes
            Expanded(
              child: ListView.builder(
                itemCount: wallets.length,
                itemBuilder: (context, index) {
                  String walletName = wallets[index]['name'];
                  String address = wallets[index]['address'];
                  String bnbBalance = wallets[index]['bnbBalance'];
                  String usdtBalance = wallets[index]['usdtBalance'];
                  String ktrBalance = wallets[index]['ktrBalance'];

                  // Shorten the address for display
                  String shortAddress = (address.length > 10)
                      ? '${address.substring(0, 5)}...${address.substring(address.length - 5)}'
                      : address;

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.green, width: 1),
                    ),
                    child: ListTile(
                      title: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: walletName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            TextSpan(
                              text: ': $shortAddress',
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Row(
                            children: [
                              Image.asset('assets/images/bnb-bnb-logo.png', width: 24, height: 24),
                              const SizedBox(width: 4),
                              Text('$bnbBalance'),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Row(
                            children: [
                              Image.asset('assets/images/usdt_logo.png', width: 24, height: 24),
                              const SizedBox(width: 4),
                              Text('$usdtBalance'),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Row(
                            children: [
                              Image.asset('assets/images/logo_ktr.png', width: 24, height: 24),
                              const SizedBox(width: 4),
                              Text('$ktrBalance'),
                            ],
                          ),
                        ],
                      ),
                      trailing: Checkbox(
                        value: _selectedWallets[address],
                        onChanged: (bool? value) {
                          setState(() {
                            _selectedWallets[address] = value!;
                            _selectedCount = _selectedWallets.values.where((isSelected) => isSelected).length;
                            _calculatePerWalletAmount(); // Recalculate per wallet amount
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: isLoading ? null : _performSend,
                  child: isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Send All',
                    style: TextStyle(color: Colors.green),
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

class CountdownDialog extends StatefulWidget {
  final int totalWaitTime;
  final Function onSendComplete;

  CountdownDialog({required this.totalWaitTime, required this.onSendComplete});

  @override
  _CountdownDialogState createState() => _CountdownDialogState();
}

class _CountdownDialogState extends State<CountdownDialog> {
  late int currentWaitTime;



  @override
  void initState() {
    super.initState();
    currentWaitTime = widget.totalWaitTime;
    startCountdown();
  }

  void startCountdown() async {
    while (currentWaitTime > 0) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        currentWaitTime--;
      });
    }
    // Sau khi đếm ngược kết thúc, gọi hàm onSendComplete
    widget.onSendComplete();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          const Text(
            "Sending tokens:",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 10),
          Text("Remaining time: $currentWaitTime seconds",  style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),),
          const SizedBox(height: 20),
          Image.asset(
            'assets/images/loading.gif',
            height: 200, // Điều chỉnh kích thước ảnh GIF tùy ý
            width: 200,
          ),
        ],
      ),
    );
  }
}

void _showCountdownDialog(BuildContext context, int totalWaitTime) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return CountdownDialog(
        totalWaitTime: totalWaitTime,
        onSendComplete: () {
          // Sau khi hoàn thành, đóng dialog
          Navigator.of(context).pop();
        },
      );
    },
  );
}
