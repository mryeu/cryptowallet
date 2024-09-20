import 'package:flutter/material.dart';
import 'Discover_Screen.dart';
import 'Play_Screen.dart';
import 'Swap_Screen.dart';
import 'Wallet_screen.dart';
import 'document_screen.dart';
import 'home_screen.dart';

void main() {
  runApp(const WalletTop1());
}

class WalletTop1 extends StatelessWidget {
  const WalletTop1({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Loại bỏ banner "Debug"
      title: '#1Wallet',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const WalletScreen(),
    );
  }
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _selectedIndex = 2; // Mặc định tab Swap được chọn
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    PlayScreen(),
    SwapScreen(),
    DocumentScreen(),
    Wallet(),
  ];

  // Khi chọn một tab, sẽ thay đổi chỉ số của tab đó
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 1 // Kiểm tra nếu đang ở PlayScreen thì ẩn AppBar
          ? null
          : AppBar(
        // AppBar chỉ hiện khi không phải PlayScreen
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // Xử lý nhấn nút cài đặt
              },
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () {
                // Xử lý nhấn nút quét QR code
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                // Xử lý nhấn nút thông báo
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.play_arrow_sharp),
            label: 'Play',
          ),
          BottomNavigationBarItem(
            icon: _buildSwapIcon(),
            label: 'Swap',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Document',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.purpleAccent,
        onTap: _onItemTapped,
      ),
    );
  }

  // Hàm để xây dựng icon Swap với hiệu ứng bo tròn và vòng quay
  Widget _buildSwapIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_selectedIndex == 2) // Nếu tab Swap được chọn thì hiển thị hiệu ứng
          const SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.green, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: Image.asset(
              'assets/images/logo_ktr.png',
              width: 40,
              height: 40,
            ),
          ),
        ),
      ],
    );
  }
}
