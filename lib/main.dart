import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:cryptowallet/pinScreen.dart';
import 'package:cryptowallet/services/session_manager.dart';
import 'package:cryptowallet/terms_screen.dart';
import 'package:cryptowallet/wallet_create.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Play_Screen.dart';
import 'Swap_Screen.dart';
import 'Wallet_screen.dart';
import 'document_screen.dart';
import 'home_screen.dart';
import 'wallet_selector_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final walletData = await loadWalletFromJson();
  bool hasAcceptedTerms = prefs.getBool('acceptedTerms') ?? false;

  // Check if PIN is set
  String? userPin = SessionManager.userPin;

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: hasAcceptedTerms
        ? (userPin == null
        ? const SetupPinScreen()
        : (walletData == null ? const WalletSelectorScreen() : const WalletScreen()))
        : const TermsScreen(),
  ));
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _selectedIndex = 2; // Default to Swap tab
  static const List<Widget> _widgetOptions = <Widget>[

    HomeScreen(),
    PlayScreen(),
    SwapScreen(),
    DocumentScreen(),
    Wallet(),
  ];

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  // Check if PIN is set before allowing access
  void _checkPinStatus() {
    if (SessionManager.userPin == null) {
      // If PIN is null, redirect to SetupPinScreen
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SetupPinScreen()),
        );
      });
    }
  }

  // When a tab is selected, update the selected tab index
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: ConvexAppBar(
        backgroundColor: Colors.green,
        style: TabStyle.fixed,
        items: [
          const TabItem(icon: Icons.home),
          const TabItem(icon: Icons.play_arrow_sharp),
          TabItem(icon: _buildSwapIcon()),
          const TabItem(icon: Icons.explore),
          const TabItem(icon: Icons.account_balance_wallet),
        ],
        initialActiveIndex: _selectedIndex, // Set the default selected tab
        onTap: (int index) {
          _onItemTapped(index); // Change tab index when the user taps
        },
      ),
    );
  }

  // Build the Swap icon with rounded effect and spinning animation
  Widget _buildSwapIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_selectedIndex == 2) // Show effect if the Swap tab is selected
          const SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
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
              width: 50,
              height: 50,
            ),
          ),
        ),
      ],
    );
  }
}
