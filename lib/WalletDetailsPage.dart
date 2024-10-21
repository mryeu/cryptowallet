import 'package:cryptowallet/check_balance.dart';
import 'package:cryptowallet/mixins/check_time_claim_mixin.dart';
import 'package:cryptowallet/services/filter_base.dart';
import 'package:cryptowallet/services/member_service.dart';
import 'package:cryptowallet/services/scan_transaction.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter/services.dart';

class WalletDetailsPage extends StatefulWidget {
  final Map<String, dynamic> wallet;
  const WalletDetailsPage({Key? key, required this.wallet}) : super(key: key);

  @override
  _WalletDetailsState createState () => _WalletDetailsState();
}

class _WalletDetailsState extends State<WalletDetailsPage> {
  late Map<String, dynamic> wallet;
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    _loadWalletDetail();
  }

  Future<void> _loadWalletDetail() async {
    try {
      setState(() {
        isLoading = true;
      });
      wallet = Map<String, dynamic>.from(widget.wallet);
      MemberService memberService = MemberService();
      bool isMember = await memberService.checkIsMember(wallet['address']) ?? false;
      wallet['can_play'] = false;
      wallet['next_play_time'] = 'Fetching...';
      wallet['sponsor'] = 'Fetching...';
      wallet['total_ref'] = 'Fetching...';
      wallet['total_ref'] = 'Fetching...';
      wallet['is_member'] = isMember;
      wallet['referrer_link'] = isMember ?  'https://kittyrun.io/?ref=${wallet['address']}' : 'N/A';
      wallet['can_play'] = false;
      wallet['info'] = {
        'totalVote': 0,
        'totalClaim': 0
      };
      bool can_play = await checkPlay(wallet['address']) ?? false;
      wallet['isMember'] = isMember;
      Map<String, dynamic>? dataTree = await memberService.fetchTree(wallet['address']);
      print('=====data ${dataTree} ${can_play}');
      String sponsor = await memberService.getSponsor(wallet['address']);
      String timePlay = await getTimePlay(wallet['address']);
      Map<String, int> depositPlay = await memberService.getPlayBalance(wallet['address']);
      Map<String, dynamic> info = await memberService.getUserInfo(wallet['address']);

      print('=======mouhted: $mounted');
      if (mounted) {
        setState(() {
          wallet['next_play_time'] = timePlay;
          wallet['sponsor'] = isMember ? sponsor : 'Please join kittyrun or looking for referrer link!';
          wallet['total_ref'] =  dataTree?['total'] ?? 0;
          wallet['can_play'] = isMember ? can_play : false;
          print("=====info $info");
          wallet['info'] = info;
          wallet['team'] = dataTree?['members'];
          wallet['deposit'] = depositPlay;
        });
      }

      ScanTransaction transaction = ScanTransaction();
      FilterEntity filter = FilterEntity(keyword: '', limit: 20, page: 1);
      Map<String, dynamic>? dataPlay = await transaction.scanServer(wallet['address'], filter);
      List<Map<String, dynamic>> dataUpdate = [];

      for (var entry in dataPlay?['data'] ?? []) {
        var member = entry;

        int timestamp = int.tryParse(member['timestamp'] ?? '0') ?? 0;
        bool isClaim = checkClaim(timestamp);

        if (isClaim) {
          int day = (timestamp / 86400).floor() - 20;
          Map<String, dynamic> infoUpdate = await memberService.getVote(member['address'] ?? '', day);
          print('======info new $infoUpdate');
          member['info'] = [infoUpdate['percent'], infoUpdate['claimed']];
        }

        dataUpdate.add(member);
      }


      
      setState(() {
        // wallet['played'] = dataPlay;
        print('data $dataPlay');
        wallet['histories'] = dataUpdate;
        isLoading = false;
      });
    } catch (e) {
      print('=====error update state detail $e');
      // Handle the error (e.g., print to console or show an error message)
    }
  }

  Future<void> _onPlay() async {
    try {
      wallet = Map<String, dynamic>.from(widget.wallet);
      TokenBalanceChecker checker = TokenBalanceChecker();
      MemberService memberService = MemberService();
      double? usdt = await checker.getUsdtBalance(wallet['address']);


      if (usdt! >= 32) {
        final txHash = await memberService.approveAndPlay(wallet['privateKey'] ?? '', EthereumAddress.fromHex(wallet['address'] ?? ''));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Play success $txHash',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Don't insufficient 32 USDT, Please deposit money to address",
          ),
          backgroundColor: Colors.yellow,
        ),
      );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Play error $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addAutoPlay (context) async {
    try {
      wallet = Map<String, dynamic>.from(widget.wallet);
      TokenBalanceChecker checker = TokenBalanceChecker();
      MemberService memberService = MemberService();
      double? usdt = await checker.getUsdtBalance(wallet['address']);

      if (usdt! >= 480) {
          String txHash = await memberService.addDeposit(context, wallet['privateKey'], wallet['address']);  
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Add auto play success $txHash',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please deposit money to address!',
            ),
            backgroundColor: Colors.yellow,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Add atuo play error $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  Future<void> _onClaim(Map<String, dynamic> played, List<Map<String, dynamic>> histories) async {
    try {
      Map<String, dynamic> wallet = Map<String, dynamic>.from(widget.wallet);
      print('on Claim $wallet');
      MemberService memberService = MemberService();
      int unixTime = int.parse(played['timestamp']);
      int day = (unixTime / 86400).floor() - 20;
      String txHash = await memberService.onClaim(
        wallet['privateKey'] ?? '', 
        EthereumAddress.fromHex(wallet['address'] ?? ''), 
        day,
      );
      if (txHash.isNotEmpty) {
        // Display success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Claim success $txHash'),
            backgroundColor: Colors.green,
          ),
        );
        List<Map<String, dynamic>> dataUpdate = [];

        for (var member in histories) {
          int timestamp = int.parse(member['timestamp']);
          bool isClaim = checkClaim(timestamp);

          if (isClaim) {
            int day = (timestamp / 86400).floor() - 20;
            Map<String, dynamic> infoUpdate = await memberService.getVote(member['address'] ?? '', day);
            print('======info new $infoUpdate');
            if(played['timestamp'] == member['timestamp']) {
              member['info'] = [infoUpdate['percent'], true]; 
            } else {
              member['info'] = [infoUpdate['percent'], infoUpdate['claimed']]; 
            }
          }
          dataUpdate.add(member);
        }
        wallet['histories'] = dataUpdate;

        print('==========update new $dataUpdate');
        setState(() {
          wallet = wallet;
        });

        // setState(() {
        //   print('==========update new $dataUpdate');
        //   wallet['histories'] = dataUpdate;
        // });
      }
    } catch (e) {
      // Display error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Claim error $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  String _shortenReferrerLink(String? link) {
    if (link == null || link.length < 10) {
      return link ?? 'N/A';
    }
    return '${link.substring(0, 10)}...';
  }
  String _shortenAddress(String? address) {
    if (address == null || address.length < 10) {
      return address ?? 'N/A';
    }
    return '${address.substring(0, 5)}...${address.substring(address.length - 5)}';
  }

  Future<void> _copyToClipboard(String? text) async {
    if (text != null && text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied',
            ),
            backgroundColor: Colors.green,
          ),
        );
      print('Referrer link copied to clipboard: $text'); // Debug message
    } else {
      print('No referrer link to copy'); // Debug message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wallet Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Card 1: Wallet Status
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              // Sử dụng Stack để chèn gradient background cho Card
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[600]!, Colors.green[200]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(12.0)), // Bo góc cho toàn bộ container
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hiển thị trạng thái chơi
                      Text(
                        'Status Play: ${isLoading ? 'Fetching...' : wallet['isMember'] ? (wallet['can_play'] ? 'Play' : 'Played') : "Can't Play"}',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 10),

                      // Hiển thị thời gian chơi tiếp theo
                      Text(
                        'Next Play: ${isLoading ? 'Fetching...' : wallet['next_play_time'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 10),

                      // Hiển thị sponsor với địa chỉ rút gọn
                      Text(
                        'Sponsor: ${isLoading ? 'Fetching...' : _shortenAddress(wallet['sponsor']) ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      // Hiển thị ký gửi
                      Text(
                        'Deposit Auto: ${isLoading ? 'Fetching...' : (wallet['deposit']['amount'])} USDT',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 10),

                      // Hiển thị số lượng total ref
                      Text(
                        'Total Ref: ${isLoading ? 'Fetching...' : wallet['total_ref'] ?? 0}',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 10),

                      // Hiển thị link rút gọn
                      Row(
                        children: [
                          Expanded(
                            // Rút gọn referrer link 10 ký tự đầu tiên
                            child: Text(
                              'Referrer Link: ${isLoading ? 'Fetching...' : _shortenReferrerLink(wallet['referrer_link']) ?? 'N/A'}',
                              style: const TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.white),
                            onPressed: wallet['is_member'] == true
                                ? () {
                              _copyToClipboard(wallet['referrer_link']);
                            }
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Nút Play và Auto Play
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Button 1: Play/WaitPlay
                          Expanded(
                            child: Container(
                              child: ElevatedButton(
                                onPressed: !isLoading && wallet['can_play'] == true
                                    ? () {
                                  _onPlay();
                                }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.green,
                                ),
                                child: Text(
                                  wallet['is_playing'] == true ? 'WaitPlay' : 'Play',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10,),
                          // Button 2: Auto Play
                          Expanded(
                            child: Container(
                              child: ElevatedButton(
                                onPressed: wallet['can_play'] == true
                                    ? () {
                                  _addAutoPlay(context);
                                }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.green,

                                ),
                                child: const Text(
                                  'Auto Play',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Card 2: Team Management
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    Text('Played Management ${ isLoading ?  0 : (wallet['info']?['totalVote'] ?? 0)} / ${isLoading ? 0 : (wallet['info']?['totalClaim'] ?? 0)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: (wallet['histories'] ?? []).length,
                      itemBuilder: (context, index) {
                        var member = wallet['histories'][index];
                        bool isClaim = checkClaim(int.parse(member['timestamp']));
                        String timeClaim = formatTimeEnd(int.parse(member['timestamp']));
                        String shortTxID = member['TxID'].substring(0, 5);  // Rút gọn TxID còn 5 ký tự

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: member['info'][1] == true || !isClaim ? Colors.green : Colors.red, // Xanh nếu đã claim, đỏ nếu interactive
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(8), // Bo góc cho đường viền
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                // Cột 1: Hiển thị index (#)
                                Expanded(
                                  flex: 1,  // Chiếm 1 phần
                                  child: Text(
                                    '#${index + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                // Cột 2: Chứa thông tin Played, TxID, và Time Claim
                                Expanded(
                                  flex: 5,  // Chiếm 5 phần
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Played: ${member['info'][1] == true ? 'Claimed' : 'Played'}'),
                                      Text('TxID: $shortTxID'),  // Rút gọn TxID chỉ còn 5 ký tự
                                      Text('Time claim: $timeClaim'),
                                    ],
                                  ),
                                ),
                                // Cột 3: Nút Action (Claim hoặc Claimed)
                                Expanded(
                                  flex: 3,  // Chiếm 3 phần
                                  child: ElevatedButton(
                                    onPressed: member['info'][1] == true ? null : isClaim
                                        ? () {
                                      _onClaim(member, wallet['histories']);
                                    }
                                        : null,  // Disable button if already Claimed
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: member['info'][1] == true
                                          ? Colors.orange // Màu cam khi đã Claimed, dù đã disable vẫn giữ màu
                                          : isClaim == true
                                          ? Colors.green // Màu xanh khi có thể Claim
                                          : Colors.grey, // Màu xám khi không thể Claim
                                    ),
                                    child: Text(
                                      member['info'][1] == true
                                          ? 'Claimed' // Hiển thị Claimed khi đã Claim
                                          : isClaim
                                          ? 'Claim' // Hiển thị Claim nếu có thể Claim
                                          : 'Interactive',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // // Card 3: My Members
            // Card(
            //   elevation: 4,
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(12.0),
            //   ),
            //   child: Padding(
            //     padding: const EdgeInsets.all(16.0),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         const Text('My Members ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            //         const SizedBox(height: 10),
            //         ListView.builder(
            //           physics: const NeverScrollableScrollPhysics(),
            //           shrinkWrap: true,
            //           itemCount: (wallet['members'] ?? []).length,
            //           itemBuilder: (context, index) {
            //             var member = wallet['members'][index];
            //             return Padding(
            //               padding: const EdgeInsets.symmetric(vertical: 8.0),
            //               child: Column(
            //                 crossAxisAlignment: CrossAxisAlignment.start,
            //                 children: [
            //                   Text(
            //                       'Index: ${member['index']}, Address: ${member['address']}, Ref1: ${member['ref1']}, Ref2: ${member['ref2']}, Ref3: ${member['ref3']}'),
            //                   const SizedBox(height: 5),
            //                   Text('Total Play: ${member['total_play']}, Play Month: ${member['play_month']}'),
            //                 ],
            //               ),
            //             );
            //           },
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
