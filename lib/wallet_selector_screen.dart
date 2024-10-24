import 'package:cryptowallet/pinScreen.dart';
import 'package:cryptowallet/services/session_manager.dart';
import 'package:cryptowallet/terms_screen.dart';
import 'package:cryptowallet/wallet_create.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptowallet/services/localization_service.dart'; // Giả sử có dịch vụ này để xử lý đa ngôn ngữ
import 'main.dart';

class WalletSelectorScreen extends StatefulWidget {
  const WalletSelectorScreen({Key? key}) : super(key: key);

  @override
  _WalletSelectorScreenState createState() => _WalletSelectorScreenState();
}

class _WalletSelectorScreenState extends State<WalletSelectorScreen> {
  // Các chuỗi văn bản được dịch
  String _createWalletText = '';
  String _importMnemonicText = '';
  String _removeWalletText = '';
  String _welcomeToText = '';
  String _appTitleText = '';
  String _selectionText = '';

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
      _createWalletText = LocalizationService.translate('wallet_selector_screen.create_wallet');
      _importMnemonicText = LocalizationService.translate('wallet_selector_screen.import_mnemonic');
      _removeWalletText = LocalizationService.translate('wallet_selector_screen.remove_wallet');
      _welcomeToText = LocalizationService.translate('wallet_selector_screen.welcome_to');
      _appTitleText = LocalizationService.translate('wallet_selector_screen.app_title');
      _selectionText = LocalizationService.translate('wallet_selector_screen.selection_text');
    });
  }

  Future<void> _removeWallet(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Xóa tất cả dữ liệu lưu trữ trong SharedPreferences
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SetupPinScreen()),
      );
      print("Đã xóa ví thành công");
    } catch (e) {
      print("Lỗi khi xóa ví: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (SessionManager.userPin == null) {
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
              Color(0xFF66BB6A), // Xanh nhạt
              Color(0xFF004D40), // Xanh đậm
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
                'assets/images/logo_ktr.png',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 20),
              Text(
                _welcomeToText,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              Text(
                _appTitleText,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                _selectionText,
                style: const TextStyle(
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
                      MaterialPageRoute(builder: (context) => const SetupPinScreen()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TermsScreen()),
                    );
                  }
                },
                child: Text(_createWalletText),
              ),
              const SizedBox(height: 20),
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
                child: Text(_importMnemonicText),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  await _removeWallet(context);
                },
                child: Text(_removeWalletText),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> checkIfAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('acceptedTerms') ?? false;
  }
}

class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({Key? key}) : super(key: key);

  @override
  _CreateWalletScreenState createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  String _createWalletText = '';
  String _importMnemonicText = '';
  String _welcomeToText = '';
  String _appTitleText = '';
  String _selectionText = '';

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
      _createWalletText = LocalizationService.translate('wallet_selector_screen.create_wallet');
      _importMnemonicText = LocalizationService.translate('wallet_selector_screen.import_mnemonic');
      _welcomeToText = LocalizationService.translate('wallet_selector_screen.welcome_to');
      _appTitleText = LocalizationService.translate('wallet_selector_screen.app_title');
      _selectionText = LocalizationService.translate('wallet_selector_screen.selection_text');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF66BB6A),
              Color(0xFF004D40),
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
                'assets/images/logo_ktr.png',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 20),
              Text(
                _welcomeToText,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              Text(
                _appTitleText,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                _selectionText,
                style: const TextStyle(
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SetupPinScreen()),
                  );
                },
                child: Text(_createWalletText),
              ),
              const SizedBox(height: 20),
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
                child: Text(_importMnemonicText),
              ),
              const SizedBox(height: 50), // Thêm khoảng cách
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
