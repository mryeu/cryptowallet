import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CountdownDialog extends StatefulWidget {
  final int totalWaitTime;  // Tổng thời gian đếm ngược
  final Function onSendComplete;  // Hàm callback khi hoàn tất

  CountdownDialog({required this.totalWaitTime, required this.onSendComplete});

  @override
  _CountdownDialogState createState() => _CountdownDialogState();
}

class _CountdownDialogState extends State<CountdownDialog> {
  late int currentWaitTime;

  @override
  void initState() {
    super.initState();
    currentWaitTime = widget.totalWaitTime;
    _startCountdown();
  }

  void _startCountdown() async {
    while (currentWaitTime > 0) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        currentWaitTime--;
      });
    }
    widget.onSendComplete();  // Gọi callback khi hoàn tất
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          const Text(
            "Sending tokens:",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 10),
          Text("Remaining time: $currentWaitTime seconds",  style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),),
          const SizedBox(height: 20),
          Image.asset(
            'assets/images/loading.gif',
            height: 200,
            width: 200,
          ),
        ],
      ),
    );
  }
}
