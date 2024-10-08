import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:web3dart/web3dart.dart';
import 'dart:math';

import '../../../services/filter_base.dart';
import '../../../services/member_service.dart';
import '../../../services/scan_transaction.dart';

part 'transaction_play_event.dart';
part 'transaction_play_state.dart';

class TransactionPlayBloc extends Bloc<TransactionPlayEvent, TransactionPlayState> {
  // final SmartcamServicesmartcamServices = SmartcamServices();
  bool canLoadMore = true; // Biến để theo dõi việc tải thêm

  ScanTransaction scanTransactionService = ScanTransaction();
  MemberService memberService = MemberService();

  TransactionPlayBloc() : super( TransactionPlayState( filters: FilterEntity.initial())) {
    on<OnTransactionPlayInit>(_onTransactionPlayInit);
    on<OnSelectedWallet>(_onSelectedWallet);
    on<OnTransactionPlayLoadMore>(_onLoadMore);
    on<OnClaimPlayed>(_onClaimPlayed);
    on<OnGetVote>(_onGetVote);
  }



  Future<void> _onLoadMore(
      OnTransactionPlayLoadMore event,
      Emitter<TransactionPlayState> emit,
      ) async {
    if (!state.hasMaxReached) return;  // Không tải thêm nếu đã đạt tới giới hạn

    final request = FilterEntity.override(
      state.filters,
      map: {"page": state.filters.page + 1},
    );

    print('filter ${state.filters.page} ${state.filters.limit} ${state.hasMaxReached}');

    emit(state.copyWith(
      filters: request,
      status: BlocStatus.loadMore,
    ));

    if (state.selectedAddress != null) {
      final data = await scanTransactionService.scanServer(state.selectedAddress!, state.filters);

      print('====> data filter $data $state');

      if (data != null && data.containsKey('data')) {
        final List<dynamic> rawDataPlay = data['data'];

        final List<Map<String, dynamic>> dataPlay = rawDataPlay.map((item) {
          return {
            'id': item['id'].toString(),
            'address': item['address'].toString(),
            'statistic': item['statistic'].toString(),
            'TxID': item['TxID'].toString(),
            'created_at': item['created_at'].toString(),
            'updated_at': item['updated_at'].toString(),
            'timestamp': item['timestamp'],
            'TxID_claim': item['TxID_claim'].toString(),
            'info': item['info'].toString(),
          };
        }).toList();

        print('total ${data['total']} ===  ${state.dataPlay.length}}');

        final bool hasReachedMax = (state.dataPlay.length + rawDataPlay.length) < data['total'];

        emit(state.copyWith(
          status: BlocStatus.success,
          dataPlay: [...state.dataPlay, ...dataPlay],
          hasMaxReached: hasReachedMax,
        ));
      } else {
        emit(state.copyWith(status: BlocStatus.failed));
      }
    }
  }


  Future<void> _onTransactionPlayInit(
      OnTransactionPlayInit event,
      Emitter<TransactionPlayState> emit,
      ) async {
    try {
      emit(state.copyWith(
        status: BlocStatus.loading,
        hasMaxReached: false,  // Đặt lại trạng thái để có thể tải thêm
        filters: FilterEntity.initial(),  // Đặt lại bộ lọc về trang đầu tiên
      ));

      final walletList = event.walletList;
      String selectedWallet = event.selected;

      final data = await scanTransactionService.scanServer(selectedWallet, state.filters);

      if (data != null && data.containsKey('data')) {
        final List<dynamic> rawDataPlay = data['data'];

        final List<Map<String, String>> dataPlay = rawDataPlay.map((item) {
          return {
            'id': item['id'].toString(),
            'address': item['address'].toString(),
            'statistic': item['statistic'].toString(),
            'TxID': item['TxID'].toString(),
            'created_at': item['created_at'].toString(),
            'updated_at': item['updated_at'].toString(),
            'timestamp': item['timestamp'].toString(),
            'TxID_claim': item['TxID_claim'].toString(),
            'info': item['info'].toString(),
          };
        }).toList();

        // Kiểm tra nếu số lượng dữ liệu trả về ít hơn `limit`
          print('total ${data['total']} ===  ${state.dataPlay.length}}');
        final bool hasReachedMax = (state.dataPlay.length + rawDataPlay.length) < data['total'];

        emit(state.copyWith(
          status: BlocStatus.success,
          data: walletList,
          dataPlay: dataPlay,
          selectedAddress: selectedWallet,
          hasMaxReached: hasReachedMax,
        ));
      } else {
        emit(state.copyWith(status: BlocStatus.failed));
      }
    } catch (e) {
      emit(state.copyWith(status: BlocStatus.failed));
    }
  }


  Future<void> _onSelectedWallet(
      OnSelectedWallet event,
      Emitter<TransactionPlayState> emit,
      ) async {
    final String selected = event.selected;
    final String privateKey = event.privatekey;

    emit(state.copyWith(
      status: BlocStatus.loading,
      selectedAddress: selected,
      privateKey: privateKey,
      hasMaxReached: false,  // Đặt lại để có thể tải thêm dữ liệu khi chọn ví mới
      filters: FilterEntity.initial(),  // Đặt lại bộ lọc về giá trị ban đầu
    ));

    add(OnTransactionPlayInit(walletList: state.data, selected: selected));
  }


  Future<void> _onClaimPlayed(
    OnClaimPlayed event,
    Emitter<TransactionPlayState> emit
  ) async {
    final context = event.context;
    try {
      final String privateKey = event.privateKey ?? '';
      final int timestamp = event.timestamp ?? 0;
      final String accountAddress = event.walletAddress ?? '';
      int day = (timestamp / 86400).floor() - 20;

      if (day < 0) {
        throw Exception('Invalid day calculation.');
      }

      final txtHash = await memberService.onClaim(privateKey, EthereumAddress.fromHex(accountAddress), day);
      showTopRightSnackBar(context, 'Claim played success ${txtHash}', true);
      emit(state.copyWith(
        status: BlocStatus.success,
      ));
      add(OnTransactionPlayInit(walletList: state.data, selected: state.selectedAddress ?? ''));
    } catch (e) {
      print('=========failed $e');
      showTopRightSnackBar(context, 'On claimed failed', false);
      emit(state.copyWith(
        status: BlocStatus.failed,
      ));
    }
  }

  Future<void> _onGetVote(
    OnGetVote event,
    Emitter<TransactionPlayState> emit
  ) async {
    final Map<String, dynamic> infoPlay = await memberService.getVote(event.walletAddress, event.day);
  }
}
