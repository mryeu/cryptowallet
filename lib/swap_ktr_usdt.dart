import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

Future<String?> buySellTokenKTR({
  required String walletAddress,
  required String privateKey,
  required bool isBuy,
  required int inputNumber,
}) async {
  try {
    // Kết nối tới Binance Smart Chain
    const bscUrl = 'https://smart-yolo-wildflower.bsc.quiknode.pro/15e23273e4927b475d4a2b0b40c1231d9c7b7e91';
    final Web3Client web3 = Web3Client(bscUrl, Client());

    // Địa chỉ hợp đồng và ABI
    final contractAddress = EthereumAddress.fromHex('0xF077aa6076a2EF52d041b41B6f38B7834CcbCde0');
    const abi = '''
      [
        {
          "inputs": [
            {"internalType": "uint256", "name": "tokenAmount", "type": "uint256"},
            {"internalType": "uint256", "name": "slippage", "type": "uint256"},
            {"internalType": "contract IERC20", "name": "tokenA", "type": "address"},
            {"internalType": "contract IERC20", "name": "tokenB", "type": "address"}
          ],
          "name": "Swap",
          "outputs": [],
          "stateMutability": "nonpayable",
          "type": "function"
        }
      ]
    ''';

    // ABI đơn giản cho ERC20 (để gọi hàm approve)
    const erc20Abi = '''
      [
        {
          "constant": false,
          "inputs": [
            {"name": "_spender", "type": "address"},
            {"name": "_value", "type": "uint256"}
          ],
          "name": "approve",
          "outputs": [{"name": "", "type": "bool"}],
          "type": "function"
        }
      ]
    ''';

    // Tạo contract từ ABI
    final contract = DeployedContract(ContractAbi.fromJson(abi, 'AccessSwap'), contractAddress);

    // Địa chỉ của tokenA và tokenB
    EthereumAddress tokenAAddress, tokenBAddress;
    if (isBuy) {
      // Buy KTR với USDT
      tokenAAddress = EthereumAddress.fromHex('0xa66cD1C4d890Faa7C1a09A54a254d33d809ba3b5'); // KTR
      tokenBAddress = EthereumAddress.fromHex('0x55d398326f99059fF775485246999027B3197955'); // USDT
    } else {
      // Sell KTR lấy USDT
      tokenAAddress = EthereumAddress.fromHex('0x55d398326f99059fF775485246999027B3197955'); // USDT
      tokenBAddress = EthereumAddress.fromHex('0xa66cD1C4d890Faa7C1a09A54a254d33d809ba3b5'); // KTR
    }

    // Số lượng token KTR hoặc USDT (đơn vị wei)
    final tokenAmount = BigInt.from(inputNumber) * BigInt.from(10).pow(18);
    final slippage = BigInt.from(1000);

    // Lấy nonce của giao dịch
    final credentials = EthPrivateKey.fromHex(privateKey);
    final nonce = await web3.getTransactionCount(EthereumAddress.fromHex(walletAddress));

    // Tạo contract token để gọi approve
    final tokenContract = DeployedContract(ContractAbi.fromJson(erc20Abi, 'ERC20'), tokenAAddress);
    final approveFunction = tokenContract.function('approve');

    // Thực hiện approve token cho contract swap
    final approveTransaction = Transaction.callContract(
      contract: tokenContract,
      function: approveFunction,
      parameters: [contractAddress, tokenAmount],
      from: EthereumAddress.fromHex(walletAddress),
      gasPrice: await web3.getGasPrice(),
      maxGas: 100000,
      nonce: nonce,
    );

    // Ký và gửi giao dịch approve
    final approveSignedTransaction = await web3.signTransaction(credentials, approveTransaction, chainId: 56);
    final approveTxHash = await web3.sendRawTransaction(approveSignedTransaction);
    print("Approve transaction successful with hash: $approveTxHash");

    // Chờ giao dịch approve được xử lý
    await _waitForTransactionReceipt(web3, approveTxHash);

    // Ước lượng gas cho giao dịch swap
    final function = contract.function('Swap');
    final gasPrice = await web3.getGasPrice();
    final gasEstimate = await web3.estimateGas(
      sender: EthereumAddress.fromHex(walletAddress),
      to: contractAddress,
      data: function.encodeCall([tokenAmount, slippage, tokenAAddress, tokenBAddress]),
    );

    // Tạo transaction cho swap
    final swapTransaction = Transaction.callContract(
      contract: contract,
      function: function,
      parameters: [tokenAmount, slippage, tokenAAddress, tokenBAddress],
      from: EthereumAddress.fromHex(walletAddress),
      gasPrice: gasPrice,
      maxGas: gasEstimate.toInt() + 100000,
      nonce: nonce + 1,
    );

    // Ký và gửi giao dịch swap
    final swapSignedTransaction = await web3.signTransaction(credentials, swapTransaction, chainId: 56);
    final txHash = await web3.sendRawTransaction(swapSignedTransaction);
    print("Swap transaction successful with hash: $txHash");

    // Đợi kết quả giao dịch swap
    await _waitForTransactionReceipt(web3, txHash);

    return txHash;
  } catch (e) {
    print("An error occurred: $e");
    return null;
  }
}

// Hàm chờ giao dịch được xử lý
Future<void> _waitForTransactionReceipt(Web3Client web3, String txHash) async {
  final maxTries = 10;
  for (int i = 0; i < maxTries; i++) {
    final txReceipt = await web3.getTransactionReceipt(txHash);
    if (txReceipt != null && txReceipt.status!) {
      print("Transaction mined with success");
      return;
    } else {
      print("Waiting for transaction to be mined... Attempt ${i + 1}/$maxTries");
      await Future.delayed(const Duration(seconds: 3)); // Chờ 3 giây trước khi kiểm tra lại
    }
  }
  throw Exception("Transaction failed or timed out");
}
