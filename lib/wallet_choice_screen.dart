import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptowallet/services/localization_service.dart'; // Import dịch vụ localization
import 'import_wallet_screen.dart';
import 'pinScreen.dart';

class WalletChoiceScreen extends StatefulWidget {
  const WalletChoiceScreen({Key? key}) : super(key: key);

  @override
  _WalletChoiceScreenState createState() => _WalletChoiceScreenState();
}

class _WalletChoiceScreenState extends State<WalletChoiceScreen> {
  String _title = '';
  String _chooseOptionText = '';
  String _createNewWalletText = '';
  String _importMnemonicText = '';

  @override
  void initState() {
    super.initState();
    _loadLocalization();
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
      _title = LocalizationService.translate('wallet_choice_screen.title');
      _chooseOptionText = LocalizationService.translate('wallet_choice_screen.choose_option');
      _createNewWalletText = LocalizationService.translate('wallet_choice_screen.create_new_wallet');
      _importMnemonicText = LocalizationService.translate('wallet_choice_screen.import_mnemonic');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title), // Sử dụng tiêu đề đã dịch
        centerTitle: true,
        backgroundColor: const Color(0xFF004D40), // Đặt màu nền AppBar
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
            Text(
              _chooseOptionText, // Sử dụng văn bản đã dịch
              style: const TextStyle(
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SetupPinScreen()),
                );
              },
              child: Text(
                _createNewWalletText,
                style: const TextStyle(fontSize: 18),
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
              child: Text(
                _importMnemonicText, // Sử dụng văn bản đã dịch
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const Spacer(), // Tạo khoảng trống ở dưới cùng
          ],
        ),
      ),
    );
  }
}
