import 'package:cryptowallet/send_all_screen.dart';
import 'package:cryptowallet/services/session_manager.dart';
import 'package:cryptowallet/wallet_create.dart'; // Import wallet creation functions
import 'package:cryptowallet/with_draw_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'check_balance.dart';

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  String walletAddress = ''; // Placeholder for wallet address
  double usdtBalance = 0.0; // Placeholder for USDT balance
  double bnbBalance = 0.0;  // Placeholder for BNB balance
  double ktrBalance = 0.0;  // Placeholder for KTR balance
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
                  if (walletDataDecrypt != null && walletDataDecrypt.containsKey('decrypted_mnemonic')) {
                    await addNewWalletFromMnemonic(walletDataDecrypt['decrypted_mnemonic'], pin);
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

// Load wallet data from JSON file and update balances
  Future<void> _loadWalletData() async {
    try {
      String? pin = SessionManager.userPin;
      final walletDataDecrypt = await loadWalletPINFromJson(pin!);
      if (walletDataDecrypt != null) {
        setState(() {
          if (walletDataDecrypt.containsKey('wallet_names') && walletDataDecrypt.containsKey('addresses')) {
            wallets = List.generate(walletDataDecrypt['wallet_names'].length, (index) {
              return {
                'name': walletDataDecrypt['wallet_names'][index],
                'address': walletDataDecrypt['addresses'][index],
                'bnbBalance': 0.0,
                'usdtBalance': 0.0,
                'ktrBalance': 0.0,
              };
            });
            walletAddress = walletDataDecrypt['addresses'][0]; // Main wallet address
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
    String shortAddress;
    if (walletAddress.length > 10) {
      shortAddress = '${walletAddress.substring(0, 5)}...${walletAddress.substring(walletAddress.length - 5)}';
    } else {
      shortAddress = walletAddress;
    }

    return Scaffold(
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
              print('Import Wallet button clicked');
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
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text('Address: $shortAddress', style: const TextStyle(color: Colors.white)),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.white),
                            onPressed: () => copyToClipboard(walletAddress),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset('assets/images/usdt_logo.png', width: 24, height: 24),
                              const SizedBox(width: 8),
                              Text('USDT: $usdtBalance', style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                          const SizedBox(width: 5),
                          Row(
                            children: [
                              Image.asset('assets/images/bnb-bnb-logo.png', width: 24, height: 24),
                              const SizedBox(width: 8),
                              Text('BNB: $bnbBalance', style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                          const SizedBox(width: 5),
                          Row(
                            children: [
                              Image.asset('assets/images/logo_ktr.png', width: 24, height: 24),
                              const SizedBox(width: 8),
                              Text('KTR: $ktrBalance', style: const TextStyle(color: Colors.white)),
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
                              onPressed: () {
                                print('Send All clicked');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SendAllScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('SendAll', style: TextStyle(fontSize:10,color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const WithdrawScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('WithdrawAll', style: TextStyle(fontSize:10, color: Colors.white)),
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
                                        borderRadius: BorderRadius.circular(10.0),
                                        side: const BorderSide(color: Colors.green, width: 2),
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
                                            const Text('Scan this QR code to deposit to your wallet:'),
                                            const SizedBox(height: 20),
                                            SizedBox(
                                              width: 200,
                                              height: 200,
                                              child: QrImageView(
                                                data: walletAddress,
                                                version: QrVersions.auto,
                                                size: 200.0,
                                                embeddedImage: const AssetImage('assets/images/logo_ktr.png'),
                                                embeddedImageStyle: const QrEmbeddedImageStyle(
                                                  size: Size(40, 40),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            GestureDetector(
                                              onTap: () {
                                                Clipboard.setData(ClipboardData(text: walletAddress));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Address copied to clipboard')),
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
                                            style: TextStyle(color: Colors.green),
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
                              child: const Text('Deposit', style: TextStyle(fontSize:10,color: Colors.white)),
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

            // Wallets list excluding the main wallet
            Expanded(
              child: ListView.builder(
                itemCount: wallets.length > 1 ? wallets.length - 1 : 0,
                itemBuilder: (BuildContext context, int index) {
                  String walletName = wallets[index + 1]['name'];
                  String walletAddress = wallets[index + 1]['address'];
                  double walletBnbBalance = wallets[index + 1]['bnbBalance'];
                  double walletUsdtBalance = wallets[index + 1]['usdtBalance'];
                  double walletKtrBalance = wallets[index + 1]['ktrBalance'];
                  String shortAddress = (walletAddress.length > 10)
                      ? '${walletAddress.substring(0, 5)}...${walletAddress.substring(walletAddress.length - 5)}'
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
                              Image.asset('assets/images/bnb-bnb-logo.png', width: 24, height: 24),
                              const SizedBox(width: 4),
                              Text('$walletBnbBalance'),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Row(
                            children: [
                              Image.asset('assets/images/usdt_logo.png', width: 24, height: 24),
                              const SizedBox(width: 4),
                              Text('$walletUsdtBalance'),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Row(
                            children: [
                              Image.asset('assets/images/logo_ktr.png', width: 24, height: 24),
                              const SizedBox(width: 4),
                              Text('$walletKtrBalance'),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.info),
                        onPressed: () {
                          showWalletDetails(walletName);
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
    );
  }

  // Function to show full-screen wallet details
  void showWalletDetails(String walletName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(0),
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.green,
              title: Text('$walletName Details'),
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
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green[100]!, Colors.green[400]!],
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
                                'Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Wallet Address:', style: TextStyle(color: Colors.white)),
                                  IconButton(
                                    icon: const Icon(Icons.copy, color: Colors.white),
                                    onPressed: () => copyToClipboard(walletAddress),
                                  ),
                                ],
                              ),
                              Text(walletAddress, style: const TextStyle(color: Colors.white)),
                              const SizedBox(height: 10),
                              const Text('Total Balance:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              Text('$totalBalance USD', style: const TextStyle(color: Colors.white)),
                              const SizedBox(height: 10),
                              Text('USDT Balance: $usdtBalance', style: const TextStyle(color: Colors.white)),
                              Text('BNB Balance: $bnbBalance', style: const TextStyle(color: Colors.white)),
                              Text('KTR Balance: $ktrBalance', style: const TextStyle(color: Colors.white)),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
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
}
