import 'dart:convert'; // Để giải mã JSON
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
      languageCode = prefs.getString('selectedLanguage') ?? 'en'; // Lấy mã ngôn ngữ từ SharedPreferences
    });
    _fetchDataFromApi(); // Gọi hàm đọc dữ liệu từ API sau khi có mã ngôn ngữ
  }

  Future<void> _fetchDataFromApi() async {
    final String apiUrl = 'https://api-admin.kittyrun.net/api/section-mobile/?format=json';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // Đảm bảo giải mã dữ liệu đúng cách (trong trường hợp có ký tự đặc biệt)
        final data = json.decode(utf8.decode(response.bodyBytes));

        // Lọc dữ liệu dựa trên mã ngôn ngữ
        var languageData = data[languageCode] ?? data['en']; // Nếu không có ngôn ngữ đã chọn thì lấy mặc định tiếng Anh
        if (languageData is List) {
          setState(() {
            documentData = languageData;
          });
        } else {
          print('Error: Expected a list but got ${languageData.runtimeType}.');
        }
      } else {
        print('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading data from API: $e');
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
              title: documentData[index]['title'] ?? 'No title',
              content: documentData[index]['content'] ?? 'No content',
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
          style: const TextStyle(
            fontFamily: 'NotoSans', // Sử dụng font NotoSans
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              content,
              style: const TextStyle(
                fontFamily: 'NotoSans', // Sử dụng font NotoSans cho nội dung
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
