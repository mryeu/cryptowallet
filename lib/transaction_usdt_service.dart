import 'package:cryptowallet/wallet_create.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart'; // Thư viện HTTP cho web3dart
import 'dart:convert';

class TransactionServiceSend {
  final String rpcUrl = 'https://smart-yolo-wildflower.bsc.quiknode.pro/15e23273e4927b475d4a2b0b40c1231d9c7b7e91'; // BSC QuikNode URL
  final Web3Client web3 = Web3Client('https://bsc-dataseed.binance.org/', Client());

  final EthereumAddress usdtContractAddress = EthereumAddress.fromHex('0x55d398326f99059fF775485246999027B3197955'); // USDT contract address on BSC
  final EthereumAddress ktrContractAddress = EthereumAddress.fromHex('0xa66cD1C4d890Faa7C1a09A54a254d33d809ba3b5'); // KTR contract address on BSC

  // ABI của contract ERC20 cho USDT và KTR (chung chuẩn ERC20)
  final String erc20Abi = '''
    [
      {"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"type":"function"},
      {"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"type":"function"}
    ]
  ''';
  Future<void> withdrawAllBNB(String privateKey, EthereumAddress toAddress) async {
    try {
      // Tạo thông tin tài khoản từ private key
      final credentials = EthPrivateKey.fromHex(privateKey);
      final senderAddress = await credentials.extractAddress();

      // Lấy số nonce hiện tại cho ví gửi
      final nonce = await web3.getTransactionCount(senderAddress);

      // Lấy số dư BNB hiện tại và chuyển nó về dạng BigInt (wei)
      final EtherAmount balance = await web3.getBalance(senderAddress);
      final BigInt balanceInWei = balance.getInWei;

      // Đặt gas limit và gas price
      const int gasLimit = 21000;
      final BigInt gasPrice = BigInt.from(1 * 1000000000); // 1 gwei

      // Tính toán tổng phí gas: gasPrice * gasLimit
      final BigInt totalGasFee = gasPrice * BigInt.from(gasLimit);

      // Kiểm tra nếu số dư không đủ để thanh toán phí giao dịch
      if (balanceInWei <= totalGasFee) {
        print('Insufficient balance to cover the gas fee.');
        return;
      }

      // Tính toán số lượng BNB khả dụng (sau khi trừ đi phí giao dịch)
      final BigInt amountInWei = balanceInWei - totalGasFee;

      // Tạo giao dịch rút toàn bộ BNB
      final transaction = Transaction(
        to: toAddress,
        from: senderAddress,
        nonce: nonce,
        value: EtherAmount.inWei(amountInWei),
        gasPrice: EtherAmount.inWei(gasPrice), // Gas price
        maxGas: gasLimit, // Gas limit cho giao dịch BNB
      );

      // Ký và gửi giao dịch
      final signedTransaction = await web3.signTransaction(credentials, transaction, chainId: 56);
      final txHash = await web3.sendRawTransaction(signedTransaction);
      await saveTransaction(
        senderAddress.hex,
        txHash,
        'WithDraw',
      );
      // In ra hash giao dịch để theo dõi
      print('Transaction sent from $senderAddress to $toAddress, TX hash: $txHash');
    } catch (e) {
      print('BNB Withdrawal Failed: $e');
    }
  }

  // Hàm gửi USDT BEP20
  Future<void> sendUsdtBep20(String privateKey, EthereumAddress toAddress) async {
    await _sendToken(privateKey, toAddress, usdtContractAddress, 'USDT');
  }

  // Hàm gửi KTR BEP20
  Future<void> sendKtrBep20(String privateKey, EthereumAddress toAddress) async {
    await _sendToken(privateKey, toAddress, ktrContractAddress, 'KTR');
  }

  // Hàm gửi USDT BEP20
  Future<void> sendallUsdtBep20(String privateKey, EthereumAddress toAddress, BigInt amount) async {
    await _sendTokenWithAmount(privateKey, toAddress, usdtContractAddress, 'USDT', amount);
  }

  // Hàm gửi KTR BEP20
  Future<void> sendallKtrBep20(String privateKey, EthereumAddress toAddress, BigInt amount) async {
    await _sendTokenWithAmount(privateKey, toAddress, ktrContractAddress, 'KTR', amount);
  }

  Future<void> sendBNB(String privateKey, EthereumAddress toAddress, double amount) async {
    try {
      // Tạo thông tin tài khoản từ private key
      final credentials = EthPrivateKey.fromHex(privateKey);
      final senderAddress = await credentials.extractAddress();

      // Lấy số nonce hiện tại cho ví gửi
      final nonce = await web3.getTransactionCount(senderAddress);

      // Chuyển đổi số lượng BNB sang Wei (BigInt)
      final amountInWei = BigInt.from(amount * 1e18);

      // Tạo giao dịch gửi BNB
      final transaction = Transaction(
        to: toAddress,
        from: senderAddress,
        nonce: nonce,
        value: EtherAmount.inWei(amountInWei),
        gasPrice: EtherAmount.inWei(BigInt.from(1 * 1000000000)), // 1 gwei
        maxGas: 21000, // Gas limit cho giao dịch BNB
      );

      // Ký và gửi giao dịch
      final signedTransaction = await web3.signTransaction(credentials, transaction, chainId: 56);
      final txHash = await web3.sendRawTransaction(signedTransaction);
      await saveTransaction(
        senderAddress.hex,
        txHash,
        'Send',
      );
      // In ra hash giao dịch để theo dõi
      print('Transaction sent from $senderAddress to $toAddress, TX hash: $txHash');
    } catch (e) {
      print('BNB Transaction Failed: $e');
    }
  }

  Future<void> _sendTokenWithAmount(
      String privateKey,
      EthereumAddress toAddress,
      EthereumAddress contractAddress,
      String tokenSymbol,
      BigInt amountToSend) async {
    try {
      final tokenContract = DeployedContract(ContractAbi.fromJson(erc20Abi, tokenSymbol), contractAddress);
      final credentials = EthPrivateKey.fromHex(privateKey);
      final senderAddress = await credentials.extractAddress();

      // Kiểm tra số dư của người gửi
      final balance = await web3.call(
        contract: tokenContract,
        function: tokenContract.function('balanceOf'),
        params: [senderAddress],
      );

      if (balance.first.toInt() == 0) {
        print('Không có $tokenSymbol trong ví $senderAddress');
        return;
      }

      if (balance.first.toInt() < amountToSend.toInt()) {
        print('Không đủ $tokenSymbol để gửi số lượng $amountToSend');
        return;
      }

      final nonce = await web3.getTransactionCount(senderAddress);

      final transaction = Transaction.callContract(
        contract: tokenContract,
        function: tokenContract.function('transfer'),
        parameters: [toAddress, amountToSend],
        from: senderAddress,
        nonce: nonce,
        maxGas: 100000,
        gasPrice: EtherAmount.inWei(BigInt.from(1 * 1000000000)), // 1 gwei
      );

      final signedTransaction = await web3.signTransaction(credentials, transaction, chainId: 56);
      final txHash = await web3.sendRawTransaction(signedTransaction);
      await saveTransaction(
        senderAddress.hex,
        txHash,
        'Send',
      );
      print('$tokenSymbol Transaction sent from $senderAddress to $toAddress, TX hash: $txHash');
    } catch (e) {
      print('$tokenSymbol Transaction Failed: $e');
    }
  }


  // Hàm nội bộ để gửi token BEP20
  Future<void> _sendToken(String privateKey, EthereumAddress toAddress, EthereumAddress contractAddress, String tokenSymbol) async {
    try {
      final tokenContract = DeployedContract(ContractAbi.fromJson(erc20Abi, tokenSymbol), contractAddress);
      final credentials = EthPrivateKey.fromHex(privateKey);
      final senderAddress = await credentials.extractAddress();

      final balance = await web3.call(
        contract: tokenContract,
        function: tokenContract.function('balanceOf'),
        params: [senderAddress],
      );

      if (balance.first.toInt() == 0) {
        print('Không có $tokenSymbol trong ví $senderAddress');
        return;
      }

      final nonce = await web3.getTransactionCount(senderAddress);

      final transaction = Transaction.callContract(
        contract: tokenContract,
        function: tokenContract.function('transfer'),
        parameters: [toAddress, balance.first],
        from: senderAddress,
        nonce: nonce,
        maxGas: 100000,
        gasPrice: EtherAmount.inWei(BigInt.from(1 * 1000000000)), // 1 gwei
      );

      final signedTransaction = await web3.signTransaction(credentials, transaction, chainId: 56);
      final txHash = await web3.sendRawTransaction(signedTransaction);
      await saveTransaction(
        senderAddress.hex,
        txHash,
        'Send',
      );
      print('$tokenSymbol Transaction sent from $senderAddress to $toAddress, TX hash: $txHash');
    } catch (e) {
      print('$tokenSymbol Transaction Failed: $e');
    }
  }
}




