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

  Future<void> _onJoinMemberInit(
    onJoinMemberInit event,
    Emitter<JoinMemberState> emit,
  ) async {
    emit(state.copyWith(status: BlocStatus.initial, notMembers: [], members: [],));
    final List<Map<String, String>> members = [];
    final List<Map<String, String>> notMembers = [];
    // final params = {'\$limit': 1000};
    for (var item in event.walletList) {
      final walletAddress = item['address'] ?? '';
      bool isMember = await MemberServiceBloc.checkIsMember(walletAddress) ?? false; 

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

  Future<void> _onJoinMember(
    onJoinMember event,
    Emitter<JoinMemberState> emit
  ) async {
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

          showTopRightSnackBar(event.context, 'Add member success $txHash', true);
        }
      } catch (e) {
        showTopRightSnackBar(event.context, 'Add member failed $e', false);
      }
    }

    // After adding members, reinitialize the state and close the dialog
    add(onJoinMemberInit(walletList: state.data));
    Navigator.of(event.context).pop();
  }

  Future<void> _onPlayNow(
    onPlayNow event,
    Emitter<JoinMemberState> emit
  ) async {
    final selectedMember = event.checkedMember;
    final checked = event.checked;


    for (int index = 0; index < selectedMember.length; index++) {
      try {
        // Only process members that are checked
        if (checked[index] == true) {
          final item = selectedMember[index];
          bool isPlayed = await checkPlay(item['address'] ?? '');

          if (isPlayed) {
            final txHash = await MemberServiceBloc.approveAndPlay(
              item?['privateKey'] ?? "", 
              EthereumAddress.fromHex(item?['address'] ?? ""), 
            );
            showTopRightSnackBar(event.context, 'Play member success $txHash', true);
          }
        }
      } catch (e) {
        showTopRightSnackBar(event.context, 'Play member failed $e', false);
      }
    }
  }
}