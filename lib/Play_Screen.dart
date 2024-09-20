import 'package:flutter/material.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  _PlayScreenState createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  String? selectedWallet = 'All Wallets'; // Default selected wallet
  final List<String> walletFilterOptions = [
    'All Wallets',
    'Wallet 1',
    'Wallet 2',
    'Wallet 3'
  ]; // Wallet filter options
  final List<Map<String, dynamic>> wallets = [
    {'name': 'Wallet 1', 'balance': '500 USDT'},
    {'name': 'Wallet 2', 'balance': '1.234 BNB'},
    {'name': 'Wallet 3', 'balance': '2500 KTR'},
    {'name': 'Wallet 4', 'balance': '1500 USDT'},
    {'name': 'Wallet 5', 'balance': '1500 USDT'},
    {'name': 'Wallet 6', 'balance': '1500 USDT'},
    {'name': 'Wallet 7', 'balance': '1500 USDT'},
    // Additional wallets can go here
  ];

  final List<String> teamManagement = [
    'Team Member 1',
    'Team Member 2',
    'Team Member 3',
    'Team Member 4',
    'Team Member 5',
    'Team Member 6'
  ];
  final List<String> myMembers = [
    'Member 1',
    'Member 2',
    'Member 3',
    'Member 4',
    'Member 5',
    'Member 6',
    'Member 7'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Light background for contrast
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and filtering options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Play Screen',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700]),
                  ),
                  // Dropdown to select wallet filter
                  DropdownButton<String>(
                    dropdownColor: Colors.green[100],
                    value: selectedWallet,
                    icon: const Icon(Icons.filter_list, color: Colors.green),
                    underline: Container(height: 2, color: Colors.greenAccent),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedWallet = newValue;
                      });
                    },
                    items: walletFilterOptions
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child:
                        Text(value, style: const TextStyle(color: Colors.green)),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Handle Join action
                    },
                    icon: const Icon(Icons.group_add),
                    label: const Text('Join'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green, // Text color
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Handle Play action
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green, // Text color
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Handle Claim-Swap-Play action
                    },
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Claim-Swap-Play'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green, // Text color
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Wallets section header
              Text(
                'Your Wallets',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700]),
              ),
              const SizedBox(height: 10),

              // Wallet cards
              Expanded(
                child: ListView.builder(
                  itemCount: wallets.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // Show full-screen popup when wallet is tapped
                        showFullScreenModal(context, wallets[index]);
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                          side: const BorderSide(color: Colors.green, width: 2),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                wallets[index]['name'],
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Balance: ${wallets[index]['balance']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to show the full-screen modal with wallet info, team management, and my member
  void showFullScreenModal(BuildContext context, Map<String, dynamic> wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Full-screen popup
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder( // Thêm dòng này để loại bỏ bo tròn
        borderRadius: BorderRadius.zero,
      ),
      builder: (BuildContext context) {
        return ModalContent(
          wallet: wallet,
          teamManagement: teamManagement,
          myMembers: myMembers,
        );
      },
    );
  }
}

// StatefulWidget to handle pagination inside the modal
class ModalContent extends StatefulWidget {
  final Map<String, dynamic> wallet;
  final List<String> teamManagement;
  final List<String> myMembers;

  const ModalContent({
    Key? key,
    required this.wallet,
    required this.teamManagement,
    required this.myMembers,
  }) : super(key: key);

  @override
  _ModalContentState createState() => _ModalContentState();
}

class _ModalContentState extends State<ModalContent> {
  int teamCurrentPage = 0;
  int myMemberCurrentPage = 0;
  static const int itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    // Calculate total pages for team management
    int teamTotalPages =
        (widget.teamManagement.length + itemsPerPage - 1) ~/ itemsPerPage;
    // Calculate total pages for my members
    int myMemberTotalPages =
        (widget.myMembers.length + itemsPerPage - 1) ~/ itemsPerPage;

    return Container(
      height: MediaQuery.of(context).size.height,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),

          // Using Flex to divide the screen into parts
          Expanded(
            child: Flex(
              direction: Axis.vertical,
              children: [
                // 1 Part for Wallet Details
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    width: double.infinity, // Đặt chiều ngang full bằng popup
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      color: Colors.transparent, // Đặt Card trong suốt để thấy gradient
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.greenAccent.shade100,
                              Colors.green.shade300,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(5), // Bo góc cho gradient
                          border: Border.all(color: Colors.green, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.wallet['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white, // Đặt màu chữ để tương phản với gradient
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Balance: ${widget.wallet['balance']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white, // Đặt màu chữ để tương phản với gradient
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),


                // 2 Parts for Team Management
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Team Management',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700]),
                        ),
                        const SizedBox(height: 5),
                        Expanded(
                          child: ListView.builder(
                            itemCount: getTeamItems().length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(getTeamItems()[index]),
                                leading: const Icon(Icons.person),
                              );
                            },
                          ),
                        ),
                        // Pagination Controls for Team Management
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Page ${teamCurrentPage + 1} of $teamTotalPages',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: teamCurrentPage > 0
                                      ? () {
                                    setState(() {
                                      teamCurrentPage--;
                                    });
                                  }
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward),
                                  onPressed: teamCurrentPage < teamTotalPages - 1
                                      ? () {
                                    setState(() {
                                      teamCurrentPage++;
                                    });
                                  }
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 2 Parts for My Members
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Member',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700]),
                        ),
                        const SizedBox(height: 5),
                        Expanded(
                          child: ListView.builder(
                            itemCount: getMyMemberItems().length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(getMyMemberItems()[index]),
                                leading: const Icon(Icons.person),
                              );
                            },
                          ),
                        ),
                        // Pagination Controls for My Members
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Page ${myMemberCurrentPage + 1} of $myMemberTotalPages',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: myMemberCurrentPage > 0
                                      ? () {
                                    setState(() {
                                      myMemberCurrentPage--;
                                    });
                                  }
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward),
                                  onPressed: myMemberCurrentPage <
                                      myMemberTotalPages - 1
                                      ? () {
                                    setState(() {
                                      myMemberCurrentPage++;
                                    });
                                  }
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Functions to get items for the current page for team management
  List<String> getTeamItems() {
    int startIndex = teamCurrentPage * _ModalContentState.itemsPerPage;
    int endIndex = startIndex + _ModalContentState.itemsPerPage;
    endIndex = endIndex > widget.teamManagement.length
        ? widget.teamManagement.length
        : endIndex;
    return widget.teamManagement.sublist(startIndex, endIndex);
  }

  // Functions to get items for the current page for my members
  List<String> getMyMemberItems() {
    int startIndex = myMemberCurrentPage * _ModalContentState.itemsPerPage;
    int endIndex = startIndex + _ModalContentState.itemsPerPage;
    endIndex = endIndex > widget.myMembers.length
        ? widget.myMembers.length
        : endIndex;
    return widget.myMembers.sublist(startIndex, endIndex);
  }
}
