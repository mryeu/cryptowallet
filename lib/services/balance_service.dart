import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class TokenBalanceChecker {
  final String bscUrl =
      'https://smart-yolo-wildflower.bsc.quiknode.pro/15e23273e4927b475d4a2b0b40c1231d9c7b7e91';
  final String usdtContractAddress = '0x55d398326f99059fF775485246999027B3197955';
  final String ktrContractAddress = '0xa66cD1C4d890Faa7C1a09A54a254d33d809ba3b5';

  late Web3Client web3client;

  TokenBalanceChecker() {
    web3client = Web3Client(bscUrl, Client());
  }

  Future<double?> getBnbBalance(String walletAddress) async {
    try {
      EthereumAddress address = EthereumAddress.fromHex(walletAddress);
      EtherAmount balanceWei = await web3client.getBalance(address);
      double balanceBnb = balanceWei.getValueInUnit(EtherUnit.ether);
      return balanceBnb;
    } catch (e) {
      print('Error fetching BNB balance: $e');
      return null;
    }
  }

  Future<double?> getUsdtBalance(String walletAddress) async {
    try {
      final contractAddress = EthereumAddress.fromHex(usdtContractAddress);
      final wallet = EthereumAddress.fromHex(walletAddress);

      const erc20Abi = '''
      [
        {"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}
      ]
      ''';

      final contract = DeployedContract(
          ContractAbi.fromJson(erc20Abi, 'USDT'), contractAddress);
      final balanceFunction = contract.function('balanceOf');
      final result = await web3client.call(
        contract: contract,
        function: balanceFunction,
        params: [wallet],
      );

      final balance = result.first as BigInt;
      final usdtBalance = balance / BigInt.from(10).pow(18);
      return usdtBalance.toDouble();
    } catch (e) {
      print('Error fetching USDT balance: $e');
      return null;
    }
  }

  Future<double?> getKtrBalance(String walletAddress) async {
    try {
      final contractAddress = EthereumAddress.fromHex(ktrContractAddress);
      final wallet = EthereumAddress.fromHex(walletAddress);

      const ktrAbi = '''
      [
        {"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}
      ]
      ''';

      final contract = DeployedContract(
          ContractAbi.fromJson(ktrAbi, 'KTR'), contractAddress);
      final balanceFunction = contract.function('balanceOf');
      final result = await web3client.call(
        contract: contract,
        function: balanceFunction,
        params: [wallet],
      );

      final balance = result.first as BigInt;
      final ktrBalance = balance / BigInt.from(10).pow(18); // KTR thường có 18 chữ số thập phân
      return ktrBalance.toDouble();
    } catch (e) {
      print('Error fetching KTR balance: $e');
      return null;
    }
  }

  Future<Map<String, double>> loadBalances(String walletAddress) async {
    TokenBalanceChecker checker = TokenBalanceChecker();
    double? bnb = await checker.getBnbBalance(walletAddress);
    double? usdt = await checker.getUsdtBalance(walletAddress);
    double? ktr = await checker.getKtrBalance(walletAddress);
    return {
      "bnb": bnb ?? 0.0,
      "usdt": usdt ?? 0.0,
      "ktr": ktr ?? 0.0,
    };
  }
}
