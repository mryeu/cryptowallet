import 'dart:async';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TransactionService {
  final String rpcUrl = dotenv.env['PROVIDER_BSC']!;
  final String contractUsdtAddress = dotenv.env['CONTRACT_USDT']!;
  final String contractPlayAddress = dotenv.env['CONTRACT_PLAY']!;

  late Web3Client web3;

  TransactionService() {
    web3 = Web3Client(rpcUrl, Client());
  }

  // Hàm approve USDT
  Future<String> approveUsdt(String privateKey, EthereumAddress address) async {
    const contractAbiUsdt = '''
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

    final contractUsdt = DeployedContract(ContractAbi.fromJson(contractAbiUsdt, 'USDT'), EthereumAddress.fromHex(contractUsdtAddress));
    final credentials = EthPrivateKey.fromHex(privateKey);

    // Lấy nonce hiện tại
    final nonce = await web3.getTransactionCount(address);

    // Số lượng USDT cần approve (32 USDT)
    final BigInt amountEther = BigInt.from(32) * BigInt.from(10).pow(18);

    // Xây dựng giao dịch
    final transactionUsdt = Transaction.callContract(
      contract: contractUsdt,
      function: contractUsdt.function('approve'),
      parameters: [EthereumAddress.fromHex(contractPlayAddress), amountEther],
      from: address,
      nonce: nonce,
      gasPrice: EtherAmount.inWei(BigInt.one * BigInt.from(1000000000)), // 1 Gwei
      maxGas: 2000000,
    );

    // Ký giao dịch
    final signedTransaction = await web3.signTransaction(credentials, transactionUsdt, chainId: 56);

    // Gửi giao dịch và nhận hash
    final txHash = await web3.sendRawTransaction(signedTransaction);
    return txHash;
  }

  // Hàm call play sau khi approved USDT
  Future<String> callPlay(String privateKey, EthereumAddress address) async {
    // Gọi hàm approve trước khi thực hiện play
    final txHashApprove = await approveUsdt(privateKey, address);
    print("Approve transaction hash: $txHashApprove");

    // Đợi 7 giây để giao dịch approve hoàn tất
    await Future.delayed(Duration(seconds: 7));

    // ABI của hàm play
    const contractAbiPlay = '''
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

    final contractPlay = DeployedContract(ContractAbi.fromJson(contractAbiPlay, 'Play'), EthereumAddress.fromHex(contractPlayAddress));
    final credentials = EthPrivateKey.fromHex(privateKey);

    // Lấy số nonce hiện tại
    final nonce = await web3.getTransactionCount(address);

    // Xây dựng giao dịch cho hàm play
    final transactionPlay = Transaction.callContract(
      contract: contractPlay,
      function: contractPlay.function('play'),
      parameters: [],
      from: address,
      nonce: nonce,
      gasPrice: EtherAmount.inWei(BigInt.one * BigInt.from(1000000000)), // 1 Gwei
      maxGas: 2000000,
    );

    // Ký giao dịch
    final signedTransactionPlay = await web3.signTransaction(credentials, transactionPlay, chainId: 56);

    // Gửi giao dịch và nhận hash
    final txHashPlay = await web3.sendRawTransaction(signedTransactionPlay);
    return txHashPlay;
  }
}
