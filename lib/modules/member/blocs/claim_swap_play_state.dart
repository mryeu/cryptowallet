part of 'claim_swap_play_bloc.dart';

enum BlocStatus { initial, loading, processing, success, failed, failure }

class ClaimSwapPlayState extends Equatable {
  final BlocStatus status;
  final List<Map<String, dynamic>> members; // Danh sách thành viên (ví)
  final FilterEntity filters;
  final String title; // Tiêu đề thông báo
  final String message; // Thông báo
  final List<String> messages; // Danh sách các thông báo tiến trình

  const ClaimSwapPlayState({
    this.status = BlocStatus.initial,
    this.members = const [], // Danh sách các thành viên khởi tạo rỗng
    required this.filters, // Yêu cầu bộ lọc (filters)
    this.title = '',
    this.message = '',
    this.messages = const [], // Danh sách các thông báo tiến trình khởi tạo rỗng
  });

  // Hàm copyWith giúp tạo một phiên bản mới của state với các thay đổi cụ thể
  ClaimSwapPlayState copyWith({
    BlocStatus? status,
    List<Map<String, dynamic>>? members, // Sửa lại tham số data thành members cho nhất quán
    FilterEntity? filters,
    String? title,
    String? message,
    List<String>? messages, // Thêm khả năng cập nhật danh sách các thông báo
  }) {
    return ClaimSwapPlayState(
      status: status ?? this.status,
      members: members ?? this.members,
      filters: filters ?? this.filters,
      title: title ?? this.title,
      message: message ?? this.message,
      messages: messages ?? this.messages, // Cập nhật danh sách thông báo nếu có
    );
  }

  @override
  List<Object> get props => [status, members, title, message, messages]; // Thêm messages vào props
}
