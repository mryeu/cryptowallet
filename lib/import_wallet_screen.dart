import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptowallet/services/localization_service.dart';
import 'package:cryptowallet/pinScreen.dart';

class ImportMnemonicScreen extends StatefulWidget {
  const ImportMnemonicScreen({Key? key}) : super(key: key);

  @override
  _ImportMnemonicScreenState createState() => _ImportMnemonicScreenState();
}

class _ImportMnemonicScreenState extends State<ImportMnemonicScreen> {
  TextEditingController mnemonicController = TextEditingController();
  String errorMessage = "";
  String _pageTitle = "";
  String _enterMnemonic = "";
  String _mnemonicError = "";
  String _continueButton = "";

  @override
  void initState() {
    super.initState();
    _loadLocalization(); // Load ngôn ngữ khi khởi tạo
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
      _pageTitle = LocalizationService.translate('import_mnemonic_screen.title');
      _enterMnemonic = LocalizationService.translate('import_mnemonic_screen.enter_mnemonic');
      _mnemonicError = LocalizationService.translate('import_mnemonic_screen.mnemonic_error');
      _continueButton = LocalizationService.translate('import_mnemonic_screen.continue_button');
    });
  }

  // Hàm kiểm tra tính hợp lệ của cụm từ mnemonic
  bool _isValidMnemonic(String mnemonic) {
    List<String> words = mnemonic.trim().split(' ');
    return words.length == 12; // Kiểm tra nếu có đúng 12 từ
  }

  // Hàm khi nhấn tiếp tục
  void _onContinue() {
    String mnemonic = mnemonicController.text;
    if (_isValidMnemonic(mnemonic)) {
      setState(() {
        errorMessage = "";
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SetupPinScreen(mnemonic: mnemonic),
        ),
      );
    } else {
      setState(() {
        errorMessage = _mnemonicError; // Hiển thị thông báo lỗi đã dịch
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle), // Sử dụng tiêu đề đã dịch
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
            Text(
              _enterMnemonic, // Sử dụng chuỗi đã dịch
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: mnemonicController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: _enterMnemonic, // Sử dụng văn bản đã dịch
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
              child: Text(_continueButton, style: const TextStyle(fontSize: 18)), // Sử dụng nút đã dịch
            ),
          ],
        ),
      ),
    );
  }
}
