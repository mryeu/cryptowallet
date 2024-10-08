class FilterEntity {
  final String keyword;
  final int limit;
  final int page;

  FilterEntity({required this.keyword, required this.limit, required this.page});

  factory FilterEntity.initial() {
    return FilterEntity(
      keyword: '',
      limit: 100,
      page: 1,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['keyword'] = keyword;
    data['page'] = page;
    return data;
  }

  factory FilterEntity.fromJson(dynamic json) {
    return FilterEntity(
      limit: json["limit"] ?? 10,
      keyword: json["keyword"] ?? "",
      page: json["page"] ?? 1,
    );
  }

  factory FilterEntity.override(
    FilterEntity model, {
    required Map<String, dynamic> map,
  }) {
    return FilterEntity.fromJson({
      ...model.toJson(),
      ...map,
    });
  }

  Map<String, dynamic> toParams() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['\$limit'] = limit;
    data['\$sort[createdAt]'] = -1;
    data['\$skip'] = page * limit;

    return data;
  }
}
