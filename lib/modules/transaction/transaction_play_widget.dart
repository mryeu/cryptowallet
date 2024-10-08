import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../check_balance.dart';
import '../../mixins/check_time_claim_mixin.dart';
import '../../mixins/infinity_load_mixin.dart';
import '../../services/member_service.dart';
import 'blocs/transaction_play_bloc.dart';

class TransactionPlayWidget1 extends StatefulWidget {
  final List<Map<String, String>> walletList;
  const TransactionPlayWidget1({super.key, required this.walletList});

  @override
  State<TransactionPlayWidget1> createState() => _TransactionPlayWidget1State();
}

class _TransactionPlayWidget1State extends State<TransactionPlayWidget1> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TransactionPlayBloc()
        ..add(OnTransactionPlayInit(
            walletList: widget.walletList,
            selected: widget.walletList[0]['address'] ?? '')),
      child: TransactionPlayWidget(walletList: widget.walletList),
    );
  }
}




class TransactionPlayWidget extends StatefulWidget {
  final List<Map<String, String>> walletList;
  const TransactionPlayWidget({Key? key, required this.walletList});

  @override
  State<TransactionPlayWidget> createState() => _TransactionPlayWidget();
}

class _TransactionPlayWidget extends State<TransactionPlayWidget> with InfiniteScrollMixin {
  @override
  void onInfinityFetch() {
    // Kiểm tra nếu không còn dữ liệu mới để tải
    if (!context.read<TransactionPlayBloc>().canLoadMore) {
      return; // Không tải thêm dữ liệu
    }

    print("load more");
    context.read<TransactionPlayBloc>().add(OnTransactionPlayLoadMore());
  }

  String getRandomString(int length) {
  const characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  Random random = Random();
  return String.fromCharCodes(Iterable.generate(
      length, (_) => characters.codeUnitAt(random.nextInt(characters.length))));
}

  Future<Map<String, dynamic>> _getVote(String walletAddress, int day) async{
    MemberService memberService = MemberService();
    final Map<String, dynamic> infoPlay = await memberService.getVote(walletAddress, day);
    return infoPlay;
  }

  void onChangeWallet(BuildContext context, String selectedWallet, String privatekey) {
    BlocProvider.of<TransactionPlayBloc>(context).add(OnSelectedWallet(selected: selectedWallet, privatekey: privatekey));
  }

  void onClaimPlayedKitty(BuildContext context, String privateKey, String walletAddress, int timestamp) {
    BlocProvider.of<TransactionPlayBloc>(context).add(
        OnClaimPlayed(context: context, privateKey: privateKey, walletAddress: walletAddress, timestamp: timestamp));
  }

  String? _findPrivateKey(List<Map<String, String>> walletList, String walletAddress) {
    print('====== find address ${walletList} === ${walletAddress}');
    for (var wallet in walletList) {
      print('====find address for ${wallet}');
      if (wallet['address'] == walletAddress) {
        print('====find ${wallet}');
        return wallet['privateKey'];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext contextMain) {
    return BlocBuilder<TransactionPlayBloc, TransactionPlayState>(
      builder: (contextMain, state) {
        String selectedAddress = state.selectedAddress ?? widget.walletList[0]['address'] ?? '';

        return Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20,),
                SizedBox(
                  height: 80, // Chiều cao cho danh sách nút
                  child: FlutterCarousel(
                    options: CarouselOptions(
                      height: 80, // Đặt chiều cao cho Carousel
                      viewportFraction: 0.3, // Đặt tỉ lệ chiều rộng của mỗi item trong carousel
                      enableInfiniteScroll: false, // Tắt chế độ cuộn vô hạn
                      enlargeCenterPage: true, // Phóng to trang ở giữa

                    ),
                    items: widget.walletList.map((wallet) {
                      String walletAddress = wallet['address'] ?? '';
                      String walletName = wallet['name'] ?? 'Wallet';
                      String privatekey = wallet['privateKey'] ?? '';

                      return GestureDetector(
                        onTap: () {
                          // Gọi hàm onChangeWallet khi nhấn vào nút
                          onChangeWallet(contextMain, walletAddress, privatekey);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: selectedAddress == walletAddress ? Colors.green : Colors.greenAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            walletName,
                            style: const TextStyle(color: Colors.white, fontWeight:FontWeight.bold ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          margin: EdgeInsets.zero,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(0),
                            color: Colors.green.withOpacity(0.1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text('#', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 2),
                                  SvgPicture.asset('assets/images/sort.svg'),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text('Wallet', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 2),
                                  SvgPicture.asset('assets/images/sort.svg'),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text('TxHash', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 2),
                                  SvgPicture.asset('assets/images/sort.svg'),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text('Amount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 2),
                                  SvgPicture.asset('assets/images/sort.svg'),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text('Created at', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 2),
                                  SvgPicture.asset('assets/images/sort.svg'),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text('Status', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 2),
                                  SvgPicture.asset('assets/images/sort.svg'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (state.status == BlocStatus.loading)
                          const Expanded(
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 1.0,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        if (state.status == BlocStatus.success || state.status == BlocStatus.loadMore)
                          Expanded(
                            child: ListView.builder(
                              controller: infinityScrollController,
                              itemCount: state.dataPlay.length,
                              itemBuilder: (context, index) {
                                final displayedItems = <String>{}; // Set để kiểm tra và tránh lặp lại dữ liệu
                                final walletAddress = state.dataPlay[index]['address'] ?? '';
                                final txID = state.dataPlay[index]['TxID'] ?? '';

                                // Kiểm tra nếu dữ liệu đã tồn tại trong Set
                                if (displayedItems.contains(txID)) {
                                  return const SizedBox.shrink(); // Bỏ qua phần tử đã tồn tại
                                }
                                // Nếu chưa tồn tại, thêm vào Set
                                displayedItems.add(txID);
                                final info = state.dataPlay[index]['info'] ?? [0, false];
                                final created_at = state.dataPlay[index]['created_at'] ?? '';
                                final timestampString = state.dataPlay[index]['timestamp'];
                                final int timestamp = int.tryParse(timestampString) ?? 0;
                                final String privateKey = state.privateKeySelected;
                                bool isClaimValid = checkClaim(timestamp);
                                final covertInfo = jsonDecode(info);
                                final moneyAmount = (31 * covertInfo[0]) / 100000 + 31;
                                int day = (timestamp / 86400).floor() - 20;

                                return FutureBuilder<Map<String, dynamic>>(
                                  future: _getVote(walletAddress, day),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Text("loading...");
                                    } else if (snapshot.hasError) {
                                      return const Text("Error");
                                    } else {
                                      final Map<String, dynamic> data = snapshot.data ?? {'claimed': false};

                                      return Card(
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('${index + 1}', style: const TextStyle(fontSize: 10)),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${walletAddress.substring(0, 5)}...${walletAddress.substring(walletAddress.length - 5)}',
                                                    style: const TextStyle(fontSize: 10),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${txID.substring(0, 5)}...${txID.substring(txID.length - 5)}',
                                                    style: const TextStyle(fontSize: 10),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('$moneyAmount', style: const TextStyle(fontSize: 10)),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(created_at, style: const TextStyle(fontSize: 10)),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  TextButton(
                                                    onPressed: isClaimValid && !data['claimed']
                                                        ? () {
                                                      try {
                                                        if (covertInfo[1] == false) {
                                                          onClaimPlayedKitty(contextMain, privateKey, walletAddress, timestamp);
                                                        }
                                                      } catch (e) {
                                                        showTopRightSnackBar(contextMain, 'On claim failed $e', false);
                                                      }
                                                    }
                                                        : null,
                                                    child: Text(data['claimed'] ? 'Claimed' : 'Claim', style: TextStyle(color: Colors.white),),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: Colors.white,
                                                      backgroundColor: data['claimed']
                                                          ? Colors.orangeAccent
                                                          : isClaimValid
                                                          ? Colors.green
                                                          : Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


