import 'package:flutter/material.dart';
import 'wallet_create.dart';
import 'login_wallet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptowallet/services/localization_service.dart';

class VerifyWalletPage extends StatefulWidget {
  final String encryptedMnemonic;
  final String password;
  final String generatedMnemonic;

  const VerifyWalletPage({
    Key? key,
    required this.encryptedMnemonic,
    required this.password,
    required this.generatedMnemonic,
  }) : super(key: key);

  @override
  _VerifyWalletPageState createState() => _VerifyWalletPageState();
}

class _VerifyWalletPageState extends State<VerifyWalletPage> {
  List<TextEditingController> verificationControllers =
  List.generate(4, (_) => TextEditingController());
  String errorMessage = '';
  String _verifyWalletTitle = '';
  String _generatedMnemonicText = '';
  String _confirmBackupText = '';
  String _enterWordsText = '';
  String _cancelText = '';
  String _verifyText = '';

  @override
  void initState() {
    super.initState();
    _loadLocalization(); // Load localization
  }

  Future<void> _loadLocalization() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String selectedLanguage = prefs.getString('selectedLanguage') ?? 'en';
    String selectedFlag = prefs.getString('selectedCountry') ?? 'us';
    print("Selected Language: $selectedLanguage, Selected Flag: $selectedFlag");

    List<String> validLanguages = ['en', 'zh', 'id', 'hi', 'vi', 'ko', 'ru', 'th', 'fr', 'pt', 'tr', 'ar'];
    List<String> validCountries = ['us', 'cn', 'id', 'in', 'vn', 'kr', 'ru', 'th', 'fr', 'pt', 'tr', 'sa'];

    if (!validLanguages.contains(selectedLanguage)) {
      selectedLanguage = 'en';
    }
    if (!validCountries.contains(selectedFlag)) {
      selectedFlag = 'us';
    }

    try {
      await LocalizationService.load(selectedLanguage);
    } catch (e) {
      print("Error loading language file: $e");
      await LocalizationService.load('en');

      selectedLanguage = 'en';
      selectedFlag = 'us';
    }
    setState(() {
      _verifyWalletTitle = LocalizationService.translate('verify_wallet_screen.title');
      _generatedMnemonicText = LocalizationService.translate('verify_wallet_screen.generated_mnemonic');
      _confirmBackupText = LocalizationService.translate('verify_wallet_screen.confirm_backup');
      _enterWordsText = LocalizationService.translate('verify_wallet_screen.enter_words');
      _cancelText = LocalizationService.translate('verify_wallet_screen.cancel');
      _verifyText = LocalizationService.translate('verify_wallet_screen.verify');
    });
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_enterWordsText),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: verificationControllers
                .map((controller) => TextField(
              controller: controller,
              decoration: InputDecoration(labelText: 'Word'),
            ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close popup
              },
              child: Text(_cancelText),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close popup
                verifyMnemonic(); // Verify mnemonic after input
              },
              child: Text(_verifyText),
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
        title: Text(_verifyWalletTitle),
      ),
      body: Row(
        children: [
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
          Expanded(
            flex: 2,
            child: Center(
              child: SizedBox(
                width: 600,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_generatedMnemonicText),
                    const SizedBox(height: 20),
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
                      onPressed: _showBackupDialog,
                      child: Text(_confirmBackupText),
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

