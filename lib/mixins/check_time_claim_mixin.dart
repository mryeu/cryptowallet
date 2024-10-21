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

String formatTimeEnd(int timestamp) {
  if (timestamp == null) return '';

  // Parse the timestamp and convert it to DateTime
  final timeEnd = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
      .toUtc()
      .subtract(Duration(hours: DateTime.now().timeZoneOffset.inHours)) // Ensure consistent UTC start of the day
      .add(Duration(days: 30));

  // Convert timeEnd to "MM/DD/YYYY" format
  String formattedTimeEnd = DateFormat('MM/dd/yyyy').format(timeEnd);

  return formattedTimeEnd;
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

Future<String> getTimePlay(String? walletAddress) async {
  bool check = await checkPlay(walletAddress);
  
  DateTime date = DateTime.now();

  if (!check) {
    date = date.add(const Duration(days: 1));
  }

  // Formatting the date as MM/DD/YYYY
  String formattedDate = DateFormat('MM/dd/yyyy').format(date);
  return formattedDate;
}