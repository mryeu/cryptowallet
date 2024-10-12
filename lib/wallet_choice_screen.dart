import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'import_wallet_screen.dart';
import 'pinScreen.dart';

class WalletChoiceScreen extends StatelessWidget {
  const WalletChoiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wallet Setup"),
        centerTitle: true,
        backgroundColor: const Color(0xFF004D40), // Đặt màu phù hợp với background
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF66BB6A), // Light green
              Color(0xFF004D40), // Dark green
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(), // Tạo khoảng trống trên cùng
            const Text(
              "Choose an option to set up your wallet:",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.white, // Nền trắng để nổi bật hơn
                foregroundColor: const Color(0xFF004D40), // Màu chữ
              ),
              onPressed: () {
                // Điều hướng tới màn hình nhập PIN để tạo ví mới
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SetupPinScreen()),
                );
              },
              child: const Text(
                'Create New Wallet',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF004D40),
              ),
              onPressed: () {
                // Điều hướng tới màn hình nhập Mnemonic
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ImportMnemonicScreen()),
                );
              },
              child: const Text(
                'Import Mnemonic',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const Spacer(), // Tạo khoảng trống ở dưới cùng
          ],
        ),
      ),
    );
  }
}
