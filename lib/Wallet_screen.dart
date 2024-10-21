import 'dart:convert';
import 'dart:io';

import 'package:cryptowallet/send_all_screen.dart';
import 'package:cryptowallet/services/get_recent_transactions.dart';
import 'package:cryptowallet/services/session_manager.dart';
import 'package:cryptowallet/transaction_usdt_service.dart';
import 'package:cryptowallet/wallet_create.dart'; // Import wallet creation functions
import 'package:cryptowallet/with_draw_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'check_balance.dart';
import 'package:web3dart/credentials.dart';
import 'package:url_launcher/url_launcher.dart';
import 'check_price_ktr.dart';


class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  String walletAddress = ''; // Placeholder for wallet address
  double usdtBalance = 0.0; // Placeholder for USDT balance
  double bnbBalance = 0.0; // Placeholder for BNB balance
  double ktrBalance = 0.0; // Placeholder for KTR balance
  double totalBalance = 0.0; // Placeholder for total balance
  List<Map<String, dynamic>> wallets = []; // Placeholder for wallet details

  final TokenBalanceChecker _balanceChecker = TokenBalanceChecker(); // Initialize TokenBalanceChecker

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  void _showCreateWalletDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Wallet'),
          content: const Text('Do you want to create a new wallet?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                String? pin = SessionManager.userPin;
                if (pin != null) {
                  final walletDataDecrypt = await loadWalletPINFromJson(pin);
                  if (walletDataDecrypt != null &&
                      walletDataDecrypt.containsKey('decrypted_mnemonic')) {
                    await addNewWalletFromMnemonic(
                        walletDataDecrypt['decrypted_mnemonic'], pin);
                    await _loadWalletData(); // Reload wallet data
                  } else {
                    print('Failed to load or decrypt wallet data.');
                  }
                }
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> loadWalletDataMain() async {
    try {
      String? pin = SessionManager.userPin; // Lấy PIN từ SessionManager
      final walletDataDecrypt = await loadWalletPINFromJson(
          pin!); // Giải mã dữ liệu ví bằng PIN

      if (walletDataDecrypt != null) {
        setState(() {
          if (walletDataDecrypt.containsKey('wallet_names') &&
              walletDataDecrypt.containsKey('addresses') &&
              walletDataDecrypt.containsKey('private_keys')) {
            // Lưu thông tin ví vào danh sách wallets
            wallets = List.generate(
                walletDataDecrypt['wallet_names'].length, (index) {
              return {
                'name': walletDataDecrypt['wallet_names'][index],
                'address': walletDataDecrypt['addresses'][index],
                'privateKey': walletDataDecrypt['decrypted_private_keys'][index],
              };
            });

            // Lấy địa chỉ và private key của ví đầu tiên (Main wallet)
            walletAddress = walletDataDecrypt['addresses'][0];
            String mainPrivateKey = walletDataDecrypt['private_keys'][0]; // Private key của ví đầu tiên

            // In ra private key (lưu ý rằng in private key chỉ nên thực hiện khi cần thiết để bảo mật)
            print('Main wallet private key: $mainPrivateKey');
          }
        });

        // Sau khi tải dữ liệu ví, gọi hàm để cập nhật số dư
        await _updateBalances();
      }
    } catch (e) {
      print('Failed to load wallet data: $e');
    }
  }


// Load wallet data from JSON file and update balances
  Future<void> _loadWalletData() async {
    try {
      String? pin = SessionManager.userPin;
      final walletDataDecrypt = await loadWalletPINFromJson(pin!);
      if (walletDataDecrypt != null) {
        setState(() {
          if (walletDataDecrypt.containsKey('wallet_names') &&
              walletDataDecrypt.containsKey('addresses')) {
            wallets = List.generate(
                walletDataDecrypt['wallet_names'].length, (index) {
              return {
                'name': walletDataDecrypt['wallet_names'][index],
                'address': walletDataDecrypt['addresses'][index],
                'privateKey': walletDataDecrypt['decrypted_private_keys'][index],
                'bnbBalance': 0.0,
                'usdtBalance': 0.0,
                'ktrBalance': 0.0,
              };
            });
            walletAddress =
            walletDataDecrypt['addresses'][0]; // Main wallet address
          }
        });

        // Fetch balances using the TokenBalanceChecker
        await _updateBalances();
      }
    } catch (e) {
      print('Failed to load wallet data: $e');
    }
  }

  // Fetch and update the BNB, USDT, and KTR balances for each wallet
  Future<void> _updateBalances() async {
    try {
      double totalBnb = 0.0;
      double totalUsdt = 0.0;
      double totalKtr = 0.0;

      for (var wallet in wallets) {
        String address = wallet['address'];
        final bnb = await _balanceChecker.getBnbBalance(address);
        final usdt = await _balanceChecker.getUsdtBalance(address);
        final ktr = await _balanceChecker.getKtrBalance(address);

        setState(() {
          wallet['bnbBalance'] = bnb ?? 0.0;
          wallet['usdtBalance'] = usdt ?? 0.0;
          wallet['ktrBalance'] = ktr ?? 0.0;

          totalBnb += wallet['bnbBalance'];
          totalUsdt += wallet['usdtBalance'];
          totalKtr += wallet['ktrBalance'];
        });
      }

      setState(() {
        bnbBalance = totalBnb;
        usdtBalance = totalUsdt;
        ktrBalance = totalKtr;
        totalBalance = bnbBalance + usdtBalance + ktrBalance;
      });
    } catch (e) {
      print('Error updating balances: $e');
    }
  }

  // Function to copy wallet address to clipboard
  void copyToClipboard(String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin từ ví chính (wallets[0])
    String mainWalletAddress = wallets.isNotEmpty &&
        wallets[0]['address'] != null ? wallets[0]['address'] : 'No Address';
    String mainPrivateKey = wallets.isNotEmpty &&
        wallets[0]['privateKey'] != null
        ? wallets[0]['privateKey']
        : 'No PrivateKey';

    // String mainPrivateKey = wallets[0]['privateKey'] !;

    double mainWalletBnbBalance = wallets.isNotEmpty
        ? wallets[0]['bnbBalance']
        : 0.0;
    double mainWalletUsdtBalance = wallets.isNotEmpty
        ? wallets[0]['usdtBalance']
        : 0.0;
    double mainWalletKtrBalance = wallets.isNotEmpty
        ? wallets[0]['ktrBalance']
        : 0.0;

    String shortAddress;
    if (mainWalletAddress.length > 10) {
      shortAddress =
      '${mainWalletAddress.substring(0, 5)}...${mainWalletAddress.substring(
          mainWalletAddress.length - 5)}';
    } else {
      shortAddress = mainWalletAddress;
    }

    String formatBalance(double value) {
      String formattedValue = value.toStringAsFixed(4);
      formattedValue = double.parse(formattedValue).toString();
      return formattedValue;
    }

    // Tính toán tổng số dư
    double totalUsdtBalance = wallets.fold(
        0, (sum, wallet) => sum + wallet['usdtBalance']);
    double totalBnbBalance = wallets.fold(
        0, (sum, wallet) => sum + wallet['bnbBalance']);
    double totalKtrBalance = wallets.fold(
        0, (sum, wallet) => sum + wallet['ktrBalance']);

    void _showWithdrawDialog() async {
      if (mainWalletAddress.isEmpty) {
        print('No wallet loaded');
        return;
      }

      String selectedToken = 'BNB';
      TextEditingController recipientController = TextEditingController();
      TextEditingController amountController = TextEditingController();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Center( // Center the title
                  child: Text(
                    'Withdraw Funds',
                    style: TextStyle(
                      color: Colors.green, // Set the title color to blue
                    ),
                  ),
                ), content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('From Wallet: Your Main Wallet',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('$mainWalletAddress',
                        style: const TextStyle(color: Colors.black)),
                    const SizedBox(height: 10),
                    // Dropdown lựa chọn loại tiền
                    DropdownButton<String>(
                      value: selectedToken,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedToken = newValue!;
                        });
                      },
                      items: <String>['BNB', 'USDT', 'KTR']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 10),

                    // Hiển thị số dư tương ứng
                    if (selectedToken == 'BNB')
                      Text('Balance: ${formatBalance(
                          mainWalletBnbBalance)} BNB'),
                    if (selectedToken == 'USDT')
                      Text('Balance: ${formatBalance(
                          mainWalletUsdtBalance)} USDT'),
                    if (selectedToken == 'KTR')
                      Text('Balance: ${formatBalance(
                          mainWalletKtrBalance)} KTR'),

                    const SizedBox(height: 10),

                    // Ô nhập địa chỉ nhận
                    TextField(
                      controller: recipientController,
                      decoration: const InputDecoration(
                        labelText: 'Recipient Address',
                        hintText: 'Enter recipient address',
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Ô nhập số lượng rút
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        hintText: 'Enter amount to withdraw',
                      ),
                    ),
                  ],
                ),
              ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () async {
                      String amountStr = amountController.text.trim();
                      String recipient = recipientController.text.trim();

                      if (amountStr.isEmpty || recipient.isEmpty) {
                        print('Amount or recipient is empty.');
                        return;
                      }
                      try {
                        final EthereumAddress toEthereumAddress = EthereumAddress
                            .fromHex(recipient);
                        TransactionServiceSend action = TransactionServiceSend();
                        double amount = double.parse(
                            amountStr); // Chuyển đổi chuỗi thành số

                        if (selectedToken == 'USDT') {
                          // Gọi hàm gửi USDT (chuyển sang BigInt với 18 chữ số thập phân)
                          await action.sendallUsdtBep20(
                              mainPrivateKey, toEthereumAddress,
                              BigInt.from(amount * 1e18));
                          print('Withdraw $amount USDT to $recipient');
                        } else if (selectedToken == 'KTR') {
                          // Gọi hàm gửi KTR (chuyển sang BigInt với 18 chữ số thập phân)
                          await action.sendallKtrBep20(
                              mainPrivateKey, toEthereumAddress,
                              BigInt.from(amount * 1e18));
                          print('Withdraw $amount KTR to $recipient');
                        } else if (selectedToken == 'BNB') {
                          await action.sendBNB(
                              mainPrivateKey, toEthereumAddress, amount);
                          print('Withdraw $amount BNB to $recipient');
                        }

                        Navigator.of(context)
                            .pop(); // Đóng popup sau khi hoàn thành
                      } catch (e) {
                        print('Error during withdrawal: $e');
                      }
                    },
                    child: const Text("Confirm"),
                  ),

                ],
              );
            },
          );
        },
      );
    }
    Future<double> convertToUsdt(String token, double amount) async {
      if (token == 'BNB') {
        // Giả sử bạn có một hàm để lấy giá BNB theo USDT
        String bnbPrice = await checkPriceBNB(
            1); // Hàm này lấy giá BNB theo USDT
        return amount * double.parse(bnbPrice);
      } else if (token == 'KTR') {
        // Giả sử bạn có một hàm để lấy giá KTR theo USDT
        String ktrPrice = await checkPriceKTR(
            1); // Hàm này lấy giá KTR theo USDT
        return amount * double.parse(ktrPrice);
      }
      return 0.0; // Nếu không phải BNB hoặc KTR, trả về 0
    }
    return WillPopScope(
      onWillPop: () async {
        return false; // Vô hiệu hóa nút quay lại
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('KittyRun Wallet'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.green),
              onPressed: _showCreateWalletDialog,
            ),
            IconButton(
              icon: const Icon(Icons.upload_file, color: Colors.green),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    TextEditingController privateKeyController = TextEditingController();
                    bool _isLoading = false;

                    return StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          title: const Text("Enter PrivateKey(s)"),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: privateKeyController,
                                  keyboardType: TextInputType.multiline,
                                  maxLines: null,
                                  decoration: const InputDecoration(
                                    labelText: 'PrivateKey(s)',
                                    hintText: 'Enter one or more PrivateKey(s), separated by lines, commas, semicolons, pipes, or spaces',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Đóng popup
                              },
                              child: const Text("Cancel"),
                            ),
                            _isLoading
                                ? const CircularProgressIndicator()
                                : TextButton(
                              onPressed: () async {
                                String privateKeyInput = privateKeyController
                                    .text;
                                String? pin = SessionManager.userPin;

                                if (privateKeyInput.isNotEmpty && pin != null) {
                                  setState(() {
                                    _isLoading = true;
                                  });

                                  try {
                                    List<
                                        String> privateKeyList = privateKeyInput
                                        .split(RegExp(r'[\n,\s;|]+'))
                                        .map((key) => key.trim())
                                        .where((key) => key.isNotEmpty)
                                        .toList();

                                    await importMultiPrivateKeys(
                                        privateKeyList, pin);
                                    await _loadWalletData();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Wallet(s) imported successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Failed to import wallet(s): $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }

                                  setState(() {
                                    _isLoading = false;
                                  });
                                  Navigator.of(context).pop();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'PrivateKey is empty or PIN is not available'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              },
                              child: const Text("Confirm"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.green),
              onPressed: () {
                print('Settings button clicked');
              },
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card hiển thị tổng số dư
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[600]!, Colors.green[200]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Balance',
                          style: TextStyle(fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                    'assets/images/usdt_logo.png', width: 24,
                                    height: 24),
                                const SizedBox(width: 8),
                                Text('${formatBalance(totalUsdtBalance)}',
                                    style: const TextStyle(
                                        color: Colors.white)),
                                const SizedBox(width: 8),
                                Image.asset(
                                    'assets/images/bnb-bnb-logo.png', width: 24,
                                    height: 24),
                                const SizedBox(width: 8),
                                Text('${formatBalance(totalBnbBalance)}',
                                    style: const TextStyle(
                                        color: Colors.white)),
                                const SizedBox(width: 8),
                                Image.asset(
                                    'assets/images/logo_ktr.png', width: 24,
                                    height: 24),
                                const SizedBox(width: 8),
                                Text('${formatBalance(totalKtrBalance)}',
                                    style: const TextStyle(
                                        color: Colors.white)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  print('Send All clicked');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (
                                          context) => const SendAllScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Send All', style: TextStyle(
                                    fontSize: 10, color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (
                                          context) => const WithdrawScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Withdraw All',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 5),

              // Main Wallet Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[600]!, Colors.green[200]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Main Wallet',
                          style: TextStyle(fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text('Address: $shortAddress',
                                style: const TextStyle(color: Colors.white)),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.white),
                              onPressed: () =>
                                  copyToClipboard(mainWalletAddress),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                    'assets/images/usdt_logo.png', width: 24,
                                    height: 24),
                                const SizedBox(width: 8),
                                Text(formatBalance(mainWalletUsdtBalance),
                                    style: const TextStyle(
                                        color: Colors.white)),
                              ],
                            ),
                            const SizedBox(width: 5),
                            Row(
                              children: [
                                Image.asset(
                                    'assets/images/bnb-bnb-logo.png', width: 24,
                                    height: 24),
                                const SizedBox(width: 8),
                                Text(formatBalance(mainWalletBnbBalance),
                                    style: const TextStyle(
                                        color: Colors.white)),
                              ],
                            ),
                            const SizedBox(width: 5),
                            Row(
                              children: [
                                Image.asset(
                                    'assets/images/logo_ktr.png', width: 24,
                                    height: 24),
                                const SizedBox(width: 8),
                                Text(formatBalance(mainWalletKtrBalance),
                                    style: const TextStyle(
                                        color: Colors.white)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _showWithdrawDialog,
                                // Hiển thị popup rút tiền
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Withdraw', style: TextStyle(
                                    fontSize: 10, color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              10.0),
                                          side: const BorderSide(
                                              color: Colors.green, width: 2),
                                        ),
                                        title: const Center(
                                          child: Text(
                                            "Deposit",
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                  'Scan this QR code to deposit to your wallet:'),
                                              const SizedBox(height: 20),
                                              SizedBox(
                                                width: 200,
                                                height: 200,
                                                child: QrImageView(
                                                  data: mainWalletAddress,
                                                  version: QrVersions.auto,
                                                  size: 200.0,
                                                  embeddedImage: const AssetImage(
                                                      'assets/images/logo_ktr.png'),
                                                  embeddedImageStyle: const QrEmbeddedImageStyle(
                                                    size: Size(40, 40),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              GestureDetector(
                                                onTap: () {
                                                  Clipboard.setData(
                                                      ClipboardData(
                                                          text: mainWalletAddress));
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            'Address copied to clipboard')),
                                                  );
                                                },
                                                child: SelectableText(
                                                  mainWalletAddress,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.of(context).pop();
                                              await _loadWalletData();
                                              setState(() {});
                                            },
                                            child: const Text(
                                              'Close',
                                              style: TextStyle(
                                                  color: Colors.green),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Deposit', style: TextStyle(
                                    fontSize: 10, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              // Wallets list excluding the main wallet
              Expanded(
                child: ListView.builder(
                  itemCount: wallets.length > 1 ? wallets.length - 1 : 0,
                  itemBuilder: (BuildContext context, int index) {
                    String walletName = wallets[index + 1]['name'];
                    String privateKey = wallets[index + 1]['privateKey'];
                    String walletAddress = wallets[index + 1]['address'];
                    double walletBnbBalance = wallets[index + 1]['bnbBalance'];
                    double walletUsdtBalance = wallets[index +
                        1]['usdtBalance'];
                    double walletKtrBalance = wallets[index + 1]['ktrBalance'];
                    String formatBalance(double value) {
                      String formattedValue = value.toStringAsFixed(4);
                      formattedValue = double.parse(formattedValue).toString();
                      return formattedValue;
                    }
                    String shortAddress = (walletAddress.length > 10)
                        ? '${walletAddress.substring(0, 5)}...${walletAddress
                        .substring(walletAddress.length - 5)}'
                        : walletAddress;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.green, width: 1),
                      ),
                      child: ListTile(
                        title: Row(
                          children: [
                            Text(
                              walletName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                shortAddress,
                                style: const TextStyle(color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                    'assets/images/bnb-bnb-logo.png', width: 24,
                                    height: 24),
                                const SizedBox(width: 4),
                                Text(formatBalance(walletBnbBalance)),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Row(
                              children: [
                                Image.asset(
                                    'assets/images/usdt_logo.png', width: 24,
                                    height: 24),
                                const SizedBox(width: 4),
                                Text(formatBalance(walletUsdtBalance)),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Row(
                              children: [
                                Image.asset(
                                    'assets/images/logo_ktr.png', width: 24,
                                    height: 24),
                                const SizedBox(width: 4),
                                Text(formatBalance(walletKtrBalance)),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          // Biểu tượng ba chấm dọc
                          color: Colors.green,
                          // Đặt màu xanh cho biểu tượng
                          onPressed: () {
                            showWalletDetails(privateKey,
                                walletName, walletAddress, walletBnbBalance,
                                walletUsdtBalance,
                                walletKtrBalance);
                          },
                        ),

                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to show full-screen wallet details
  Future<List> loadTransactionDataWithDuplicates(List transactions) async {
    Map<String, int> addressCount = {};

    // Duyệt qua danh sách transactions để đếm số lần xuất hiện của mỗi address
    for (var transaction in transactions) {
      String address = transaction['address'];
      addressCount[address] = (addressCount[address] ?? 0) + 1;
    }

    // Lọc các giao dịch chỉ giữ những giao dịch có địa chỉ ví trùng lặp
    List filteredTransactions = transactions.where((transaction) {
      return addressCount[transaction['address']]! > 1;
    }).toList();

    return filteredTransactions;
  }

  void showWalletDetails(String privateKey,String walletName, String walletAddress, double walletBnbBalance,
      double walletUsdtBalance, double walletKtrBalance) {
    String formatBalance(double value) {
      String formattedValue = value.toStringAsFixed(4);
      formattedValue = double.parse(formattedValue).toString();
      return formattedValue;
    }

    void _showWithdrawDialog() async {
      if (walletAddress.isEmpty) {
        print('No wallet loaded');
        return;
      }

      String selectedToken = 'BNB';
      TextEditingController recipientController = TextEditingController();
      TextEditingController amountController = TextEditingController();
     // getRecentTransactions(walletAddress);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Center(
                  child: Text(
                    'Withdraw Funds',
                    style: TextStyle(
                      color: Colors.green,
                    ),
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('From Wallet: Your Wallet',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('$walletAddress',
                          style: const TextStyle(color: Colors.black)),
                      const SizedBox(height: 10),
                      DropdownButton<String>(
                        value: selectedToken,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedToken = newValue!;
                          });
                        },
                        items: <String>['BNB', 'USDT', 'KTR']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      if (selectedToken == 'BNB')
                        Text('Balance: ${formatBalance(walletBnbBalance)} BNB'),
                      if (selectedToken == 'USDT')
                        Text('Balance: ${formatBalance(walletUsdtBalance)} USDT'),
                      if (selectedToken == 'KTR')
                        Text('Balance: ${formatBalance(walletKtrBalance)} KTR'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: recipientController,
                        decoration: const InputDecoration(
                          labelText: 'Recipient Address',
                          hintText: 'Enter recipient address',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          hintText: 'Enter amount to withdraw',
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () async {
                      String amountStr = amountController.text.trim();
                      String recipient = recipientController.text.trim();

                      if (amountStr.isEmpty || recipient.isEmpty) {
                        print('Amount or recipient is empty.');
                        return;
                      }
                      try {
                        final EthereumAddress toEthereumAddress = EthereumAddress
                            .fromHex(recipient);
                        TransactionServiceSend action = TransactionServiceSend();
                        double amount = double.parse(
                            amountStr); // Chuyển đổi chuỗi thành số

                        if (selectedToken == 'USDT') {
                          // Gọi hàm gửi USDT (chuyển sang BigInt với 18 chữ số thập phân)
                          await action.sendallUsdtBep20(
                              privateKey, toEthereumAddress,
                              BigInt.from(amount * 1e18));
                          print('Withdraw $amount USDT to $recipient');
                        } else if (selectedToken == 'KTR') {
                          // Gọi hàm gửi KTR (chuyển sang BigInt với 18 chữ số thập phân)
                          await action.sendallKtrBep20(
                              privateKey, toEthereumAddress,
                              BigInt.from(amount * 1e18));
                          print('Withdraw $amount KTR to $recipient');
                        } else if (selectedToken == 'BNB') {
                          await action.sendBNB(
                              privateKey, toEthereumAddress, amount);
                          print('Withdraw $amount BNB to $recipient');
                        }

                        Navigator.of(context)
                            .pop(); // Đóng popup sau khi hoàn thành
                      } catch (e) {
                        print('Error during withdrawal: $e');
                      }
                    },
                    child: const Text("Confirm"),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    // Hiển thị Dialog chứa chi tiết ví
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(0),
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.green,
              title: Text(
                '$walletName Details',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wallet details card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green[400]!, Colors.green[200]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Wallet Address:',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, color: Colors.white),
                                    onPressed: () => copyToClipboard(walletAddress),
                                  ),
                                ],
                              ),
                              Text(walletAddress, style: const TextStyle(color: Colors.white)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Text(
                                    'Total Balance:',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('$totalBalance USD', style: const TextStyle(color: Colors.white)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // USDT Balance with logo
                                  Row(
                                    children: [
                                      Image.asset('assets/images/usdt_logo.png', width: 24, height: 24),
                                      Text(formatBalance(walletUsdtBalance), style: const TextStyle(color: Colors.white)),
                                      const SizedBox(width: 8),
                                      Image.asset('assets/images/bnb-bnb-logo.png', width: 24, height: 24),
                                      const SizedBox(width: 8),
                                      Text(formatBalance(walletBnbBalance), style: const TextStyle(color: Colors.white)),
                                      const SizedBox(width: 8),
                                      Image.asset('assets/images/logo_ktr.png', width: 24, height: 24),
                                      const SizedBox(width: 8),
                                      Text(formatBalance(walletKtrBalance), style: const TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(
                                                    10.0),
                                                side: const BorderSide(
                                                    color: Colors.green, width: 2),
                                              ),
                                              title: const Center(
                                                child: Text(
                                                  "Deposit",
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              ),
                                              content: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Text(
                                                        'Scan this QR code to deposit to your wallet:'),
                                                    const SizedBox(height: 20),
                                                    SizedBox(
                                                      width: 200,
                                                      height: 200,
                                                      child: QrImageView(
                                                        data: walletAddress,
                                                        version: QrVersions.auto,
                                                        size: 200.0,
                                                        embeddedImage: const AssetImage(
                                                            'assets/images/logo_ktr.png'),
                                                        embeddedImageStyle: const QrEmbeddedImageStyle(
                                                          size: Size(40, 40),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 20),
                                                    GestureDetector(
                                                      onTap: () {
                                                        Clipboard.setData(
                                                            ClipboardData(
                                                                text: walletAddress));
                                                        ScaffoldMessenger.of(context)
                                                            .showSnackBar(
                                                          const SnackBar(
                                                              content: Text(
                                                                  'Address copied to clipboard')),
                                                        );
                                                      },
                                                      child: SelectableText(
                                                        walletAddress,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () async {
                                                    Navigator.of(context).pop();
                                                    await _loadWalletData();
                                                    setState(() {});
                                                  },
                                                  child: const Text(
                                                    'Close',
                                                    style: TextStyle(
                                                        color: Colors.green),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text('Deposit', style: TextStyle(
                                          fontSize: 10, color: Colors.white)),
                                    ),
                                  ),

                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Hiển thị dialog Withdraw
                                        _showWithdrawDialog();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orangeAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: const Text('Withdraw', style: TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Transaction history placeholder
                    const Text(
                      'Transaction History',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder(
                      future: loadTransactionData(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return const Text('Error loading transactions');
                        } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
                          return const Text('No transactions available');
                        }

                        List transactions = snapshot.data as List;

                        List filteredTransactions = transactions.where((transaction) {
                          return transaction['address'] == walletAddress;
                        }).toList();

                        if (filteredTransactions.isEmpty) {
                          return const Text('No transactions for this wallet');
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = filteredTransactions[index];

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                                side: BorderSide(color: Colors.green, width: 1),
                              ),
                              child: ListTile(
                                leading: Text(
                                  '#${index + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                title: Text(
                                  'Hash: ${transaction['hash'].substring(0, 6)}...',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text('Status: ${transaction['type']}'),
                                trailing: Text('${transaction['time']}'),
                                onTap: () async {
                                  final url = 'https://bscscan.com/tx/${transaction['hash']}';
                                  if (await canLaunch(url)) {
                                    await launch(url);
                                  } else {
                                    throw 'Could not launch $url';
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  Future<List<Map<String, dynamic>>> loadTransactionData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
          '${directory.path}/transactions.json'); // Đường dẫn file JSON

      if (!await file.exists()) {
        print('File transactions.json không tồn tại');
        return []; // Trả về danh sách rỗng nếu file không tồn tại
      }

      final contents = await file.readAsString();

      final List<dynamic> jsonData = jsonDecode(contents);
      return jsonData.map((transaction) =>
      Map<String, dynamic>.from(transaction)).toList();
    } catch (e) {
      print('Lỗi khi đọc file JSON: $e');
      return [];
    }
  }
}
