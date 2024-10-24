import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_flags/country_flags.dart';

class LanguageSelectionDialog {
  static Future<void> show(BuildContext context, Function(String) onLanguageSelected) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String selectedLanguage = prefs.getString('selectedLanguage') ?? 'us';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _LanguageSelectionDialog(
          selectedLanguage: selectedLanguage,
          onLanguageSelected: onLanguageSelected,
        );
      },
    );
  }
}

class _LanguageSelectionDialog extends StatefulWidget {
  final String selectedLanguage;
  final Function(String) onLanguageSelected;

  const _LanguageSelectionDialog({Key? key, required this.selectedLanguage, required this.onLanguageSelected}) : super(key: key);

  @override
  __LanguageSelectionDialogState createState() => __LanguageSelectionDialogState();
}

class __LanguageSelectionDialogState extends State<_LanguageSelectionDialog> {
  String selectedLanguage = 'us';

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
    {'code': 'ar', 'name': 'Arabic', 'flag': 'sa'},  // Cờ Ả Rập Xê Út (Saudi Arabia)
  ];

  @override
  void initState() {
    super.initState();
    selectedLanguage = widget.selectedLanguage;
  }

  _saveSelectedLanguage(String flagCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', flagCode);
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Choose Language', style: TextStyle(color: Colors.green)),
      children: languages.map((language) {
        return SimpleDialogOption(
          onPressed: () {
            setState(() {
              selectedLanguage = language['flag']!;
            });
            _saveSelectedLanguage(language['flag']!);
            widget.onLanguageSelected(language['flag']!);
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
