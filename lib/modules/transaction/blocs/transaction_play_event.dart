part of 'transaction_play_bloc.dart';

abstract class TransactionPlayEvent extends Equatable {
  const TransactionPlayEvent(); // Add a constructor to allow const for events

  @override
  List<Object> get props => [];
}

// Event triggered to initialize the join member process
class OnTransactionPlayInit extends TransactionPlayEvent {
  final List<Map<String,dynamic>> walletList;
  final String selected;
  const OnTransactionPlayInit({ required this.walletList, required this.selected });
  
  @override
  List<Object> get props => [walletList.hashCode, selected.hashCode];
   // Keep this event simple with no props
}



class OnSelectedWallet extends TransactionPlayEvent {
  final String selected;
  final String privatekey;

  const OnSelectedWallet({ required this.selected, required this.privatekey });

  @override
  List<Object> get props => [selected, privatekey];
}

class OnClaimPlayed extends TransactionPlayEvent {
  final String privateKey;
  final int timestamp;
  final String walletAddress;
  final BuildContext context;

  const OnClaimPlayed({ required this.context, required this.privateKey, required  this.timestamp, required this.walletAddress });

  @override
  List<Object> get props => [context, privateKey, timestamp, walletAddress];
}

class OnGetVote extends TransactionPlayEvent {
  final String walletAddress;
  final int day;

  const OnGetVote({ required this.walletAddress, required this.day });
  @override
  List<Object> get props => [ day, walletAddress];
}


class OnTransactionPlayLoadMore extends TransactionPlayEvent {}