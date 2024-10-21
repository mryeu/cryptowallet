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

  Future<void> _onClaim(Map<String, dynamic> played) async {
    try {
      wallet = Map<String, dynamic>.from(widget.wallet);
      print('on Claim $wallet');
      MemberService memberService = MemberService();
      int unixTime = int.parse(played['timestamp']);
      int day = (unixTime / 86400).floor() - 20;
      String txHash =  await memberService.onClaim(wallet['privateKey'] ?? '', EthereumAddress.fromHex(wallet['address'] ?? ''), day);
      print('txHash $txHash');
      if (txHash != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Claim success $txHash',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadWalletDetail();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Claim error $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  Future<void> _copyToClipboard(String? text) async {
    if (text != null && text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      print('Referrer link copied to clipboard: $text'); // Debug message
    } else {
      print('No referrer link to copy'); // Debug message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Details'),
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status Play: ${ isLoading ? 'Fetching...' :  wallet['isMember'] ? ( wallet['can_play'] ? 'Play' : 'Played') : "Can't Play"}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Text('Next Play: ${ isLoading ? 'Fetching....' : wallet['next_play_time'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Text('Sponsor: ${isLoading ? 'Fetching....' : wallet['sponsor'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Text('Total Ref: ${isLoading ? 'Fetcing...' : wallet['total_ref'] ?? 0}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Referrer Link: ${ isLoading ? 'Fetching...' : wallet['referrer_link'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: wallet['is_member'] == true ?  () {
                            // Copy referrer link to clipboard
                            _copyToClipboard(wallet['referrer_link']);
                          } : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Button 1: Play/WaitPlay
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF56AB2F),Color(0xFFA8E063) ], // Light green to dark green gradient
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: ElevatedButton(
                                onPressed: !isLoading &&  wallet['can_play'] == true
                                  ? () {
                                      _onPlay();
                                    }
                                  : null, 
                                style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              child: Text(
                                wallet['is_playing'] == true ? 'WaitPlay' : 'Play',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),

                        // Button 2: Auto Play
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFA8E063), Color(0xFF56AB2F)], // Light green to dark green gradient
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: ElevatedButton(
                              onPressed: wallet['can_play'] == true ?  () {
                                _addAutoPlay(context);
                                // Handle Auto Play action
                              } : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
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
                        print('=====> member $member ${wallet['histories']}');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Index: ${index + 1}, Played: ${member['info'][0] ? 'Claimed' : 'Played'}, TxID: ${member['TxID']}'),
                              const SizedBox(height: 5),
                              Text('Amount: ${31 + ((31 * member['info'][0]) / 100000)} USDT'),
                              const SizedBox(height: 5),
                              Text('Time claim: ${timeClaim}'),
                              const SizedBox(height: 5),
                              ElevatedButton(
                                onPressed: isClaim ? () {
                                  _onClaim(member);
                                } : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: member['info'][1] == true
                                      ? Colors.grey
                                      : isClaim  == true
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                child: Text(member['info'][1] == true
                                    ? 'Claimed'
                                    : isClaim
                                    ? 'Claim'
                                    : 'Interactive'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
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
