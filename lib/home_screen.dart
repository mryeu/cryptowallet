import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDisposed = false; // Track if the widget is disposed
  List<dynamic> newsItems = [];
  String languageCode = 'en'; // Default to English
  String flagCode = 'us'; // Default to US flag

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
    fetchNewsData();
  }

  Future<void> fetchNewsData() async {
    try {
      final response = await http.get(
        Uri.parse('https://api-admin.kittyrun.net/api/content-mobile/?format=json'),
      );

      if (response.statusCode == 200 && mounted) {
        // Đảm bảo xử lý mã hóa UTF-8 cho dữ liệu từ API
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes)); // Sử dụng utf8.decode
        if (jsonResponse.containsKey('data')) {
          setState(() {
            newsItems = jsonResponse['data'];
          });
        } else {
          print('Data field missing in response');
        }
      } else {
        print('Failed to load data');
      }
    } catch (e) {
      if (!_isDisposed) {
        print('Error fetching data: $e');
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;  // Đánh dấu là đã hủy
    super.dispose();
  }

  // Hàm lấy text theo ngôn ngữ đã chọn
  String getLocalizedText(Map<String, dynamic> data) {
    print('Current languageCode: $languageCode');  // Kiểm tra giá trị của languageCode
    return data[languageCode] ?? data['en'] ?? ''; // Nếu không có ngôn ngữ đã chọn thì lấy mặc định tiếng Anh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 20),
          newsItems.isNotEmpty
              ? FlutterCarousel(
            options: CarouselOptions(
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              enlargeCenterPage: true,
              aspectRatio: 25 / 9,
              viewportFraction: 1,
            ),
            items: List.generate(
              newsItems.take(5).length,
                  (index) {
                var item = newsItems[index];
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: NetworkImage(item['imagesource']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: Center(
                        child: Text(
                          getLocalizedText(item['title']),
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NotoSans', // Sử dụng font NotoSans
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
              : const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: newsItems.length,
              itemBuilder: (context, index) {
                var item = newsItems[index];
                return SizedBox(
                  height: 100,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.green, width: 1),
                    ),
                    child: ListTile(
                      title: Text(
                        getLocalizedText(item['title']),
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'NotoSans', // Sử dụng font NotoSans
                        ),
                      ),
                      subtitle: Text(
                        getLocalizedText(item['content']),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'NotoSans', // Sử dụng font NotoSans
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: Image.network(
                        item['imagesource'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        _showNewsDetailPopup(context, item);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      languageCode = prefs.getString('selectedLanguage') ?? 'en';  // Mã ngôn ngữ (ví dụ: 'en', 'vi', ...)
      flagCode = prefs.getString('selectedCountry') ?? 'us';  // Mã quốc gia (flag code)
      print('Loaded Language Code: $languageCode, Flag Code: $flagCode');
    });
  }


  void _showNewsDetailPopup(BuildContext context, dynamic newsItem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        // Sử dụng cùng languageCode và flagCode từ SharedPreferences
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          initialChildSize: 0.75,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          getLocalizedText(newsItem['title']),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontFamily: 'NotoSans', // Sử dụng font NotoSans
                          ),
                        ),
                        const SizedBox(height: 20),
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            newsItem['imagesource'],
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          getLocalizedText(newsItem['content']),
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'NotoSans', // Sử dụng font NotoSans
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Kittyrun Studio 2024 news',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
