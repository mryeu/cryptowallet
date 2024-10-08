import 'package:flutter/material.dart';
import 'dart:async';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TransactionServiceMember {
  final String rpcUrl = 'https://special-burned-sky.bsc.quiknode.pro/de871b0cbc0b8feed0229ee21332597fca5b15c5';
  final EthereumAddress contractMemberAddress = EthereumAddress.fromHex("0xEfe8941a849719B2FB0bD6735F4c34e6a2103058");
  final EthereumAddress contractDataPlayAccess = EthereumAddress.fromHex("0x36b9FFf0F43686560f1eBb3C4C8eD992F063C28D");
  final EthereumAddress usdtContractAddress = EthereumAddress.fromHex('0x55d398326f99059fF775485246999027B3197955');

  late Web3Client web3;

  TransactionServiceMember() {
    web3 = Web3Client(rpcUrl, Client());
  }

  // Hàm thêm thành viên
  Future<String> addMember(String privateKey, EthereumAddress accountAddress, EthereumAddress refAddress) async {
    // ABI cho hàm addMember
    const contractAbi = '''
    [
      {
        "inputs": [
          {"internalType": "address", "name": "_member", "type": "address"},
          {"internalType": "address", "name": "_sponsor", "type": "address"}
        ],
        "name": "addMember",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      }
    ]
    ''';

    // Khởi tạo contract member
    final contractMember = DeployedContract(ContractAbi.fromJson(contractAbi, 'Member'), contractMemberAddress);
    final credentials = EthPrivateKey.fromHex(privateKey);

    // Lấy số nonce của tài khoản
    final nonce = await web3.getTransactionCount(accountAddress);

    // Tạo giao dịch cho hàm addMember
    final transaction = Transaction.callContract(
      contract: contractMember,
      function: contractMember.function('addMember'),
      parameters: [accountAddress, refAddress],
      from: accountAddress,
      nonce: nonce,
      gasPrice: EtherAmount.inWei(BigInt.from(1 * 1000000000)), // 1 gwei
      maxGas: 1000000,
    );

    // Ký giao dịch
    final signedTransaction = await web3.signTransaction(credentials, transaction, chainId: 56);

    // Gửi giao dịch
    final txHash = await web3.sendRawTransaction(signedTransaction);

    // In hash giao dịch để theo dõi
    print('Transaction hash: $txHash');

    return txHash;
  }


  Future<bool?> checkIsMember(String walletAddress) async {
    try {
      final contractAddress = EthereumAddress.fromHex('0xEfe8941a849719B2FB0bD6735F4c34e6a2103058'); // Địa chỉ hợp đồng
      const abi = '''
        [
          {
            "inputs": [
              {
                "internalType": "address",
                "name": "_addr",
                "type": "address"
              }
            ],
            "name": "isMember",
            "outputs": [
              {
                "internalType": "bool",
                "name": "",
                "type": "bool"
              }
            ],
            "stateMutability": "view",
            "type": "function"
          }
        ]
      ''';

      // Tạo contract từ ABI
      final contract = DeployedContract(ContractAbi.fromJson(abi, 'MemberContract'), contractAddress);
    
      // Tạo function từ contract
      final function = contract.function('isMember');

      // Gọi hàm isMember với tham số là địa chỉ ví
      final result = await web3.call(
        contract: contract,
        function: function,
        params: [EthereumAddress.fromHex(walletAddress)],
      );

      // Trả về kết quả (result là một mảng, phần tử đầu tiên sẽ là giá trị boolean)
      print('====> isMember $result');
      return result.first as bool;
    } catch (e) {
      print("An error occurred: $e");
      return false;
    } 
  }

// Function to handle the call to addAccessPlay
  Future<String> addDeposit(BuildContext context, String privateKey, EthereumAddress accountAddress) async {
    // ABI for the addAccessPlay function
    const playAbi = '''
    [
      {
        "inputs": [
          {"internalType": "uint256", "name": "amount", "type": "uint256"}
        ],
        "name": "addAccessPlay",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [],
        "name": "FEE",
        "outputs": [
          {
            "internalType": "uint256",
            "name": "",
            "type": "uint256"
          }
        ],
        "stateMutability": "view",
        "type": "function"
      }
    ]
    ''';

    const usdtAbi = '''
    [
      {
          "constant": false,
          "inputs": [
            {
              "name": "_spender",
              "type": "address"
            },
            {
              "name": "_value",
              "type": "uint256"
            }
          ],
          "name": "approve",
          "outputs": [],
          "payable": false,
          "stateMutability": "nonpayable",
          "type": "function"
        }
    ]
    ''';

    try {
      // Initialize USDT contract
      final usdtContract = DeployedContract(ContractAbi.fromJson(usdtAbi, 'USDT'), usdtContractAddress);
      final playContract = DeployedContract(ContractAbi.fromJson(playAbi, 'PlayContract'), contractDataPlayAccess);
      final credentials = EthPrivateKey.fromHex(privateKey);

      // Define the PlayAmount and amount to be passed
      final BigInt playAmount = BigInt.parse("32000000000000000000"); // 32 Ether (in Wei)
      final BigInt totalPlayAmount = playAmount * BigInt.from(15); // Multiply the play amount by 15
    
      // Call approve on USDT contract to allow play contract to spend tokens
      final approveFunction = usdtContract.function('approve');
      final nonce = await web3.getTransactionCount(accountAddress);

      final approveTransaction = Transaction.callContract(
        contract: usdtContract,
        function: approveFunction,
        parameters: [contractDataPlayAccess, totalPlayAmount],
        from: accountAddress,
        gasPrice: EtherAmount.inWei(BigInt.from(1 * 1000000000)), // 1 gwei
        maxGas: 1000000,
        nonce: nonce,
      );

      // Sign the approve transaction
      final signedApproveTransaction = await web3.signTransaction(credentials, approveTransaction, chainId: 56);

      // Send the approve transaction
      final approveTxHash = await web3.sendRawTransaction(signedApproveTransaction);
      print('Approval transaction hash: $approveTxHash');

      // Wait for approval to be mined (you might want to implement a way to wait for confirmation)

      // Get FEE from the play contract
      final feeFunction = playContract.function('FEE');
      final feeResult = await web3.call(
        contract: playContract,
        function: feeFunction,
        params: [],
      );
      BigInt FEE = BigInt.parse(feeResult.first.toString());

      // Calculate total fee based on the number of times
      BigInt totalFee = FEE * BigInt.from(15);
      print('======> fee totalFee $totalFee');

      // Call addAccessPlay function on play contract
      final addAccessPlayFunction = playContract.function('addAccessPlay');
      final playTransaction = Transaction.callContract(
        contract: playContract,
        function: addAccessPlayFunction,
        parameters: [totalPlayAmount],
        from: accountAddress,
        value: EtherAmount.inWei(totalFee), // Include the total fee in the transaction
        gasPrice: EtherAmount.inWei(BigInt.from(1 * 1000000000)), // 1 gwei
        maxGas: 1000000,
      );

      // Sign the addAccessPlay transaction
      final signedPlayTransaction = await web3.signTransaction(credentials, playTransaction, chainId: 56);

      // Send the play transaction
      final playTxHash = await web3.sendRawTransaction(signedPlayTransaction);
      print('addAccessPlay transaction hash: $playTxHash');

      return playTxHash;

    } catch (e) {
      print('An error occurred: $e');

// Check if the platform supports fluttertoast
      if (Theme.of(context).platform == TargetPlatform.iOS || Theme.of(context).platform == TargetPlatform.android) {
        // Show toast on mobile platforms
        // Fluttertoast.showToast(
        //   msg: "Error occurred: $e",
        //   toastLength: Toast.LENGTH_LONG,
        //   gravity: ToastGravity.BOTTOM,
        //   backgroundColor: Colors.red,
        //   textColor: Colors.white,
        //   fontSize: 16.0,
        // );
      } else {
        // Fallback for desktop (macOS/Windows) using SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }
}

void showTopToast(String message, bool success) {
  try {
    // Fluttertoast.showToast(
    //     msg: "This is Center Short Toast",
    //     toastLength: Toast.LENGTH_SHORT,
    //     gravity: ToastGravity.CENTER,
    //     timeInSecForIosWeb: 1,
    //     backgroundColor: Colors.red,
    //     textColor: Colors.white,
    //     fontSize: 16.0
    // );
  } catch(e) {
    print('error toast $e');
  }
}

void showTopRightSnackBar(BuildContext context, String message, bool success) {
  OverlayEntry? overlayEntry; // Declare as nullable

  // Initialize the overlayEntry directly
  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 20,
      right: 20,
      child: Material(
        color: Colors.white,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.white,
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: TextStyle(color: success ? Colors.green : Colors.red),
              )
            ],
          ),
        ),
      ),
    ),
  );

  // Insert the overlay into the Overlay widget
  Overlay.of(context)!.insert(overlayEntry);

  // Automatically remove the snackbar after 3 seconds
  Future.delayed(Duration(seconds: 3), () {
    overlayEntry?.remove();
  });
}
