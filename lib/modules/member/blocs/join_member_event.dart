part of 'join_member_bloc.dart';

abstract class JoinMemberEvent extends Equatable {
  const JoinMemberEvent(); // Add a constructor to allow const for events

  @override
  List<Object> get props => [];
}

// Event triggered to initialize the join member process
class onJoinMemberInit extends JoinMemberEvent {
  final List<Map<String,String>> walletList;

  const onJoinMemberInit({ required this.walletList}); // Keep this event simple with no props
}

// Event triggered when the filter is changed
class onJoinMemberFilterChanged extends JoinMemberEvent {
  final Map<String, String> filter;

  const onJoinMemberFilterChanged({required this.filter});

  @override
  List<Object> get props => [filter];
}

class onJoinMember extends JoinMemberEvent {
  final List<Map<String,String>> selectedMember;
  final String refCode;
  final BuildContext context;
  final List<bool> checked;

  const onJoinMember({required this.context,required this.selectedMember, required this.refCode, required this.checked });

  @override
  List<Object> get props => [selectedMember, refCode]; 
}

class onCheckedMember extends JoinMemberEvent {
  final List<Map<String,String>> checkedMember;
  final bool checked;

  const onCheckedMember({ required this.checkedMember, required this.checked });

  @override
  // TODO: implement hashCode
  List <Object> get props => [checkedMember , checked];
}

class onPlayNow extends JoinMemberEvent {
  final List<Map<String, String>> checkedMember;
  final List<bool> checked;
  final BuildContext context;

  const onPlayNow({ required this.checkedMember , required this.checked, required this.context });
}