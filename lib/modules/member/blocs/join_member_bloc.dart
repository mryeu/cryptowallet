import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:web3dart/web3dart.dart';

import '../../../check_balance.dart';
import '../../../mixins/check_time_claim_mixin.dart';
import '../../../services/member_service.dart';
part 'join_member_event.dart';
part 'join_member_state.dart';

class JoinMemberBloc extends Bloc<JoinMemberEvent, JoinMemberState> {
  // final SmartcamServicesmartcamServices = SmartcamServices();
  MemberService MemberServiceBloc = MemberService();
  TokenBalanceChecker BlaanceService = TokenBalanceChecker();

  JoinMemberBloc() : super(const JoinMemberState()) {
    on<onJoinMemberInit>(_onJoinMemberInit);
    on<onJoinMember>(_onJoinMember);
    on<onPlayNow>(_onPlayNow);
  }

  Future<void> _onJoinMemberInit(onJoinMemberInit event,
      Emitter<JoinMemberState> emit,) async {
    emit(state.copyWith(
      status: BlocStatus.initial, notMembers: [], members: [],));
    final List<Map<String, String>> members = [];
    final List<Map<String, String>> notMembers = [];
    // final params = {'\$limit': 1000};
    for (var item in event.walletList) {
      final walletAddress = item['address'] ?? '';
      bool isMember = await MemberServiceBloc.checkIsMember(walletAddress) ??
          false;

      if (isMember) {
        final dataUser = await MemberServiceBloc.getUserInfo(walletAddress);
        print('Data user ${dataUser}');
        members.add(item);
      } else {
        notMembers.add(item);
      }
    }

    print('not member $notMembers');
    emit(state.copyWith(
      status: BlocStatus.success,
      data: event.walletList,
      members: members,
      notMembers: notMembers,
    ));
  }

  Future<void> _onJoinMember(onJoinMember event,
      Emitter<JoinMemberState> emit) async {
    final selectedMember = event.selectedMember;
    final refCode = event.refCode;
    final checked = event.checked;

    // Iterate over selectedMember using index
    for (int index = 0; index < selectedMember.length; index++) {
      try {
        // Only process members that are checked
        if (checked[index] == true) {
          final item = selectedMember[index];
          print('item $item ==== refCode $refCode');

          final txHash = await MemberServiceBloc.addMember(
              item?['privateKey'] ?? "",
              EthereumAddress.fromHex(item?['address'] ?? ""),
              EthereumAddress.fromHex(refCode ?? "")
          );

          showTopRightSnackBar(
              event.context, 'Add member success $txHash', true);
        }
      } catch (e) {
        showTopRightSnackBar(event.context, 'Add member failed $e', false);
      }
    }

    // After adding members, reinitialize the state and close the dialog
    add(onJoinMemberInit(walletList: state.data));
    Navigator.of(event.context).pop();
  }

  Future<void> _onPlayNow(onPlayNow event,
      Emitter<JoinMemberState> emit,) async {
    final selectedMember = event.checkedMember;
    final checked = event.checked;

    for (int index = 0; index < selectedMember.length; index++) {
      try {
        // Chỉ xử lý những ví được chọn
        if (checked[index] == true) {
          final item = selectedMember[index];
          String walletAddress = item['address'] ?? '';
          TokenBalanceChecker BlaanceService = TokenBalanceChecker();
          // Kiểm tra số dư USDT trước khi xử lý Play
          double? usdtBalance = await BlaanceService.getUsdtBalance(walletAddress);
          // Nếu số dư nhỏ hơn 32 USDT, bỏ qua ví này
          if (usdtBalance! < 32.0) {
            showTopRightSnackBar(event.context,
                'Wallet $walletAddress skipped due to insufficient USDT balance: $usdtBalance',
                false);
            continue; // Bỏ qua ví này và tiếp tục với ví tiếp theo
          }
          // Nếu đủ điều kiện chơi (có ít nhất 32 USDT)
          bool isPlayed = await checkPlay(walletAddress);
          if (isPlayed) {
            final txHash = await MemberServiceBloc.approveAndPlay(
              item['privateKey'] ?? "",
              EthereumAddress.fromHex(walletAddress),
            );
            showTopRightSnackBar(
                event.context, 'Play member success $txHash', true);
          }
        }
      } catch (e) {
        showTopRightSnackBar(event.context, 'Play member failed $e', false);
      }
    }
  }
}