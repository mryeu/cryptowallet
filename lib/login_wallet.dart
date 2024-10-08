import 'package:cryptowallet/socket_connect_wl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'buid_play_widget.dart';
import 'check_balance.dart';
import 'check_price_ktr.dart';
import 'ktr_swap.dart';
import 'wallet_create.dart'; // Import nếu cần các hàm từ wallet_create.dart
import 'build_widget.dart'; // Import các hàm build widget


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = '';

  Future<void> login() async {
    final password = passwordController.text;
    final walletData = await loadWalletFromJson();

    if (walletData == null) {
      setState(() {
        errorMessage = "Wallet information not found.";
      });
      return;
    }
    final encryptedMnemonic = walletData['encrypted_mnemonic'];

    try {
      final mnemonic = decryptDataAES(encryptedMnemonic, password);

      if (mnemonic.isNotEmpty) {
        // Lấy private key của main wallet (ví đầu tiên)
        final String encryptedMainWalletPrivateKey = walletData['encrypted_private_keys'][0];
        final String mainWalletPrivateKey = decryptDataAES(encryptedMainWalletPrivateKey, password);

        // Truyền mnemonic, password, và mainWalletPrivateKey vào WalletDisplayPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WalletDisplayPage(
            walletData: walletData,
            mnemonic: mnemonic,
            password: password,
            mainWalletPrivateKey: mainWalletPrivateKey, // Truyền mainWalletPrivateKey đã giải mã
          )),
        );
      } else {
        setState(() {
          errorMessage = "Incorrect password.";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Incorrect password or another error: $e";
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildLoginScreen(
        passwordController: passwordController,
        loginFunction: login,
        errorMessage: errorMessage,
      ),
    );
  }
}

// Trang hiển thị địa chỉ ví sau khi đăng nhập thành công
class WalletDisplayPage extends StatelessWidget {
  final Map<String, dynamic> walletData;
  final String mnemonic;
  final String password;
  final String mainWalletPrivateKey;

  const WalletDisplayPage({super.key, required this.walletData, required this.mnemonic, required this.password, required this.mainWalletPrivateKey});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Số lượng tab
      child: Scaffold(
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                children: [
                  // Truyền mainWalletPrivateKey đã giải mã vào _buildWalletTab
                  _buildWalletTab(context, walletData, mnemonic, password, mainWalletPrivateKey),
                  _buildPlayTab(context, walletData, mnemonic, password, mainWalletPrivateKey),
                  KtrSwapTab(
                    walletData: walletData,
                    mnemonic: mnemonic,
                    password: password,
                    mainWalletPrivateKey: mainWalletPrivateKey,
                  ), // Tab KTRSwap
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _buildKtrSwapTab {
}

Widget _buildPlayTab(BuildContext context, Map<String, dynamic> walletData, String mnemonic, String password, String mainWalletPrivateKey) {
  final List<String> walletAddresses = List<String>.from(walletData['addresses'] ?? []);
  final List<String> walletNames = List<String>.from(walletData['wallet_names'] ?? []);
  final List<String> encryptedPrivateKeys = List<String>.from(walletData['encrypted_private_keys'] ?? []);

  if (walletAddresses.isEmpty) {
    return const Center(child: Text("No wallet addresses found."));
  }

  // Giải mã tất cả các private keys từ danh sách encryptedPrivateKeys
  final List<String> decryptedPrivateKeys = encryptedPrivateKeys.map((encryptedKey) {
    return decryptDataAES(encryptedKey, password); // Giải mã private key
  }).toList();

  // Tạo danh sách các ví với tên, địa chỉ và privateKey
  final List<Map<String, String>> allWallets = List<Map<String, String>>.generate(
    walletAddresses.length,
        (index) => {
      "name": walletNames[index], // Tên ví từ wallet_names
      "address": walletAddresses[index], // Địa chỉ ví
      "privateKey": decryptedPrivateKeys[index], // Private key đã giải mã
    },
  );

  // Địa chỉ ví chính là ví đầu tiên
  final String mainWalletAddress = allWallets[0]["address"]!;

  final List<Map<String, String>> otherWallets = allWallets.length > 1 ? allWallets.sublist(1) : [];

  return Center(
    child: Row(
      children: [
        buildPlayHistoryWidget_1(),
        buildPlayMainWalletWidget(context, otherWallets),
      ],
    ),
  );
}


  Widget _buildTabBar() {
    return Container(
      width: 350,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.greenAccent, Colors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.green,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            colors: [Colors.white, Colors.greenAccent],
            tileMode: TileMode.clamp,
          ).createShader(bounds);
        },
        child: const TabBar(
          tabs: [
            Tab(text: 'Wallet'),
            Tab(text: 'Play'),
            Tab(text: 'KTRSwap'),
          ],
          indicatorColor: Colors.white,
        ),
      ),
    );
  }

Widget _buildWalletTab(BuildContext context, Map<String, dynamic> walletData, String mnemonic, String password, String mainWalletPrivateKey) {
  final List<String> walletAddresses = List<String>.from(walletData['addresses'] ?? []);
  final List<String> walletNames = List<String>.from(walletData['wallet_names'] ?? []);
  final List<String> encryptedPrivateKeys = List<String>.from(walletData['encrypted_private_keys'] ?? []);

  if (walletAddresses.isEmpty) {
    return const Center(child: Text("No wallet addresses found."));
  }

  // Giải mã tất cả các private keys từ danh sách encryptedPrivateKeys
  final List<String> decryptedPrivateKeys = encryptedPrivateKeys.map((encryptedKey) {
    return decryptDataAES(encryptedKey, password); // Giải mã private key
  }).toList();

  // Tạo danh sách các ví với tên, địa chỉ và privateKey
  final List<Map<String, String>> allWallets = List<Map<String, String>>.generate(
    walletAddresses.length,
        (index) => {
      "name": walletNames[index], // Tên ví từ wallet_names
      "address": walletAddresses[index], // Địa chỉ ví
      "privateKey": decryptedPrivateKeys[index], // Private key đã giải mã
    },
  );

  // Địa chỉ ví chính là ví đầu tiên
  final String mainWalletAddress = allWallets[0]["address"]!;

  final List<Map<String, String>> otherWallets = allWallets.length > 1 ? allWallets.sublist(1) : [];

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildMainWalletInfo(context, allWallets), // Hiển thị thông tin ví chính
              const SizedBox(height: 5),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildTransactionHistory(), // Hiển thị lịch sử giao dịch
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                buildMainWallet(mainWalletAddress, mainWalletPrivateKey, otherWallets, context), // Truyền mainWalletPrivateKey và otherWallets
                const SizedBox(height: 10),
                buildAddWalletWidget(mnemonic, password, context), // Truyền mnemonic và password
                const SizedBox(height: 10),
                buildWalletListBuilder(otherWallets), // Hiển thị danh sách ví
              ],
            ),
          ),
        ),
      ],
    ),
  );
}



Widget _buildMainWalletInfo(BuildContext context, List<Map<String, String>> allWallets) {
  // Lấy địa chỉ ví từ danh sách ví (allWallets)
  List<String> walletAddresses = allWallets.map((wallet) => wallet['address']!).toList();

  WebSocketTransactionListener listener = WebSocketTransactionListener(walletAddresses);

  // Gọi phương thức fetchLogs() để lấy logs


  // Khởi tạo TokenBalanceChecker để kiểm tra số dư
  TokenBalanceChecker checker = TokenBalanceChecker();

  return FutureBuilder<Map<String, double>>(
    future: _getTotalBalanceInUsdtForAllWallets(checker, allWallets),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      } else if (snapshot.hasData) {
        final totalBalanceInUsdt = snapshot.data!['totalUsdt'] ?? 0.0;

        // Hàm định dạng số dư
        String formatBalance(double value) {
          // Chuyển đổi số thành chuỗi, giữ lại tối đa 4 chữ số thập phân
          String formattedValue = value.toStringAsFixed(4);
          // Chuyển lại thành số để loại bỏ các số 0 thừa phía sau nếu có
          formattedValue = double.parse(formattedValue).toString();

          return formattedValue;
        }

        // Giao diện hiển thị số dư
        return Container(
          height: 150,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[500]!, Colors.green[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.green, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Total Balance in USDT:',
                style: TextStyle(fontSize: 15, color: Colors.white),
              ),
              // Sử dụng hàm formatBalance để định dạng totalBalanceInUsdt
              Text(
                '\$ ${formatBalance(totalBalanceInUsdt)}', // Hiển thị tổng số dư với định dạng chuẩn
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Hiển thị các thông tin token
                  Expanded(
                    flex: 1,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildCurrencyInfo('assets/images/usdt_logo.png', formatBalance(snapshot.data!['usdt']!)),
                        const SizedBox(width: 10),
                        _buildCurrencyInfo('assets/images/bnb-bnb-logo.png', formatBalance(snapshot.data!['bnb']!)),
                        const SizedBox(width: 10),
                        _buildCurrencyInfo('assets/images/logo_ktr.png', formatBalance(snapshot.data!['ktr']!)),
                      ],
                    ),
                  ),
                  // Hiển thị các nút Deposit và Withdraw cho ví đầu tiên
                  Expanded(
                    flex: 1,
                    child: allWallets.isNotEmpty
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            buildWalletActionButton(
                                'Deposit', allWallets[0]['address']!, context),
                            const SizedBox(width: 10),
                            buildWalletWithdrawButton(
                                'Withdraw', allWallets[0]['address']!, context),
                          ],
                        ),
                      ],
                    )
                        : const Center(child: Text('No wallets available')),
                  ),
                ],
              ),
            ],
          ),
        );
      } else {
        return const Center(child: Text('No balance data'));
      }
    },
  );
}

Future<Map<String, double>> _getTotalBalanceInUsdtForAllWallets(TokenBalanceChecker checker, List<Map<String, String>> allWallets) async {
  double totalBnbBalance = 0.0;
  double totalUsdtBalance = 0.0;
  double totalKtrBalance = 0.0;

  // Lấy giá của BNB và KTR theo USDT
  String bnbPriceInUsdtStr = await checkPriceBNB(1);
  String ktrPriceInUsdtStr = await checkPriceKTR(1);
  double bnbPriceInUsdt = double.tryParse(bnbPriceInUsdtStr) ?? 0.0;
  double ktrPriceInUsdt = double.tryParse(ktrPriceInUsdtStr) ?? 0.0;

  // Lặp qua tất cả các ví
  for (var wallet in allWallets) {
    String walletAddress = wallet['address']!;

    // Lấy số dư BNB, USDT, KTR cho ví này
    double bnbBalance = await checker.getBnbBalance(walletAddress) ?? 0.0;
    double usdtBalance = await checker.getUsdtBalance(walletAddress) ?? 0.0;
    double ktrBalance = await checker.getKtrBalance(walletAddress) ?? 0.0;

    // Cộng số dư token vào tổng số dư
    totalBnbBalance += bnbBalance;
    totalUsdtBalance += usdtBalance;
    totalKtrBalance += ktrBalance;
  }

  // Quy đổi tổng số dư BNB và KTR sang USDT
  double totalBnbInUsdt = totalBnbBalance * bnbPriceInUsdt;
  double totalKtrInUsdt = totalKtrBalance * ktrPriceInUsdt;

  // Tổng số dư quy đổi ra USDT
  double totalBalanceInUsdt = totalUsdtBalance + totalBnbInUsdt + totalKtrInUsdt;

  return {
    'bnb': totalBnbBalance,
    'usdt': totalUsdtBalance,
    'ktr': totalKtrBalance,
    'totalUsdt': totalBalanceInUsdt,
  };
}




Widget _buildCurrencyInfo(String imagePath, String amount) {
    return Row(
      children: [
        Image.asset(
          imagePath,
          width: 15,
          height: 15,
        ),
        const SizedBox(width: 5),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 30),
      ],
    );
  }

  Widget _buildTransactionHistory() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            _buildTransactionHeader(),
            const SizedBox(height: 10),
            buildListView(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
        color: Colors.green.withOpacity(0.1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTransactionHeaderColumn('Transaction Hash'),
          _buildTransactionHeaderColumn('Block'),
          _buildTransactionHeaderColumn('From/To'),
          _buildTransactionHeaderColumn('Value (USD)'),
          _buildTransactionHeaderColumn('KTR Fee'),
          _buildTransactionHeaderColumn('Age'),
        ],
      ),
    );
  }

  Widget _buildTransactionHeaderColumn(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 2),
        SvgPicture.asset('assets/images/sort.svg'),
      ],
    );
  }



