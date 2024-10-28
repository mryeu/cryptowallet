import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptowallet/wallet_choice_screen.dart';
import 'package:cryptowallet/services/localization_service.dart';
import 'langguage.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  _TermsScreenState createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _isChecked = false;
  bool _isLanguageSelected = false;
  String _termsTitle = '';
  String _termsContent = '';
  String _agreeText = '';
  String _acceptButtonText = '';

  @override
  void initState() {
    super.initState();
    // Hiển thị popup chọn ngôn ngữ đầu tiên khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLanguageSelectionDialog();
    });
  }

  // Hàm để hiển thị popup chọn ngôn ngữ
  Future<void> _showLanguageSelectionDialog() async {
    await LanguageSelectionDialog.show(context, _onLanguageSelected);
  }

  // Hàm xử lý sau khi người dùng chọn ngôn ngữ
  void _onLanguageSelected(String languageCode, String flagCode) async {
    print('Selected Language Code: $languageCode, Flag Code: $flagCode');

    // Lưu mã ngôn ngữ và quốc gia vào SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', languageCode);
    await prefs.setString('selectedCountry', flagCode);

    // Cập nhật trạng thái đã chọn ngôn ngữ và tải thông tin ngôn ngữ
    setState(() {
      _isLanguageSelected = true;
    });

    _loadLocalization(); // Tải ngôn ngữ sau khi chọn
  }

  // Hàm để tải thông tin ngôn ngữ từ localization service
  Future<void> _loadLocalization() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String selectedLanguage = prefs.getString('selectedLanguage') ?? 'en';
    String selectedFlag = prefs.getString('selectedCountry') ?? 'us';
    print("Selected Language: $selectedLanguage, Selected Flag: $selectedFlag");

    try {
      await LocalizationService.load(selectedLanguage);
    } catch (e) {
      print("Error loading language file: $e");
      await LocalizationService.load('en');
    }

    setState(() {
      _termsTitle = LocalizationService.translate('terms_screen.title');
      _termsContent = LocalizationService.translate('terms_screen.terms_content');
      _agreeText = LocalizationService.translate('terms_screen.agree_to_terms');
      _acceptButtonText = LocalizationService.translate('terms_screen.accept_button');
    });
  }

  // Hàm lưu trạng thái đã đồng ý điều khoản
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
      body: _isLanguageSelected // Kiểm tra nếu đã chọn ngôn ngữ thì hiển thị nội dung
          ? Container(
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
      )
          : const Center(
        child: CircularProgressIndicator(), // Hiển thị vòng tròn tải khi chưa chọn ngôn ngữ
      ),
    );
  }
}
