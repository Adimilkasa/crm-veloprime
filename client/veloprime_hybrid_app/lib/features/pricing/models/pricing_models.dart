class PricingSheetData {
  const PricingSheetData({
    required this.headers,
    required this.rows,
    required this.updatedAt,
    required this.updatedBy,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final String? updatedAt;
  final String? updatedBy;

  factory PricingSheetData.fromJson(Map<String, dynamic> json) {
    final rawHeaders = (json['headers'] as List<dynamic>? ?? const []).map((value) => value.toString()).toList();
    final rawRows = (json['rows'] as List<dynamic>? ?? const [])
        .map(
          (row) => (row as List<dynamic>? ?? const [])
              .map((value) => value.toString())
              .toList(),
        )
        .toList();

    return PricingSheetData(
      headers: rawHeaders,
      rows: rawRows,
      updatedAt: json['updatedAt'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  PricingSheetData copyWith({
    List<String>? headers,
    List<List<String>>? rows,
    String? updatedAt,
    String? updatedBy,
  }) {
    return PricingSheetData(
      headers: headers ?? this.headers,
      rows: rows ?? this.rows,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}