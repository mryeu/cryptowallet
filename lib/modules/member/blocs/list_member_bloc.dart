import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:web3dart/web3dart.dart';

import '../../../check_balance.dart';
import '../../../services/member_service.dart';
part 'list_member_event.dart';
part 'list_member_state.dart';

class ListMemberBloc extends Bloc<ListMemberEvent, ListMemberState> {
  // final SmartcamServicesmartcamServices = SmartcamServices();
  MemberService MemberServiceBloc = MemberService();
  TokenBalanceChecker BlaanceService = TokenBalanceChecker();

  ListMemberBloc() : super(const ListMemberState()) {
    on<onListMemberInit>(_onListMemberInit);
    on<onAddDeposit>(_onAddDeposit);
  }

  Future<void> _onListMemberInit(
    onListMemberInit event,
    Emitter<ListMemberState> emit,
  ) async {
    final List<Map<String, String>> members = [];
    final List<Map<String, String>> notMembers = [];
    // final params = {'\$limit': 1000};
    for (var item in event.walletList) {
      final walletAddress = item['address'] ?? '';
      bool isMember = await MemberServiceBloc.checkIsMember(walletAddress) ?? false; 

      if (isMember) {
        members.add(item);
      } else {
        
        notMembers.add(item);
      }
    }
    emit(state.copyWith(
      status: BlocStatus.success,
      data: event.walletList,
      members: members,
      notMembers: notMembers,
    ));
  }

  Future<void> _onAddDeposit(
    onAddDeposit event,
    Emitter<ListMemberState> emit
  ) async {
     try {
        EthereumAddress accountAddress = EthereumAddress.fromHex(event.walletAddress); // Replace with your account address

        // Call the addDeposit function
        String txHash = await MemberServiceBloc.addDeposit(event.context, event.privateKey, accountAddress);
        showTopRightSnackBar(event.context, "Success auto play $txHash", true);
      } catch (e) {
        showTopRightSnackBar(event.context, "Error auto play $e", false);
      }
  }
}
