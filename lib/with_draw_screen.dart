import 'package:cryptowallet/transaction_usdt_service.dart';
import 'package:flutter/material.dart';
import 'package:cryptowallet/services/session_manager.dart';
import 'package:cryptowallet/wallet_create.dart'; // Import wallet creation functions
import 'package:web3dart/web3dart.dart';

import 'build_widget.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({Key? key}) : super(key: key);

  @override
  _WithdrawScreenState createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  Map<String, bool> _selectedWallets = {}; // Tracks which wallets are selected
  String _selectedToken = 'USDT'; // Default selected token for withdrawal
  int _selectedCount = 0; // Counter for selected wallets
  List<Map<String, dynamic>> wallets = []; // Placeholder for wallet data
  String? mainWalletAddress; // The main wallet address
  bool isLoading = false; // Tracks if a withdrawal is in progress

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  // Load the wallet data using the stored PIN
  // Load the wallet data using the stored PIN
  Future<void> _loadWalletData() async {
    String? pin = SessionManager.userPin;
    if (pin != null) {
      final walletDataDecrypt = await loadWalletPINFromJson(pin);
      if (walletDataDecrypt != null) {
        setState(() {
          // Clear previous wallet data to avoid duplication
          wallets.clear();
          _selectedWallets.clear();

          // Read wallet names and addresses
          List<String> walletNames = walletDataDecrypt['wallet_names'] ?? [];
          List<String> walletAddresses = walletDataDecrypt['addresses'] ?? [];
          List<double> bnbBalances = walletDataDecrypt['bnb_balance'] ?? List.filled(walletAddresses.length, 0.0);
          List<double> usdtBalances = walletDataDecrypt['usdt_balance'] ?? List.filled(walletAddresses.length, 0.0);
          List<String> privateKeys = walletDataDecrypt['decrypted_private_keys'] ?? [];

          // Check if walletAddresses have enough elements
          if (walletAddresses.isEmpty) {
            print('No wallet addresses found.');
            return;
          }

          // Set the main wallet address (index 0)
          mainWalletAddress = walletAddresses[0];

          // Create the wallets list excluding the main wallet (index 0)
          for (int i = 1; i < walletAddresses.length; i++) {
            wallets.add({
              'name': i < walletNames.length ? walletNames[i] : 'Wallet $i', // Fallback in case name is missing
              'address': walletAddresses[i],
              'bnbBalance': i < bnbBalances.length ? bnbBalances[i] : 0.0,
              'usdtBalance': i < usdtBalances.length ? usdtBalances[i] : 0.0,
              'privateKey': i < privateKeys.length ? privateKeys[i] : '', // Ensure there's a fallback
            });
            _selectedWallets[walletAddresses[i]] = true; // Select all wallets by default
          }

          _selectedCount = _selectedWallets.length; // Set the initial count
        });
      } else {
        print('Failed to load or decrypt wallet data.');
      }
    } else {
      print('No PIN found in session.');
    }
  }

  void showCountdownDialog(BuildContext context, int totalWaitTime) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CountdownDialog(
          totalWaitTime: totalWaitTime,
          onSendComplete: () {
            Navigator.of(context).pop(); // Đóng dialog khi hoàn tất
          },
        );
      },
    );
  }

  // This method will handle the withdraw process
// This method will handle the withdraw process
  Future<void> _performWithdraw() async {
    List<Map<String, dynamic>> selectedWallets = wallets.where((wallet) {
      return _selectedWallets[wallet['address']] == true;
    }).toList();

    print('Selected wallets for $_selectedToken withdrawal: $selectedWallets');

    if (selectedWallets.isNotEmpty) {
      setState(() {
        isLoading = true;
      });

      // Tính toán tổng thời gian xử lý cho tất cả ví (mỗi ví mất 2 giây)
      int totalWaitTime = selectedWallets.length * 2;

      // Hiển thị CountdownDialog
      showCountdownDialog(context, totalWaitTime);

      // Initialize the transaction service
      TransactionServiceSend action = TransactionServiceSend();

      for (var wallet in selectedWallets) {
        String fromAddress = wallet['address'];
        String privateKey = wallet['privateKey'];
        try {
          if (_selectedToken == 'USDT') {
            // Withdraw all USDT
            print('Sending all USDT from $fromAddress to $mainWalletAddress');
            await action.sendUsdtBep20(privateKey, EthereumAddress.fromHex(mainWalletAddress!));
          } else if (_selectedToken == 'BNB') {
            // Withdraw all BNB
            print('Sending all BNB from $fromAddress to $mainWalletAddress');
            await action.withdrawAllBNB(privateKey, EthereumAddress.fromHex(mainWalletAddress!));
          }
        } catch (e) {
          print('Error withdrawing from $fromAddress: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error withdrawing from $fromAddress: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }

        // Tạm dừng 2 giây trước khi xử lý ví tiếp theo
        await Future.delayed(const Duration(seconds: 2));
      }

      setState(() {
        isLoading = false;
      });

      Navigator.of(context).pop(); // Close the dialog after processing
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No wallet selected.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw from all wallets', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Token selection with logo and count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Token logo based on selected token
                    Image.asset(
                      _selectedToken == 'USDT' ? 'assets/images/usdt_logo.png' : 'assets/images/bnb-bnb-logo.png',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedToken,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedToken = newValue!;
                        });
                      },
                      items: <String>['USDT', 'BNB'].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'To: (${mainWalletAddress != null && mainWalletAddress!.length > 10 ? mainWalletAddress!.substring(0, 5) + '...' + mainWalletAddress!.substring(mainWalletAddress!.length - 5) : mainWalletAddress})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text('Selected: $_selectedCount / ${_selectedWallets.length}'),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: wallets.length,
                itemBuilder: (context, index) {
                  String walletName = wallets[index]['name'];
                  String address = wallets[index]['address'];
                  double bnbBalance = wallets[index]['bnbBalance'];
                  double usdtBalance = wallets[index]['usdtBalance'];

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
                              text: walletName, // Wallet name
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green, // Style for wallet name
                              ),
                            ),
                            TextSpan(
                              text: ': $shortAddress', // Shortened address
                              style: const TextStyle(
                                color: Colors.grey, // Style for the shortened address
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
                              Text('BNB: $bnbBalance'),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Row(
                            children: [
                              Image.asset('assets/images/usdt_logo.png', width: 24, height: 24),
                              const SizedBox(width: 4),
                              Text('USDT: $usdtBalance'),
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
                  onPressed: isLoading ? null : _performWithdraw,
                  child: isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Withdraw All',
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
