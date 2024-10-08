import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart'; // Sử dụng HTTP client cho web3dart

Future<String> checkPriceBNB(double bnbAmount) async  {
  const String bscUrl = 'https://bsc-dataseed.binance.org/';  // Sử dụng node RPC của BSC
  final Web3Client web3client = Web3Client(bscUrl, Client());

  final pancakeswapRouterAddress =
  EthereumAddress.fromHex('0x10ED43C718714eb63d5aA57B78B54704E256024E');  // PancakeSwap Router V2

  const routerAbi = '''
    [
      {
        "inputs":[
          {"internalType":"uint256","name":"amountIn","type":"uint256"},
          {"internalType":"address[]","name":"path","type":"address[]"}
        ],
        "name":"getAmountsOut",
        "outputs":[
          {"internalType":"uint256[]","name":"","type":"uint256[]"}
        ],
        "stateMutability":"view",
        "type":"function"
      }
    ]
    ''';

  final contract = DeployedContract(
    ContractAbi.fromJson(routerAbi, 'PancakeSwapRouter'),
    pancakeswapRouterAddress,
  );

  final wbnbAddress =
  EthereumAddress.fromHex('0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c');  // Địa chỉ WBNB toàn chữ thường
  final usdtAddress =
  EthereumAddress.fromHex('0x55d398326f99059fF775485246999027B3197955');  // Địa chỉ USDT

  final path = [wbnbAddress, usdtAddress];

  // Số lượng BNB bạn muốn kiểm tra
  final amountIn = BigInt.from(bnbAmount * 1e18);  // amountBNB là số BNB bạn muốn kiểm tra

  final getAmountsOut = contract.function('getAmountsOut');

  try {
    final result = await web3client.call(
      contract: contract,
      function: getAmountsOut,
      params: [amountIn, path],
    );

    final priceInUsdt = result[0] as List;
    final priceInUsdtReal = priceInUsdt.last / BigInt.from(10).pow(18);

    return priceInUsdtReal.toString();
  } catch (e) {
    return "Error: $e";
  }
}




Future<String> checkPriceKTR(double amountKTR) async {
  const String bscUrl =
      'https://smart-yolo-wildflower.bsc.quiknode.pro/15e23273e4927b475d4a2b0b40c1231d9c7b7e91';
  final Web3Client web3client = Web3Client(bscUrl, Client());

  final pancakeswapRouterAddress =
  EthereumAddress.fromHex('0x10ED43C718714eb63d5aA57B78B54704E256024E');
  const routerAbi = '''
    [
      {
        "inputs":[
          {"internalType":"uint256","name":"amountIn","type":"uint256"},
          {"internalType":"address[]","name":"path","type":"address[]"}
        ],
        "name":"getAmountsOut",
        "outputs":[
          {"internalType":"uint256[]","name":"","type":"uint256[]"}
        ],
        "stateMutability":"view",
        "type":"function"
      }
    ]
    ''';

  final contract = DeployedContract(
    ContractAbi.fromJson(routerAbi, 'PancakeSwapRouter'),
    pancakeswapRouterAddress,
  );

  final usdtAddress =
  EthereumAddress.fromHex('0x55d398326f99059fF775485246999027B3197955');
  final ktrAddress =
  EthereumAddress.fromHex('0xa66cD1C4d890Faa7C1a09A54a254d33d809ba3b5');

  final path = [ktrAddress, usdtAddress];

  // Chuyển đổi amountKTR thành số BigInt (18 decimal places)
  final amountIn = BigInt.from(amountKTR * 1e18);

  final getAmountsOut = contract.function('getAmountsOut');

  try {
    final result = await web3client.call(
      contract: contract,
      function: getAmountsOut,
      params: [amountIn, path],
    );

    final priceInUsdt = result[0] as List;
    final priceInUsdtReal = priceInUsdt.last / BigInt.from(10).pow(18);

    return priceInUsdtReal.toString();
  } catch (e) {
    return "Error: $e";
  }
}

