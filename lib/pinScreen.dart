import 'dart:io';
import 'package:cryptowallet/services/session_manager.dart';
import 'package:cryptowallet/terms_screen.dart';
import 'package:cryptowallet/wallet_create.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';

class SetupPinScreen extends StatefulWidget {
  final String? mnemonic;

  const SetupPinScreen({Key? key, this.mnemonic}) : super(key: key);

  @override
  _SetupPinScreenState createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  String _enteredPin = "";
  String _firstPin = "";
  bool _isConfirming = false;
  bool _walletExists = false;
  String _message = "Enter Your PIN";

  @override
  void initState() {
    super.initState();
    _checkWalletExistence();
  }

  // Hàm kiểm tra ví đã tồn tại chưa
  Future<void> _checkWalletExistence() async {

    if (widget.mnemonic != null) {
      setState(() {
        _message = "Enter Your PIN to Restore Wallet";  // Nếu có mnemonic, yêu cầu nhập PIN để khôi phục
        _walletExists = false; // Đảm bảo rằng nó không kiểm tra ví cũ
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    bool walletCreated = prefs.getBool('wallet_created') ?? false;

    if (walletCreated) {
      setState(() {
        _walletExists = true;
        _message = "Enter Your PIN to Unlock Wallet";
      });
    } else {
      // Nếu cờ chưa được tạo, kiểm tra tệp ví (nếu cần)
      bool exists = await _walletExistsInStorage();
      setState(() {
        _walletExists = exists;
        if (exists) {
          _message = "Enter Your PIN to Unlock Wallet";
        } else {
          _message = "Enter Your PIN to Create New Wallet";  // Nếu không có gì, yêu cầu tạo ví mới
        }
      });
    }
  }

  Future<bool> _walletExistsInStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/wallet_mobile.json'; // Đảm bảo chuỗi được đóng đúng
      final file = File(filePath);
      return file.existsSync(); // Trả về true nếu tệp tồn tại
    } catch (e) {
      print("Error checking wallet_mobile.json existence: $e");
      return false;
    }
  }


  // Khi nhấn phím để nhập PIN
  void _onKeyPress(String value) async {
    setState(() {
      if (value == 'DELETE') {
        if (_enteredPin.isNotEmpty) {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        }
      } else if (_enteredPin.length < 6) {
        _enteredPin += value;

        if (_enteredPin.length == 6) {
          if (_walletExists) {
            // Nếu ví đã tồn tại, chỉ cần xác nhận PIN một lần để mở khóa
            _unlockWalletWithPin(_enteredPin);
          } else if (_isConfirming) {
            // Nếu đang ở chế độ xác nhận (khi tạo hoặc khôi phục ví)
            _handlePinConfirmation();
          } else {
            _firstPin = _enteredPin;
            _enteredPin = "";
            _isConfirming = true;
            _message = "Re-enter Your PIN";
          }
        }
      }
    });
  }

  // Xác nhận hoặc mở ví nếu đã tồn tại
  void _handlePinConfirmation() async {
    if (_enteredPin == _firstPin) {
      if (widget.mnemonic == null) {
        // Nếu không có mnemonic, tạo ví mới
        _createWalletWithPin(_enteredPin);
      } else {
        // Nếu có mnemonic, khôi phục ví từ mnemonic
        _importWalletWithPin(_enteredPin);
      }
    } else {
      _resetPinEntry("PINs did not match. Please try again.");
    }
  }

  // Mở khóa ví đã tồn tại bằng PIN (chỉ nhập 1 lần PIN)
  Future<void> _unlockWalletWithPin(String pin) async {
    try {
      _showLoadingDialog("Unlocking wallet...");
      SessionManager.userPin = pin;
      final walletData = await loadWalletPINFromJson(pin); // Giải mã ví bằng PIN
      _hideLoadingDialog();

      if (walletData != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WalletScreen()), // Chuyển tới màn hình chính
        );
      } else {
        _resetPinEntry("Invalid PIN. Please try again.");
      }
    } catch (e) {
      _hideLoadingDialog();
      _resetPinEntry("Failed to unlock wallet. Try again.");
    }
  }

  // Tạo ví mới với PIN
  Future<void> _createWalletWithPin(String pin) async {
    try {
      _showLoadingDialog("Creating wallet, please wait...");

      SessionManager.userPin = pin;
      Map<String, dynamic> walletData = await generateWallet(pin);
      _hideLoadingDialog();

      if (walletData != null) {
        // Lưu trạng thái ví đã được tạo trong SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('wallet_created', true);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WalletScreen()),
        );
      } else {
        _resetPinEntry("Failed to create wallet. Try again.");
      }
    } catch (e) {
      _hideLoadingDialog();
      _resetPinEntry("Failed to create wallet. Try again.");
    }
  }

  // Khôi phục ví từ mnemonic
  Future<void> _importWalletWithPin(String pin) async {
    try {
      _showLoadingDialog("Restoring wallet, please wait...");

      SessionManager.userPin = pin;
      await importWalletFromSeed(widget.mnemonic!, pin);
      _hideLoadingDialog();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WalletScreen()),
      );
    } catch (e) {
      _hideLoadingDialog();
      _resetPinEntry("Failed to restore wallet. Try again.");
    }
  }

  // Reset quá trình nhập PIN khi có lỗi
  void _resetPinEntry(String message) {
    setState(() {
      _enteredPin = "";
      _firstPin = "";
      _isConfirming = false;
      _message = message;
    });
  }

  // Hiển thị dialog đợi
  Future<void> _showLoadingDialog(String message) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Không cho phép thoát khi dialog đang hiển thị
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(message),
              ],
            ),
          ),
        );
      },
    );
  }

  // Đóng dialog
  void _hideLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _removeWallet(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Thêm log để kiểm tra trước khi xóa
      print("Before deletion, wallet_created: ${prefs.getBool('wallet_created')}");
      print("Before deletion, wallet_pin: ${prefs.getString('wallet_pin')}");

      // Xóa cờ 'wallet_created' và các dữ liệu khác liên quan đến ví trong SharedPreferences
      await prefs.remove('wallet_created');
      await prefs.remove('wallet_pin');
      await prefs.remove('wallet_data');
      await prefs.remove('acceptedTerms');

      // Thêm log để kiểm tra sau khi xóa
      print("After deletion, wallet_created: ${prefs.getBool('wallet_created')}");
      print("After deletion, wallet_pin: ${prefs.getString('wallet_pin')}");

      try {
        final directory = await getApplicationDocumentsDirectory(); // Lấy thư mục tài liệu của ứng dụng
        final file = File('${directory.path}/wallet_mobile.json'); // Tạo đường dẫn file wallet.json

        if (await file.exists()) { // Kiểm tra xem file có tồn tại không
          await file.delete(); // Xóa file nếu tồn tại
          print('Đã xóa wallet.json');
        } else {
          print('wallet.json không tồn tại');
        }
      } catch (e) {
        print("Lỗi khi xóa ví: $e");
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TermsScreen()),
        );
      }

      print("Xóa ví thành công");
    } catch (e) {
      print("Lỗi khi xóa ví: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Vô hiệu hóa nút back của hệ thống
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Setup PIN"),
          centerTitle: true,
          automaticallyImplyLeading: false, // Vô hiệu hóa nút back trên AppBar
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF66BB6A),
                Color(0xFF004D40),
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
                _enteredPin.replaceAll(RegExp(r'.'), '*'),
                style: const TextStyle(fontSize: 32, letterSpacing: 8, color: Colors.white),
              ),
              const SizedBox(height: 100),
              _buildKeypad(),
              const Spacer(),

              // Nút "Remove Wallet"
              TextButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                onPressed: () async {
                  bool? confirm = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text(
                          "Confirm Wallet Deletion",
                          style: TextStyle(color: Colors.red),
                        ),
                        content: const Text(
                            "Are you sure you want to delete this wallet? This action cannot be undone."),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                          ),
                          TextButton(
                            onPressed: () async {
                              await deleteWalletJson();
                              await _removeWallet(context);

                              Navigator.of(context).pop(true);
                            },
                            child: const Text("Delete", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirm == true) {
                    await _removeWallet(context);
                  }
                },
                child: const Text(
                  'Remove Wallet',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Xây dựng bàn phím số
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
              _buildEmptyKey(),
              _buildKey('0'),
              _buildDeleteKey(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyKey() {
    return const Expanded(
      child: SizedBox(
        height: 70,
        child: Text(''),
      ),
    );
  }

  Widget _buildDeleteKey() {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => _onKeyPress('DELETE'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(25),
          shape: const CircleBorder(),
        ),
        child: const Icon(
          Icons.backspace,
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
