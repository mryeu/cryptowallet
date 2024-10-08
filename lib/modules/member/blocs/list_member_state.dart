part of 'list_member_bloc.dart';
enum BlocStatus {initial, loading, success, failed}

class ListMemberState extends Equatable {
  final BlocStatus status;
  final List<Map<String,String>>  data;
  final List<Map<String,String>>  members;
  final List<Map<String,String>>  notMembers;
  

  const ListMemberState({
    this.status = BlocStatus.initial,
    this.data = const [],
    this.members = const [],
    this.notMembers = const []
   
  });

  ListMemberState copyWith({
    BlocStatus? status,
    List<Map<String,String>>? data,
    List<Map<String,String>>? members,
    List<Map<String,String>>? notMembers,
  }) {
    return ListMemberState(
      status: status ?? this.status,
      data: data ?? this.data,
      members: members ?? this.members,
      notMembers: notMembers ?? this.notMembers
    );
  }

  @override
  List<Object> get props => [status, data];
}
