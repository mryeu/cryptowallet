import 'package:cryptowallet/swap_ktr_usdt.dart';
import 'package:cryptowallet/wallet_create.dart'; // Assuming this file contains loadWalletFromJson()
import 'package:flutter/material.dart';
import 'package:cryptowallet/services/session_manager.dart';
import 'package:http/http.dart'; // Add this import for Web3Client
import 'package:web3dart/web3dart.dart';


class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});


  @override
  _SwapScreenState createState() => _SwapScreenState();

}

class _SwapScreenState extends State<SwapScreen> {
  late Web3Client web3;
  String? selectedWallet; // To handle dynamic wallet data
  String? selectedCoinFrom = 'BNB'; // Default coin for swapping
  String? selectedCoinTo = 'USDT'; // Target coin for swapping
  final TextEditingController amountController = TextEditingController();

  List<String> wallets = []; // Wallets will be loaded dynamically
  final List<String> coins = ['BNB', 'USDT', 'KTR'];

  // Variables to hold balance information
  double totalBalance = 0.0;
  double bnbBalance = 0.0;
  double usdtBalance = 0.0;
  double ktrBalance = 0.0;



  @override
  void initState() {
    super.initState();
    _initializeWeb3();
    _loadWalletData();
  }

  void _initializeWeb3() {
    const bscUrl = 'https://smart-yolo-wildflower.bsc.quiknode.pro/15e23273e4927b475d4a2b0b40c1231d9c7b7e91';
    web3 = Web3Client(bscUrl, Client());
  }
  Future<void> _loadWalletData() async {
    try {
      String? pin = SessionManager.userPin;
      final walletDataDecrypt = await loadWalletPINFromJson(pin!);
      if (walletDataDecrypt != null && walletDataDecrypt.containsKey('wallet_names')) {
        setState(() {
          wallets = List<String>.from(walletDataDecrypt['wallet_names']);
          selectedWallet = wallets.isNotEmpty ? wallets[0] : null; // Default to the first wallet if available

          // Load balances (use actual data extraction from JSON)
          bnbBalance = walletDataDecrypt['bnb_balance'] ?? 0.0;
          usdtBalance = walletDataDecrypt['usdt_balance'] ?? 0.0;
          ktrBalance = walletDataDecrypt['ktr_balance'] ?? 0.0;
          totalBalance = bnbBalance + usdtBalance + ktrBalance;
        });
      }
    } catch (e) {
      print('Failed to load wallet data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swap Coins'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card to select wallet
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.green, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Wallet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      value: selectedWallet,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_downward),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedWallet = newValue;
                        });
                      },
                      items: wallets.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card to display total and individual balances
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.green, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Total Balance',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text('Total: \$${totalBalance.toStringAsFixed(2)}'),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Image.asset(
                          'assets/images/bnb-bnb-logo.png',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 10),
                        Text('${bnbBalance.toStringAsFixed(4)} BNB'),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // USDT Balance with Logo
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/usdt_logo.png',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 10),
                        Text('${usdtBalance.toStringAsFixed(2)} USDT'),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // KTR Balance with Logo
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/logo_ktr.png',
                          width: 28,
                          height: 28,
                        ),
                        const SizedBox(width: 6),
                        Text('${ktrBalance.toStringAsFixed(2)} KTR'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card for Swap section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.green, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Swap Coins',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // Coin From Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('From:'),
                        DropdownButton<String>(
                          value: selectedCoinFrom,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCoinFrom = newValue;
                            });
                          },
                          items: coins.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Amount to Swap Input
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Enter amount to swap',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),

                    // Coin To Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('To:'),
                        DropdownButton<String>(
                          value: selectedCoinTo,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCoinTo = newValue;
                            });
                          },
                          items: coins.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Swap Button
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          // Chuyển đổi số lượng từ TextField sang double
                          final inputNumber = double.parse(amountController.text);

                          // Gọi hàm buySellTokenKTR
                          String? txHash = await buySellTokenKTR(
                            walletAddress: "0xDa22644F364155dFb41Ae756484177906D925F3f",
                            privateKey: '4828b59ab795f0a667c321a721f0d6661cd57ee4510b71fdbe26ba51e0cd6a8a',
                            isBuy: selectedCoinFrom == 'KTR',
                            inputNumber: inputNumber.toInt(),
                          );

                          if (txHash != null) {
                            print('Giao dịch đã được gửi với mã băm: $txHash');

                            // Chờ đợi giao dịch được xử lý
                            var txReceipt;
                            int retryCount = 0;
                            do {
                              txReceipt = await web3.getTransactionReceipt(txHash);
                              if (txReceipt == null) {
                                // Đợi một vài giây trước khi thử lại
                                await Future.delayed(Duration(seconds: 5));
                              }
                              retryCount++;
                            } while (txReceipt == null && retryCount < 12); // Thử lại tối đa 1 phút

                            // Kiểm tra kết quả giao dịch
                            if (txReceipt != null && txReceipt.status!) {
                              print("Giao dịch đã được xác nhận thành công!");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Swap thành công! TX Hash: $txHash')),
                              );
                            } else {
                              print("Giao dịch thất bại hoặc mất quá nhiều thời gian.");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Swap thất bại hoặc mất quá nhiều thời gian!')),
                              );
                            }
                          } else {
                            print('Gửi giao dịch thất bại.');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Swap thất bại!')),
                            );
                          }
                        } catch (e) {
                          print('Đã xảy ra lỗi: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Đã xảy ra lỗi: $e')),
                          );
                        }
                      },
                      child: const Text('Swap Now'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
