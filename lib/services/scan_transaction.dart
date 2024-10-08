import 'dart:convert';
import 'package:http/http.dart' as http;

import 'filter_base.dart';
// import 'package:kittyrunwallet/modules/transaction/blocs/transaction_play_bloc.dart';

class ScanTransaction {
  final String bscScanApiUrl = 'https://api.bscscan.com/api';
  final String apiKey = 'SKEIIS25KQWPUZJ7TX51QVRRJXNPJBTF3H'; // Replace with your BscScan API key
  final String kittyRunApiUrl = 'https://kittyrun.io/api/votes/';
  
  // Function to scan account balance
  Future<BigInt?> scanAccount(String walletAddress) async {
    try {
      // API URL with query parameters
      final Uri url = Uri.parse('$bscScanApiUrl?module=account&action=balance&address=$walletAddress&apikey=$apiKey');

      // Making the HTTP GET request
      final http.Response response = await http.get(url);

      // If the request is successful
      if (response.statusCode == 200) {
        // Parse the JSON response
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == '1') {
          // Extract the balance (in Wei) and return it as BigInt
          BigInt balance = BigInt.parse(data['result']);
          return balance;
        } else {
          print('Error: ${data['message']}');
          return null;
        }
      } else {
        print('Failed to fetch account balance. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error scanning account: $e');
      return null;
    }
  }


  Future<Map<String, dynamic>?> scanServer(String walletAddress, FilterEntity filter) async {
    try {
      // Build the API URL with query parameters
      final Uri url = Uri.parse('$kittyRunApiUrl?address=$walletAddress&page=${filter.page}&show=${filter.limit}');

      // Making the HTTP GET request
      final http.Response response = await http.get(url);

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the JSON response
        final Map<String, dynamic> data = json.decode(response.body);
        return data; // Return the parsed data
      } else {
        print('Failed to fetch data. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching data from server: $e');
      return null;
    }
  }
}
