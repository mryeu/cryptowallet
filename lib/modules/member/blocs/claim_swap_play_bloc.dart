import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:web3dart/web3dart.dart';

import '../../../check_balance.dart';
import '../../../check_price_ktr.dart';
import '../../../mixins/check_time_claim_mixin.dart';
import '../../../services/filter_base.dart';
import '../../../services/member_service.dart';
import '../../../services/scan_transaction.dart';
import '../../../swap_ktr_usdt.dart';
part 'claim_swap_play_state.dart';
part 'claim_swap_play_event.dart';

class ClaimSwapPlayBloc extends Bloc<ClaimSwapPlayEvent, ClaimSwapPlayState> {

  MemberService memberService = MemberService();
  ScanTransaction scanTransactionService = ScanTransaction();

  ClaimSwapPlayBloc() : super(ClaimSwapPlayState(filters: FilterEntity.initial())) {
    on<onClaimSwapPlayInit>(_onClaimSwapPlayInit);
    on<onAutoClaimSwapPlay>(_onAutoClaimSwap);
  }

  Future<void> _onClaimSwapPlayInit(
      onClaimSwapPlayInit event,
      Emitter<ClaimSwapPlayState> emit
      ) async {
    final List <Map<String, dynamic>> members = event.members ?? [];
    emit(state.copyWith(
      status: BlocStatus.success,
      members: members,
      filters: FilterEntity.initial(),  // Đặt lại bộ lọc về trang đầu tiên
    ));
  }

  Future<void> _onAutoClaimSwap(
      onAutoClaimSwapPlay event,
      Emitter<ClaimSwapPlayState> emit
      ) async {
    // await buySellTokenKTR(walletAddress: "0xDa22644F364155dFb41Ae756484177906D925F3f",
    //     privateKey: '4828b59ab795f0a667c321a721f0d6661cd57ee4510b71fdbe26ba51e0cd6a8a', isBuy: true, inputNumber: 12);
    emit(state.copyWith(status: BlocStatus.processing));
    final price_ktr = await checkPriceKTR(1);
    final double value_price_ktr = double.parse(price_ktr);
    print('=======price kTR $price_ktr');
    final double amount_ktr_to_32 = (34 / value_price_ktr);
    print('=====amount ktr $amount_ktr_to_32');
    for(var member in event.members) {
      int unixTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      int unixNow = (unixTime / 86400).floor() - 20;
      emit(state.copyWith(title: '${member['name']} ${member['address']}', message: 'Checking play...'));

      final info_now = await memberService.getVote(member['address'] ?? '', unixNow);
      final info_last_day = await memberService.getVote(member['address'] ?? '', unixNow - 1);
      final int percent_now = info_now['percent'] ?? 0;
      final int percent_last_day = info_last_day['percent'] ?? 0;
      TokenBalanceChecker checker = TokenBalanceChecker();
      double? usdt = await checker.getUsdtBalance(member['address'] ?? '');
      double? ktr = await checker.getKtrBalance(member['address'] ?? '');

      if (percent_now == 0 && percent_last_day == 0) {
        emit(state.copyWith(message: 'checking blance....'));
        if (usdt! >= 32) {
          try {
            final txHash = await memberService.approveAndPlay(member['privateKey'] ?? '', EthereumAddress.fromHex(member['address'] ?? ''));
            emit(state.copyWith(message: "Play success $txHash"));
          } catch(e) {
            emit(state.copyWith(message:  "Play failed $e"));
          }
        } else {
          emit(state.copyWith(message: "Don't insufficient 32 USDT, checking balance KTR"));
          if (ktr! >= amount_ktr_to_32) {
            emit(state.copyWith(message: "Swaping KTR to USDT"));
            try {
              // Thực hiện swap KTR to USDT
              final txHash = await buySellTokenKTR(
                walletAddress: member['address'] ?? '',
                privateKey: member['privateKey'] ?? '',
                isBuy: true, // Swap từ KTR sang USDT
                inputNumber: amount_ktr_to_32.toInt(),
              );
              emit(state.copyWith(message: 'Swap KTR to USDT successful! Transaction Hash: $txHash'));
              bool isBalanceUpdated = false;
              const int maxAttempts = 10;
              int attempt = 0;
              final int checkInterval = 5;

              while (!isBalanceUpdated && attempt < maxAttempts) {
                await Future.delayed(Duration(seconds: checkInterval));
                usdt = await checker.getUsdtBalance(member['address'] ?? '');

                if (usdt != null && usdt >= 32) {
                  isBalanceUpdated = true;
                  emit(state.copyWith(message: "USDT balance updated: $usdt"));
                } else {
                  attempt++;
                  emit(state.copyWith(message: "Checking USDT balance... Attempt $attempt"));
                }
              }

              // Nếu sau tất cả các lần kiểm tra mà số dư vẫn chưa đạt yêu cầu
              if (!isBalanceUpdated) {
                emit(state.copyWith(message: "USDT balance did not update after swap. Please check transaction status."));
              }

            } catch (e) {
              // Xử lý lỗi nếu quá trình swap thất bại
              emit(state.copyWith(message: "Swap failed: $e"));
            }
          } else {
            int unixClaim = int.parse(member['unixClaim'] ?? "0");
            // print("unix ${member['unixClaim'].runtimeType}");
            if (unixClaim > 0) {
              emit(state.copyWith(message: 'Claiming....'));
              await memberService.onClaim(member['privateKey'] ?? '', EthereumAddress.fromHex(member['address'] ?? ''), unixClaim);
              await Future.delayed(Duration(seconds: 10)); // Sleep for 10 seconds
              emit(state.copyWith(message: 'Claim success'));
              ktr = await checker.getKtrBalance(member['address'] ?? '');
              emit(state.copyWith(message: 'Swap KTR to USDT'));
              try {
                // Thực hiện swap KTR to USDT
                final txHash = await buySellTokenKTR(
                  walletAddress: member['address'] ?? '',
                  privateKey: member['privateKey'] ?? '',
                  isBuy: true, // Swap từ KTR sang USDT
                  inputNumber: amount_ktr_to_32.toInt(),
                );
                emit(state.copyWith(message: 'Swap KTR to USDT successful! Transaction Hash: $txHash'));
                bool isBalanceUpdated = false;
                const int maxAttempts = 10;
                int attempt = 0;
                final int checkInterval = 5;

                while (!isBalanceUpdated && attempt < maxAttempts) {
                  await Future.delayed(Duration(seconds: checkInterval));
                  usdt = await checker.getUsdtBalance(member['address'] ?? '');

                  if (usdt != null && usdt >= 32) {
                    isBalanceUpdated = true;
                    emit(state.copyWith(message: "USDT balance updated: $usdt"));
                  } else {
                    attempt++;
                    emit(state.copyWith(message: "Checking USDT balance... Attempt $attempt"));
                  }
                }

                // Nếu sau tất cả các lần kiểm tra mà số dư vẫn chưa đạt yêu cầu
                if (!isBalanceUpdated) {
                  emit(state.copyWith(message: "USDT balance did not update after swap. Please check transaction status."));
                }

              } catch (e) {
                // Xử lý lỗi nếu quá trình swap thất bại
                emit(state.copyWith(message: "Swap failed: $e"));
              }
            } else {
              emit(state.copyWith(message: "Don't found claim"));
            }
          }

          //try again play
          if (usdt! >= 32) {
            try {
              final txHash = await memberService.approveAndPlay(member['privateKey'] ?? '', EthereumAddress.fromHex(member['address'] ?? ''));
              emit(state.copyWith(message: "Play success $txHash"));
            } catch(e) {
              emit(state.copyWith(message:  "Play failed $e"));
            }
          } else {
            emit(state.copyWith(message:  "Please deposit 32 USDT to address"));
          }
        }


        print('========claim ${member}');
        // final data = await scanTransactionService.scanServer(member['address'] ?? '', state.filters) ?? null;
        // if (data != null && data.containsKey('data')) {
        //   final List<dynamic> rawDataPlay = data['data'];

        //   final List<Map<String, dynamic>> dataPlay = rawDataPlay.map((item) {
        //     return {
        //       'id': item['id'].toString(),
        //       'address': item['address'].toString(),
        //       'statistic': item['statistic'].toString(),
        //       'TxID': item['TxID'].toString(),
        //       'created_at': item['created_at'].toString(),
        //       'updated_at': item['updated_at'].toString(),
        //       'timestamp': item['timestamp'],
        //       'TxID_claim': item['TxID_claim'].toString(),
        //       'info': item['info'].toString(),
        //     };
        //   }).toList();

        //   // print('r${member['address']} total ${data['total']} ===  ${dataPlay.length}}');
        //   if (dataPlay.length > 0) {
        //     bool isClaimValid = false;
        //     emit(state.copyWith(message: 'Checking is claim....'));
        //     bool isClaimed = false;
        //     for (var play in dataPlay) {
        //       // print('====> play ${play}');

        //       int timestamp = int.tryParse(play['timestamp']) ?? 0;
        //       int day = (timestamp / 86400).floor() - 20;
        //       isClaimValid = checkClaim(timestamp);
        //       // final String TxID = play['TxID'] ?? '';
        //       if (isClaimValid && isClaimed == false) {
        //         // emit(state.copyWith(message: 'Claiming ${TxID}.... '));
        //         Map<String, dynamic> infoPlay = await memberService.getVote(member['address'] ?? '', day);
        //         if (infoPlay['claimed'] == false) {
        //           await memberService.onClaim(member['privateKey'] ?? '', EthereumAddress.fromHex(member['address'] ?? ''), day);
        //           emit(state.copyWith(message: 'Claim success'));
        //           isClaimed = true;
        //           await Future.delayed(Duration(seconds: 10)); // Sleep for 3 seconds
        //           ktr = await checker.getKtrBalance(member['address'] ?? '');
        //         }
        //       }
        //     }

        //     if (!isClaimed) {
        //       emit(state.copyWith(message: 'Dont found claim, continue checking... USDT!'));
        //     }
        //     if (usdt! < 32) {
        //       if (ktr! >= amount_ktr_to_32) {
        //         try {
        //           // Thực hiện swap KTR to USDT
        //           final txHash = await buySellTokenKTR(
        //             walletAddress: member['address'] ?? '',
        //             privateKey: member['privateKey'] ?? '',
        //             isBuy: true, // Swap từ KTR sang USDT
        //             inputNumber: amount_ktr_to_32.toInt(),
        //           );
        //           emit(state.copyWith(message: 'Swap KTR to USDT successful! Transaction Hash: $txHash'));
        //           bool isBalanceUpdated = false;
        //           const int maxAttempts = 10;
        //           int attempt = 0;
        //           final int checkInterval = 5;

        //           while (!isBalanceUpdated && attempt < maxAttempts) {
        //             await Future.delayed(Duration(seconds: checkInterval));
        //             usdt = await checker.getUsdtBalance(member['address'] ?? '');

        //             if (usdt != null && usdt >= 32) {
        //                isBalanceUpdated = true;
        //               emit(state.copyWith(message: "USDT balance updated: $usdt"));
        //             } else {
        //               attempt++;
        //               emit(state.copyWith(message: "Checking USDT balance... Attempt $attempt"));
        //             }
        //           }

        //           // Nếu sau tất cả các lần kiểm tra mà số dư vẫn chưa đạt yêu cầu
        //           if (!isBalanceUpdated) {
        //             emit(state.copyWith(message: "USDT balance did not update after swap. Please check transaction status."));
        //           }

        //         } catch (e) {
        //           // Xử lý lỗi nếu quá trình swap thất bại
        //           emit(state.copyWith(message: "Swap failed: $e"));
        //         }
        //       } else {
        //         // Thông báo nếu không đủ số dư KTR để thực hiện swap
        //         emit(state.copyWith(message: "Insufficient KTR balance for swap."));
        //       }
        //     } else {
        //       // Thông báo nếu số dư USDT đã đủ
        //       emit(state.copyWith(message: "USDT balance is already sufficient."));
        //     }


        //     if (usdt! >= 32) {
        //       try {
        //         final txHash = await memberService.approveAndPlay(member['privateKey'] ?? '', EthereumAddress.fromHex(member['address'] ?? ''));
        //         emit(state.copyWith(message: "Play success $txHash"));
        //       } catch(e) {
        //         emit(state.copyWith(message:  "Play failed $e"));
        //       }
        //     } else {
        //       emit(state.copyWith(message: "Address don't insufficient 32 USDT"));
        //     }
        //   } else {
        //     if (usdt! < 32) {
        //       if (ktr! >= amount_ktr_to_32) {
        //         try {
        //           final txHash =  await buySellTokenKTR(walletAddress: member['address'] ?? '', privateKey: member['privateKey'] ?? '', isBuy: false, inputNumber: amount_ktr_to_32.toInt());
        //           emit(state.copyWith(message: 'Swap KTR to USDT success $txHash!'));
        //           await Future.delayed(const Duration(seconds: 3)); // Sleep for 3 seconds
        //         } catch(e) {
        //           emit(state.copyWith(message: "Failed $e"));
        //         }
        //       } else {
        //         emit(state.copyWith(message: "Address don't insufficient KTR"));
        //         print('Totak KTR ${ktr} === ${amount_ktr_to_32}');
        //       }
        //     }

        //     await Future.delayed(const Duration(seconds: 10));

        //     try {
        //       usdt = await checker.getUsdtBalance(member['address'] ?? '');
        //       if (usdt! >= 32) {
        //         await memberService.approveAndPlay(member['privateKey'] ?? '', EthereumAddress.fromHex(member['address'] ?? ''));
        //         emit(state.copyWith(message: "Play success"));
        //       } else {
        //         emit(state.copyWith(message: "${member['name']} don't insufficient 32 USDT to play"));
        //       }
        //     } catch(e) {
        //       emit(state.copyWith(message:  "Play failed $e"));
        //     }
        //   }
        // } else {
        //   emit(state.copyWith(status: BlocStatus.failed));
        // }
      }

      await Future.delayed(const Duration(seconds: 10)); // Sleep for 10 seconds

    }

    emit(state.copyWith(
        status: BlocStatus.success
    ));
  }
}