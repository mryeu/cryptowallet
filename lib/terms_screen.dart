import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptowallet/wallet_choice_screen.dart';
import 'package:cryptowallet/services/localization_service.dart'; // Import localization service

class TermsScreen extends StatefulWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  _TermsScreenState createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _isChecked = false;
  String _termsTitle = '';
  String _termsContent = '';
  String _agreeText = '';
  String _acceptButtonText = '';

  @override
  void initState() {
    super.initState();
    _loadLocalization(); // Load ngôn ngữ khi initState
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
      _termsTitle = LocalizationService.translate('terms_screen.title');
      _termsContent = LocalizationService.translate('terms_screen.terms_content');
      _agreeText = LocalizationService.translate('terms_screen.agree_to_terms');
      _acceptButtonText = LocalizationService.translate('terms_screen.accept_button');
    });
  }



  Future<void> _acceptTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acceptedTerms', true); // Lưu trạng thái đồng ý điều khoản
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_termsTitle), // Sử dụng tiêu đề đã dịch
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
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _termsContent, // Sử dụng nội dung đã dịch
                  style: const TextStyle(
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
                Text(
                  _agreeText, // Sử dụng văn bản "I agree" đã dịch
                  style: const TextStyle(color: Colors.white),
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
                child: Text(_acceptButtonText), // Sử dụng văn bản "Accept" đã dịch
              ),
            ),
          ],
        ),
      ),
    );
  }
}
