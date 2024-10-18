import 'package:cryptowallet/wallet_choice_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'wallet_selector_screen.dart'; // Ensure correct import for navigation

class TermsScreen extends StatefulWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  _TermsScreenState createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _isChecked = false;

  Future<void> _acceptTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acceptedTerms', true); // Lưu trạng thái đồng ý điều khoản
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms of Use"),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  "KittyRun Wallet - Terms and Conditions\n\n"
                      "1. **Decentralized Nature**: KittyRun Wallet is a non-custodial wallet. This means that you, the user, are fully responsible for managing your private keys and recovery phrases. We do not store, control, or have access to your private keys or funds.\n\n"
                      "2. **Privacy**: As a decentralized wallet, KittyRun Wallet does not collect or store any personal information or transaction data. All your data is stored locally on your device and is never transmitted to our servers.\n\n"
                      "3. **Self-Custody**: You are the sole owner of your assets. If you lose your private keys or recovery phrase, you will not be able to access your funds. It is your responsibility to securely store and back up your recovery phrase and private keys.\n\n"
                      "4. **Transaction Responsibility**: All transactions initiated through KittyRun Wallet are irreversible and cannot be undone. You are fully responsible for verifying the details of your transactions before confirming them.\n\n"
                      "5. **Security**: KittyRun Wallet employs industry-standard encryption to protect your data on your device. However, the security of your wallet also depends on the security of your device. You are responsible for safeguarding your device against unauthorized access, malware, and other security threats.\n\n"
                      "6. **Updates**: We may release updates to improve security, fix bugs, or add new features. It is recommended that you keep the app updated to the latest version to ensure optimal performance and security.\n\n"
                      "7. **No Liability**: KittyRun Wallet and its developers shall not be liable for any loss, damage, or expense arising from the use or inability to use the wallet, including but not limited to the loss of funds, data breaches, or unauthorized access to your device.\n\n"
                      "8. **Acceptance of Terms**: By using KittyRun Wallet, you acknowledge that you have read, understood, and agreed to these terms. If you do not agree to any of these terms, you should discontinue the use of the wallet immediately.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _isChecked,
                  onChanged: (bool? value) {
                    setState(() {
                      _isChecked = value ?? false;
                    });
                  },
                ),
                const Text(
                  "I agree to the terms of use",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: _isChecked
                    ? () async {
                  await _acceptTerms(); // Đợi quá trình lưu trữ hoàn tất

                  // Điều hướng tới màn hình lựa chọn Create hoặc Import
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WalletChoiceScreen(),
                      ),
                    );
                  }
                }
                    : null,
                child: const Text("Accept"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
