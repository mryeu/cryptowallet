import 'dart:convert';
import 'package:http/http.dart' as http;

Future<int> getLatestBlockNumber() async {
  const nodeUrl = 'https://blissful-thrumming-gas.bsc.quiknode.pro/015c5ea8ce4478bf2566a604f5266f7e928c7462/';

  final payload = {
    "jsonrpc": "2.0",
    "method": "eth_blockNumber",
    "params": [],
    "id": 1
  };

  try {
    final response = await http.post(
      Uri.parse(nodeUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('result')) {
        final blockHex = data['result'];
        final blockHexWithoutPrefix = blockHex.replaceFirst("0x", "");
        int latestBlock = int.parse(blockHexWithoutPrefix, radix: 16);
        return latestBlock;
      } else {
        print('Không tìm thấy "result" trong phản hồi API');
        return -1;
      }
    } else {
      print('Lỗi khi gọi API: ${response.statusCode}');
      return -1;
    }
  } catch (e) {
    print('Lỗi khi gọi API: $e');
    return -1;
  }
}

Future<void> getRecentTransactions(String walletAddress) async {
  const nodeUrl = 'https://blissful-thrumming-gas.bsc.quiknode.pro/015c5ea8ce4478bf2566a604f5266f7e928c7462/';

  // Lấy block hiện tại
  final latestBlock = await getLatestBlockNumber();
  if (latestBlock == -1) {
    print('Không thể lấy block hiện tại.');
    return;
  }

  print("Block hiện tại: $latestBlock");

  // Chia block thành các phần nhỏ hơn
  const int blockStep = 10000;  // Số block yêu cầu mỗi lần (có thể điều chỉnh nếu cần)
  int fromBlock = latestBlock - 864000;  // Block cách đây 1 tháng
  int toBlock = fromBlock + blockStep;

  while (fromBlock < latestBlock) {
    // Kiểm tra để không yêu cầu vượt quá block hiện tại
    if (toBlock > latestBlock) {
      toBlock = latestBlock;
    }

    print('Yêu cầu từ block $fromBlock đến block $toBlock...');

    final payload = {
      "jsonrpc": "2.0",
      "method": "eth_getLogs",
      "params": [
        {
          "fromBlock": "0x${fromBlock.toRadixString(16)}",  // Block bắt đầu
          "toBlock": "0x${toBlock.toRadixString(16)}",      // Block kết thúc
          "address": walletAddress,                         // Địa chỉ ví
          "topics": []                                      // Có thể để trống nếu không lọc theo sự kiện
        }
      ],
      "id": 1
    };

    try {
      final response = await http.post(
        Uri.parse(nodeUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['result'] != null && data['result'].isNotEmpty) {
          // Xử lý giao dịch
          List transactions = data['result'];
          print('Số lượng giao dịch nhận được từ block $fromBlock đến $toBlock: ${transactions.length}');
          for (var tx in transactions) {
            print('Transaction Hash: ${tx['transactionHash']}');
            print('Block Number: ${int.parse(tx['blockNumber'], radix: 16)}');
            print('---');
          }
        } else {
          print('Không có giao dịch nào từ block $fromBlock đến block $toBlock.');
        }
      } else {
        print('Lỗi khi gọi API: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi gọi API: $e');
    }

    // Chuyển sang nhóm block tiếp theo
    fromBlock = toBlock + 1;
    toBlock = fromBlock + blockStep;
  }
}

