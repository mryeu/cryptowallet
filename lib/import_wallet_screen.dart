import 'package:cryptowallet/pinScreen.dart';
import 'package:flutter/material.dart';

class ImportMnemonicScreen extends StatefulWidget {
  const ImportMnemonicScreen({Key? key}) : super(key: key);

  @override
  _ImportMnemonicScreenState createState() => _ImportMnemonicScreenState();
}

class _ImportMnemonicScreenState extends State<ImportMnemonicScreen> {
  TextEditingController mnemonicController = TextEditingController();
  String errorMessage = "";

  // Hàm kiểm tra tính hợp lệ của cụm từ mnemonic
  bool _isValidMnemonic(String mnemonic) {
    // Tách cụm từ mnemonic thành danh sách từ
    List<String> words = mnemonic.trim().split(' ');

    // Kiểm tra nếu có đúng 12 từ
    if (words.length == 12) {
      // Bạn có thể thêm các logic kiểm tra cụ thể hơn ở đây (nếu cần thiết)
      return true;
    } else {
      return false;
    }
  }

  // Hàm khi nhấn tiếp tục
  void _onContinue() {
    String mnemonic = mnemonicController.text;

    // Kiểm tra tính hợp lệ của cụm từ mnemonic
    if (_isValidMnemonic(mnemonic)) {
      setState(() {
        errorMessage = ""; // Xóa thông báo lỗi nếu cụm từ hợp lệ
      });
      // Điều hướng tới màn hình nhập PIN sau khi nhập Mnemonic hợp lệ
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SetupPinScreen(mnemonic: mnemonic),),
      );
    } else {
      setState(() {
        errorMessage = "Invalid mnemonic phrase. Please enter exactly 12 words.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Import Mnemonic"),
        centerTitle: true,
      ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Enter your 12-word mnemonic phrase:",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: mnemonicController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Mnemonic Phrase',
                errorText: errorMessage.isNotEmpty ? errorMessage : null,
              ),
              maxLines: 3,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onContinue,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Continue", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
