import 'dart:ffi';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'dart:math';

import '../swap_ktr_usdt.dart'; // Import for using the pow function

class MemberService {
  final String rpcUrl = 'https://autumn-hidden-energy.bsc.quiknode.pro/9c02ac546716d9eb7dfec7226dd03270a924d3c3';
  final EthereumAddress contractMemberAddress = EthereumAddress.fromHex(
      "0xEfe8941a849719B2FB0bD6735F4c34e6a2103058");
  final EthereumAddress contractDataPlayAccess = EthereumAddress.fromHex(
      "0x36b9FFf0F43686560f1eBb3C4C8eD992F063C28D");
  final EthereumAddress usdtContractAddress = EthereumAddress.fromHex(
      '0x55d398326f99059fF775485246999027B3197955');
  final EthereumAddress contractDataPlayAddress = EthereumAddress.fromHex(
      '0x0f80cE9e485996e339134969634613CFFAb6a6df');
  final EthereumAddress contractDataAddress = EthereumAddress.fromHex(
      '0xF871c38C6505Fb96a40164424aEa2178c0C7cfB6');
  final EthereumAddress contractClaimAddress = EthereumAddress.fromHex(
      '0xCe0FE6d980914292804AdbEC0f55392712953b74');

  late Web3Client web3;

  MemberService() {
    web3 = Web3Client(rpcUrl, Client());
  }

  // Hàm thêm thành viên
  Future<String> addMember(String privateKey, EthereumAddress accountAddress,
      EthereumAddress refAddress) async {
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
    final contractMember = DeployedContract(
        ContractAbi.fromJson(contractAbi, 'Member'), contractMemberAddress);
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
      gasPrice: EtherAmount.inWei(BigInt.from(1 * 1000000000)),
      // 1 gwei
      maxGas: 1000000,
    );

    // Ký giao dịch
    final signedTransaction = await web3.signTransaction(
        credentials, transaction, chainId: 56);

    // Gửi giao dịch
    final txHash = await web3.sendRawTransaction(signedTransaction);

    // In hash giao dịch để theo dõi
    print('Transaction hash: $txHash');

    return txHash;
  }

  Future<bool?> checkIsMember(String walletAddress) async {
    try {
      final contractAddress = EthereumAddress.fromHex(
          '0xEfe8941a849719B2FB0bD6735F4c34e6a2103058'); // Địa chỉ hợp đồng
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
      final contract = DeployedContract(
          ContractAbi.fromJson(abi, 'MemberContract'), contractAddress);

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
  Future<String> addDeposit(BuildContext context, String privateKey,
      EthereumAddress accountAddress) async {
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
      final usdtContract = DeployedContract(
          ContractAbi.fromJson(usdtAbi, 'USDT'), usdtContractAddress);
      final playContract = DeployedContract(
          ContractAbi.fromJson(playAbi, 'PlayContract'),
          contractDataPlayAccess);
      final credentials = EthPrivateKey.fromHex(privateKey);

      // Define the PlayAmount and amount to be passed
      final BigInt playAmount = BigInt.parse(
          "32000000000000000000"); // 32 Ether (in Wei)
      final BigInt totalPlayAmount = playAmount *
          BigInt.from(15); // Multiply the play amount by 15

      // Call approve on USDT contract to allow play contract to spend tokens
      final approveFunction = usdtContract.function('approve');
      final nonce = await web3.getTransactionCount(accountAddress);

      final approveTransaction = Transaction.callContract(
        contract: usdtContract,
        function: approveFunction,
        parameters: [contractDataPlayAccess, totalPlayAmount],
        from: accountAddress,
        gasPrice: EtherAmount.inWei(BigInt.from(1 * 1000000000)),
        // 1 gwei
        maxGas: 1000000,
        nonce: nonce,
      );

      // Sign the approve transaction
      final signedApproveTransaction = await web3.signTransaction(
          credentials, approveTransaction, chainId: 56);

      // Send the approve transaction
      final approveTxHash = await web3.sendRawTransaction(
          signedApproveTransaction);
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
        value: EtherAmount.inWei(totalFee),
        // Include the total fee in the transaction
        gasPrice: EtherAmount.inWei(BigInt.from(1 * 1000000000)),
        // 1 gwei
        maxGas: 1000000,
      );

      // Sign the addAccessPlay transaction
      final signedPlayTransaction = await web3.signTransaction(
          credentials, playTransaction, chainId: 56);

      // Send the play transaction
      final playTxHash = await web3.sendRawTransaction(signedPlayTransaction);
      print('addAccessPlay transaction hash: $playTxHash');

      return playTxHash;
    } catch (e) {
      print('An error occurred: $e');

// Check if the platform supports fluttertoast
      if (Theme
          .of(context)
          .platform == TargetPlatform.iOS || Theme
          .of(context)
          .platform == TargetPlatform.android) {
        // Show toast on mobile platforms

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


  // Function to get Play Balance for a specific address
  Future<Map<String, int>> getPlayBalance(String walletAddress) async {
    try {
      // ABI for the PlayBalances function
      const playBalanceAbi = '''
      [
        {
          "inputs": [
            {"internalType": "address", "name": "", "type": "address"}
          ],
          "name": "PlayBalances",
          "outputs": [
            {"internalType": "uint256", "name": "amounted", "type": "uint256"},
            {"internalType": "uint256", "name": "amount", "type": "uint256"}
          ],
          "stateMutability": "view",
          "type": "function"
        }
      ]
      ''';

      // Initialize the PlayContract
      final playContract = DeployedContract(
        ContractAbi.fromJson(playBalanceAbi, 'PlayContract'),
        contractDataPlayAddress,
      );

      // Define the PlayBalances function
      final playBalanceFunction = playContract.function('PlayBalances');

      // Call the PlayBalances function with the wallet address
      final result = await web3.call(
        contract: playContract,
        function: playBalanceFunction,
        params: [EthereumAddress.fromHex(walletAddress)],
      );

      // The result is an array with "amounted" and "amount" in BigInt form
      BigInt amountedWei = result[0] as BigInt; // "amounted" value
      BigInt amountWei = result[1] as BigInt; // "amount" value

      // Convert from Wei to Ether or token units (dividing by 10^18)
      int amounted = (amountedWei / BigInt.from(pow(10, 18))).toInt();
      int amount = (amountWei / BigInt.from(pow(10, 18))).toInt();

      // Return the results as a map
      return {
        "amounted": amounted,
        "amount": amount,
      };
    } catch (e) {
      print("Error getting play balance: $e");
      return {
        "amounted": 0,
        "amount": 0,
      };
    }
  }

  Future<Map<String, dynamic>> getUserInfo(String walletAddress) async {
    try {
      // ABI for the userInfo function
      const userInfoAbi = '''
      [
        {
          "inputs": [
            {"internalType": "address", "name": "", "type": "address"}
          ],
          "name": "userInfo",
          "outputs": [
            {"internalType": "uint64", "name": "totalVote", "type": "uint64"},
            {"internalType": "uint64", "name": "totalClaim", "type": "uint64"},
            {"internalType": "bool", "name": "check", "type": "bool"}
          ],
          "stateMutability": "view",
          "type": "function"
        }
      ]
      ''';

      // Initialize the contract
      final contract = DeployedContract(
        ContractAbi.fromJson(userInfoAbi, 'DataContract'),
        contractDataAddress,
      );

      // Define the userInfo function
      final userInfoFunction = contract.function('userInfo');

      // Call the userInfo function with the wallet address
      final result = await web3.call(
        contract: contract,
        function: userInfoFunction,
        params: [EthereumAddress.fromHex(walletAddress)],
      );

      // Parse the result: totalVote, totalClaim, and check
      BigInt totalVote = result[0] as BigInt;
      BigInt totalClaim = result[1] as BigInt;
      bool check = result[2] as bool;

      // Return the results in a readable format
      return {
        "totalVote": totalVote.toInt(),
        // Convert BigInt to int for easier handling
        "totalClaim": totalClaim.toInt(),
        // Convert BigInt to int for easier handling
        "check": check
        // Boolean result as is
      };
    } catch (e) {
      print("Error getting user info: $e");
      rethrow;
    }
  }

  Future<String> approveAndPlay(String privateKey,
      EthereumAddress accountAddress) async {
    try {
      // ABI cho hàm approve trong hợp đồng USDT
      const usdtAbi = '''
    [
      {
        "constant": false,
        "inputs": [
          {"name": "_spender", "type": "address"},
          {"name": "_value", "type": "uint256"}
        ],
        "name": "approve",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
      }
    ]
    ''';

      // ABI cho hàm play
      const playAbi = '''
    [
      {
        "inputs": [],
        "name": "play",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      }
    ]
    ''';

      final credentials = EthPrivateKey.fromHex(privateKey);

      // Bước 1: Approve 32 USDT
      final usdtContract = DeployedContract(
          ContractAbi.fromJson(usdtAbi, 'USDT'), usdtContractAddress);
      final approveFunction = usdtContract.function('approve');
      final BigInt amountToApprove = BigInt.parse("32000000000000000000");
      print('======approve $amountToApprove $accountAddress $privateKey');

      final nonce = await web3.getTransactionCount(accountAddress);
      final approveTransaction = Transaction.callContract(
        contract: usdtContract,
        function: approveFunction,
        parameters: [contractDataPlayAccess, amountToApprove],
        from: accountAddress,
        gasPrice: EtherAmount.inWei(BigInt.from(1 * 1000000000)),
        maxGas: 100000,
        nonce: nonce,
      );

      final approveTxHash = await _signAndSendTransaction(
          credentials, approveTransaction);
      print('Approval transaction hash: $approveTxHash');

      // Bước 2: Gọi hàm play sau khi approve
      final playContract = DeployedContract(
          ContractAbi.fromJson(playAbi, 'PlayContract'),
          contractDataPlayAccess);
      final playFunction = playContract.function('play');

      final playTransaction = Transaction.callContract(
        contract: playContract,
        function: playFunction,
        parameters: [],
        from: accountAddress,
        gasPrice: EtherAmount.inWei(BigInt.from(1 * 1000000000)),
        maxGas: 1000000,
      );

      final playTxHash = await _signAndSendTransaction(
          credentials, playTransaction);
      print('Play transaction hash: $playTxHash');

      return playTxHash;
    } catch (e) {
      print('An error occurred: $e');
      rethrow;
    }
  }

  Future<String> onClaim(String privateKey, EthereumAddress accountAddress, int day) async {
    try {
      // Validate inputs before proceeding
      if (privateKey.isEmpty) {
        throw ArgumentError('Private key is required.');
      }
      if (day < 0) {
        throw ArgumentError('Day must be a positive integer.');
      }

      // ABI for claim function
      const claimAbi = '''
    [
      {
        "inputs": [
          {"internalType": "uint256", "name": "day", "type": "uint256"}
        ],
        "name": "claim",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
      }
    ]
    ''';

      // Create contract instance
      DeployedContract? claimContract;
      try {
        claimContract = DeployedContract(
          ContractAbi.fromJson(claimAbi, 'ClaimContract'),
          contractClaimAddress,
        );
      } catch (e) {
        throw Exception('Failed to create contract: $e');
      }

      // Access claim function from contract
      final claimFunction = claimContract.function('claim');

      // Convert private key to credentials
      EthPrivateKey? credentials;
      try {
        credentials = EthPrivateKey.fromHex(privateKey);
      } catch (e) {
        throw Exception('Invalid private key format: $e');
      }

      // Get transaction nonce
      int? nonce;
      try {
        nonce = await web3.getTransactionCount(accountAddress);
      } catch (e) {
        throw Exception('Failed to retrieve transaction nonce: $e');
      }

      // Set gas price and value
      final EtherAmount gasPrice = EtherAmount.inWei(BigInt.from(1000000000)); // 1 Gwei
      final EtherAmount value = EtherAmount.inWei(BigInt.from(300000000000000)); // Value for the claim

      // Prepare transaction
      Transaction? transaction;
      try {
        transaction = Transaction.callContract(
          contract: claimContract,
          function: claimFunction,
          parameters: [BigInt.from(day)],
          from: accountAddress,
          gasPrice: gasPrice,
          maxGas: 300000,
          value: value,
          nonce: nonce,
        );
      } catch (e) {
        throw Exception('Failed to create transaction: $e');
      }

      // Sign and send the transaction
      String? txHash;
      try {
        txHash = await _signAndSendTransaction(credentials, transaction);
      } catch (e) {
        throw Exception('Failed to sign or send transaction: $e');
      }

      print('Claim transaction hash: $txHash');
      return txHash;
    } catch (e) {
      // General error handling
      print('An error occurred during the claim process: $e');
      return 'Error: ${e.toString()}';
    }
  }

  Future<String?>  swapKTRToUSDT({
    required String walletAddress,
    required String privateKey,
    required int inputNumber,
  }) async {
    try {
      String? txHash = await buySellTokenKTR(walletAddress: walletAddress, privateKey: privateKey, isBuy: true, inputNumber: inputNumber);
      print('=======sưap $walletAddress $privateKey $inputNumber $txHash');
      return txHash;
    }
    catch(e) {
      print('===>error swap $e');
    }
  }

  Future<void> executeActionsForWallets(
      List<Map<String, String>> wallets,
      double amount,
      ) async {
    for (var wallet in wallets) {
      String walletAddress = wallet['address'] ?? '';
      String privateKey = wallet['privateKey'] ?? '';

      try {
        // 1. Thực hiện Claim
        print('Starting claim for wallet: $walletAddress');
        String claimTxHash = await onClaim(
          privateKey,
          EthereumAddress.fromHex(walletAddress),
          1,
        );
        print('Claim transaction hash: $claimTxHash');

        await Future.delayed(const Duration(seconds: 10));

        print('Starting swap for wallet: $walletAddress with amount: $amount');
        String? swapTxHash = await swapKTRToUSDT(
          walletAddress: walletAddress,
          privateKey: privateKey,
          inputNumber: amount.toInt(),
        );
        if (swapTxHash != null) {
          print('Swap transaction hash: $swapTxHash');
        } else {
          print('Swap failed for wallet: $walletAddress');
        }

        await Future.delayed(const Duration(seconds: 10));

        // 3. Thực hiện Play
        print('Starting play for wallet: $walletAddress');
        String playTxHash = await approveAndPlay(
          privateKey,
          EthereumAddress.fromHex(walletAddress),
        );
        print('Play transaction hash: $playTxHash');

        await Future.delayed(const Duration(seconds: 10));
      } catch (e) {
        print('An error occurred for wallet: $walletAddress - $e');
      }
    }
  }


// Hàm hỗ trợ ký và gửi giao dịch để giảm lặp lại
  Future<String> _signAndSendTransaction(EthPrivateKey credentials,
      Transaction transaction) async {
    final signedTransaction = await web3.signTransaction(
        credentials, transaction, chainId: 56);
    return await web3.sendRawTransaction(signedTransaction);
  }

  // Function to get the vote details
  Future<Map<String, dynamic>> getVote(String walletAddress, int day) async {
    try {
      const votesAbi = '''
      [
        {
          "inputs": [
            {
              "internalType": "address",
              "name": "",
              "type": "address"
            },
            {
              "internalType": "uint256",
              "name": "",
              "type": "uint256"
            }
          ],
          "name": "votes",
          "outputs": [
            {
              "internalType": "uint16",
              "name": "percent",
              "type": "uint16"
            },
            {
              "internalType": "bool",
              "name": "claimed",
              "type": "bool"
            }
          ],
          "stateMutability": "view",
          "type": "function"
        }
      ]
      ''';
      final contract = DeployedContract(
        ContractAbi.fromJson(votesAbi, 'VoteContract'),
        contractDataAddress,
      );

      // Get the votes function from the contract
      final voteFunction = contract.function('votes');

      // Call the contract function with the wallet address and day
      final result = await web3.call(
        contract: contract,
        function: voteFunction,
        params: [EthereumAddress.fromHex(walletAddress), BigInt.from(day)],
      );

      // Extract the result (percent and claimed)
      final percent = result[0] as BigInt;
      final claimed = result[1] as bool;

      // Return a map containing the vote details
      return {
        'percent': percent.toInt(), // Convert BigInt to int
        'claimed': claimed,
      };
    } catch (e) {
      print('Error getting vote: $e');
      throw Exception('Failed to get vote');
    }
  }
}



  void showTopToast(String message, bool success) {
  try {

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
          padding: const EdgeInsets.all(16),
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
