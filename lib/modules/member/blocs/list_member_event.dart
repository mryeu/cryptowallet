part of 'list_member_bloc.dart';

abstract class ListMemberEvent extends Equatable {
  const ListMemberEvent(); // Add a constructor to allow const for events

  @override
  List<Object> get props => [];
}

// Event triggered to initialize the join member process
class onListMemberInit extends ListMemberEvent {
  final List<Map<String,String>> walletList;

  const onListMemberInit({ required this.walletList}); // Keep this event simple with no props
}

class onAddDeposit extends ListMemberEvent {
  final String privateKey;
  final String walletAddress;
  final BuildContext context;

  const onAddDeposit({ required this.context, required this.privateKey, required this.walletAddress });
}
