import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart'; // Import thư viện mới

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Chỉ số của card đang hiển thị trong carousel
  final List<String> carouselItems = [
    'Feature design 1',
    'Feature design 2',
    'Feature design 3',
    'Feature design 4',
    'Feature design 5',
  ];

  final List<String> newsItems = [
    'News Item 1: Breaking News!',
    'News Item 2: Latest Update!',
    'News Item 3: Flutter 3.0 Released!',
    'News Item 4: New Features in Dart!',
    'News Item 5: Hotfix Update Available!',
    'News Item 6: Flutter Dev Conference!',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Sử dụng flutter_carousel_widget để tạo slideshow
          FlutterCarousel(
            options: CarouselOptions(
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              enlargeCenterPage: true,
              aspectRatio: 25 / 9,
              viewportFraction: 1,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            items: carouselItems.map((item) {
              return Builder(
                builder: (BuildContext context) {
                  return Card(
                    color: Colors.green[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Danh sách tin tức với chiều cao 50
          Expanded(
            child: ListView.builder(
              itemCount: newsItems.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  height: 150,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.green, width: 1),
                    ),
                    child: ListTile(
                      title: Text(
                        newsItems[index],
                        style: const TextStyle(fontSize: 14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: const Icon(Icons.fiber_new, color: Colors.green),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
}
