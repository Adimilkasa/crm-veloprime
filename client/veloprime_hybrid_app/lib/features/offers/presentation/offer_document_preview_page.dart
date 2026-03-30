import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/presentation/veloprime_ui.dart';
import '../data/local_offer_assets.dart';
import '../data/offers_repository.dart';
import '../models/offer_document.dart';

class OfferDocumentPreviewPage extends StatefulWidget {
  const OfferDocumentPreviewPage({
    super.key,
    required this.offerId,
    required this.repository,
    this.initialDocument,
    this.versionId,
  });

  final String offerId;
  final String? versionId;
  final OffersRepository repository;
  final OfferDocumentSnapshot? initialDocument;

  @override
  State<OfferDocumentPreviewPage> createState() => _OfferDocumentPreviewPageState();
}

class _OfferDocumentPreviewPageState extends State<OfferDocumentPreviewPage> {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  late Future<OfferDocumentSnapshot> _documentFuture;

  @override
  void initState() {
    super.initState();
    _documentFuture = widget.initialDocument != null && (widget.versionId == null || widget.versionId!.isEmpty)
        ? Future.value(widget.initialDocument)
        : widget.repository.fetchDocumentSnapshot(
            offerId: widget.offerId,
            versionId: widget.versionId,
          );
  }

  Future<void> _openBundledDocument(String assetPath, String label) async {
    try {
      final assetBytes = await rootBundle.load(assetPath);
      final extension = assetPath.contains('.') ? assetPath.substring(assetPath.lastIndexOf('.')) : '';
      final tempDirectory = await Directory.systemTemp.createTemp('veloprime_offer_');
      final tempFile = File('${tempDirectory.path}/$label$extension');
      await tempFile.writeAsBytes(
        assetBytes.buffer.asUint8List(assetBytes.offsetInBytes, assetBytes.lengthInBytes),
        flush: true,
      );

      final opened = await launchUrl(Uri.file(tempFile.path), mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie udalo sie otworzyc dokumentu: $label.')),
        );
      }
    } on FlutterError {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Brak lokalnego dokumentu: $label.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udalo sie przygotowac dokumentu: $label.\n$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VeloPrimeShell(
        decorateBackground: true,
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
        child: FutureBuilder<OfferDocumentSnapshot>(
        future: _documentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const VeloPrimeWorkspaceState(
              tint: VeloPrimePalette.sea,
              eyebrow: 'Podglad dokumentu',
              title: 'Ladujemy snapshot dokumentu',
              message: 'Przygotowujemy podglad sekcji, parametrow i materialow.',
              isLoading: true,
            );
          }

          if (snapshot.hasError) {
            return VeloPrimeWorkspaceState(
              tint: VeloPrimePalette.rose,
              eyebrow: 'Podglad dokumentu',
              title: 'Nie udalo sie pobrac snapshotu dokumentu',
              message: '${snapshot.error}',
              icon: Icons.warning_amber_rounded,
              action: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Wroc do edycji'),
              ),
            );
          }

          final document = snapshot.data;
          if (document == null) {
            return const VeloPrimeWorkspaceState(
              tint: VeloPrimePalette.sea,
              eyebrow: 'Podglad dokumentu',
              title: 'Brak danych dokumentu',
              message: 'Snapshot nie zawiera jeszcze gotowych danych do prezentacji.',
              icon: Icons.preview_outlined,
            );
          }

          final customer = document.payload.customer;
          final advisor = document.payload.advisor;
          final localAssets = getLocalOfferAssetBundle(customer.modelName ?? document.title);
          final galleryImages = localAssets.galleryImages;
          final heroImageAsset = localAssets.heroImageAsset;
            final contactParts = [customer.customerEmail, customer.customerPhone]
              .whereType<String>()
              .where((item) => item.trim().isNotEmpty)
              .toList();
            final contactLine = contactParts.isEmpty ? 'Kontakt do potwierdzenia' : contactParts.join(' • ');
            final advisorParts = [advisor.email, advisor.phone]
              .whereType<String>()
              .where((item) => item.trim().isNotEmpty)
              .toList();
            final advisorLine = advisorParts.isEmpty ? 'Brak danych kontaktowych opiekuna' : advisorParts.join(' • ');
            final commercialSummary = customer.financingSummary != null && customer.financingSummary!.trim().isNotEmpty
              ? customer.financingSummary!
              : customer.financingVariant ?? 'Warunki ustalane indywidualnie';
            final offerNarrative = 'Dokument zbiera konfigurację ${customer.modelName ?? document.title} '
              'dla ${customer.customerName}, poziom ceny końcowej i proponowany scenariusz rozmowy o finansowaniu: $commercialSummary.';
          final specPdfAssetPath = localAssets.specPdfAssetPath;

          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Powrot'),
                        ),
                        if (specPdfAssetPath != null)
                          OutlinedButton.icon(
                            onPressed: () => _openBundledDocument(specPdfAssetPath, 'specyfikacja-modelu'),
                            icon: const Icon(Icons.description_outlined),
                            label: const Text('Otworz specyfikacje PDF'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _PreviewHeroCard(
                      document: document,
                      heroImageAsset: heroImageAsset,
                      dateFormat: _dateFormat,
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _PreviewMetricCard(label: 'Model', value: customer.modelName ?? document.title),
                        _PreviewMetricCard(label: 'Kolor', value: customer.selectedColorName ?? 'Bazowy'),
                        _PreviewMetricCard(label: 'Kontakt', value: contactLine),
                        _PreviewMetricCard(label: 'Finansowanie', value: commercialSummary),
                      ],
                    ),
                    if (specPdfAssetPath != null) ...[
                      const SizedBox(height: 20),
                      _PreviewSectionCard(
                        title: 'Specyfikacja modelu',
                        child: _LinkedAssetCard(
                          eyebrow: 'Dokument pomocniczy',
                          title: 'PDF specyfikacji samochodu',
                          value: 'Plik jest wbudowany w aplikacje i otwiera sie lokalnie bez przechodzenia przez WWW.',
                          icon: Icons.description_outlined,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 980;
                        final left = Column(
                          children: [
                            _PreviewSectionCard(
                              title: 'Skrot handlowy',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    offerNarrative,
                                    style: const TextStyle(color: Colors.black87, height: 1.6),
                                  ),
                                  const SizedBox(height: 16),
                                  _PreviewInfoGrid(items: [
                                    _PreviewInfoItem('Numer oferty', customer.offerNumber),
                                    _PreviewInfoItem('Kontakt', contactLine),
                                    _PreviewInfoItem('Konfiguracja', '${customer.modelName ?? '-'} • ${customer.selectedColorName ?? 'Bazowy'}'),
                                    _PreviewInfoItem('Waznosc', _formatNullableDate(customer.validUntil) ?? '-'),
                                  ]),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _PreviewSectionCard(
                              title: 'Dane dokumentu',
                              child: _PreviewInfoGrid(items: [
                                _PreviewInfoItem('Numer oferty', customer.offerNumber),
                                _PreviewInfoItem('Klient', customer.customerName),
                                _PreviewInfoItem('Email', customer.customerEmail ?? '-'),
                                _PreviewInfoItem('Telefon', customer.customerPhone ?? '-'),
                                _PreviewInfoItem('Model', customer.modelName ?? '-'),
                                _PreviewInfoItem('Kolor', customer.selectedColorName ?? '-'),
                                _PreviewInfoItem('Wazna do', _formatNullableDate(customer.validUntil) ?? '-'),
                                _PreviewInfoItem('Utworzono', _formatNullableDate(customer.createdAt, _dateFormat) ?? '-'),
                              ]),
                            ),
                            const SizedBox(height: 16),
                            _PreviewSectionCard(
                              title: 'Wycena dla klienta',
                              child: _PreviewInfoGrid(items: [
                                _PreviewInfoItem('Cena katalogowa', customer.listPriceLabel),
                                _PreviewInfoItem('Rabat', customer.discountLabel),
                                _PreviewInfoItem('Rabat %', customer.discountPercentLabel),
                                _PreviewInfoItem('Final brutto', customer.finalGrossLabel),
                                _PreviewInfoItem('Final netto', customer.finalNetLabel),
                              ]),
                            ),
                          ],
                        );

                        final right = Column(
                          children: [
                            _PreviewSectionCard(
                              title: 'Finansowanie i opis',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _PreviewInfoGrid(items: [
                                    _PreviewInfoItem('Wariant finansowania', customer.financingVariant ?? '-'),
                                    _PreviewInfoItem('Podsumowanie', customer.financingSummary ?? '-'),
                                  ]),
                                  if (customer.financingDisclaimer != null && customer.financingDisclaimer!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _PreviewCalloutBox(
                                      title: 'Disclaimer finansowania',
                                      value: customer.financingDisclaimer!,
                                      tint: const Color(0xFFF7F1E1),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  _PreviewCalloutBox(
                                    title: 'Uwagi do oferty',
                                    value: customer.notes?.isNotEmpty == true
                                        ? customer.notes!
                                        : 'Brak dodatkowych notatek w dokumencie. Ten snapshot jest gotowym punktem wyjścia do rozmowy handlowej.',
                                    tint: const Color(0xFFF3EFE7),
                                  ),
                                  const SizedBox(height: 12),
                                  _PreviewCalloutBox(
                                    title: 'Opiekun oferty',
                                    value: [
                                      advisor.fullName.isNotEmpty ? advisor.fullName : document.payload.internal.ownerName,
                                      advisorLine,
                                    ].where((item) => item.trim().isNotEmpty).join('\n'),
                                    tint: const Color(0xFFEAF4F4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _PreviewSectionCard(
                              title: 'Materiały modelu',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Galeria wspiera rozmowę z klientem i pokazuje finalny kierunek konfiguracji bez wychodzenia z aplikacji.',
                                    style: const TextStyle(color: Colors.black54, height: 1.55),
                                  ),
                                  const SizedBox(height: 14),
                                  _AssetGallery(
                                    heroImageAsset: heroImageAsset,
                                    imageAssets: galleryImages,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: left),
                              const SizedBox(width: 20),
                              Expanded(flex: 2, child: right),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            left,
                            const SizedBox(height: 16),
                            right,
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}

class _PreviewHeroCard extends StatelessWidget {
  const _PreviewHeroCard({
    required this.document,
    required this.heroImageAsset,
    required this.dateFormat,
  });

  final OfferDocumentSnapshot document;
  final String? heroImageAsset;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return VeloPrimeWorkspacePanel(
      tint: VeloPrimePalette.sea,
      radius: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const VeloPrimeSectionEyebrow(label: 'Podglad dokumentu', color: VeloPrimePalette.sea),
            const SizedBox(height: 12),
            Text(
              document.title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '${document.offerNumber} • wersja ${document.payload.versionNumber}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _PreviewPill(label: 'Klient', value: document.payload.customer.customerName),
                _PreviewPill(label: 'Brutto', value: document.payload.customer.finalGrossLabel),
                _PreviewPill(label: 'Netto', value: document.payload.customer.finalNetLabel),
                _PreviewPill(label: 'Wygenerowano', value: _formatNullableDate(document.payload.createdAt, dateFormat) ?? '-'),
              ],
            ),
            if (heroImageAsset != null) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  heroImageAsset!,
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const _MissingImagePlaceholder(label: 'Brak podgladu grafiki modelu'),
                ),
              ),
            ],
          ],
      ),
    );
  }
}

class _AssetGallery extends StatelessWidget {
  const _AssetGallery({
    required this.heroImageAsset,
    required this.imageAssets,
  });

  final String? heroImageAsset;
  final List<String> imageAssets;

  @override
  Widget build(BuildContext context) {
    final thumbnails = imageAssets.where((item) => item != heroImageAsset).take(6).toList();

    if (heroImageAsset == null && thumbnails.isEmpty) {
      return const _MissingImagePlaceholder(label: 'Brak grafik modelu dla tego dokumentu');
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: thumbnails
          .map(
            (imageAsset) => ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                imageAsset,
                width: 140,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 140,
                  height: 100,
                  color: const Color(0xFFEDE7DB),
                  alignment: Alignment.center,
                  child: const Text('Brak', style: TextStyle(color: Colors.black45)),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PreviewSectionCard extends StatelessWidget {
  const _PreviewSectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return VeloPrimeWorkspacePanel(
      tint: VeloPrimePalette.sea,
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LinkedAssetCard extends StatelessWidget {
  const _LinkedAssetCard({
    required this.eyebrow,
    required this.title,
    required this.value,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VeloPrimePalette.lineStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EFE4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: VeloPrimePalette.bronzeDeep),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(eyebrow, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: VeloPrimePalette.muted)),
                    const SizedBox(height: 3),
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SelectableText(
            value,
            style: const TextStyle(color: Colors.black54, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _PreviewInfoGrid extends StatelessWidget {
  const _PreviewInfoGrid({required this.items});

  final List<_PreviewInfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (item) => Container(
              width: 240,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.84),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: VeloPrimePalette.lineStrong),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: const TextStyle(fontSize: 12, color: VeloPrimePalette.muted)),
                  const SizedBox(height: 6),
                  Text(item.value, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PreviewPill extends StatelessWidget {
  const _PreviewPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VeloPrimePalette.lineStrong),
      ),
      child: Text('$label: $value'),
    );
  }
}

class _PreviewMetricCard extends StatelessWidget {
  const _PreviewMetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFCFAF4), Color(0xFFF4EEE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VeloPrimePalette.lineStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: VeloPrimePalette.muted)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.35)),
        ],
      ),
    );
  }
}

class _PreviewCalloutBox extends StatelessWidget {
  const _PreviewCalloutBox({
    required this.title,
    required this.value,
    required this.tint,
  });

  final String title;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: VeloPrimePalette.lineStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: VeloPrimePalette.muted)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(height: 1.55, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _MissingImagePlaceholder extends StatelessWidget {
  const _MissingImagePlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VeloPrimePalette.lineStrong),
      ),
      alignment: Alignment.center,
      child: Text(label, style: const TextStyle(color: VeloPrimePalette.muted)),
    );
  }
}

class _PreviewInfoItem {
  const _PreviewInfoItem(this.label, this.value);

  final String label;
  final String value;
}

String? _formatNullableDate(String? value, [DateFormat? format]) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  return (format ?? DateFormat('dd.MM.yyyy')).format(parsed);
}