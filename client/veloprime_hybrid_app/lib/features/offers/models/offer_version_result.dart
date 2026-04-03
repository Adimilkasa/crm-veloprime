class OfferVersionResult {
  const OfferVersionResult({
    required this.id,
    required this.versionNumber,
    required this.summary,
    required this.createdAt,
  });

  final String id;
  final int versionNumber;
  final String summary;
  final String createdAt;

  factory OfferVersionResult.fromJson(Map<String, dynamic> json) {
    return OfferVersionResult(
      id: json['id'] as String? ?? '',
      versionNumber: json['versionNumber'] as int? ?? 0,
      summary: json['summary'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}