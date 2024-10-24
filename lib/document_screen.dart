import 'dart:convert'; // Để giải mã JSON
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key});

  @override
  _DocumentScreenState createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  List<dynamic> documentData = [];
  String languageCode = 'en'; // Mặc định ngôn ngữ là tiếng Anh

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      languageCode = prefs.getString('selectedLanguage') ?? 'en';  // Lấy mã ngôn ngữ từ SharedPreferences
    });
    _loadJsonData();  // Gọi hàm đọc dữ liệu JSON sau khi có mã ngôn ngữ
  }

  Future<void> _loadJsonData() async {
    try {

      final String response = await rootBundle.loadString('assets/document_data.json');
      final data = json.decode(response);
       var languageData = data[languageCode] ?? data['en'];
      if (languageData is List) {
        setState(() {
          documentData = languageData;
        });
      } else {
        print('Error: Expected a list but got ${languageData?.runtimeType}.');
      }
    } catch (e) {
      print('Error loading JSON data: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false; // Ngăn việc quay lại trang trước
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Document'),
        ),
        body: documentData.isNotEmpty
            ? ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: documentData.length,
          itemBuilder: (context, index) {
            return _buildTreeItem(
              title: documentData[index]['title'],
              content: documentData[index]['content'],
            );
          },
        )
            : const Center(child: CircularProgressIndicator()), // Hiển thị vòng tròn tải khi đang load dữ liệu
      ),
    );
  }

  // Hàm xây dựng mỗi mục ExpansionTile
  Widget _buildTreeItem({required String title, required String content}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(content, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
