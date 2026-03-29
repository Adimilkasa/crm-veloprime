class OfferPdfVersionResult {
  const OfferPdfVersionResult({
    required this.id,
    required this.versionNumber,
    required this.summary,
    required this.createdAt,
    required this.pdfUrl,
  });

  final String id;
  final int versionNumber;
  final String summary;
  final String createdAt;
  final String? pdfUrl;

  factory OfferPdfVersionResult.fromJson(Map<String, dynamic> json) {
    return OfferPdfVersionResult(
      id: json['id'] as String? ?? '',
      versionNumber: json['versionNumber'] as int? ?? 0,
      summary: json['summary'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      pdfUrl: json['pdfUrl'] as String?,
    );
  }
}