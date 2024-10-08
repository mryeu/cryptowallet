import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class WebSocketTransactionListener {
  final List<String> walletAddresses;
  final String urlrequest = 'https://special-burned-sky.bsc.quiknode.pro/de871b0cbc0b8feed0229ee21332597fca5b15c5/';

  WebSocketTransactionListener(this.walletAddresses);

  // Hàm để lấy logs từ địa chỉ ví trong 3 ngày qua
  Future<void> fetchLogs() async {
    for (String address in walletAddresses) {
      final logs = await getLogsForAddress(address);
      if (logs != null && logs.isNotEmpty) {
        // Lưu logs vào file JSON
        await _saveTransactionToJson(logs);
      }
    }
  }

  /// Hàm để lấy logs từ địa chỉ ví với eth_getLogs
  Future<List<Map<String, dynamic>>?> getLogsForAddress(String address) async {
    const int maxBlockRange = 10000;  // Giới hạn mỗi lần 10.000 block
    int latestBlock = await getLatestBlockNumber(); // Lấy block mới nhất từ API
    int blocksPerDay = (86400 ~/ 3);  // Số block trong một ngày (~28800 block/ngày)

    // Tính toán block cách đây 3 ngày
    int fromBlock = latestBlock - (blocksPerDay * 3);

    List<Map<String, dynamic>> allLogs = [];

    // Chia truy vấn thành các khoảng block không quá 10,000
    while (fromBlock <= latestBlock) {
      int toBlock = (fromBlock + maxBlockRange - 1) < latestBlock ? fromBlock + maxBlockRange - 1 : latestBlock;

      final body = jsonEncode({
        "jsonrpc": "2.0",
        "method": "eth_getLogs",
        "params": [
          {
            "address": address,
            "fromBlock": "0x${fromBlock.toRadixString(16)}", // Convert to hexadecimal
            "toBlock": "0x${toBlock.toRadixString(16)}" // Convert to hexadecimal
          }
        ],
        "id": 1
      });

      try {
        final response = await http.post(Uri.parse(urlrequest), headers: {
          'Content-Type': 'application/json',
        }, body: body);

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          if (jsonResponse.containsKey('result')) {
            List<Map<String, dynamic>> logs = List<Map<String, dynamic>>.from(jsonResponse['result']);
            allLogs.addAll(logs); // Thêm logs vào danh sách
          } else {
            print("No logs found for address: $address in range $fromBlock - $toBlock");
          }
        } else {
          print("Failed to fetch logs: ${response.body}");
        }
      } catch (e) {
        print("Error fetching logs: $e");
      }

      // Cập nhật fromBlock cho lần truy vấn tiếp theo
      fromBlock = toBlock + 1;
    }

    return allLogs;
  }

  // Hàm để lấy số block mới nhất
  Future<int> getLatestBlockNumber() async {
    final body = jsonEncode({
      "jsonrpc": "2.0",
      "method": "eth_blockNumber",
      "params": [],
      "id": 1
    });

    try {
      final response = await http.post(Uri.parse(urlrequest), headers: {
        'Content-Type': 'application/json',
      }, body: body);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return int.parse(jsonResponse['result']); // Trả về block mới nhất (dưới dạng int)
      } else {
        print("Failed to fetch latest block number: ${response.body}");
      }
    } catch (e) {
      print("Error fetching latest block number: $e");
    }

    return 0; // Trả về 0 nếu không lấy được block mới nhất
  }

  // Lưu giao dịch vào JSON
  Future<void> _saveTransactionToJson(List<Map<String, dynamic>> logs) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/transactions.json');

      // Đọc dữ liệu hiện có từ file
      List<dynamic> currentData = [];
      if (await file.exists()) {
        final contents = await file.readAsString();
        currentData = jsonDecode(contents);
      }

      // Thêm logs mới vào JSON
      currentData.addAll(logs);

      // Ghi lại file với logs mới
      await file.writeAsString(jsonEncode(currentData), flush: true);
      print("Logs saved: $logs");
    } catch (e) {
      print("Error saving logs: $e");
    }
  }
}
