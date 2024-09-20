import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  String walletAddress = '0xA12bC34d5678Ef90123456789AbCdEF123456789'; // Địa chỉ ví mẫu
  double usdtBalance = 5000.00; // Số dư USDT
  double bnbBalance = 1.2345;   // Số dư BNB
  double ktrBalance = 2500.00;  // Số dư KTR
  double totalBalance = 8751.2345; // Tổng số dư
  List<String> wallets = ['Wallet 1', 'Wallet 2', 'Wallet 3'];
  List<String> transactionHistory = ['Tx1: +200 USDT', 'Tx2: -50 BNB', 'Tx3: +300 KTR'];

  // Hàm sao chép địa chỉ ví
  void copyToClipboard(String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address copied to clipboard')),
    );
  }

  // Hiển thị popup chi tiết ví full screen
  void showWalletDetails(String walletName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(0), // Xóa padding để hiển thị full màn hình
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.green,
              title: Text('$walletName Details'),
              automaticallyImplyLeading: false, // Ẩn nút back mặc định
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop(); // Đóng popup
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
                    // Khối thông tin Main Wallet với viền
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green[700]!,
                              Colors.green[300]!,
                            ],
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
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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

                              // Nút Send
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange, // Màu cam cho nút Send
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  // Xử lý gửi tiền
                                },
                                child: const Center(
                                  child: Text('Send'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Transaction History khối với viền
                    const Text(
                      'Transaction History',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          height: 300, // Giới hạn chiều cao cho list giao dịch
                          child: ListView.builder(
                            itemCount: transactionHistory.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(color: Colors.green, width: 1),
                                ),
                                child: ListTile(
                                  title: Text(transactionHistory[index]),
                                ),
                              );
                            },
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

  @override
  Widget build(BuildContext context) {
    // Rút gọn địa chỉ ví
    String shortAddress =
        '${walletAddress.substring(0, 5)}...${walletAddress.substring(walletAddress.length - 5)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thẻ hiển thị thông tin ví chính
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
                      'Main Wallet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Address: $shortAddress'),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () => copyToClipboard(walletAddress),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Balance:', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('USDT: $usdtBalance'),
                            Text('BNB: $bnbBalance'),
                            Text('KTR: $ktrBalance'),
                          ],
                        ),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                // Xử lý gửi tiền
                              },
                              child: const Text('Send'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                // Xử lý nạp tiền
                              },
                              child: const Text('Deposit'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Hàng ngang hiển thị danh sách ví
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Wallet List: ${wallets.length}', style: const TextStyle(fontSize: 18)),
                DropdownButton<String>(
                  value: wallets[0],
                  onChanged: (String? newValue) {
                    setState(() {
                      // Cập nhật ví được chọn
                    });
                  },
                  items: wallets.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Thêm ví mới
                  },
                  child: const Text('Add Wallet'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Danh sách các ví
            Expanded(
              child: ListView.builder(
                itemCount: wallets.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.green, width: 1),
                    ),
                    child: ListTile(
                      title: Text(wallets[index]),
                      subtitle: const Text('Balance: 100 USDT'),
                      trailing: IconButton(
                        icon: const Icon(Icons.info),
                        onPressed: () {
                          // Hiển thị popup khi nhấn vào ví
                          showWalletDetails(wallets[index]);
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
}
