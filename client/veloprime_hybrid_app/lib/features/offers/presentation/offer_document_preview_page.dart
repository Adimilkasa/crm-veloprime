import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/api_config.dart';
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
  bool _isSendingEmail = false;

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

  bool _isBundledAsset(String pathOrUrl) {
    return pathOrUrl.startsWith('assets/');
  }

  Uri _resolveSourceUri(String pathOrUrl) {
    final parsed = Uri.parse(pathOrUrl);
    if (parsed.hasScheme) {
      return parsed;
    }

    return Uri.parse(ApiConfig.baseUrl).resolveUri(parsed);
  }

  Future<void> _openDocumentSource(String pathOrUrl, String label) async {
    if (_isBundledAsset(pathOrUrl)) {
      await _openBundledDocument(pathOrUrl, label);
      return;
    }

    try {
      final opened = await launchUrl(_resolveSourceUri(pathOrUrl), mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie udalo sie otworzyc dokumentu: $label.')),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udalo sie uruchomic dokumentu: $label.\n$error')),
      );
    }
  }

  Future<String?> _promptRecipientEmail(String initialValue) async {
    final controller = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Wyślij ofertę e-mailem'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Adres e-mail odbiorcy',
              hintText: 'klient@firma.pl',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Wyślij'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<void> _sendOfferByEmail(OfferDocumentSnapshot document) async {
    if (_isSendingEmail) {
      return;
    }

    final requestedEmail = await _promptRecipientEmail(document.payload.customer.customerEmail?.trim() ?? '');
    if (requestedEmail == null) {
      return;
    }

    if (requestedEmail.isEmpty || !requestedEmail.contains('@')) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podaj poprawny adres email odbiorcy.')),
      );
      return;
    }

    setState(() {
      _isSendingEmail = true;
    });

    try {
      final emailResult = await widget.repository.sendOfferEmail(
        offerId: document.offerId,
        versionId: document.version?.id ?? widget.versionId,
        toEmail: requestedEmail,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oferta została wysłana na ${emailResult.to}.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się wysłać oferty na email. $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingEmail = false;
        });
      }
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
              eyebrow: 'Podgląd oferty',
              title: 'Przygotowujemy podgląd oferty',
              message: 'Ładujemy dokument, parametry i materiały modelu.',
              isLoading: true,
            );
          }

          if (snapshot.hasError) {
            return VeloPrimeWorkspaceState(
              tint: VeloPrimePalette.rose,
              eyebrow: 'Podgląd oferty',
              title: 'Nie udało się pobrać dokumentu',
              message: '${snapshot.error}',
              icon: Icons.warning_amber_rounded,
              action: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Wróć do edycji'),
              ),
            );
          }

          final document = snapshot.data;
          if (document == null) {
            return const VeloPrimeWorkspaceState(
              tint: VeloPrimePalette.sea,
              eyebrow: 'Podgląd oferty',
              title: 'Brak danych oferty',
              message: 'Dokument nie zawiera jeszcze kompletu danych do prezentacji.',
              icon: Icons.preview_outlined,
            );
          }

          final customer = document.payload.customer;
          final advisor = document.payload.advisor;
          final fallbackAssets = getLocalOfferAssetBundle(
            modelName: customer.modelName ?? document.title,
            catalogKey: document.payload.internal.catalogKey,
            powertrainType: document.payload.internal.powertrainType,
          );
          final resolvedMedia = _ResolvedPreviewMedia.fromDocument(document, fallbackAssets);
          final galleryImages = resolvedMedia.gallerySources;
          final heroImageSource = resolvedMedia.heroSource;
          final specDocumentSource = resolvedMedia.specSource;
          final canSendEmail = document.version != null;
          final contactParts = [customer.customerEmail, customer.customerPhone]
              .whereType<String>()
              .where((item) => item.trim().isNotEmpty)
              .toList();
          final contactLine = contactParts.isEmpty ? 'Dane kontaktowe do uzupełnienia' : contactParts.join(' • ');
          final advisorParts = [advisor.email, advisor.phone]
              .whereType<String>()
              .where((item) => item.trim().isNotEmpty)
              .toList();
          final advisorLine = advisorParts.isEmpty ? 'Dane kontaktowe opiekuna do uzupełnienia' : advisorParts.join(' • ');
          final commercialSummary = customer.financingSummary != null && customer.financingSummary!.trim().isNotEmpty
              ? customer.financingSummary!
              : customer.financingVariant ?? 'Warunki ustalane indywidualnie';
          final offerNarrative = 'Dokument zbiera konfigurację ${customer.modelName ?? document.title} '
              'dla ${customer.customerName}, poziom ceny końcowej i proponowany scenariusz rozmowy o finansowaniu: $commercialSummary.';

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
                          label: const Text('Powrót'),
                        ),
                        if (specDocumentSource != null)
                          OutlinedButton.icon(
                            onPressed: () => _openDocumentSource(specDocumentSource, 'specyfikacja-modelu'),
                            icon: const Icon(Icons.description_outlined),
                            label: const Text('Otwórz specyfikację PDF'),
                          ),
                        if (canSendEmail)
                          FilledButton.icon(
                            onPressed: _isSendingEmail ? null : () => _sendOfferByEmail(document),
                            icon: _isSendingEmail
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2.2),
                                  )
                                : const Icon(Icons.alternate_email_outlined),
                            label: Text(_isSendingEmail ? 'Wysyłamy ofertę...' : 'Wyślij ofertę'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _PreviewHeroCard(
                      document: document,
                      heroImageSource: heroImageSource,
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
                    if (specDocumentSource != null) ...[
                      const SizedBox(height: 20),
                      const _PreviewSectionCard(
                        title: 'Specyfikacja modelu',
                        child: _LinkedAssetCard(
                          eyebrow: 'Dokument pomocniczy',
                          title: 'PDF specyfikacji samochodu',
                          value: 'Dokument otwiera się lokalnie w aplikacji.',
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
                              title: 'Skrót oferty',
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
                                    _PreviewInfoItem('Ważność', _formatNullableDate(customer.validUntil) ?? '-'),
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
                                _PreviewInfoItem('Ważna do', _formatNullableDate(customer.validUntil) ?? '-'),
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
                                      title: 'Warunki finansowania',
                                      value: customer.financingDisclaimer!,
                                      tint: const Color(0xFFF7F1E1),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  _PreviewCalloutBox(
                                    title: 'Uwagi do oferty',
                                    value: customer.notes?.isNotEmpty == true
                                        ? customer.notes!
                                        : 'Brak dodatkowych uwag do oferty.',
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
                                  const Text(
                                    'Galeria wspiera rozmowę z klientem i pokazuje finalny kierunek konfiguracji bez wychodzenia z aplikacji.',
                                    style: TextStyle(color: Colors.black54, height: 1.55),
                                  ),
                                  const SizedBox(height: 14),
                                  _AssetGallery(
                                    heroImageSource: heroImageSource,
                                    imageSources: galleryImages,
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
    required this.heroImageSource,
    required this.dateFormat,
  });

  final OfferDocumentSnapshot document;
  final String? heroImageSource;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return VeloPrimeWorkspacePanel(
      tint: VeloPrimePalette.sea,
      radius: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const VeloPrimeSectionEyebrow(label: 'Podgląd oferty', color: VeloPrimePalette.sea),
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
            if (heroImageSource != null) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _PreviewImage(
                  source: heroImageSource!,
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  missingLabel: 'Podgląd grafiki modelu jest niedostępny',
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
    required this.heroImageSource,
    required this.imageSources,
  });

  final String? heroImageSource;
  final List<String> imageSources;

  @override
  Widget build(BuildContext context) {
    final thumbnails = imageSources.where((item) => item != heroImageSource).take(6).toList();

    if (heroImageSource == null && thumbnails.isEmpty) {
      return const _MissingImagePlaceholder(label: 'Brak grafik modelu dla tego dokumentu');
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: thumbnails
          .map(
            (imageSource) => ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _PreviewImage(
                source: imageSource,
                width: 140,
                height: 100,
                fit: BoxFit.cover,
                missingLabel: 'Brak',
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ResolvedPreviewMedia {
  const _ResolvedPreviewMedia({
    required this.specSource,
    required this.heroSource,
    required this.gallerySources,
  });

  final String? specSource;
  final String? heroSource;
  final List<String> gallerySources;

  factory _ResolvedPreviewMedia.fromDocument(OfferDocumentSnapshot document, LocalOfferAssetBundle fallbackAssets) {
    final documentImages = [
      ...document.assets.premiumImages,
      ...document.assets.exteriorImages,
      ...document.assets.interiorImages,
      ...document.assets.detailImages,
    ].where((item) => item.trim().isNotEmpty).toList(growable: false);

    final gallerySources = (documentImages.isNotEmpty ? documentImages : fallbackAssets.galleryImages)
        .where((item) => item.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);

    final heroSource = [
      ...document.assets.premiumImages,
      ...document.assets.exteriorImages,
      ...document.assets.detailImages,
      if (fallbackAssets.heroImageAsset != null) fallbackAssets.heroImageAsset!,
    ].where((item) => item.trim().isNotEmpty).cast<String?>().firstWhere((item) => item != null, orElse: () => null);

    return _ResolvedPreviewMedia(
      specSource: document.assets.specPdfUrl?.trim().isNotEmpty == true ? document.assets.specPdfUrl : fallbackAssets.specPdfAssetPath,
      heroSource: heroSource,
      gallerySources: gallerySources,
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({
    required this.source,
    required this.width,
    required this.height,
    required this.fit,
    required this.missingLabel,
  });

  final String source;
  final double width;
  final double height;
  final BoxFit fit;
  final String missingLabel;

  @override
  Widget build(BuildContext context) {
    final imageWidget = source.startsWith('assets/')
        ? Image.asset(
            source,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _inlineMissingImage(width, height),
          )
        : Image.network(
            _resolveAbsolutePreviewUrl(source),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _inlineMissingImage(width, height),
          );

    return imageWidget;
  }

  Widget _inlineMissingImage(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFEDE7DB),
      alignment: Alignment.center,
      child: Text(missingLabel, style: const TextStyle(color: Colors.black45)),
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

String _resolveAbsolutePreviewUrl(String pathOrUrl) {
  final parsed = Uri.parse(pathOrUrl);
  if (parsed.hasScheme) {
    return parsed.toString();
  }

  return Uri.parse(ApiConfig.baseUrl).resolveUri(parsed).toString();
}