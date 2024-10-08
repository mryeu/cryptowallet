// build_widget.dart

import 'package:cryptowallet/transaction_usdt_service.dart';
import 'package:cryptowallet/wallet_create.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/credentials.dart';
import 'check_balance.dart';
import 'check_price_ktr.dart';
import 'login_wallet.dart';
import 'dart:async';
import 'add_member.dart';


Widget buildListView() {
  return Expanded(
    child: ListView.builder(
      itemCount: 29,
      itemBuilder: (context, index) {
        return const Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // Bỏ border radius
          ),
          child: Padding(
            padding: EdgeInsets.all(8.0), // Khoảng cách giữa nội dung và viền card
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Căn đều sát hai bên
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('0xd4938a2.....', style: TextStyle(fontSize: 10)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('12345678', style: TextStyle(fontSize: 10)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('0xd4938a2560...', style: TextStyle(fontSize: 10)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('100.25', style: TextStyle(fontSize: 10)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('0.001', style: TextStyle(fontSize: 10)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1 days ago', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}



Widget buildMainWallet(String mainWalletAddress, String mainWalletPrivateKey, List<Map<String, String>> walletList, BuildContext context) {
  return FutureBuilder<Map<String, double>>(
    future: _loadBalances(mainWalletAddress), // Gọi hàm _loadBalances để lấy số dư
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator()); // Hiển thị loading khi đang lấy số dư
      } else if (snapshot.hasError) {
        return const Center(child: Text("Error loading balances")); // Hiển thị lỗi nếu có lỗi xảy ra
      } else if (snapshot.hasData) {
        final balances = snapshot.data!;
        final usdtBalance = balances['usdt'] ?? 0.0;
        final bnbBalance = balances['bnb'] ?? 0.0;
        final ktrBalance = balances['ktr'] ?? 0.0;

        String formatBalance(double value) {
          // Chuyển đổi số thành chuỗi, bỏ đi những số 0 không cần thiết
          String formattedValue = value.toStringAsFixed(4);
          formattedValue = double.parse(formattedValue).toString();
          return formattedValue;
        }

        return Container(
          height: 150,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Colors.white,
                Colors.white,
              ],
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
              Row(
                children: [
                  const Text(
                    'Main Wallet',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.green,
                    ),
                  ),
                  const Spacer(),
                  buildSendAllButton('Send all', mainWalletAddress, mainWalletPrivateKey, walletList, context),
                  const SizedBox(width: 20),
                  buildWithdrawAllButton('Withdraw all', mainWalletAddress, walletList, context),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2, // Tăng flex để dành thêm không gian cho địa chỉ ví
                    child: SizedBox(
                      height: 90,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 30),
                            child: Container(
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
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 30),
                                  child: Text(
                                    'Wallet Main KTR',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Spacer(),
                                Row(
                                  children: [
                                    // Hiển thị địa chỉ ví rút gọn
                                    Flexible(
                                      child: Text(
                                        '${mainWalletAddress.substring(0, 6)}...${mainWalletAddress.substring(mainWalletAddress.length - 4)}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.blueGrey,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    // Icon copy
                                    const SizedBox(width: 5),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 10, color: Colors.green),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: mainWalletAddress)); // Sao chép địa chỉ ví
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Wallet address copied to clipboard",
                                              style: TextStyle(color: Colors.white), // Chữ màu trắng
                                            ),
                                            backgroundColor: Colors.green, // Nền màu xanh lá cây
                                            duration: Duration(seconds: 2), // Thời gian hiển thị SnackBar
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Expanded(
                    flex: 1, // Điều chỉnh flex cho cột giữa
                    child: SizedBox(
                      height: 60,
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 30),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Played time left',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '24h 00m 00s',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    flex: 2, // Tăng flex cho cột balance để vừa vặn hơn
                    child: SizedBox(
                      height: 70,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 10, top: 20),
                            child: FutureBuilder<List<String>>(
                              future: Future.wait([
                                checkPriceBNB(1), // Lấy giá trị BNB theo USDT
                                checkPriceKTR(1), // Lấy giá trị KTR theo USDT
                              ]),
                              builder: (context, priceSnapshot) {
                                if (priceSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator()); // Hiển thị loading khi đang lấy giá token
                                } else if (priceSnapshot.hasError) {
                                  return const Text('Error loading token prices'); // Hiển thị lỗi nếu không lấy được giá token
                                } else if (priceSnapshot.hasData) {
                                  // Chuyển đổi các giá trị trả về thành số thực để tính toán
                                  final bnbPriceInUsdt = double.tryParse(priceSnapshot.data![0]) ?? 0.0;
                                  final ktrPriceInUsdt = double.tryParse(priceSnapshot.data![1]) ?? 0.0;

                                  // Tính tổng giá trị USDT của các token
                                  final totalInUsdt = usdtBalance + (bnbBalance * bnbPriceInUsdt) + (ktrBalance * ktrPriceInUsdt);

                                  return Text(
                                    '\$${formatBalance(totalInUsdt)}', // Tổng balance đã định dạng
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                } else {
                                  return const Text('No data available');
                                }
                              },
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Image.asset(
                                'assets/images/usdt_logo.png',
                                width: 15,
                                height: 15,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                formatBalance(usdtBalance), // Số dư USDT đã định dạng
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Image.asset(
                                'assets/images/bnb-bnb-logo.png',
                                width: 15,
                                height: 15,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                formatBalance(bnbBalance), // Số dư BNB đã định dạng
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Image.asset(
                                'assets/images/logo_ktr.png',
                                width: 15,
                                height: 15,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                formatBalance(ktrBalance), // Số dư KTR đã định dạng
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      } else {
        return const Center(child: Text("No balance data"));
      }
    },
  );
}





Widget buildSendAllButton(String text, String mainWalletAddress, String mainWalletPrivateKey, List<Map<String, String>> walletList, BuildContext context) {
  return ElevatedButton(
    onPressed: () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          List<bool> walletChecked = List<bool>.filled(walletList.length, true);
          int selectedWalletCount = walletChecked.where((checked) => checked).length;
          String selectedToken = 'BNB';
          String selectedIcon = 'assets/images/bnb-bnb-logo.png';
          TextEditingController amountController = TextEditingController();

          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              bool isDialogMounted = true;

              return WillPopScope(
                onWillPop: () async {
                  isDialogMounted = false;
                  return true;
                },
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: const BorderSide(color: Colors.green, width: 2),
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: 700,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Send to all",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('From (Main Wallet):'),
                        const SizedBox(height: 10),
                        SelectableText(
                          mainWalletAddress,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Image.asset(
                              selectedIcon,
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 10),
                            DropdownButton<String>(
                              value: selectedToken,
                              items: <String>['BNB', 'KTR', 'USDT'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    selectedToken = newValue;
                                    switch (newValue) {
                                      case 'BNB':
                                        selectedIcon = 'assets/images/bnb-bnb-logo.png';
                                        break;
                                      case 'KTR':
                                        selectedIcon = 'assets/images/logo_ktr.png';
                                        break;
                                      case 'USDT':
                                        selectedIcon = 'assets/images/usdt_logo.png';
                                        break;
                                    }
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: amountController,
                                decoration: const InputDecoration(
                                  labelText: "Amount",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Text('Select wallets to send to: '),
                            Text(
                              '$selectedWalletCount/${walletList.length}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: selectedWalletCount < walletList.length ? Colors.red : Colors.green,
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (amountController.text.isNotEmpty && selectedWalletCount > 0)
                              Text(
                                '(${(double.tryParse(amountController.text) ?? 0) / selectedWalletCount} per wallet)',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        walletList.length > 5
                            ? SizedBox(
                          height: 400,
                          child: ListView.builder(
                            itemCount: walletList.length,
                            itemBuilder: (context, index) {
                              return _buildWalletItem(walletList, walletChecked, index, setState, () {
                                setState(() {
                                  if (walletChecked[index]) {
                                    selectedWalletCount--;
                                  } else {
                                    selectedWalletCount++;
                                  }
                                  walletChecked[index] = !walletChecked[index];
                                });
                              });
                            },
                          ),
                        )
                            : Column(
                          children: List<Widget>.generate(walletList.length, (int index) {
                            return _buildWalletItem(walletList, walletChecked, index, setState, () {
                              setState(() {
                                if (walletChecked[index]) {
                                  selectedWalletCount--;
                                } else {
                                  selectedWalletCount++;
                                }
                                walletChecked[index] = !walletChecked[index];
                              });
                            });
                          }),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                isDialogMounted = false;
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                double amount = double.tryParse(amountController.text) ?? 0;
                                if (selectedWalletCount > 0 && amount > 0) {
                                  double amountPerWallet = amount / selectedWalletCount;

                                  // Tổng thời gian chờ (7 giây cho mỗi ví được chọn)
                                  int totalWaitTime = selectedWalletCount * 7;

                                  // Hiển thị dialog đếm ngược
                                  _showCountdownDialog(context, totalWaitTime);

                                  // Gửi token cho từng ví
                                  for (int i = 0; i < walletList.length; i++) {
                                    if (walletChecked[i]) {
                                      String toAddress = walletList[i]['address'] ?? '';
                                      String privateKey = mainWalletPrivateKey;
                                      TransactionServiceSend action = TransactionServiceSend();

                                      // Convert amountPerWallet to BigInt (multiply by 10^18 for decimals)
                                      BigInt amountToSend = BigInt.from(amountPerWallet * 1e18);

                                      if (selectedToken == 'BNB') {
                                        print('Sending $amountPerWallet BNB from $mainWalletAddress to $toAddress');
                                        await action.sendBNB(privateKey, EthereumAddress.fromHex(toAddress), amountPerWallet);
                                      } else if (selectedToken == 'USDT') {
                                        print('Sending $amountPerWallet USDT from $mainWalletAddress to $toAddress');
                                        await action.sendallUsdtBep20(privateKey, EthereumAddress.fromHex(toAddress), amountToSend);
                                      } else if (selectedToken == 'KTR') {
                                        print('Sending $amountPerWallet KTR from $mainWalletAddress to $toAddress');
                                        await action.sendallKtrBep20(privateKey, EthereumAddress.fromHex(toAddress), amountToSend);
                                      }

                                      // Đếm ngược mỗi ví gửi
                                      await Future.delayed(const Duration(seconds: 7));
                                    }
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invalid amount or no wallet selected.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Send',
                                style: TextStyle(color: Colors.green),
                              ),
                            )

                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      side: const BorderSide(color: Colors.green),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.black),
    ),
  );
}
// Hàm phụ để hiển thị từng mục ví
// Hàm phụ để hiển thị từng mục ví với số dư BNB, USDT, KTR
Widget _buildWalletItem(List<Map<String, String>> walletList, List<bool> walletChecked, int index, StateSetter setState, VoidCallback onChanged) {
  String walletAddress = walletList[index]["address"] ?? "";
  String walletName = walletList[index]["name"] ?? "Unknown";

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 5.0),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(5),
    ),
    child: FutureBuilder<Map<String, double>>(
      future: _loadBalances(walletAddress), // Gọi hàm load balances cho từng ví
      builder: (BuildContext context, AsyncSnapshot<Map<String, double>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Hiển thị biểu tượng loading khi đang tải số dư
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // Hiển thị lỗi nếu có lỗi xảy ra
          return const Text("Error loading balances");
        } else if (snapshot.hasData) {
          // Khi đã có số dư, hiển thị thông tin
          double bnbBalance = snapshot.data?["bnb"] ?? 0.0;
          double usdtBalance = snapshot.data?["usdt"] ?? 0.0;
          double ktrBalance = snapshot.data?["ktr"] ?? 0.0;
          String formatBalance(double value) {
            // Chuyển đổi số thành chuỗi, bỏ đi những số 0 không cần thiết
            String formattedValue = value.toStringAsFixed(4);
            formattedValue = double.parse(formattedValue).toString();
            return formattedValue;
          }

          return CheckboxListTile(
            value: walletChecked[index],
            onChanged: (bool? value) {
              // Cập nhật trạng thái khi người dùng check/uncheck
              onChanged();
            },
            title: Row(
              children: [
                // Hiển thị tên ví
                Text(
                  walletName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 5),

                // Hiển thị địa chỉ ví
                Expanded(
                  child: Text(
                    walletAddress,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 5),

                // Hiển thị số dư BNB
                Image.asset(
                  'assets/images/bnb-bnb-logo.png',
                  width: 15,
                  height: 15,
                ),
                const SizedBox(width: 5),
                Text(
                  formatBalance(bnbBalance),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 10),

                // Hiển thị số dư USDT
                Image.asset(
                  'assets/images/usdt_logo.png',
                  width: 15,
                  height: 15,
                ),
                const SizedBox(width: 5),
                Text(
                  formatBalance(usdtBalance),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 10),

                // Hiển thị số dư KTR
                Image.asset(
                  'assets/images/logo_ktr.png',
                  width: 15,
                  height: 15,
                ),
                const SizedBox(width: 5),
                Text(
                  formatBalance(ktrBalance),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          );
        } else {
          // Trường hợp không có dữ liệu
          return const Text("No balance data");
        }
      },
    ),
  );
}




Widget buildAddWalletWidget(String mnemonic, String password, BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    height: 46,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Text(
              'Wallet list ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              '190/200',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Row(
          children: [
            TextButton(
              onPressed: () {
                // Hiển thị popup yêu cầu nhập password để backup
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    TextEditingController passwordController = TextEditingController();

                    return AlertDialog(
                      title: const Text("Enter Password"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Please enter your password to backup your wallets."),
                          const SizedBox(height: 10),
                          TextField(
                            controller: passwordController,
                            obscureText: true, // Ẩn mật khẩu
                            decoration: const InputDecoration(
                              labelText: "Password",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Đóng popup nếu cancel
                          },
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            // Kiểm tra mật khẩu trước khi backup
                            if (passwordController.text == password) {
                              Navigator.of(context).pop(); // Đóng popup
                              backupWallet(passwordController.text, context); // Gọi hàm backup
                            } else {
                              // Hiển thị lỗi nếu sai mật khẩu
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Incorrect password")),
                              );
                            }
                          },
                          child: const Text("Backup"),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text(
                'Backup',
                style: TextStyle(fontSize: 10),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 90,
              child: DropdownButton<String>(
                value: 'All',
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                ],
                onChanged: (value) {
                  // Thực hiện hành động khi chọn
                },
                style: const TextStyle(fontSize: 10, color: Colors.black),
                isExpanded: true,
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                // Mở popup cho Add Wallet
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0), // Viền popup bo tròn
                        side: const BorderSide(color: Colors.green, width: 2), // Viền màu xanh green
                      ),
                      title: const Text(
                        "Add Wallet",
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.create, color: Colors.green),
                            title: const Text("Create New Wallet"),
                            onTap: () async {
                              try {
                                // Gọi hàm tạo ví mới
                                final newWalletData = await addNewWalletFromMnemonic(mnemonic, password);

                                // Sau khi tạo ví thành công, cập nhật dữ liệu wallet
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WalletDisplayPage(
                                      walletData: newWalletData, // Truyền dữ liệu ví mới tạo vào
                                      mnemonic: mnemonic,
                                      password: password,
                                      mainWalletPrivateKey: newWalletData['encrypted_private_keys'][0], // Giải mã nếu cần
                                    ),
                                  ),
                                );

                                // Hiển thị SnackBar thông báo thành công
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Complete create new wallet",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } catch (e) {
                                // Hiển thị thông báo lỗi nếu tạo ví thất bại
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Failed to create wallet: $e"),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),



                          ListTile(
                            leading: const Icon(Icons.import_export, color: Colors.green),
                            title: const Text("Import Wallet via Private Key"),
                            onTap: () {
                              // Gọi hàm mở popup nhập private key
                              Navigator.of(context).pop();
                              _showImportPrivateKeyDialog(context, mnemonic, password);
                            },
                          ),
                        ],
                      ),
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
                'Add Wallet',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


// Hàm mở popup để nhập private key
void _showImportPrivateKeyDialog(BuildContext context, String mnemonic, String password) {
  TextEditingController privateKeyController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Viền popup bo tròn
          side: const BorderSide(color: Colors.green, width: 2), // Viền màu xanh green
        ),
        title: const Text(
          "Import Wallet via Private Key",
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: privateKeyController,
              decoration: const InputDecoration(
                labelText: 'Enter your private key',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
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
            onPressed: () {
              // Gọi hàm để import ví từ private key
              String privateKey = privateKeyController.text;
              if (privateKey.isNotEmpty) {
                importWalletFromPrivateKey(privateKey, password);
                Navigator.of(context).pop();
              } else {
                // Hiển thị thông báo lỗi nếu private key trống
                print('Private key is empty');
              }
            },
            child: const Text(
              'Import',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      );
    },
  );
}




Widget buildWalletListBuilder(List<Map<String, dynamic>> walletList) {
  return Expanded(
    child: ListView.builder(
      itemCount: walletList.length, // Sử dụng độ dài của danh sách ví
      itemBuilder: (context, index) {
        final wallet = walletList[index]; // Lấy ví tại vị trí index
        TransactionServiceMember memberService = TransactionServiceMember();
        // Kiểm tra giá trị null và cung cấp giá trị mặc định
        final walletName = wallet['name'] ?? 'Unknown Wallet'; // Nếu 'name' là null, sử dụng 'Unknown Wallet'
        final privateKey = wallet['privateKey'] ?? '';
        final walletAddress = wallet['address'] ?? 'No Address'; // Nếu 'address' là null, sử dụng 'No Address'
        final playedTime = wallet['playedTime'] ?? '00h 00m 00s'; // Nếu 'playedTime' là null, sử dụng '00h 00m 00s'
        final isMember = memberService
            .checkIsMember(walletAddress)
            .then((value) => value ?? false);
        print('member $walletAddress ===> $isMember');
        // Sử dụng FutureBuilder để tải số dư của ví hiện tại
        return FutureBuilder<Map<String, double>>(
          future: _loadBalances(walletAddress), // Gọi hàm _loadBalances với address của ví
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator()); // Hiển thị loading khi đang tải số dư
            } else if (snapshot.hasError) {
              return const Text('Error loading balancbnbPriceInUsdtes'); // Hiển thị lỗi nếu không tải được số dư
            } else if (snapshot.hasData) {
              final balances = snapshot.data!;
              final usdtBalance = balances['usdt'] ?? 0.0;
              final bnbBalance = balances['bnb'] ?? 0.0;
              final ktrBalance = balances['ktr'] ?? 0.0;
              String formatBalance(double value) {
                // Chuyển đổi số thành chuỗi, giữ lại tối đa 4 chữ số thập phân
                String formattedValue = value.toStringAsFixed(4);

                // Chuyển lại thành số để loại bỏ các số 0 thừa phía sau nếu có
                formattedValue = double.parse(formattedValue).toString();

                return formattedValue;
              }


              // Sử dụng FutureBuilder để lấy giá trị chuyển đổi từ BNB và KTR sang USDT
              return FutureBuilder<List<String>>(
                future: Future.wait([
                  checkPriceBNB(1), // Lấy giá trị BNB theo USDT
                  checkPriceKTR(1)  // Lấy giá trị KTR theo USDT
                ]),
                builder: (context, priceSnapshot) {
                  if (priceSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator()); // Hiển thị loading khi đang lấy giá token
                  } else if (priceSnapshot.hasError) {
                    return const Text('Error loading token prices'); // Hiển thị lỗi nếu không lấy được giá token
                  } else if (priceSnapshot.hasData) {
                    // Chuyển đổi các giá trị trả về thành số thực để tính toán
                    final bnbPriceInUsdt = double.tryParse(priceSnapshot.data![0]) ?? 0.0;
                    final ktrPriceInUsdt = double.tryParse(priceSnapshot.data![1]) ?? 0.0;
                    print('$bnbPriceInUsdt BNBUSDT');
                    print('$ktrPriceInUsdt KTRUSDT');
                    // Tính tổng giá trị USDT của các token
                    final totalInUsdt = usdtBalance + (bnbBalance * bnbPriceInUsdt) + (ktrBalance * ktrPriceInUsdt);
                    print('$totalInUsdt TotalUSDT');
                    // Hiển thị thông tin ví và tổng giá trị USDT sau khi đã tải thành công
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2), // Khoảng cách giữa các item
                      child: Card(
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Colors.green),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0), // Đặt padding cho toàn bộ nội dung
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Cột 1
                              Expanded(
                                child: SizedBox(
                                  height: 60,
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
                                          mainAxisAlignment: MainAxisAlignment.center, // Căn giữa theo chiều dọc
                                          crossAxisAlignment: CrossAxisAlignment.start, // Căn trái cho văn bản
                                          children: [
                                            Text(
                                              walletName, // Hiển thị tên ví
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    '${walletAddress.substring(0, 5)}...${walletAddress.substring(walletAddress.length - 5)}',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.blueGrey,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                IconButton(
                                                  icon: const Icon(Icons.copy, size: 10, color: Colors.green),
                                                  onPressed: () {
                                                    Clipboard.setData(ClipboardData(text: walletAddress)); // Sao chép địa chỉ ví
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          "Wallet address copied to clipboard",
                                                          style: TextStyle(color: Colors.white), // Chữ màu trắng
                                                        ),
                                                        backgroundColor: Colors.green, // Nền màu xanh lá cây
                                                        duration: Duration(seconds: 2), // Thời gian hiển thị SnackBar
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                                    // Cột 2: Kiểm tra là thành viên và hiển thị 'Played time left' hoặc 'Join Member'
                              FutureBuilder<bool>(
                                future: isMember, // Dùng Future để kiểm tra thành viên
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const CircularProgressIndicator(); // Hiển thị vòng xoay khi chờ đợi
                                  } else if (snapshot.hasError) {
                                    return const Text('Error checking membership');
                                  } else {
                                    final isMember = snapshot.data ?? false; // Kiểm tra giá trị trả về của thành viên
                                    return Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (isMember)
                                              Column(
                                                children: [
                                                  const Text(
                                                    'Played time left',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.blueGrey,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    playedTime,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.black,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  // ElevatedButton(
                                                  //     onPressed: () async {
                                                  //       try {
                                                  //         EthereumAddress accountAddress = EthereumAddress.fromHex(walletAddress); // Replace with your account address

                                                  //         // Call the addDeposit function
                                                  //         String txHash = await memberService.addDeposit(context, privateKey, accountAddress);
                                                  //         showTopRightSnackBar(context, "Success auto play", true);
                                                  //       } catch (e) {
                                                  //         showTopRightSnackBar(context, "Error auto play!", false);
                                                  //       }
                                                  //     },
                                                  //     style: ElevatedButton.styleFrom(
                                                  //       backgroundColor: Colors.green,
                                                  //       shape: RoundedRectangleBorder(
                                                  //         borderRadius: BorderRadius.circular(5),
                                                  //       ),
                                                  //     ),
                                                  //     child: const Text(
                                                  //       'Auto Play',
                                                  //       style: TextStyle(color: Colors.white, fontSize: 10),
                                                  //     ),
                                                  //   ),
                                                  ],
                                              )
                                            else
                                              ElevatedButton(
                                                onPressed: () {
                                                  // Mở popup cho Add Wallet
                                                  showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      String refCode = ''; // Variable to hold the value from the text field
                                                      bool checkIsMemberRef = false;
                                                      return AlertDialog(
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(10.0), // Viền popup bo tròn
                                                          side: const BorderSide(color: Colors.green, width: 2), // Viền màu xanh green
                                                        ),
                                                        title: const Text(
                                                          "Join member",
                                                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                                        ),
                                                        content: Column(
                                                          mainAxisSize: MainAxisSize.min, // Đảm bảo nội dung không chiếm toàn bộ chiều dài
                                                          children: [
                                                            const Text(
                                                              'Enter your reference code:',
                                                              style: TextStyle(fontSize: 14),
                                                            ),
                                                            const SizedBox(height: 10),
                                                            // TextField to input the ref code
                                                            TextField(
                                                              onChanged: (value)  async {
                                                                refCode = value; // Update the ref code on text change
                                                                checkIsMemberRef = await memberService.checkIsMember(refCode) ?? false;

                                                                if (checkIsMemberRef == false) {
                                                                  showTopRightSnackBar(context, 'Reference code is not member of kittyrun', false);
                                                                } else {
                                                                  showTopRightSnackBar(context, 'Reference code is member of kittyru ', true);
                                                                }
                                                              },
                                                              decoration: InputDecoration(
                                                                labelText: 'Ref Code', // Label for the input field
                                                                hintText: 'Enter ref code', // Placeholder text
                                                                border: OutlineInputBorder(
                                                                  borderRadius: BorderRadius.circular(5.0),
                                                                  borderSide: const BorderSide(color: Colors.green),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        actions: [
                                                          // Button to submit the form
                                                          ElevatedButton(
                                                            onPressed: () async{
                                                              try {
                                                                final txtHash = await memberService.addMember(privateKey, EthereumAddress.fromHex(walletAddress), EthereumAddress.fromHex(refCode));
                                                                showTopRightSnackBar(context, 'Join member success $txtHash', true);
                                                                Navigator.of(context).pop();
                                                              }
                                                              catch(e) {
                                                                print('error add member $e ==> $refCode'); 
                                                                showTopRightSnackBar(context, 'Join member failed $e', false);
                                                              }
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.green,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(5),
                                                              ),
                                                            ),
                                                            child: const Text(
                                                              'Join now',
                                                              style: TextStyle(color: Colors.white, fontSize: 12),
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
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Join member',
                                                  style: TextStyle(color: Colors.white, fontSize: 10),
                                                ),
                                              )
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              // const SizedBox(width: 5),
                              // Cột 3
                              Expanded(
                                child: SizedBox(
                                  height: 60,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(right: 10),
                                        child: Text(
                                          '\$${formatBalance(totalInUsdt)}', // Hiển thị tổng số dư
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Padding(
                                        padding: const EdgeInsets.only(right: 5), // Thêm khoảng cách với lề phải
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end, // Căn phải các giá trị
                                          children: [
                                            Image.asset(
                                              'assets/images/usdt_logo.png',
                                              width: 15,
                                              height: 15,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              formatBalance(usdtBalance), // Hiển thị số dư USDT
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Image.asset(
                                              'assets/images/bnb-bnb-logo.png',
                                              width: 15,
                                              height: 15,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                                formatBalance(bnbBalance), // Hiển thị số dư BNB
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Image.asset(
                                              'assets/images/logo_ktr.png',
                                              width: 15,
                                              height: 15,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              formatBalance(ktrBalance), // Hiển thị số dư KTR
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink(); // Thêm giá trị trả về mặc định
                },
              );
            }
            return const SizedBox.shrink(); // Thêm giá trị trả về mặc định
          },
        );
      },
    ),
  );
}








Widget buildPlayHistoryWidget_1() {
  return Expanded(
    flex: 3,
    child: Padding(
      padding: const EdgeInsets.only(left: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Play History',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    margin: EdgeInsets.zero,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(0),
                      color: Colors.green.withOpacity(0.1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('#', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 2),
                            SvgPicture.asset('assets/images/sort.svg'),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Wallet', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 2),
                            SvgPicture.asset('assets/images/sort.svg'),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Create at', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 2),
                            SvgPicture.asset('assets/images/sort.svg'),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Amount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 2),
                            SvgPicture.asset('assets/images/sort.svg'),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Status', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 2),
                            SvgPicture.asset('assets/images/sort.svg'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 15,
                      itemBuilder: (context, index) {
                        return const Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('0xd4938a2.....', style: TextStyle(fontSize: 10)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('12345678', style: TextStyle(fontSize: 10)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('0xd4938a2560...', style: TextStyle(fontSize: 10)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('100.25', style: TextStyle(fontSize: 10)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('0.001', style: TextStyle(fontSize: 10)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('1 days ago', style: TextStyle(fontSize: 10)),
                                  ],
                                ),
                              ],
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
        ],
      ),
    ),
  );
}
Widget buildLoginScreen({
  required TextEditingController passwordController,
  required Function loginFunction,
  required String errorMessage,
}) {
  return Row(
    children: [
      // Cột chứa ảnh
      Expanded(
        flex: 1,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/login_background.PNG'), // Đường dẫn tới ảnh
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      // Cột chứa form login
      Expanded(
        flex: 1,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: FractionallySizedBox(
            widthFactor: 0.5, // Form login sẽ chiếm 1/2 chiều rộng của cột chứa nó
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon login
                Center(
                  child: Image.asset(
                    'assets/images/logo_ktr.png', // Đường dẫn đến hình ảnh logo
                    width: 100,  // Chiều rộng của ảnh
                    height: 100, // Chiều cao của ảnh
                    fit: BoxFit.contain, // Đảm bảo hình ảnh chứa trong kích thước đã chỉ định
                  ),
                ),
                const SizedBox(height: 20),
                // Tiêu đề "Login"
                const Center(
                  child: Text(
                    'Login Wallet',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Text box Password
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                // TextField nhập Password
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 20),
                // Checkbox Remember Me
                Row(
                  children: [
                    Checkbox(
                      value: true,
                      onChanged: (bool? value) {},
                    ),
                    const Text('Remember Me'),
                  ],
                ),
                const SizedBox(height: 20),
                // Nút đăng nhập
                Center(
                  child: ElevatedButton(
                    onPressed: () => loginFunction(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 100,
                        vertical: 20,
                      ),
                      backgroundColor: Colors.green, // Màu nền của nút
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Hiển thị lỗi nếu có
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}


// Hàm tạo nút hành động ví (Deposit)
Widget buildWalletActionButton(String text, String walletAddress, BuildContext context) {
  return ElevatedButton(
    onPressed: () {
      // Hiển thị Popup mã QR
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0), // Viền popup bo tròn
              side: const BorderSide(color: Colors.green, width: 2), // Viền màu xanh green
            ),
            title: const Center(
              child: Text(
                "Deposit",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ), // Căn giữa tiêu đề "Deposit"
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Scan this QR code to deposit to your wallet:'),
                  const SizedBox(height: 20),
                  // Đặt kích thước cụ thể cho mã QR
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        QrImageView(
                          data: walletAddress, // Địa chỉ ví
                          version: QrVersions.auto,
                          size: 200.0,
                          embeddedImage: const AssetImage('assets/images/logo_ktr.png'), // Thêm logo vào giữa QR code
                          embeddedImageStyle: const QrEmbeddedImageStyle(
                            size: Size(40, 40), // Kích thước logo
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SelectableText(
                    walletAddress,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Đóng Popup
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
      backgroundColor: Colors.transparent,
      side: const BorderSide(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white),
    ),
  );
}


Widget buildWalletWithdrawButton(String text, String walletAddress, BuildContext context) {
  final TextEditingController toAddressController = TextEditingController(); // Controller cho To Address
  final TextEditingController amountController = TextEditingController(); // Controller cho số tiền
  String selectedToken = 'BNB';
  String selectedIcon = 'assets/images/bnb-bnb-logo.png';
  double tokenBalance = 0.0; // Biến lưu số dư của token đã chọn

  // Hàm cập nhật số dư token dựa vào loại token đã chọn
  Future<void> updateTokenBalance(String token, StateSetter setState) async {
    TokenBalanceChecker checker = TokenBalanceChecker();
    double balance = 0.0;

    switch (token) {
      case 'BNB':
        balance = await checker.getBnbBalance(walletAddress) ?? 0.0;
        break;
      case 'KTR':
        balance = await checker.getKtrBalance(walletAddress) ?? 0.0;
        break;
      case 'USDT':
        balance = await checker.getUsdtBalance(walletAddress) ?? 0.0;
        break;
    }

    // Cập nhật số dư token trong giao diện bằng setState
    setState(() {
      tokenBalance = balance;
    });
  }

  return ElevatedButton(
    onPressed: () {
      // Hiển thị Popup cho Withdraw
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0), // Viền popup bo tròn
                  side: const BorderSide(color: Colors.green, width: 2), // Viền màu xanh green
                ),
                title: const Center(
                  child: Text(
                    "Withdraw",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ), // Căn giữa tiêu đề "Withdraw"
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('From (Your Wallet Address):'),
                      const SizedBox(height: 10),
                      // Hiển thị địa chỉ ví của người dùng (From)
                      SelectableText(
                        walletAddress,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Icon token, DropdownButton và số dư token
                      Row(
                        children: [
                          Image.asset(
                            selectedIcon,
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 10),
                          DropdownButton<String>(
                            value: selectedToken,
                            items: <String>['BNB', 'KTR', 'USDT'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) async {
                              if (newValue != null) {
                                setState(() {
                                  selectedToken = newValue; // Cập nhật loại token đã chọn
                                  // Cập nhật icon tương ứng với loại token
                                  switch (newValue) {
                                    case 'BNB':
                                      selectedIcon = 'assets/images/bnb-bnb-logo.png';
                                      break;
                                    case 'KTR':
                                      selectedIcon = 'assets/images/logo_ktr.png';
                                      break;
                                    case 'USDT':
                                      selectedIcon = 'assets/images/usdt_logo.png';
                                      break;
                                  }
                                });
                                await updateTokenBalance(newValue, setState); // Cập nhật số dư token
                              }
                            },
                          ),
                          const SizedBox(width: 20),
                          // Hiển thị số dư của token
                          Text(
                            tokenBalance == 0 ? '0.00' : tokenBalance.toStringAsFixed(2), // Hiển thị số dư
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Nhập địa chỉ ví To
                      TextField(
                        controller: toAddressController,
                        decoration: InputDecoration(
                          labelText: 'Enter recipient wallet address (To)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 20),

                      // TextField để nhập số tiền cần rút
                      TextField(
                        controller: amountController,
                        decoration: InputDecoration(
                          labelText: 'Enter amount to withdraw',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Đóng Popup
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Lấy thông tin To Address, số tiền và loại token từ Dropdown và TextField
                      final String toAddress = toAddressController.text;
                      final String amount = amountController.text;

                      // Xử lý logic Withdraw khi nhấn "Confirm"
                      if (toAddress.isNotEmpty && amount.isNotEmpty) {
                        // Thực hiện hành động rút tiền từ walletAddress sang toAddress với số tiền
                        print('Withdraw $amount $selectedToken from $walletAddress to $toAddress');

                        // Sau khi xử lý, đóng Popup
                        Navigator.of(context).pop();
                      } else {
                        // Nếu thông tin chưa đầy đủ, có thể hiển thị thông báo lỗi
                        print('Vui lòng nhập đủ thông tin địa chỉ và số tiền');
                      }
                    },
                    child: const Text(
                      'Confirm',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      side: const BorderSide(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white),
    ),
  );
}



Widget buildWithdrawAllButton(String text, String mainWalletAddress, List<Map<String, String>> walletList, BuildContext context) {
  return ElevatedButton(
    onPressed: () {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          List<bool> walletChecked = List<bool>.filled(walletList.length, true);
          int selectedWalletCount = walletChecked.where((checked) => checked).length;

          String selectedToken = 'USDT';
          String selectedIcon = 'assets/images/usdt_logo.png';
          TextEditingController amountController = TextEditingController();
          bool isLoading = false; // Biến trạng thái loading

          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: const BorderSide(color: Colors.green, width: 2),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 700,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Withdraw from all wallets",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('To (Main Wallet Address):'),
                      const SizedBox(height: 10),
                      SelectableText(
                        mainWalletAddress,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Image.asset(
                            selectedIcon,
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 10),
                          DropdownButton<String>(
                            value: selectedToken,
                            items: <String>['BNB', 'USDT'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedToken = newValue;
                                  switch (newValue) {
                                    case 'BNB':
                                      selectedIcon = 'assets/images/bnb-bnb-logo.png';
                                      break;
                                    case 'USDT':
                                      selectedIcon = 'assets/images/usdt_logo.png';
                                      break;
                                  }
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: amountController,
                              decoration: const InputDecoration(
                                labelText: "Amount",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Text('Select wallets to withdraw from: '),
                          Text(
                            '$selectedWalletCount/${walletList.length}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: selectedWalletCount < walletList.length ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      walletList.length > 5
                          ? SizedBox(
                        height: 400,
                        child: ListView.builder(
                          itemCount: walletList.length,
                          itemBuilder: (context, index) {
                            return _buildWithdrawWalletItem(walletList, walletChecked, index, setState, () {
                              setState(() {
                                if (walletChecked[index]) {
                                  selectedWalletCount--;
                                } else {
                                  selectedWalletCount++;
                                }
                                walletChecked[index] = !walletChecked[index];
                              });
                            });
                          },
                        ),
                      )
                          : Column(
                        children: List<Widget>.generate(walletList.length, (int index) {
                          return _buildWithdrawWalletItem(walletList, walletChecked, index, setState, () {
                            setState(() {
                              if (walletChecked[index]) {
                                selectedWalletCount--;
                              } else {
                                selectedWalletCount++;
                              }
                              walletChecked[index] = !walletChecked[index];
                            });
                          });
                        }),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
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
                            onPressed: isLoading ? null : () async { // Disable button when loading
                              // Kiểm tra số tiền nhập vào
                              double amount = double.tryParse(amountController.text) ?? 0;
                              if (selectedWalletCount > 0 && amount > 0) {
                                setState(() {
                                  isLoading = true; // Bắt đầu loading
                                });

                                for (int i = 0; i < walletList.length; i++) {
                                  if (walletChecked[i]) {
                                    String fromAddress = walletList[i]['address'] ?? '';
                                    String privateKey = walletList[i]['privateKey'] ?? '';
                                    TransactionServiceSend action = TransactionServiceSend();

                                    if (selectedToken == 'USDT') {
                                      print('Sending $amount USDT from $fromAddress to $mainWalletAddress');
                                      await action.sendUsdtBep20(privateKey, EthereumAddress.fromHex(mainWalletAddress));
                                    } else if (selectedToken == 'BNB') {
                                      print('Sending $amount BNB from $fromAddress to $mainWalletAddress');
                                      await action.sendBNB(privateKey, EthereumAddress.fromHex(mainWalletAddress), amount);
                                    }
                                  }
                                }

                                setState(() {
                                  isLoading = false; // Dừng loading sau khi hoàn thành giao dịch
                                });

                                Navigator.of(context).pop();
                              } else {
                                // Hiển thị cảnh báo nếu số tiền hoặc số ví không hợp lệ
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invalid amount or no wallet selected.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: isLoading
                                ? const SizedBox( // Đặt CircularProgressIndicator vào SizedBox để không bị tràn
                              width: 20, // Chiều rộng cố định
                              height: 20, // Chiều cao cố định
                              child: CircularProgressIndicator(
                                strokeWidth: 2, // Độ dày đường tròn của indicator
                              ),
                            )
                                : const Text(
                              'Withdraw',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),

                        ],
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
      backgroundColor: Colors.transparent,
      side: const BorderSide(color: Colors.green),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.black),
    ),
  );
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

Widget _buildWithdrawWalletItem(List<Map<String, String>> walletList, List<bool> walletChecked, int index, StateSetter setState, VoidCallback onChanged) {
  String walletAddress = walletList[index]["address"] ?? "";
  String walletName = walletList[index]["name"] ?? "Unknown";

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 5.0),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(5),
    ),
    child: FutureBuilder<Map<String, double>>(
      future: _loadBalances(walletAddress), // Gọi hàm load balances
      builder: (BuildContext context, AsyncSnapshot<Map<String, double>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Hiển thị biểu tượng loading khi chờ tải số dư
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // Hiển thị lỗi nếu có lỗi xảy ra
          return const Text("Error loading balances");
        } else if (snapshot.hasData) {
          // Khi đã có số dư, hiển thị thông tin
          double bnbBalance = snapshot.data?["bnb"] ?? 0.0;
          double usdtBalance = snapshot.data?["usdt"] ?? 0.0;
          String formatBalance(double value) {
            // Chuyển đổi số thành chuỗi, giữ lại tối đa 4 chữ số thập phân
            String formattedValue = value.toStringAsFixed(4);
            // Chuyển lại thành số để loại bỏ các số 0 thừa phía sau nếu có
            formattedValue = double.parse(formattedValue).toString();

            return formattedValue;
          }


          return CheckboxListTile(
            value: walletChecked[index], // Trạng thái checkbox của ví tại vị trí index
            onChanged: (bool? value) {
              // Cập nhật trạng thái checked/uncheck khi checkbox được thay đổi
              onChanged();
            },
            title: Row(
              children: [
                // Hiển thị tên ví
                Text(
                  walletName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 5),

                // Hiển thị địa chỉ ví
                Expanded(
                  child: Text(
                    walletAddress,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: 5),

                // Hiển thị logo và số dư BNB với 4 số thập phân
                Image.asset(
                  'assets/images/bnb-bnb-logo.png',
                  width: 15,
                  height: 15,
                ),
                const SizedBox(width: 5),
                Text(
                  formatBalance(bnbBalance), // Hiển thị 4 số thập phân cho BNB
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(width: 10),

                // Hiển thị logo và số dư USDT với 4 số thập phân
                Image.asset(
                  'assets/images/usdt_logo.png',
                  width: 15,
                  height: 15,
                ),
                const SizedBox(width: 5),
                Text(
                  formatBalance(usdtBalance), // Hiển thị 4 số thập phân cho USDT
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          );
        } else {
          // Trường hợp không có dữ liệu
          return const Text("No balance data");
        }
      },
    ),
  );
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
    _startCountdown();
  }

  void _startCountdown() async {
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
          const Text("Sending tokens..."),
          const SizedBox(height: 10),
          Text("Remaining time: $currentWaitTime seconds"),
          const SizedBox(height: 20),
          const CircularProgressIndicator(),
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

