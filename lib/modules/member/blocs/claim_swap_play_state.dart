part of 'claim_swap_play_bloc.dart';
enum BlocStatus {initial, loading, processing, success, failed}

class ClaimSwapPlayState extends Equatable {
  final BlocStatus status;
  final List<Map<String,String>>  members;
  final FilterEntity filters;
  final String title;
  final String message;

  const ClaimSwapPlayState({
    this.status = BlocStatus.initial,
    this.members = const [],
    required this.filters,
    this.title = '',
    this.message = ''
  });

  ClaimSwapPlayState copyWith({
    BlocStatus? status,
    List<Map<String,String>>? data,
    List<Map<String,String>>? members,
    FilterEntity? filters,
    String? title,
    String? message,
  }) {
    return ClaimSwapPlayState(
      status: status ?? this.status,
      members: members ?? this.members,
      filters: filters ?? this.filters,
      title: title ?? this.title,
      message: message ?? this.message
    );
  }

  @override
  List<Object> get props => [status, members, title, message];
}
