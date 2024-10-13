import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:web3dart/crypto.dart';
import 'package:hex/hex.dart';
import 'package:web3dart/web3dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pointycastle/export.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Import compute for heavy operations



Future<Map<String, dynamic>> generateWallet(String password) async {
  // Tạo mnemonic từ BIP39
  final String generatedMnemonic = bip39.generateMnemonic();

  // Tạo seed từ mnemonic
  final seed = bip39.mnemonicToSeed(generatedMnemonic);
  final root = bip32.BIP32.fromSeed(seed);

  // Tạo ví đầu tiên với đường dẫn BIP44 chuẩn "m/44'/60'/0'/0/0"
  final child = root.derivePath("m/44'/60'/0'/0/0");

  // Lấy private key và địa chỉ
  final String privateKey = HEX.encode(child.privateKey!);  // Private key ở dạng hex
  final privateKeyBytes = Uint8List.fromList(HEX.decode(privateKey));
  // Tính địa chỉ Ethereum
  final address = ethereumAddressFromPrivateKey(privateKeyBytes);

  print('Địa chỉ Ethereum từ private key là: $address');

  print("Generated Private Key: $privateKey");
  print("Generated Address: $address");

  // Mã hóa private key với AES
  final String encryptedPrivateKey = encryptDataAES(privateKey, password);

  // Tạo dữ liệu ví
  const String walletName = "Main Wallet";
  final walletData = {
    'encrypted_mnemonic': encryptDataAES(generatedMnemonic, password),
    'encrypted_private_keys': [encryptedPrivateKey],
    'addresses': [address],
    'wallet_names': [walletName],
  };

  // Lưu ví vào file JSON nếu cần
  await saveWalletToJson(walletData);

  return walletData;
}



Future<Map<String, dynamic>> importWalletFromSeed(String mnemonic, String password) async {
  // Step 1: Generate the seed and root outside the main thread
  final seed = await compute(_deriveSeedFromMnemonic, mnemonic);
  final root = bip32.BIP32.fromSeed(seed);

  // Step 2: Variables to store wallets with nonce > 0
  List<String> addresses = [];
  List<String> privateKeys = [];
  List<String> walletNames = [];

  int consecutiveEmptyNonces = 0; // Count consecutive wallets with nonce = 0

  // Step 3: Iterate over wallets and check nonce
  for (int i = 0; i < 700; i++) {
    // Derive wallet path (BIP44 standard)
    final child = root.derivePath("m/44'/60'/0'/0/$i");

    // Extract private key and address
    final String privateKey = HEX.encode(child.privateKey!);
    final privateKeyBytes = Uint8List.fromList(HEX.decode(privateKey));
    final address = ethereumAddressFromPrivateKey(privateKeyBytes);

    // Log the derived address
    print('Checking address: $address at index $i');

    // Check the nonce for the address
    try {
      final nonce = await getNonce(address);
      print('Address: $address, Nonce: $nonce');

      // Always add the first wallet, even if nonce = 0
      if (i == 0 || nonce > 0) {
        consecutiveEmptyNonces = 0; // Reset consecutive count for active wallets
        addresses.add(address);
        privateKeys.add(encryptDataAES(privateKey, password));
        walletNames.add("KTRWL-$i");
      } else {
        consecutiveEmptyNonces++;
      }

      // Stop if 5 consecutive wallets have nonce = 0, but don't stop before processing the first wallet
      if (consecutiveEmptyNonces >= 5 && i > 0) {
        print('Stopping after finding 5 consecutive addresses with nonce = 0');
        break;
      }
    } catch (e) {
      // Handle errors for nonce fetching
      print('Error fetching nonce for address $address: $e');
      consecutiveEmptyNonces++; // Count this as an empty nonce to continue
    }
  }

  // Encrypt the mnemonic
  final encryptedMnemonic = encryptDataAES(mnemonic, password);

  // Construct wallet data
  final walletData = {
    'encrypted_mnemonic': encryptedMnemonic,
    'encrypted_private_keys': privateKeys,
    'addresses': addresses,
    'wallet_names': walletNames,
  };

  // Save the wallet to JSON (if needed)
  await saveWalletToJson(walletData);

  return walletData;
}

// Function to derive the seed outside the main thread
Uint8List _deriveSeedFromMnemonic(String mnemonic) {
  return bip39.mnemonicToSeed(mnemonic);
}

Future<int> getNonce(String address) async {
  const url = 'https://api.bscscan.com/api';
  const apiKey = 'PHPY7R4ERV4RKSYRDYAB7H4AJSQ3FWKTG7';

  final response = await http.get(Uri.parse(
      '$url?module=proxy&action=eth_getTransactionCount&address=$address&tag=latest&apikey=$apiKey'));

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);
    return int.parse(jsonResponse['result']); // Nonce dưới dạng số nguyên
  } else {
    throw Exception('Failed to fetch nonce');
  }
}



Uint8List publicKeyFromPrivateKey(Uint8List privateKey) {
  final ecDomain = ECDomainParameters('secp256k1');
  final privateKeyNum = BigInt.parse(HEX.encode(privateKey), radix: 16);
  final publicKey = ecDomain.G * privateKeyNum;
  // Chuyển public key thành Uint8List
  final compressedPublicKey = publicKey!.getEncoded(false);
  return Uint8List.fromList(compressedPublicKey);
}

// Hàm tính địa chỉ Ethereum từ public key
String ethereumAddressFromPrivateKey(Uint8List privateKey) {
  // Lấy public key từ private key
  final publicKey = publicKeyFromPrivateKey(privateKey);
  // Bỏ byte đầu tiên (0x04) và lấy 64 byte còn lại
  final publicKeyBytes = publicKey.sublist(1);
  // Tính keccak256 cho public key (đã bỏ byte đầu)
  final addressBytes = keccak256(publicKeyBytes).sublist(12); // Lấy 20 byte cuối cùng
  return '0x${HEX.encode(addressBytes)}';
}



String encryptDataAES(String plaintext, String password) {
  // Tạo khóa AES từ mật khẩu bằng cách băm SHA-256
  final key = encrypt.Key.fromUtf8(sha256.convert(utf8.encode(password)).toString().substring(0, 32));

  final iv = encrypt.IV.fromLength(16); // Tạo IV ngẫu nhiên (16 bytes)
  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc)); // Sử dụng CBC mode
  final encrypted = encrypter.encrypt(plaintext, iv: iv);
  final combined = iv.bytes + encrypted.bytes;
  return base64.encode(combined);
}

String decryptDataAES(String encryptedText, String password) {
  // Tạo khóa AES từ mật khẩu bằng cách băm SHA-256 (cách mới)
  final newKey = encrypt.Key.fromUtf8(sha256.convert(utf8.encode(password)).toString().substring(0, 32));

  final decoded = base64.decode(encryptedText);
  // Tách IV ra từ dữ liệu đã mã hóa
  final iv = encrypt.IV(decoded.sublist(0, 16));
  final encryptedBytes = decoded.sublist(16);

  // Cách 1: Thử giải mã với khóa SHA-256 (cách mới)
  try {
    final encrypterNew = encrypt.Encrypter(encrypt.AES(newKey, mode: encrypt.AESMode.cbc)); // Sử dụng CBC mode
    final decrypted = encrypterNew.decrypt(encrypt.Encrypted(encryptedBytes), iv: iv);
    return decrypted; // Giải mã thành công với cách mới
  } catch (e) {
    print('Giải mã bằng cách mới thất bại, thử cách cũ: $e');
  }

  // Cách 2: Nếu thất bại, thử với khóa cũ (padRight(32))
  try {
    final oldKey = encrypt.Key.fromUtf8(password.padRight(32)); // Tạo khóa cũ bằng cách padRight
    final encrypterOld = encrypt.Encrypter(encrypt.AES(oldKey, mode: encrypt.AESMode.cbc));
    final decrypted = encrypterOld.decrypt(encrypt.Encrypted(encryptedBytes), iv: iv);
    return decrypted; // Giải mã thành công với cách cũ
  } catch (e) {
    print('Giải mã bằng cách cũ thất bại: $e');
    throw Exception('Unable to decrypt data');
  }
}

// Lưu ví vào file JSON
Future<void> saveWalletToJson(Map<String, dynamic> walletData) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/wallet_mobile.json');

  print('Lưu ví vào đường dẫn: ${file.path}'); // In ra đường dẫn lưu ví
  await file.writeAsString(jsonEncode(walletData));

  // Đọc lại nội dung file sau khi lưu để kiểm tra
  final fileContents = await file.readAsString();
  print('Nội dung tệp wallet.json: $fileContents');
}

// Hàm xóa ví từ file JSON
Future<void> deleteWalletJson() async {
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
}

// Tải ví từ file JSON
Future<Map<String, dynamic>?> loadWalletFromJson() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/wallet_mobile.json');
    if (await file.exists()) {
      final contents = await file.readAsString();
      final walletData = jsonDecode(contents);
      return {
        'encrypted_mnemonic': walletData['encrypted_mnemonic'],
        'encrypted_private_keys': List<String>.from(walletData['encrypted_private_keys']),
        'addresses': List<String>.from(walletData['addresses']),
        'wallet_names': List<String>.from(walletData['wallet_names']), // Tải danh sách tên ví
      };
    } else {
      return null;
    }
  } catch (e) {
    print("Lỗi khi tải ví: $e");
    return null;
  }
}
Future<Map<String, dynamic>?> loadWalletPINFromJson(String pin) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/wallet_mobile.json');

    if (await file.exists()) {
      final contents = await file.readAsString();
      final walletData = jsonDecode(contents);

      // Decrypt the mnemonic and private keys using the provided PIN
      final decryptedMnemonic = decryptDataAES(walletData['encrypted_mnemonic'], pin);
      final decryptedPrivateKeys = walletData['encrypted_private_keys']
          .map<String>((key) => decryptDataAES(key, pin))
          .toList();

      return {
        'decrypted_mnemonic': decryptedMnemonic,
        'decrypted_private_keys': decryptedPrivateKeys,
        'addresses': List<String>.from(walletData['addresses']),
        'wallet_names': List<String>.from(walletData['wallet_names']), // Wallet names list
      };
    } else {
      return null;
    }
  } catch (e) {
    print("Lỗi khi tải và giải mã ví: $e");
    return null;
  }
}

Future<Map<String, dynamic>> importMultiPrivateKeys(List<String> privateKeys, String password) async {
  try {
    // Tải dữ liệu ví hiện tại từ file JSON
    final existingWalletData = await loadWalletFromJson();

    List<String> encryptedPrivateKeys = [];
    List<String> addresses = [];
    List<String> walletNames = [];

    // Nếu đã có dữ liệu ví, lấy danh sách private keys, addresses, và wallet names
    if (existingWalletData != null) {
      encryptedPrivateKeys = List<String>.from(existingWalletData['encrypted_private_keys']);
      addresses = List<String>.from(existingWalletData['addresses']);
      walletNames = List<String>.from(existingWalletData['wallet_names']);
    }

    // Đếm số ví được thêm thành công
    int addedWalletsCount = 0;

    for (String privateKey in privateKeys) {
      try {
        // Chuyển đổi private key từ hex sang Uint8List
        final Uint8List privateKeyBytes = Uint8List.fromList(HEX.decode(privateKey));

        // Kiểm tra độ dài private key (Ethereum private key luôn có độ dài 32 bytes)
        if (privateKeyBytes.length != 32) {
          print('Private key invalid: $privateKey');
          continue;
        }

        // Tạo Ethereum credentials từ private key
        final credentials = EthPrivateKey.fromHex(privateKey);

        // Lấy địa chỉ ví từ private key
        final ethAddress = await credentials.extractAddress();
        print('Địa chỉ ví từ private key: $ethAddress');

        // Kiểm tra xem địa chỉ đã tồn tại trong danh sách addresses chưa
        if (addresses.contains(ethAddress.hex)) {
          print('Address $ethAddress already exists in wallet. Skipping...');
          continue;
        }

        // Mã hóa private key với password
        final String encryptedPrivateKey = encryptDataAES(privateKey, password);

        // Thêm private key và địa chỉ vào danh sách
        encryptedPrivateKeys.add(encryptedPrivateKey);
        addresses.add(ethAddress.hex);

        // Đặt tên ví mới theo mẫu "KTRWL-{index}"
        final int walletIndex = encryptedPrivateKeys.length - 1; // Số thứ tự của ví mới
        final String walletName = "KTRWL-$walletIndex";
        walletNames.add(walletName);

        addedWalletsCount++; // Tăng số đếm ví được thêm thành công
      } catch (e) {
        print("Lỗi khi import private key: $e");
        continue;
      }
    }

    // Nếu không có ví nào được thêm, in ra thông báo
    if (addedWalletsCount == 0) {
      print('No new wallets were added.');
      return existingWalletData ?? {};
    }

    // Tạo dữ liệu ví mới
    final walletData = {
      'encrypted_mnemonic': existingWalletData?['encrypted_mnemonic'] ?? '', // Nếu đã có mnemonic trước đó, giữ nguyên
      'encrypted_private_keys': encryptedPrivateKeys,
      'addresses': addresses,
      'wallet_names': walletNames,
    };

    // Lưu dữ liệu ví mới vào file JSON
    await saveWalletToJson(walletData);
    print('Ví từ nhiều private key đã được lưu thành công');

    return walletData;

  } catch (e) {
    print("Lỗi khi import nhiều private key: $e");
    throw Exception('Import failed');
  }
}


// Hàm tạo nhiều ví từ 12 từ mnemonic có sẵn
Future<Map<String, dynamic>> addNewWalletFromMnemonic(String mnemonic, String password) async {
  // Kiểm tra mnemonic có hợp lệ không
  if (!bip39.validateMnemonic(mnemonic)) {
    throw Exception('Mnemonic Invalid');
  }

  // Tải dữ liệu ví hiện tại từ file JSON (nếu có)
  final existingWalletData = await loadWalletFromJson();

  List<String> privateKeys = [];
  List<String> addresses = [];
  List<String> walletNames = [];

  if (existingWalletData != null) {
    privateKeys = List<String>.from(existingWalletData['encrypted_private_keys']);
    addresses = List<String>.from(existingWalletData['addresses']);
    walletNames = List<String>.from(existingWalletData['wallet_names']);
  }

  // Mã hóa mnemonic với password
  final String encryptedMnemonic = encryptDataAES(mnemonic, password);

  // Tạo seed từ mnemonic
  final seed = bip39.mnemonicToSeed(mnemonic);
  final root = bip32.BIP32.fromSeed(seed);

  // Chỉ số ví mới sẽ là độ dài danh sách ví hiện có
  int walletIndex = privateKeys.length;

  // Tạo ví mới (private key và address)
  final child = root.derivePath("m/44'/60'/0'/0/$walletIndex");  // Đường dẫn HD với chỉ số walletIndex

  final String privateKey = HEX.encode(child.privateKey!);  // Lấy private key dưới dạng hex

  final privateKeyBytes = Uint8List.fromList(HEX.decode(privateKey));
  // Tính địa chỉ Ethereum
  final address = ethereumAddressFromPrivateKey(privateKeyBytes);

  // Mã hóa private key với password
  final String encryptedPrivateKey = encryptDataAES(privateKey, password);

  // Thêm private key và địa chỉ vào danh sách
  privateKeys.add(encryptedPrivateKey);
  addresses.add(address);

  // Đặt tên ví mới theo mẫu "KTRWL-{index}"
  final String walletName = "KTRWL-$walletIndex";
  walletNames.add(walletName);

  // Tạo dữ liệu ví mới
  final walletData = {
    'encrypted_mnemonic': encryptedMnemonic,
    'encrypted_private_keys': privateKeys,
    'addresses': addresses,
    'wallet_names': walletNames, // Lưu danh sách tên ví
  };

  // Lưu dữ liệu ví mới vào file JSON
  await saveWalletToJson(walletData);
  print('Ví mới đã được lưu thành công');

  return walletData;
}

// Hàm chuyển đổi khóa công khai thành địa chỉ ví Ethereum
String ethereumAddressFromPublicKey(Uint8List publicKey) {
  final publicKeyBytes = publicKey.sublist(1);  // Bỏ byte đầu tiên (04) của khóa công khai
  final address = keccak256(publicKeyBytes).sublist(12);  // Lấy 20 byte cuối cùng của hàm băm keccak256
  return '0x${HEX.encode(address)}';
}

// Hàm import ví từ private key
Future<Map<String, dynamic>> importWalletFromPrivateKey(String privateKey, String password) async {
  try {
    // Chuyển đổi private key từ hex sang Uint8List
    final Uint8List privateKeyBytes = Uint8List.fromList(HEX.decode(privateKey));

    // Kiểm tra độ dài private key (Ethereum private key luôn có độ dài 32 bytes)
    if (privateKeyBytes.length != 32) {
      throw Exception('Private key không hợp lệ');
    }
    // Tạo Ethereum credentials từ private key
    final credentials = EthPrivateKey.fromHex(privateKey);

    // Lấy địa chỉ ví từ private key
    final ethAddress = await credentials.extractAddress();
    print('Địa chỉ ví từ private key: $ethAddress');

    // Tải dữ liệu ví hiện tại từ file JSON (nếu có)
    final existingWalletData = await loadWalletFromJson();

    List<String> privateKeys = [];
    List<String> addresses = [];
    List<String> walletNames = [];

    if (existingWalletData != null) {
      privateKeys = List<String>.from(existingWalletData['encrypted_private_keys']);
      addresses = List<String>.from(existingWalletData['addresses']);
      walletNames = List<String>.from(existingWalletData['wallet_names']);
    }

    // Mã hóa private key với password
    final String encryptedPrivateKey = encryptDataAES(privateKey, password);

    // Thêm private key và địa chỉ vào danh sách
    privateKeys.add(encryptedPrivateKey);
    addresses.add(ethAddress.hex);

    // Đặt tên ví mới theo mẫu "KTRWL-{index}"
    final int walletIndex = privateKeys.length - 1; // Số thứ tự của ví mới
    final String walletName = "KTRWL-$walletIndex";
    walletNames.add(walletName);

    // Tạo dữ liệu ví mới
    final walletData = {
      'encrypted_mnemonic': existingWalletData?['encrypted_mnemonic'] ?? '', // Nếu đã có mnemonic trước đó, giữ nguyên
      'encrypted_private_keys': privateKeys,
      'addresses': addresses,
      'wallet_names': walletNames, // Lưu danh sách tên ví
    };

    // Lưu dữ liệu ví mới vào file JSON
    await saveWalletToJson(walletData);
    print('Ví từ private key đã được lưu thành công');

    return walletData;
  } catch (e) {
    print("Lỗi khi import ví từ private key: $e");
    throw Exception('Import ví thất bại');
  }
}




// Hàm backup ví cho phép người dùng chọn đường dẫn để lưu tệp trên Windows
Future<void> backupWallet(String password, BuildContext context) async {
  // Tải dữ liệu ví từ file JSON
  final walletData = await loadWalletFromJson();

  if (walletData == null) {
    // Nếu không có ví nào được lưu trước đó
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No wallets available for backup.")),
    );
    return;
  }

  try {
    // Giải mã dữ liệu mnemonic và private key từ walletData
    final String decryptedMnemonic = decryptDataAES(walletData['encrypted_mnemonic'], password);

    // Giải mã danh sách private key
    List<String> decryptedPrivateKeys = [];
    for (String encryptedPrivateKey in walletData['encrypted_private_keys']) {
      final decryptedPrivateKey = decryptDataAES(encryptedPrivateKey, password);
      decryptedPrivateKeys.add(decryptedPrivateKey);
    }

    // Tạo nội dung file JSON cần backup (dạng mã hóa)
    final backupData = {
      'mnemonic': decryptedMnemonic,
      'private_keys': decryptedPrivateKeys,
      'addresses': walletData['addresses'],
      'wallet_names': walletData['wallet_names'],
    };

    // Sử dụng file_picker để chọn đường dẫn lưu file
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory == null) {
      // Người dùng không chọn đường dẫn hoặc đóng trình chọn file
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No directory selected.")),
      );
      return;
    }

    // Tạo file backup tại đường dẫn đã chọn
    final backupFile = File('$selectedDirectory/wallet_backup.json');
    await backupFile.writeAsString(jsonEncode(backupData));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Wallet backup saved as ${backupFile.path}")),
    );

  } catch (e) {
    // Nếu mật khẩu không đúng hoặc lỗi trong quá trình giải mã
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to backup wallet: Incorrect password or error occurred.")),
    );
    print("Error during wallet backup: $e");
  }
}