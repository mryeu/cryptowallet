import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_flags/country_flags.dart';

class LanguageSelectionDialog {
  static Future<void> show(BuildContext context, Function(String, String) onLanguageSelected) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String selectedLanguage = prefs.getString('selectedLanguage') ?? 'en';  // Sử dụng 'en' mặc định
    String selectedCountry = prefs.getString('selectedCountry') ?? 'us';  // Sử dụng 'us' mặc định

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _LanguageSelectionDialog(
          selectedLanguage: selectedLanguage,
          selectedCountry: selectedCountry,
          onLanguageSelected: onLanguageSelected,
        );
      },
    );
  }
}

class _LanguageSelectionDialog extends StatefulWidget {
  final String selectedLanguage;
  final String selectedCountry;
  final Function(String, String) onLanguageSelected;

  const _LanguageSelectionDialog({
    Key? key,
    required this.selectedLanguage,
    required this.selectedCountry,
    required this.onLanguageSelected,
  }) : super(key: key);

  @override
  __LanguageSelectionDialogState createState() => __LanguageSelectionDialogState();
}

class __LanguageSelectionDialogState extends State<_LanguageSelectionDialog> {
  String selectedLanguage = 'en';  // Mặc định là English
  String selectedCountry = 'us';  // Mặc định là US

  final List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English', 'flag': 'us'},  // Cờ Mỹ
    {'code': 'zh', 'name': 'Chinese', 'flag': 'cn'},  // Cờ Trung Quốc
    {'code': 'id', 'name': 'Indonesian', 'flag': 'id'},  // Cờ Indonesia
    {'code': 'hi', 'name': 'Hindi', 'flag': 'in'},  // Cờ Ấn Độ
    {'code': 'vi', 'name': 'Vietnamese', 'flag': 'vn'},  // Cờ Việt Nam
    {'code': 'ko', 'name': 'Korean', 'flag': 'kr'},  // Cờ Hàn Quốc
    {'code': 'ru', 'name': 'Russian', 'flag': 'ru'},  // Cờ Nga
    {'code': 'th', 'name': 'Thai', 'flag': 'th'},  // Cờ Thái Lan
    {'code': 'fr', 'name': 'French', 'flag': 'fr'},  // Cờ Pháp
    {'code': 'pt', 'name': 'Portuguese', 'flag': 'pt'},  // Cờ Bồ Đào Nha
    {'code': 'tr', 'name': 'Turkish', 'flag': 'tr'},  // Cờ Thổ Nhĩ Kỳ
    {'code': 'ar', 'name': 'Arabic', 'flag': 'sa'},  // Cờ Ả Rập Xê Út
  ];

  @override
  void initState() {
    super.initState();
    selectedLanguage = widget.selectedLanguage;
    selectedCountry = widget.selectedCountry;
  }

  // Lưu cả languageCode và flagCode vào SharedPreferences
  Future<void> _saveSelectedLanguage(String languageCode, String flagCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', languageCode);
    await prefs.setString('selectedCountry', flagCode);
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Choose Language', style: TextStyle(color: Colors.green)),
      children: languages.map((language) {
        return SimpleDialogOption(
          onPressed: () {
            setState(() {
              selectedLanguage = language['code']!;
              selectedCountry = language['flag']!;
            });
            _saveSelectedLanguage(language['code']!, language['flag']!);  // Lưu cả languageCode và flagCode
            widget.onLanguageSelected(language['code']!, language['flag']!);  // Trả về cả code và flag
            Navigator.pop(context);
          },
          child: Row(
            children: [
              CountryFlag.fromCountryCode(language['flag']!, height: 18, width: 25),
              const SizedBox(width: 10),
              Text(language['name']!),
            ],
          ),
        );
      }).toList(),
    );
  }
}
