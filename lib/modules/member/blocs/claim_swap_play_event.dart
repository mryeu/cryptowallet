part of 'claim_swap_play_bloc.dart';

abstract class ClaimSwapPlayEvent extends Equatable {
  const ClaimSwapPlayEvent();
}

// Event triggered to initialize the join member process
class onClaimSwapPlayInit extends ClaimSwapPlayEvent {
  final List<Map<String, String>> members;

  const onClaimSwapPlayInit({required this.members}); // Ensure the constructor initializes members

  @override
  List<Object> get props => [members];
}

class onAutoClaimSwapPlay extends ClaimSwapPlayEvent {
    final List<Map<String, String>> members;

  const onAutoClaimSwapPlay({ required this.members });
  
  @override
  // TODO: implement props
  List<Object?> get props => [members];
}