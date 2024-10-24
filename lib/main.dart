import 'dart:math';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:cryptowallet/pinScreen.dart';
import 'package:cryptowallet/services/session_manager.dart';
import 'package:cryptowallet/terms_screen.dart';
import 'package:cryptowallet/wallet_create.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptowallet/services/localization_service.dart'; // Tích hợp LocalizationService
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

  // Load the selected language for localization
  String selectedLanguage = prefs.getString('selectedLanguage') ?? 'en';
  await LocalizationService.load(selectedLanguage);

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
      _showErrorDialog(context, LocalizationService.translate('wallet_screen.error_fetching_mnemonic'));
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
      _showErrorDialog(context, LocalizationService.translate('wallet_screen.mnemonic_not_found'));
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
            LocalizationService.translate('wallet_screen.restore_wallet'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LocalizationService.translate('wallet_screen.restore_wallet_description'),
                style: const TextStyle(fontSize: 16.0, color: Colors.red),
              ),
              const SizedBox(height: 16.0),
              Text(
                LocalizationService.translate('wallet_screen.enter_password'),
                style: const TextStyle(fontSize: 14.0),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: LocalizationService.translate('wallet_screen.enter_password'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cancel the action
              },
              child: Text(LocalizationService.translate('wallet_screen.cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(_passwordController.text); // Return the entered password
              },
              child: Text(LocalizationService.translate('wallet_screen.submit')),
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

  // Các chuỗi được dùng trong Backup Dialog
  late String _backupTitle = '';
  late String _backupDescription = '';
  late String _laterText = '';
  late String _confirmText = '';
  late String _validateText = '';
  late String _mnemonicError = '';
  late String _backupSuccess = '';
  late String _iHaveWrittenMnemonic = ''; // Biến đã bỏ qua được thêm lại

  @override
  void initState() {
    super.initState();
    _generateRandomPositions();
    _loadBackupDialogLocalization(); // Tải chuỗi văn bản cho hộp thoại sao lưu
  }

  Future<void> _loadBackupDialogLocalization() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String selectedLanguage = prefs.getString('selectedLanguage') ?? 'en';
    String selectedFlag = prefs.getString('selectedCountry') ?? 'us';
    print("Selected Language: $selectedLanguage, Selected Flag: $selectedFlag");

    List<String> validLanguages = ['en', 'zh', 'id', 'hi', 'vi', 'ko', 'ru', 'th', 'fr', 'pt', 'tr', 'ar'];
    List<String> validCountries = ['us', 'cn', 'id', 'in', 'vn', 'kr', 'ru', 'th', 'fr', 'pt', 'tr', 'sa'];

    if (!validLanguages.contains(selectedLanguage)) {
      selectedLanguage = 'en';
    }
    if (!validCountries.contains(selectedFlag)) {
      selectedFlag = 'us';
    }

    try {
      await LocalizationService.load(selectedLanguage);
    } catch (e) {
      print("Error loading language file: $e");
      await LocalizationService.load('en');

      selectedLanguage = 'en';
      selectedFlag = 'us';
    }

    setState(() {
      // Khởi tạo các biến chuỗi với giá trị dịch
      _backupTitle = LocalizationService.translate('backup_dialog.title');
      _backupDescription = LocalizationService.translate('backup_dialog.description');
      _laterText = LocalizationService.translate('backup_dialog.later');
      _confirmText = LocalizationService.translate('backup_dialog.confirm');
      _validateText = LocalizationService.translate('backup_dialog.validate');
      _mnemonicError = LocalizationService.translate('backup_dialog.mnemonic_error');
      _backupSuccess = LocalizationService.translate('backup_dialog.backup_success');
      _iHaveWrittenMnemonic = LocalizationService.translate('backup_dialog.i_have_written_mnemonic'); // Khôi phục biến bị thiếu
    });
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[900]!, Colors.green[200]!],
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
                _backupTitle.isNotEmpty ? _backupTitle : 'Backup Wallet', // Kiểm tra chuỗi trước khi hiển thị
                style: const TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              Text(
                _backupDescription.isNotEmpty ? _backupDescription : 'Please backup your wallet.',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: mnemonicWords.asMap().entries.map((entry) {
                  final index = entry.key;
                  final word = entry.value;

                  return Chip(
                    label: Text(
                      '${index + 1}. $word',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green[500],
                  );
                }).toList(),
              ),
              CheckboxListTile(
                title: Text(
                  _iHaveWrittenMnemonic.isNotEmpty ? _iHaveWrittenMnemonic : 'I have written down the 12 mnemonic words',
                  style: const TextStyle(color: Colors.red),
                ),
                value: _checkboxConfirmed,
                onChanged: (bool? value) {
                  setState(() {
                    _checkboxConfirmed = value!;
                  });
                },
                checkColor: Colors.white,
                activeColor: Colors.green[300],
              ),
              if (_checkboxConfirmed) _mnemonicInputFields(mnemonicWords),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Đóng dialog
                    },
                    child: Text(_laterText.isNotEmpty ? _laterText : 'Later', style: const TextStyle(color: Colors.red)),
                  ),
                  ElevatedButton(
                    onPressed: _isConfirmed ? _confirmBackup : null,
                    child: Text(_confirmText.isNotEmpty ? _confirmText : 'Confirm', style: const TextStyle(color: Colors.white)),
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
        Text(
          _validateText.isNotEmpty ? _validateText : 'Please enter the following words based on their positions:',
          style: const TextStyle(color: Colors.white),
        ),
        for (int i = 0; i < 4; i++)
          TextField(
            controller: _mnemonicControllers[i],
            decoration: InputDecoration(
              labelText: '${LocalizationService.translate('backup_dialog.word_at_position')} ${_randomPositions[i] + 1}',
              border: const OutlineInputBorder(),
            ),
          ),
        ElevatedButton(
          onPressed: () {
            _validateMnemonics(mnemonicWords);
          },
          child: Text(_validateText.isNotEmpty ? _validateText : 'Validate'),
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
        SnackBar(content: Text(_backupSuccess.isNotEmpty ? _backupSuccess : 'Backup successful!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mnemonicError.isNotEmpty ? _mnemonicError : 'Mnemonic validation failed')),
      );
    }
  }

  void _confirmBackup() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('hasBackedUp', true);
    Navigator.of(context).pop();
  }
}

