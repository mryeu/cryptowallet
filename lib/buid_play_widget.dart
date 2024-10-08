
import 'dart:ffi';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:web3dart/credentials.dart';
import 'add_member.dart';
import 'check_balance.dart';
import 'dart:async';

import 'modules/member/join_memeber_widget.dart';
import 'modules/member/list_member_widget.dart';



// Hàm để tạo cột 1
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
                walletName,  // Remove const and use dynamic walletName
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${address.substring(0, 5)}...${address.substring(address.length - 5)}',  // Use dynamic address
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
      future: _loadBalances(walletAddress), // Your future function fetching balances
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading state while waiting for data
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // Show error state if there's an issue fetching data
          return const Text(
            'Error loading balance',
            style: TextStyle(color: Colors.red),
          );
        } else if (snapshot.hasData) {
          // Extract balance and amount
          final balanceData = snapshot.data;
          double usdBalance = balanceData?['usdt'] ?? '0.00';  // Assuming the data structure has 'usdBalance'
          double usdtAmount = balanceData?['usdt'] ?? '0.00';  // Assuming the data structure has 'usdtAmount'
          final bnbBalance = balanceData?['bnb'] ?? 0.0;
          final ktrBalance = balanceData?['ktr'] ?? 0.0;
          String formatBalance(double value) {
            // Chuyển đổi số thành chuỗi, bỏ đi những số 0 không cần thiết
            String formattedValue = value.toStringAsFixed(4);
            formattedValue = double.parse(formattedValue).toString();
            return formattedValue;
          }
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
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Image.asset(
                      'assets/images/usdt_logo.png',
                      width: 15,
                      height: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      formatBalance(usdtAmount), // Số dư USDT đã định dạng
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
          );
        } else {
          // Show empty state if no data is available
          return const Text('No balance available');
        }
      },
    ),
  );
}

// Hàm để tạo cột 3
Widget buildColumn3(BuildContext context, String name, String privateKey, String walletAddress, bool isMember) {
  TransactionServiceMember memberService = TransactionServiceMember();
  return Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () async {
              // Hành động khi nhấn nút
              try {
                  EthereumAddress accountAddress = EthereumAddress.fromHex(walletAddress); // Replace with your account address

                  // Call the addDeposit function
                  String txHash = await memberService.addDeposit(context, privateKey, accountAddress);
                  showTopRightSnackBar(context, "Success auto play $txHash", true);
                } catch (e) {
                  showTopRightSnackBar(context, "Error auto play $e", false);
                }
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
        ),
      ],
    ),
  );
}

Widget buildPlayedWalletList(BuildContext context, List<Map<String, dynamic>> walletList) {
  String selectedFilter = 'All'; // Biến lưu trữ giá trị dropdown được chọn
  //handle walletList
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    height: 80,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Phần bên trái: Text
        Row(
          children: [
            const Text(
              'Played Wallet list ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              '${walletList.length}/200', // Hiển thị số ví đã dùng so với tổng số
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
        // Phần bên phải: Các nút và dropdown
        Row(
          children: [
            const SizedBox(width: 10),
            // DropdownButton trong Container để kiểm soát chiều rộng
            SizedBox(
              width: 90, // Đặt chiều rộng của DropdownButton
              child: DropdownButton<String>(
                value: selectedFilter,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                ],
                onChanged: (String? value) {
                  if (value != null) {
                    selectedFilter = value;
                    // Thêm logic xử lý khi người dùng chọn một trạng thái
                    print('Selected filter: $selectedFilter');
                  }
                },
                style: const TextStyle(fontSize: 10, color: Colors.black),
                isExpanded: true, // Đảm bảo dropdown mở rộng đầy đủ bên trong container
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                // Thực hiện hành động khi nhấn vào nút Play
                print('Play action triggered');
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
                  builder: (BuildContext context) {
                    TextEditingController sponsorWalletController = TextEditingController(); // Controller cho ô nhập sponsor
                    List<bool> walletChecked = List<bool>.filled(walletList.length, false); // Danh sách kiểm tra trạng thái checkbox
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8, // Mở rộng chiều rộng thành 80% của màn hình
                            height: 700, // Đặt chiều cao bằng 700
                            child: Column(
                              children: [
                                // Tiêu đề
                                const Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Text(
                                    'Join Member Play Now',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Text "Sponsor"
                                const Padding(
                                  padding: EdgeInsets.only(left: 20.0),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Sponsor',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Ô nhập sponsor wallet
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                  child: TextField(
                                    controller: sponsorWalletController,
                                    decoration: const InputDecoration(
                                      labelText: 'Enter Sponsor Wallet',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Tiêu đề danh sách ví
                                const Padding(
                                  padding: EdgeInsets.only(left: 20.0),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Select Wallets:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                ),
                                const Divider(),
                                // Header cho danh sách ví
                                const Row(
                                  children: [
                                    Expanded(flex: 1, child: Text('  Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Expanded(flex: 4, child: Text('Address', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Expanded(flex: 2, child: Text('BNB Balance', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Expanded(flex: 2, child: Text('USDT Balance', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Expanded(flex: 1, child: Text('Select', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                ),
                                const Divider(),
                                // Danh sách ví hiển thị từ `walletList`
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: walletList.length,
                                    itemBuilder: (context, index) {
                                      TransactionServiceMember memberService = TransactionServiceMember();
                                      String walletName = walletList[index]["name"] ?? "Unknown Wallet";
                                      String walletAddress = walletList[index]["address"] ?? "";
                                      String privateKey = walletList[index]["privateKey"] ?? "";
                                      // Sử dụng FutureBuilder để tải số dư BNB và USDT
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
                                                      value: walletChecked[index], // Trạng thái checkbox
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
                                const Spacer(),
                                // Nút Cancel và Join Now
                                Padding(
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
                                          String sponsorWallet = sponsorWalletController.text;
                                          // Kiểm tra sponsorWallet không null và có định dạng hợp lệ
                                          if (sponsorWallet.isEmpty) {
                                            // Hiển thị cảnh báo nếu sponsor wallet trống
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Sponsor wallet cannot be empty.'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          } else if (!RegExp(r"^0x[a-fA-F0-9]{40}$").hasMatch(sponsorWallet)) {
                                            // Kiểm tra định dạng ví blockchain hợp lệ
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Invalid sponsor wallet address.'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          } else {
                                            // Nếu sponsor wallet hợp lệ, thực hiện hành động
                                            List<String> selectedWallets = [];
                                            TransactionServiceMember memberService = TransactionServiceMember();
                                            for (int i = 0; i < walletChecked.length; i++) {
                                              if (walletChecked[i]) {
                                                String walletAddress = walletList[i]["address"] ?? "";
                                                String privateKey = walletList[i]["privateKey"] ?? "";

                                                // Kiểm tra privateKey không rỗng
                                                if (privateKey.isEmpty) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Private key is missing for wallet $walletAddress'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                  continue;
                                                }

                                                try {
                                                  // Gọi hàm addMember
                                                  String txHash = await memberService.addMember(
                                                    privateKey,
                                                    EthereumAddress.fromHex(walletAddress),
                                                    EthereumAddress.fromHex(sponsorWallet),
                                                  );
                                                  print('Transaction hash for wallet $walletAddress: $txHash');
                                                } catch (e) {
                                                  print('Error adding member for wallet $walletAddress: $e');
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Error adding member for wallet $walletAddress'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            }

                                            // Xử lý danh sách ví đã chọn và sponsor wallet
                                            print('Sponsor Wallet: $sponsorWallet');
                                            print('Selected Wallets: $selectedWallets');

                                            Navigator.of(context).pop(); // Đóng popup
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
            )
          ],
        ),
      ],
    ),
  );
}


Widget buildPlayMainWalletWidget(BuildContext context,List<Map<String, String>> walletList) {
  return Expanded(
    flex: 2,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 120,
          width: 505,
          padding: const EdgeInsets.all(3),
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
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Deposit',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 60,
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
                          const Expanded(
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 30),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Wallet Main Bot',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
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
                                      '0xd4938a25...',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blueGrey,
                                      ),
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
                    child: SizedBox(
                      height: 60,
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 30),
                            // Add any widget if needed here
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(right: 10, top: 20),
                            // Add any widget if needed here
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Text(
                                '1234.00',
                                style: TextStyle(
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
                              const Text(
                                '1234.00',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        //
        ///buildPlayedWalletList(context, walletList),
        JoinMemeberWidget(walletList: walletList),
        const SizedBox(height: 10),
        ListMemberWidget(walletList: walletList)
      ],
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