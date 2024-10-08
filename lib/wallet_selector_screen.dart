import 'package:cryptowallet/services/session_manager.dart';
import 'package:cryptowallet/wallet_create.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class WalletSelectorScreen extends StatelessWidget {
  const WalletSelectorScreen({Key? key}) : super(key: key);

  Future<bool> checkIfAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('acceptedTerms') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Check if PIN is null
    if (SessionManager.userPin == null) {
      // If PIN is null, redirect to SetupPinScreen
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SetupPinScreen()),
        );
      });
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF66BB6A), // Light green
              Color(0xFF004D40), // Dark green
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              Image.asset(
                'assets/images/logo_ktr.png', // Replace with your logo asset path
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 20),
              // Welcome Text
              const Text(
                'Welcome to',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const Text(
                'Kittyrun Wallet',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const Text(
                'Please make a selection below to create or import mnemonic',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  bool hasAcceptedTerms = await checkIfAcceptedTerms();
                  if (hasAcceptedTerms) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SetupPinScreen()), // Navigate to the PIN setup screen
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TermsScreen()),
                    );
                  }
                },
                child: const Text(
                  'Create New Wallet',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              // "Import Mnemonic" Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ImportSeedScreen()),
                  );
                },
                child: const Text(
                  'Import Mnemonic',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 50), // Adds a 50-pixel gap at the bottom
            ],
          ),
        ),
      ),
    );
  }
}
class TermsScreen extends StatefulWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  _TermsScreenState createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _isChecked = false;

  Future<void> _acceptTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acceptedTerms', true); // Store true to indicate acceptance
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms of Use"),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF66BB6A), // Light green
              Color(0xFF004D40), // Dark green
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  "KittyRun Wallet - Terms and Conditions\n\n"
                      "1. **Decentralized Nature**: KittyRun Wallet is a non-custodial wallet. This means that you, the user, are fully responsible for managing your private keys and recovery phrases. We do not store, control, or have access to your private keys or funds.\n\n"
                      "2. **Privacy**: As a decentralized wallet, KittyRun Wallet does not collect or store any personal information or transaction data. All your data is stored locally on your device and is never transmitted to our servers.\n\n"
                      "3. **Self-Custody**: You are the sole owner of your assets. If you lose your private keys or recovery phrase, you will not be able to access your funds. It is your responsibility to securely store and back up your recovery phrase and private keys.\n\n"
                      "4. **Transaction Responsibility**: All transactions initiated through KittyRun Wallet are irreversible and cannot be undone. You are fully responsible for verifying the details of your transactions before confirming them.\n\n"
                      "5. **Security**: KittyRun Wallet employs industry-standard encryption to protect your data on your device. However, the security of your wallet also depends on the security of your device. You are responsible for safeguarding your device against unauthorized access, malware, and other security threats.\n\n"
                      "6. **Updates**: We may release updates to improve security, fix bugs, or add new features. It is recommended that you keep the app updated to the latest version to ensure optimal performance and security.\n\n"
                      "7. **No Liability**: KittyRun Wallet and its developers shall not be liable for any loss, damage, or expense arising from the use or inability to use the wallet, including but not limited to the loss of funds, data breaches, or unauthorized access to your device.\n\n"
                      "8. **Acceptance of Terms**: By using KittyRun Wallet, you acknowledge that you have read, understood, and agreed to these terms. If you do not agree to any of these terms, you should discontinue the use of the wallet immediately.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _isChecked,
                  onChanged: (bool? value) {
                    setState(() {
                      _isChecked = value ?? false;
                    });
                  },
                ),
                const Text(
                  "I agree to the terms of use",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: _isChecked
                    ? () {
                  _acceptTerms();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateWalletScreen()),
                  );
                }
                    : null,
                child: const Text("Accept"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class CreateWalletScreen extends StatelessWidget {
  const CreateWalletScreen({Key? key}) : super(key: key);

  Future<bool> _checkIfAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('acceptedTerms') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Check if PIN is null
    if (SessionManager.userPin == null) {
      // If PIN is null, redirect to SetupPinScreen
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SetupPinScreen()),
        );
      });
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF66BB6A), // Light green
              Color(0xFF004D40), // Dark green
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              Image.asset(
                'assets/images/logo_ktr.png', // Replace with your logo asset path
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 20),
              // Welcome Text
              const Text(
                'Welcome to',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const Text(
                'Kittyrun Wallet',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const Text(
                'Please make a selection below to create or import mnemonic',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  bool hasAcceptedTerms = await _checkIfAcceptedTerms();
                  if (hasAcceptedTerms) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SetupPinScreen()), // Navigate to the PIN setup screen
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TermsScreen()),
                    );
                  }
                },
                child: const Text(
                  'Create New Wallet',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              // "Import Mnemonic" Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ImportSeedScreen()),
                  );
                },
                child: const Text(
                  'Import Mnemonic',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 50), // Adds a 50-pixel gap at the bottom
            ],
          ),
        ),
      ),
    );
  }
}


class SetupPinScreen extends StatefulWidget {
  const SetupPinScreen({Key? key}) : super(key: key);

  @override
  _SetupPinScreenState createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  String _enteredPin = "";
  String _firstPin = "";
  bool _isConfirming = false; // Track if we are in confirmation mode
  String _message = "Enter Your PIN"; // Message to display at the top

  void _onKeyPress(String value) async {
    setState(() {
      if (value == 'DELETE') {
        if (_enteredPin.isNotEmpty) {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        }
      } else if (_enteredPin.length < 6) {
        _enteredPin += value;

        // If the user has entered 6 digits
        if (_enteredPin.length == 6) {
          // Check if the wallet already exists
          _handlePinConfirmation();
        }
      }
    });
  }

// Function to handle PIN confirmation logic
  void _handlePinConfirmation() async {
    final walletExists = await _walletExists(); // Check if a wallet exists

    if (walletExists) {
      // If a wallet exists, use the entered PIN to try unlocking the wallet
      final walletData = await loadWalletPINFromJson(_enteredPin);
      if (walletData != null) {
        // Successfully decrypted the wallet, save the PIN and navigate to the wallet screen
        SessionManager.userPin = _enteredPin;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WalletScreen()),
        );
      } else {
        // If decryption fails, reset the PIN entry
        _resetPinEntry("Invalid PIN. Please try again.");
      }
    } else {
      // If the wallet does not exist, proceed with PIN confirmation for wallet creation
      if (_isConfirming) {
        // If in confirmation mode, check if the PINs match
        if (_enteredPin == _firstPin) {
          _createWalletWithPin(_enteredPin);
        } else {
          // If PINs don't match, reset the process
          _resetPinEntry("PINs did not match. Please try again.");
        }
      } else {
        // If not confirming, move to confirmation mode
        _firstPin = _enteredPin;
        _enteredPin = ""; // Clear for re-entry
        _isConfirming = true;
        _message = "Re-enter Your PIN";
      }
    }
  }

// Function to check if the wallet already exists
  Future<bool> _walletExists() async {
    final walletData = await loadWalletFromJson();
    return walletData != null;
  }

// Function to reset the PIN entry process
  void _resetPinEntry(String message) {
    setState(() {
      _enteredPin = "";
      _firstPin = "";
      _isConfirming = false;
      _message = message;
    });
  }


  Future<void> _createWalletWithPin(String pin) async {
    try {
      // Save the PIN to the session manager
      SessionManager.userPin = pin;
      Map<String, dynamic> walletData = await generateWallet(pin);
      if (walletData != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const WalletScreen(),
          ),
        );
      } else {
        _resetPinEntry("Failed to create wallet. Try again.");
      }
    } catch (e) {
      // Handle errors if wallet generation fails
      _resetPinEntry("Failed to create wallet. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Setup PIN"),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF66BB6A), // Light green
              Color(0xFF004D40), // Dark green
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _message,
              style: const TextStyle(fontSize: 18, color: Colors.white54),
            ),
            const SizedBox(height: 20),
            Text(
              _enteredPin.replaceAll(RegExp(r'.'), '*'), // Hide PIN input with asterisks
              style: const TextStyle(fontSize: 32, letterSpacing: 8, color: Colors.white),
            ),
            const SizedBox(height: 20),
            _buildKeypad(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['1', '2', '3'].map((e) => _buildKey(e)).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['4', '5', '6'].map((e) => _buildKey(e)).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['7', '8', '9'].map((e) => _buildKey(e)).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEmptyKey(), // Empty key for balance
              _buildKey('0'),   // Zero key
              _buildDeleteKey(), // Delete icon button
            ],
          ),
        ],
      ),
    );
  }

  // Method to create an empty key for balancing the keypad
  Widget _buildEmptyKey() {
    return const Expanded(
      child: SizedBox(
        height: 70, // Adjust height to match other keys
        child: Text(''), // Empty text to create an empty space
      ),
    );
  }

  // Method to create a delete key with an icon
  Widget _buildDeleteKey() {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => _onKeyPress('DELETE'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(25),
          shape: const CircleBorder(),
        ),
        child: const Icon(
          Icons.backspace, // Use the backspace icon for deletion
          size: 24,
        ),
      ),
    );
  }

  Widget _buildKey(String value) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => _onKeyPress(value),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(20),
          shape: const CircleBorder(),
        ),
        child: Text(
          value,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}



class ImportSeedScreen extends StatelessWidget {
  const ImportSeedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Import Seed Phrase"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WalletScreen()),
            );
          },
          child: const Text("Import Seed And Save Wallet"),
        ),
      ),
    );
  }
}

