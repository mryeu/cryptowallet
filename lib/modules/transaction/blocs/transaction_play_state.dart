part of 'transaction_play_bloc.dart';
enum BlocStatus {initial, loading, loadMore, success, failed}


class TransactionPlayState extends Equatable {
  final BlocStatus status;
  final List<Map<String,dynamic>> data;
  final List<dynamic> dataPlay; // List to hold the transaction data
  final String? selectedAddress;
  final bool hasMaxReached;
  final FilterEntity filters;
  final String privateKeySelected;

  const TransactionPlayState({
    required this.filters,
    this.status = BlocStatus.initial,
    this.data = const [],
    this.dataPlay = const [],
    this.selectedAddress,
    this.hasMaxReached = false,
    this.privateKeySelected = ''
  });

  TransactionPlayState copyWith({
    BlocStatus? status,
    List<Map<String,dynamic>>? data,
    List<dynamic>? dataPlay,
    String? selectedAddress,
    bool? hasMaxReached,
    FilterEntity? filters,
    String ? privateKey,
  }) {
    return TransactionPlayState(
      status: status ?? this.status,
      data: data ?? this.data,
      dataPlay: dataPlay ?? this.dataPlay,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      hasMaxReached: hasMaxReached ?? this.hasMaxReached,
      filters: filters ?? this.filters,
      privateKeySelected: privateKey ?? this.privateKeySelected
    );
  }

  // TransactionPlayState setSelectedAddress({
  //   BlocStatus? status,
  //   String? selectedAddress
  // }) {
  //   return TransactionPlayState(
  //     status: status?? this.status,
  //     selectedAddress: selectedAddress ?? this.selectedAddress
  //   );
  // }

  @override
  List<Object> get props => [status, data.hashCode, dataPlay,hasMaxReached, filters];
}
