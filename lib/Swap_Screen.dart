import 'package:flutter/material.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  _SwapScreenState createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  String? selectedWallet = 'Wallet 1'; // Ví mặc định được chọn
  String? selectedCoinFrom = 'BNB'; // Coin mặc định để swap
  String? selectedCoinTo = 'USDT'; // Coin mục tiêu để swap
  final TextEditingController amountController = TextEditingController();

  final List<String> wallets = ['Wallet 1', 'Wallet 2', 'Wallet 3'];
  final List<String> coins = ['BNB', 'USDT', 'KTR'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swap Coins'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card để chọn ví
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.green, width: 2), // Thêm viền màu xanh
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Wallet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      value: selectedWallet,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_downward),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedWallet = newValue;
                        });
                      },
                      items: wallets.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card cho khung Swap
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.green, width: 2), // Thêm viền màu xanh
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Swap Coins',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // Lựa chọn Coin From
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('From:'),
                        DropdownButton<String>(
                          value: selectedCoinFrom,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCoinFrom = newValue;
                            });
                          },
                          items: coins.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Nhập số lượng cần Swap
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Enter amount to swap',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),

                    // Lựa chọn Coin To
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('To:'),
                        DropdownButton<String>(
                          value: selectedCoinTo,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCoinTo = newValue;
                            });
                          },
                          items: coins.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Nút Swap
                    ElevatedButton(
                      onPressed: () {
                        // Thực hiện hành động Swap ở đây
                        print('Swapping ${amountController.text} $selectedCoinFrom to $selectedCoinTo');
                      },
                      child: const Text('Swap Now'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
