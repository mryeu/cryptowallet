import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDisposed = false; // Track if the widget is disposed
  List<dynamic> newsItems = [];
  String languageCode = 'en';  // Mặc định là tiếng Anh

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        languageCode = Localizations.localeOf(context).languageCode;
        print('Language Code: $languageCode');
        fetchNewsData();
      });
    });
  }



  Future<void> fetchNewsData() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api-admin.kittyrun.net/api/content-mobile/?format=json'));
      if (response.statusCode == 200 && mounted) {
        final jsonResponse = json.decode(response.body);
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
    _isDisposed = true;
    super.dispose();
  }

  // Hàm để lấy nội dung theo ngôn ngữ của thiết bị
  String getLocalizedText(Map<String, dynamic> data) {
    return data[languageCode] ?? data['en'] ?? ''; // Mặc định trả về tiếng Anh nếu không tìm thấy ngôn ngữ
  }

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
              onPageChanged: (index, reason) {
                if (mounted) {
                  setState(() {
                    // Update the state
                  });
                }
              },
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
                          image: NetworkImage(item['imagesource']), // Sử dụng NetworkImage thay cho AssetImage
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
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        getLocalizedText(item['content']),
                        style: const TextStyle(fontSize: 12),
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
                          style: const TextStyle(fontSize: 16),
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
