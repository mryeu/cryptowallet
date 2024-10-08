import 'package:flutter/material.dart';
import 'wallet_create.dart';
import 'login_wallet.dart';

class VerifyWalletPage extends StatefulWidget {
  final String encryptedMnemonic;
  final String password;
  final String generatedMnemonic;

  const VerifyWalletPage({
    super.key,
    required this.encryptedMnemonic,
    required this.password,
    required this.generatedMnemonic,
  });

  @override
  _VerifyWalletPageState createState() => _VerifyWalletPageState();
}

class _VerifyWalletPageState extends State<VerifyWalletPage> {
  List<TextEditingController> verificationControllers =
  List.generate(4, (_) => TextEditingController());
  String errorMessage = '';

  // Function to show popup for entering the backup words
  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter 4 words from your seed phrase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: verificationControllers
                .map((controller) => TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Word'),
            ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close popup
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close popup
                verifyMnemonic(); // Verify mnemonic after input
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  Future<void> verifyMnemonic() async {
    try {
      final mnemonic = decryptDataAES(widget.encryptedMnemonic, widget.password);
      final mnemonicWords = mnemonic.split(' ');

      final inputWords =
      verificationControllers.map((controller) => controller.text).toList();
      if (inputWords.every((word) => mnemonicWords.contains(word))) {
        setState(() {
          errorMessage = "Verification successful!";
        });
        // Navigate to login page after successful verification
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        setState(() {
          errorMessage = "Verification failed. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Incorrect password or other error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> mnemonicWords = widget.generatedMnemonic.split(' ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Wallet'),
      ),
      body: Row(
        children: [
          // Left column: Background with gradient
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[700]!, Colors.green[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Replace with your actual KTR logo image
                    Image.asset(
                      'assets/images/logo_ktr.png',
                      height: 200,
                      width: 200,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'KittyRun Wallet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right column: Form and verification
          Expanded(
            flex: 2,
            child: Center(
              child: SizedBox(
                width: 600,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Your generated mnemonic: Please save it securely and ensure it is not shared with others.'),
                    const SizedBox(height: 20),
                    // Display mnemonic words in a grid
                    Column(
                      children: List.generate(4, (rowIndex) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(3, (colIndex) {
                            int index = rowIndex * 3 + colIndex;
                            return Container(
                              width: 180,
                              height: 100,
                              margin: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}. ${mnemonicWords[index]}',
                                  style: const TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _showBackupDialog, // Button to open backup popup
                      child: const Text('Confirm backup wallet'),
                    ),
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
      ),
    );
  }
}
