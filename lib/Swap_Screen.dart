import 'package:cryptowallet/swap_ktr_usdt.dart';
import 'package:cryptowallet/wallet_create.dart';
import 'package:flutter/material.dart';
import 'package:cryptowallet/services/session_manager.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

import 'check_balance.dart';
import 'check_price_ktr.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  _SwapScreenState createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  late Web3Client web3;
  String? selectedWallet;
  String? selectedWalletAddress; // Thêm biến để lưu trữ địa chỉ ví đã chọn
  String? selectedPrivateKey; // Thêm biến để lưu trữ private key của ví đã chọn
  String? selectedCoinFrom = 'BNB';
  String? selectedCoinTo = 'USDT';
  final TextEditingController amountController = TextEditingController();
  bool isLoading = false; // Trạng thái loading

  List<Map<String, String>> wallets = []; // Chứa tên ví, địa chỉ và privateKey
  final List<String> coins = ['BNB', 'USDT', 'KTR'];
  final TokenBalanceChecker _balanceChecker = TokenBalanceChecker();

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

  // Load wallets and fetch real balances
  Future<void> _loadWalletData() async {
    try {
      String? pin = SessionManager.userPin;
      final walletDataDecrypt = await loadWalletPINFromJson(pin!);
      if (walletDataDecrypt != null && walletDataDecrypt.containsKey('wallet_names')) {
        setState(() {
          // Lưu cả tên ví, địa chỉ và privateKey
          wallets = List<Map<String, String>>.generate(
            walletDataDecrypt['wallet_names'].length,
                (index) => {
              'name': walletDataDecrypt['wallet_names'][index],
              'address': walletDataDecrypt['addresses'][index],
              'privateKey': walletDataDecrypt['decrypted_private_keys'][index],
            },
          );
          selectedWallet = wallets.isNotEmpty ? wallets[0]['name'] : null;
          selectedWalletAddress = wallets.isNotEmpty ? wallets[0]['address'] : null;
          selectedPrivateKey = wallets.isNotEmpty ? wallets[0]['privateKey'] : null;
        });

        // Fetch balance for the first wallet
        if (wallets.isNotEmpty) {
          await _fetchWalletBalances(wallets[0]['address']!);
        }
      }
    } catch (e) {
      print('Failed to load wallet data: $e');
    }
  }

  Future<void> _fetchWalletBalances(String address) async {
    try {
      double bnbRawBalance = (await _balanceChecker.getBnbBalance(address))!;
      double usdtRawBalance = (await _balanceChecker.getUsdtBalance(address))!;
      double ktrRawBalance = (await _balanceChecker.getKtrBalance(address))!;

      // Chuyển đổi BNB và KTR sang USDT
      double bnbInUsdt = await convertToUsdt('BNB', bnbRawBalance);
      double ktrInUsdt = await convertToUsdt('KTR', ktrRawBalance);

      // Tính tổng số dư theo USDT
      setState(() {
        bnbBalance = bnbRawBalance;
        usdtBalance = usdtRawBalance;
        ktrBalance = ktrRawBalance;
        totalBalance = bnbInUsdt + usdtBalance + ktrInUsdt;
      });
    } catch (e) {
      print('Failed to fetch balances: $e');
    }
  }

  Future<double> convertToUsdt(String token, double amount) async {
    if (token == 'BNB') {
      String bnbPrice = await checkPriceBNB(1);
      return amount * double.parse(bnbPrice);
    } else if (token == 'KTR') {
      String ktrPrice = await checkPriceKTR(1);
      return amount * double.parse(ktrPrice);
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Vô hiệu hóa nút back của hệ thống
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Swap Coins'),
          automaticallyImplyLeading: false, // Vô hiệu hóa nút back trên AppBar
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Wallet Selection
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
                      onChanged: (String? newValue) async {
                        setState(() {
                          selectedWallet = newValue;
                          // Lấy địa chỉ và privateKey của ví được chọn
                          Map<String, String> selectedWalletData = wallets
                              .firstWhere((wallet) => wallet['name'] == newValue);
                          selectedWalletAddress = selectedWalletData['address'];
                          selectedPrivateKey = selectedWalletData['privateKey'];
                        });

                        // Fetch balance for the selected wallet
                        if (selectedWalletAddress != null) {
                          await _fetchWalletBalances(selectedWalletAddress!);
                        }
                      },
                      items: wallets.map<DropdownMenuItem<String>>((Map<String, String> wallet) {
                        return DropdownMenuItem<String>(
                          value: wallet['name'],
                          child: Text(wallet['name']!),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Total and individual balances
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

            // Swap section
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('From:'),
                        DropdownButton<String>(
                          value: selectedCoinFrom,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCoinFrom = newValue;
                              amountController.clear(); // Xóa giá trị khi thay đổi loại token
                              if (selectedCoinFrom == 'KTR') {
                                selectedCoinTo = 'USDT';
                              } else if (selectedCoinFrom == 'USDT') {
                                selectedCoinTo = 'BNB';
                              } else {
                                selectedCoinTo = 'USDT';
                              }
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
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Enter amount to swap',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
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
                          items: coins
                              .where((coin) => coin != selectedCoinFrom)
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Nút Swap và hiển thị trạng thái Loading
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                      onPressed: () async {
                        double enteredAmount = double.tryParse(amountController.text) ?? 0.0;

                        if (enteredAmount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid amount.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setState(() {
                          isLoading = true;
                        });

                        try {
                          if (selectedCoinFrom == 'KTR' && selectedCoinTo == 'USDT') {
                            final txHash = await buySellTokenKTR(
                              walletAddress: selectedWalletAddress ?? '',
                              privateKey: selectedPrivateKey ?? '',
                              isBuy: true, // Bán KTR lấy USDT
                              inputNumber: enteredAmount.toInt(),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Transaction successful! TX Hash: $txHash')),
                            );
                          } else if (selectedCoinFrom == 'USDT' && selectedCoinTo == 'KTR') {
                            final txHash = await buySellTokenKTR(
                              walletAddress: selectedWalletAddress ?? '',
                              privateKey: selectedPrivateKey ?? '',
                              isBuy: false, // Mua KTR bằng USDT
                              inputNumber: enteredAmount.toInt(),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Transaction successful! TX Hash: $txHash')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invalid token pair selected.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }

                          // Cập nhật lại số dư sau khi giao dịch hoàn tất
                          await _fetchWalletBalances(selectedWalletAddress!);
                        } catch (e) {
                          print('Transaction failed: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Transaction failed: $e')),
                          );
                        } finally {
                          setState(() {
                            isLoading = false;
                          });
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
