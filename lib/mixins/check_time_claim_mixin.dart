import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../services/member_service.dart';

bool checkClaim(int? timestamp) {
  if (timestamp == null) return false;
  // Parse the timestamp and convert it to DateTime
  final timeEnd = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
      .toUtc()
      .subtract(Duration(hours: DateTime.now().timeZoneOffset.inHours)) // Ensure consistent UTC start of the day
      .add(Duration(days: 30));

  // Get the current UTC time
  final now = DateTime.now().toUtc();

  // Calculate the difference between the target date and now
  final duration = timeEnd.difference(now);

  print('===> duration ${duration.inSeconds}');

  return duration.inSeconds <= 0;
}

Future<bool> checkPlay(String? walletAddress) async {
  int unixTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  int unixNow = (unixTime / 86400).floor() - 20;
  MemberService memberService = MemberService();
  final Map<String, dynamic> info_now = await memberService.getVote(walletAddress ?? '', unixNow);
  final Map<String, dynamic> info_last_day = await memberService.getVote(walletAddress ?? '', unixNow - 1);

  final int percent_now = info_now['percent'] ?? 0;
  final int percent_last_day = info_last_day['percent'] ?? 0;
  
  return percent_now == 0 && percent_last_day == 0;
}
