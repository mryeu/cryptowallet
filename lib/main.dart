import 'dart:math';
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
        : (walletData == null
        ? const WalletSelectorScreen()
        : const WalletScreen()))
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
    _showBackupPopupIfNeeded(); // Kiểm tra và hiển thị popup backup nếu cần
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

  // Kiểm tra và hiển thị popup backup nếu cần
  Future<void> _showBackupPopupIfNeeded() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasBackedUp = prefs.getBool('hasBackedUp') ?? false;

    if (!hasBackedUp) {
      _showBackupPopup(context);
    }
  }

  Future<void> _showBackupPopup(BuildContext context) async {
    String? mnemonic;
    // Prompt the user for their PIN or password (optional based on your needs)
    String? pin = await _promptForPassword(context);

    if (pin == null || pin.isEmpty) {
      // User canceled or didn't provide the pin, return early
      return;
    }

    // Attempt to fetch the mnemonic using the provided pin
    try {
      final walletDataDecrypt = await loadWalletPINFromJson(pin);
      mnemonic = walletDataDecrypt?['decrypted_mnemonic'];
    } catch (e) {
      print('Error fetching mnemonic: $e');
      // Show error dialog
      _showErrorDialog(context, 'Failed to fetch mnemonic. Please try again.');
      return;
    }

    if (mnemonic != null) {
      showDialog(
        context: context,
        builder: (context) {
          return BackupDialog(
            mnemonic: mnemonic!,
          );
        },
      );
    } else {
      // Show an error if mnemonic is null
      _showErrorDialog(context, 'Mnemonic not found. Please check your wallet.');
    }
  }

// Helper function to prompt the user for a password or PIN (optional)
  Future<String?> _promptForPassword(BuildContext context) async {
    TextEditingController _passwordController = TextEditingController();

    return await showDialog<String?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          title: Text(
            'Restore Wallet',
            textAlign: TextAlign.center, // Căn giữa chữ
            style: TextStyle(
              color: Colors.red, // Đặt màu chữ là màu đỏ
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You have not backed up your wallet. You need to store the 12 mnemonic words to protect your assets.',
                style: TextStyle(fontSize: 16.0, color: Colors.red,),
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Enter your password to start restoring your wallet:',
                style: TextStyle(fontSize: 14.0),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cancel the action
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(_passwordController.text); // Return the entered password
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }



// Helper function to show an error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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

// Backup Dialog Popup
class BackupDialog extends StatefulWidget {
  final String mnemonic;

  BackupDialog({required this.mnemonic});

  @override
  _BackupDialogState createState() => _BackupDialogState();
}

class _BackupDialogState extends State<BackupDialog> {
  final List<int> _randomPositions = [];
  final List<TextEditingController> _mnemonicControllers = List.generate(4, (_) => TextEditingController());
  bool _checkboxConfirmed = false;
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _generateRandomPositions();
  }

  void _generateRandomPositions() {
    final random = Random();
    while (_randomPositions.length < 4) {
      int position = random.nextInt(12);
      if (!_randomPositions.contains(position)) {
        _randomPositions.add(position);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mnemonicWords = widget.mnemonic.split(' ');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Bo tròn góc cho AlertDialog
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[900]!, Colors.green[200]!], // Gradient từ xanh đậm tới xanh nhạt
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Backup Wallet',
                style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              Text(
                'Here are your 12 mnemonic words:',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: mnemonicWords.asMap().entries.map((entry) {
                  final index = entry.key;
                  final word = entry.value;

                  // Đánh số thứ tự cho từ mnemonic và hiển thị chữ màu trắng
                  return Chip(
                    label: Text(
                      '${index + 1}. $word',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green[500], // Nền xanh cố định cho các từ
                  );
                }).toList(),
              ),
              CheckboxListTile(
                title: Text(
                  'I have written down the 12 mnemonic words',
                  style: TextStyle(color: Colors.red),
                ),
                value: _checkboxConfirmed,
                onChanged: (bool? value) {
                  setState(() {
                    _checkboxConfirmed = value!;
                  });
                },
                checkColor: Colors.white, // Màu dấu tick
                activeColor: Colors.green[300], // Màu hộp tick khi chọn
              ),
              if (_checkboxConfirmed) _mnemonicInputFields(mnemonicWords),
              const SizedBox(height: 16.0), // Khoảng cách giữa nội dung và nút
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nút "Backup Later"
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Đóng dialog
                    },
                    child: Text('Later', style: TextStyle(color: Colors.red)),
                  ),
                  ElevatedButton(
                    onPressed: _isConfirmed ? _confirmBackup : null,
                    child: Text('Confirm', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _mnemonicInputFields(List<String> mnemonicWords) {
    return Column(
      children: [
        Text('Please enter the following words based on their positions:', style: TextStyle(color: Colors.white),),
        for (int i = 0; i < 4; i++)
          TextField(
            controller: _mnemonicControllers[i],
            decoration: InputDecoration(
              labelText: 'Word at position ${_randomPositions[i] + 1}',
              border: OutlineInputBorder(),
            ),
          ),
        ElevatedButton(
          onPressed: () {
            _validateMnemonics(mnemonicWords);
          },
          child: Text('Validate'),
        ),
      ],
    );
  }

  void _validateMnemonics(List<String> mnemonicWords) {
    bool isValid = true;
    for (int i = 0; i < 4; i++) {
      if (_mnemonicControllers[i].text != mnemonicWords[_randomPositions[i]]) {
        isValid = false;
        break;
      }
    }

    if (isValid) {
      setState(() {
        _isConfirmed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup successful')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mnemonic validation failed')),
      );
    }
  }

  void _confirmBackup() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('hasBackedUp', true);
    Navigator.of(context).pop(); // Close the dialog
  }
}
