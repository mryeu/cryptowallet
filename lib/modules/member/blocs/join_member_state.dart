part of 'join_member_bloc.dart';
enum BlocStatus {initial, loading, success, failed}

class JoinMemberState extends Equatable {
  final BlocStatus status;
  final List<Map<String,String>>  data;
  final List<Map<String,String>>  members;
  final List<Map<String,String>>  notMembers;
  final List<Map<String,String>>  joinMember;


  const JoinMemberState({
    this.status = BlocStatus.initial,
    this.data = const [],
    this.members = const [],
    this.notMembers = const [],
    this.joinMember = const []
  });

  JoinMemberState copyWith({
    BlocStatus? status,
    List<Map<String,String>>? data,
    List<Map<String,String>>? members,
    List<Map<String,String>>? notMembers,
  }) {
    return JoinMemberState(
      status: status ?? this.status,
      data: data ?? this.data,
      members: members ?? this.members,
      notMembers: notMembers ?? this.notMembers,
    );
  }

  @override
  List<Object> get props => [status, data.hashCode, members, notMembers];
}
