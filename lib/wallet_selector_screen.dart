import 'package:cryptowallet/pinScreen.dart';
import 'package:cryptowallet/services/session_manager.dart';
import 'package:cryptowallet/terms_screen.dart';
import 'package:cryptowallet/wallet_create.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class WalletSelectorScreen extends StatelessWidget {
  const WalletSelectorScreen({Key? key}) : super(key: key);

  Future<bool> checkIfAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('acceptedTerms') ?? false;
  }

  Future<void> _removeWallet(BuildContext context) async {
    try {
      // Xóa dữ liệu ví từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Xóa tất cả dữ liệu lưu trữ trong SharedPreferences

      // Bạn có thể thêm logic khác để xóa ví từ hệ thống lưu trữ của bạn nếu cần

      // Điều hướng người dùng quay lại màn hình chính hoặc màn hình tạo ví
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SetupPinScreen()), // Navigate back to PIN setup or initial screen
      );

      print("Đã xóa ví thành công");
    } catch (e) {
      print("Lỗi khi xóa ví: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if PIN is null
    if (SessionManager.userPin == null) {
      // If PIN is null, redirect to SetupPinScreen
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SetupPinScreen()),
        );
      });
    }

    return Scaffold(
      body: Container(
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              Image.asset(
                'assets/images/logo_ktr.png', // Replace with your logo asset path
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 20),
              // Welcome Text
              const Text(
                'Welcome to',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const Text(
                'Kittyrun Wallet',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const Text(
                'Please make a selection below to create or import mnemonic',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  bool hasAcceptedTerms = await checkIfAcceptedTerms();
                  if (hasAcceptedTerms) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SetupPinScreen()), // Navigate to the PIN setup screen
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TermsScreen()),
                    );
                  }
                },
                child: const Text(
                  'Create New Wallet',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              // "Import Mnemonic" Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ImportSeedScreen()),
                  );
                },
                child: const Text(
                  'Import Mnemonic',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  backgroundColor: Colors.red, // Màu đỏ để nhấn mạnh nút xóa
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  await _removeWallet(context);
                },
                child: const Text(
                  'Remove Wallet',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}



class CreateWalletScreen extends StatelessWidget {
  const CreateWalletScreen({Key? key}) : super(key: key);

  Future<bool> _checkIfAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('acceptedTerms') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Check if PIN is null
    if (SessionManager.userPin == null) {
      // If PIN is null, redirect to SetupPinScreen
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SetupPinScreen()),
        );
      });
    }

    return Scaffold(
      body: Container(
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              Image.asset(
                'assets/images/logo_ktr.png', // Replace with your logo asset path
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 20),
              // Welcome Text
              const Text(
                'Welcome to',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const Text(
                'Kittyrun Wallet',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const Text(
                'Please make a selection below to create or import mnemonic',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  bool hasAcceptedTerms = await _checkIfAcceptedTerms();
                  if (hasAcceptedTerms) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SetupPinScreen()), // Navigate to the PIN setup screen
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TermsScreen()),
                    );
                  }
                },
                child: const Text(
                  'Create New Wallet',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              // "Import Mnemonic" Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ImportSeedScreen()),
                  );
                },
                child: const Text(
                  'Import Mnemonic',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 50), // Adds a 50-pixel gap at the bottom
            ],
          ),
        ),
      ),
    );
  }
}



class ImportSeedScreen extends StatelessWidget {
  const ImportSeedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Import Seed Phrase"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WalletScreen()),
            );
          },
          child: const Text("Import Seed And Save Wallet"),
        ),
      ),
    );
  }
}
