import 'dart:io';
import 'dart:ui' show ImageFilter;
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
    required this.versionId,
    required this.repository,
  });

  final String offerId;
  final String versionId;
  final OffersRepository repository;

  @override
  State<OfferDocumentPreviewPage> createState() => _OfferDocumentPreviewPageState();
}

class _OfferDocumentPreviewPageState extends State<OfferDocumentPreviewPage> {
  late Future<OfferDocumentSnapshot> _documentFuture;
  bool _isSendingEmail = false;

  Future<OfferDocumentSnapshot> _loadDocument() async {
    return await widget.repository.fetchDocumentSnapshot(
      offerId: widget.offerId,
      versionId: widget.versionId,
    );
  }

  @override
  void initState() {
    super.initState();
    _documentFuture = _loadDocument();
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

  Future<bool> _isReachableDocumentSource(String pathOrUrl) async {
    final uri = _resolveSourceUri(pathOrUrl);
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return true;
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.openUrl('HEAD', uri);
      final response = await request.close();
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _openDocumentSource(String pathOrUrl, String label, {String? fallbackPath}) async {
    if (_isBundledAsset(pathOrUrl)) {
      await _openBundledDocument(pathOrUrl, label);
      return;
    }

    final normalizedFallback = fallbackPath?.trim();
    if (normalizedFallback != null && normalizedFallback.isNotEmpty) {
      final isReachable = await _isReachableDocumentSource(pathOrUrl);
      if (!isReachable) {
        await _openBundledDocument(normalizedFallback, label);
        return;
      }
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
          final fallbackAssets = getLocalOfferAssetBundle(
            modelName: customer.modelName ?? document.title,
            catalogKey: document.payload.internal.catalogKey,
            powertrainType: document.payload.internal.powertrainType,
          );
          final resolvedMedia = _ResolvedPreviewMedia.fromDocument(document, fallbackAssets);
          final heroImageSource = resolvedMedia.heroSource;
          final specDocumentSource = resolvedMedia.specSource;
          final specFallbackSource = resolvedMedia.specFallbackSource;
          final canSendEmail = document.version != null;
          final validUntilLabel = _formatNullableDate(customer.validUntil) ?? 'Do potwierdzenia';
          final effectivePriceLabel = _isCompanyCustomer(document.payload.internal.customerType)
              ? customer.finalNetLabel
              : customer.finalGrossLabel;
          final pricingDisplayMode = _isCompanyCustomer(document.payload.internal.customerType) ? 'netto' : 'brutto';
          final financingInsights = _extractFinancingInsights(customer.financingSummary, customer.financingVariant);
          final formalNotice = customer.financingDisclaimer ?? _defaultFinancingDisclaimer;
          final parsedCatalogKey = _parseCatalogKey(document.payload.internal.catalogKey);
          final technicalItems = <_PreviewTechnicalItem>[
            if (parsedCatalogKey != null)
              _PreviewTechnicalItem(Icons.sell_outlined, 'Marka', parsedCatalogKey.brand),
            _PreviewTechnicalItem(Icons.directions_car_filled_outlined, 'Model', customer.modelName ?? document.title),
            if (parsedCatalogKey != null)
              _PreviewTechnicalItem(Icons.layers_outlined, 'Wersja', parsedCatalogKey.version),
            _PreviewTechnicalItem(Icons.bolt_outlined, 'Typ napędu', _formatPowertrainType(document.payload.internal.powertrainType)),
            if (document.payload.internal.driveType?.trim().isNotEmpty == true)
              _PreviewTechnicalItem(Icons.alt_route_outlined, 'Napęd osi', document.payload.internal.driveType!.trim()),
            if (document.payload.internal.year?.trim().isNotEmpty == true)
              _PreviewTechnicalItem(Icons.event_outlined, 'Rocznik', document.payload.internal.year!),
            if (document.payload.internal.batteryCapacityKwh?.trim().isNotEmpty == true)
              _PreviewTechnicalItem(Icons.battery_charging_full_outlined, 'Pojemność baterii', document.payload.internal.batteryCapacityKwh!.trim()),
            if (document.payload.internal.rangeKm?.trim().isNotEmpty == true)
              _PreviewTechnicalItem(Icons.route_outlined, 'Zasięg', document.payload.internal.rangeKm!.trim()),
            if (document.payload.internal.combustionEnginePowerHp?.trim().isNotEmpty == true)
              _PreviewTechnicalItem(Icons.local_fire_department_outlined, 'Moc silnika spalinowego', document.payload.internal.combustionEnginePowerHp!.trim()),
            if (document.payload.internal.engineDisplacementCc?.trim().isNotEmpty == true)
              _PreviewTechnicalItem(Icons.precision_manufacturing_outlined, 'Pojemność silnika', document.payload.internal.engineDisplacementCc!.trim()),
            _PreviewTechnicalItem(Icons.palette_outlined, 'Kolor konfiguracji', customer.selectedColorName ?? document.payload.internal.selectedColorName ?? 'Bazowy'),
          ];
          final baseColorName = document.payload.internal.baseColorName?.trim();
          final selectedColorName = customer.selectedColorName?.trim().toLowerCase();
          if (baseColorName != null && baseColorName.isNotEmpty && baseColorName.toLowerCase() != selectedColorName) {
            technicalItems.add(
              _PreviewTechnicalItem(Icons.format_paint_outlined, 'Kolor bazowy modelu', baseColorName),
            );
          }
          final visibleTechnicalItems = <_PreviewTechnicalItem>[];
          final seenTechnicalItems = <String>{};
          for (final item in technicalItems) {
            final key = '${item.label}::${item.value}'.toLowerCase();
            if (!seenTechnicalItems.add(key)) {
              continue;
            }
            visibleTechnicalItems.add(item);
            if (visibleTechnicalItems.length == 7) {
              break;
            }
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _PreviewHeroCard(
                    document: document,
                    heroImageSource: heroImageSource,
                    validUntilLabel: validUntilLabel,
                    hasSpecification: specDocumentSource != null,
                    canSendEmail: canSendEmail,
                    isSendingEmail: _isSendingEmail,
                    onBack: () => Navigator.of(context).pop(),
                    onOpenSpecification: specDocumentSource == null
                        ? null
                        : () => _openDocumentSource(
                              specDocumentSource,
                              'specyfikacja-modelu',
                              fallbackPath: specFallbackSource,
                            ),
                    onSendOffer: canSendEmail ? () => _sendOfferByEmail(document) : null,
                  ),
                  if (specDocumentSource != null) ...[
                    const SizedBox(height: 20),
                    _PreviewPdfStrip(
                      backgroundImageSource: heroImageSource,
                      onPressed: () => _openDocumentSource(
                        specDocumentSource,
                        'specyfikacja-modelu',
                        fallbackPath: specFallbackSource,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _PreviewSectionCard(
                    title: 'Najważniejsze dane',
                    subtitle: 'Siedem kluczowych informacji o konfiguracji, pokazanych na czystym, jasnym tle.',
                    sectionTint: VeloPrimePalette.bronzeDeep,
                    backgroundImageSource: heroImageSource,
                    child: _PreviewTechnicalSection(
                      items: visibleTechnicalItems,
                      metaItems: const [],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _PreviewSectionCard(
                    title: 'Galeria',
                    subtitle: 'Wybrane ujęcia nadwozia, wnętrza i detali tej konfiguracji.',
                    sectionTint: const Color(0xFF8A7441),
                    borderStrength: 0.64,
                    child: _AssetGallery(
                      media: resolvedMedia,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _PreviewValueSection(
                    backgroundImageSource: heroImageSource,
                    listPriceLabel: customer.listPriceLabel,
                    discountLabel: customer.discountLabel,
                    discountPercentLabel: customer.discountPercentLabel,
                    effectivePriceLabel: effectivePriceLabel,
                    secondaryPriceLabel: pricingDisplayMode == 'netto' ? customer.finalGrossLabel : customer.finalNetLabel,
                    pricingDisplayMode: pricingDisplayMode,
                  ),
                  const SizedBox(height: 24),
                  _PreviewFinancingSection(
                    backgroundImageSource: heroImageSource,
                    insights: financingInsights,
                    pricingDisplayMode: pricingDisplayMode,
                    financingVariant: customer.financingVariant ?? 'Do uzupełnienia',
                    primaryFinalPriceLabel: pricingDisplayMode == 'netto' ? customer.finalNetLabel : customer.finalGrossLabel,
                    secondaryFinalPriceLabel: pricingDisplayMode == 'netto' ? customer.finalGrossLabel : customer.finalNetLabel,
                    disclaimer: customer.financingDisclaimer ?? _defaultFinancingDisclaimer,
                  ),
                  const SizedBox(height: 24),
                  _PreviewContactSection(
                    backgroundImageSource: heroImageSource,
                    customerName: customer.customerName,
                    customerEmail: customer.customerEmail,
                    notes: customer.notes?.isNotEmpty == true
                        ? customer.notes!
                        : 'Brak dodatkowych uwag do oferty.',
                    offerNumber: customer.offerNumber,
                    commissionCode: _formatCommissionCode(
                      document.payload.internal.salespersonCommission,
                      pricingDisplayMode == 'netto',
                    ),
                    validUntilLabel: validUntilLabel,
                    specificationStatus: specDocumentSource != null ? 'PDF dostępny' : 'PDF niedostępny',
                    pricingDisplayMode: pricingDisplayMode == 'netto' ? 'netto' : 'brutto',
                    formalNotice: formalNotice,
                    canSendEmail: canSendEmail,
                  ),
                  const SizedBox(height: 28),
                ],
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
    required this.validUntilLabel,
    required this.hasSpecification,
    required this.canSendEmail,
    required this.isSendingEmail,
    required this.onBack,
    required this.onOpenSpecification,
    required this.onSendOffer,
  });

  final OfferDocumentSnapshot document;
  final _PreviewMediaImageSource? heroImageSource;
  final String validUntilLabel;
  final bool hasSpecification;
  final bool canSendEmail;
  final bool isSendingEmail;
  final VoidCallback onBack;
  final VoidCallback? onOpenSpecification;
  final VoidCallback? onSendOffer;

  @override
  Widget build(BuildContext context) {
    final customer = document.payload.customer;
    final modelLabel = customer.modelName ?? document.title;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;

        return ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: SizedBox(
            width: double.infinity,
            height: isCompact ? 520 : 628,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFC0CCDA), Color(0xFF647588), Color(0xFF27313B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: heroImageSource != null
                      ? _PreviewImage(
                          source: heroImageSource!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          missingLabel: 'Podgląd grafiki modelu jest niedostępny',
                        )
                      : const SizedBox.shrink(),
                    ),
                ),
                Positioned(
                  top: 22,
                  left: 22,
                  right: 22,
                  child: _PreviewStickyTopBar(
                    hasSpecification: hasSpecification,
                    canSendEmail: canSendEmail,
                    isSendingEmail: isSendingEmail,
                    onBack: onBack,
                    onOpenSpecification: onOpenSpecification,
                    onSendOffer: onSendOffer,
                  ),
                ),
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 28,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                                decoration: BoxDecoration(
                                  color: const Color(0xB3121821),
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.18),
                                      blurRadius: 24,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: VeloPrimePalette.bronzeDeep.withValues(alpha: 0.28)),
                                      ),
                                      child: Text(
                                        'Oferta ważna do $validUntilLabel',
                                        style: TextStyle(
                                          color: const Color(0xFFE9D3A0).withValues(alpha: 0.96),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.72,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'OFERTA DLA KLIENTA',
                                      style: TextStyle(
                                        color: Color(0xFFDDE8FF),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      customer.customerName,
                                      style: TextStyle(
                                        fontSize: isCompact ? 34 : 48,
                                        height: 1.0,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.9,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        if ((customer.customerPhone ?? '').trim().isNotEmpty)
                                          _PreviewHeroMetaPill(
                                            icon: Icons.call_outlined,
                                            label: customer.customerPhone!.trim(),
                                          ),
                                        if ((customer.customerEmail ?? '').trim().isNotEmpty)
                                          _PreviewHeroMetaPill(
                                            icon: Icons.alternate_email_outlined,
                                            label: customer.customerEmail!.trim(),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      modelLabel,
                                      style: TextStyle(
                                        fontSize: isCompact ? 24 : 34,
                                        height: 1.04,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.8,
                                        color: const Color(0xFFE8EEF7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PreviewTechnicalSection extends StatelessWidget {
  const _PreviewTechnicalSection({
    required this.items,
    required this.metaItems,
  });

  final List<_PreviewTechnicalItem> items;
  final List<String> metaItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = constraints.maxWidth >= 1040
                ? (constraints.maxWidth - 24) / 3
                : constraints.maxWidth >= 640
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: items
                  .asMap()
                  .entries
                  .map(
                    (entry) {
                      final item = entry.value;
                      final tint = _previewTechnicalTint(entry.key);

                      return SizedBox(
                        width: tileWidth,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: _previewSurfaceDecoration(
                            tint: VeloPrimePalette.bronzeDeep,
                            radius: 24,
                            fillStrength: 0.0,
                            borderStrength: 0.48,
                            shadowStrength: 0.02,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PreviewCircleIcon(
                                icon: item.icon,
                                foregroundColor: VeloPrimePalette.bronzeDeep,
                                backgroundColor: Colors.white,
                                borderColor: VeloPrimePalette.bronzeDeep.withValues(alpha: 0.24),
                              ),
                              const SizedBox(height: 14),
                              Text(item.label, style: const TextStyle(fontSize: 12, color: VeloPrimePalette.muted, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(item.value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.24, color: Color(0xFF1D1D1F))),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                  .toList(),
            );
          },
        ),
        if (metaItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: metaItems
                .map((item) => Text(item, style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF6E6E73))))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _PreviewStickyTopBar extends StatelessWidget {
  const _PreviewStickyTopBar({
    required this.hasSpecification,
    required this.canSendEmail,
    required this.isSendingEmail,
    required this.onBack,
    required this.onOpenSpecification,
    required this.onSendOffer,
  });

  final bool hasSpecification;
  final bool canSendEmail;
  final bool isSendingEmail;
  final VoidCallback onBack;
  final VoidCallback? onOpenSpecification;
  final VoidCallback? onSendOffer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xB3121821),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 10,
        spacing: 10,
        children: [
          _PreviewTopBarButton(
            onPressed: onBack,
            icon: Icons.arrow_back_rounded,
            label: 'Powrót',
          ),
          if (hasSpecification)
            _PreviewTopBarButton(
              onPressed: onOpenSpecification,
              icon: Icons.description_outlined,
              label: 'PDF modelu',
            ),
          if (canSendEmail)
            _PreviewTopBarButton(
              onPressed: isSendingEmail ? null : onSendOffer,
              icon: isSendingEmail ? null : Icons.alternate_email_outlined,
              label: isSendingEmail ? 'Wysyłamy ofertę...' : 'Wyślij e-mailem',
              isPrimary: true,
              trailing: isSendingEmail
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}

class _PreviewTopBarButton extends StatelessWidget {
  const _PreviewTopBarButton({
    required this.onPressed,
    required this.label,
    this.icon,
    this.isPrimary = false,
    this.trailing,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isPrimary;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isPrimary ? VeloPrimePalette.bronzeDeep : Colors.white.withValues(alpha: 0.96);
    final foregroundColor = const Color(0xFF181512);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isPrimary
                  ? VeloPrimePalette.bronzeDeep.withValues(alpha: 0.78)
                  : Colors.white.withValues(alpha: 0.78),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isPrimary ? 0.16 : 0.10),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: foregroundColor),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: foregroundColor,
                  letterSpacing: -0.1,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetGallery extends StatelessWidget {
  const _AssetGallery({
    required this.media,
  });

  final _ResolvedPreviewMedia media;

  @override
  Widget build(BuildContext context) {
    final sections = media.categories.isNotEmpty
        ? media.categories
        : [
            _PreviewGalleryCategory(
              title: 'Galeria modelu',
              images: media.gallerySources,
            ),
          ];

    if (media.gallerySources.isEmpty) {
      return const _MissingImagePlaceholder(label: 'Brak grafik modelu dla tego dokumentu');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...sections.expand((section) {
          final featuredSource = section.images.first;
          final thumbnails = section.images.skip(1).take(4).toList(growable: false);

          return [
            Text(
              section.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.08, color: Color(0xFF1D1D1F)),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 860;
                final featuredPanel = _PreviewGalleryHeroTile(
                  source: featuredSource,
                  allImages: media.gallerySources,
                  title: section.title,
                );
                final thumbnailsPanel = _PreviewGalleryThumbnailColumn(
                  images: thumbnails,
                  allImages: media.gallerySources,
                );

                if (isCompact) {
                  return Column(
                    children: [
                      featuredPanel,
                      if (thumbnails.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        thumbnailsPanel,
                      ],
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 12, child: featuredPanel),
                    if (thumbnails.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Expanded(flex: 8, child: thumbnailsPanel),
                    ],
                  ],
                );
              },
            ),
                        const SizedBox(height: 12),
          ];
        }),
      ],
    );
  }
}

class _ResolvedPreviewMedia {
  const _ResolvedPreviewMedia({
    required this.specSource,
    required this.specFallbackSource,
    required this.heroSource,
    required this.gallerySources,
    required this.categories,
  });

  final String? specSource;
  final String? specFallbackSource;
  final _PreviewMediaImageSource? heroSource;
  final List<_PreviewMediaImageSource> gallerySources;
  final List<_PreviewGalleryCategory> categories;

  factory _ResolvedPreviewMedia.fromDocument(OfferDocumentSnapshot document, LocalOfferAssetBundle fallbackAssets) {
    List<String> normalizeList(List<String> items) {
      return items.where((item) => item.trim().isNotEmpty).toSet().toList(growable: false);
    }

    List<_PreviewMediaImageSource> pick(List<String> primary, List<String> fallback) {
      final normalizedPrimary = normalizeList(primary);
      final normalizedFallback = normalizeList(fallback);

      if (normalizedPrimary.isNotEmpty) {
        final resolved = <_PreviewMediaImageSource>[];
        for (var index = 0; index < normalizedPrimary.length; index += 1) {
          resolved.add(
            _PreviewMediaImageSource(
              primarySource: normalizedPrimary[index],
              fallbackSource: normalizedFallback.isEmpty ? null : normalizedFallback[index % normalizedFallback.length],
            ),
          );
        }

        if (normalizedFallback.length > normalizedPrimary.length) {
          resolved.addAll(
            normalizedFallback
                .skip(normalizedPrimary.length)
                .map((item) => _PreviewMediaImageSource(primarySource: item)),
          );
        }

        return resolved;
      }

      return normalizedFallback.map((item) => _PreviewMediaImageSource(primarySource: item)).toList(growable: false);
    }

    final premiumImages = pick(document.assets.premiumImages, fallbackAssets.premiumImages);
    final exteriorImages = pick(document.assets.exteriorImages, fallbackAssets.exteriorImages);
    final interiorImages = pick(document.assets.interiorImages, fallbackAssets.interiorImages);
    final detailImages = pick(document.assets.detailImages, fallbackAssets.detailImages);

    final gallerySources = <String, _PreviewMediaImageSource>{};
    for (final image in [...premiumImages, ...exteriorImages, ...interiorImages, ...detailImages]) {
      gallerySources.putIfAbsent(image.key, () => image);
    }

    final heroCandidates = [
      ...premiumImages,
      ...exteriorImages,
      ...detailImages,
      if (fallbackAssets.heroImageAsset != null) _PreviewMediaImageSource(primarySource: fallbackAssets.heroImageAsset!),
    ];
    final heroSource = heroCandidates.isEmpty ? null : heroCandidates.first;

    final categories = [
      _PreviewGalleryCategory(title: 'Wybrane kadry', images: premiumImages),
      _PreviewGalleryCategory(title: 'Z zewnątrz', images: exteriorImages),
      _PreviewGalleryCategory(title: 'Wnętrze', images: interiorImages),
      _PreviewGalleryCategory(title: 'Detale', images: detailImages),
    ].where((category) => category.images.isNotEmpty).toList(growable: false);

    return _ResolvedPreviewMedia(
      specSource: document.assets.specPdfUrl?.trim().isNotEmpty == true ? document.assets.specPdfUrl : fallbackAssets.specPdfAssetPath,
      specFallbackSource: document.assets.specPdfUrl?.trim().isNotEmpty == true ? fallbackAssets.specPdfAssetPath : null,
      heroSource: heroSource,
      gallerySources: gallerySources.values.toList(growable: false),
      categories: categories,
    );
  }
}

class _PreviewMediaImageSource {
  const _PreviewMediaImageSource({
    required this.primarySource,
    this.fallbackSource,
  });

  final String primarySource;
  final String? fallbackSource;

  String get key => '$primarySource|${fallbackSource ?? ''}';
}

class _PreviewGalleryHeroTile extends StatelessWidget {
  const _PreviewGalleryHeroTile({
    required this.source,
    required this.allImages,
    required this.title,
  });

  final _PreviewMediaImageSource source;
  final List<_PreviewMediaImageSource> allImages;
  final String title;

  @override
  Widget build(BuildContext context) {
    return _PreviewImageActionTile(
      source: source,
      allImages: allImages,
      height: 236,
      title: title,
      subtitle: 'Pełna galeria',
      borderRadius: 30,
      overlayAlignment: Alignment.bottomLeft,
    );
  }
}

class _PreviewGalleryThumbnailColumn extends StatelessWidget {
  const _PreviewGalleryThumbnailColumn({
    required this.images,
    required this.allImages,
  });

  final List<_PreviewMediaImageSource> images;
  final List<_PreviewMediaImageSource> allImages;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const _MissingImagePlaceholder(label: 'Brak dodatkowych ujęć dla tej konfiguracji');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = constraints.maxWidth > 260 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: images
              .map(
                (image) => SizedBox(
                  width: tileWidth,
                  child: _PreviewImageActionTile(
                    source: image,
                    allImages: allImages,
                    height: 118,
                    title: 'Dodatkowe ujęcie',
                    borderRadius: 22,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _PreviewImageActionTile extends StatelessWidget {
  const _PreviewImageActionTile({
    required this.source,
    required this.allImages,
    required this.height,
    required this.title,
    this.subtitle,
    this.borderRadius = 24,
    this.overlayAlignment = Alignment.bottomRight,
  });

  final _PreviewMediaImageSource source;
  final List<_PreviewMediaImageSource> allImages;
  final double height;
  final String title;
  final String? subtitle;
  final double borderRadius;
  final Alignment overlayAlignment;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: () => _openPreviewLightbox(context, allImages, source),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF13284A).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Stack(
              children: [
                _PreviewImage(
                  source: source,
                  width: double.infinity,
                  height: height,
                  fit: BoxFit.cover,
                  missingLabel: 'Brak podglądu',
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.24),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: overlayAlignment == Alignment.bottomLeft ? 16 : null,
                  right: overlayAlignment == Alignment.bottomRight ? 16 : null,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: overlayAlignment == Alignment.bottomLeft
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: -0.1)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(subtitle!, style: TextStyle(color: Colors.white.withValues(alpha: 0.74), fontSize: 11.5, fontWeight: FontWeight.w500)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewLightboxDialog extends StatefulWidget {
  const _PreviewLightboxDialog({
    required this.images,
    required this.initialIndex,
  });

  final List<_PreviewMediaImageSource> images;
  final int initialIndex;

  @override
  State<_PreviewLightboxDialog> createState() => _PreviewLightboxDialogState();
}

class _PreviewLightboxDialogState extends State<_PreviewLightboxDialog> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
  }

  void _move(int delta) {
    if (widget.images.isEmpty) {
      return;
    }

    setState(() {
      _index = (_index + delta + widget.images.length) % widget.images.length;
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _move(-1);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _move(1);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final currentSource = widget.images[_index];

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.94),
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(84, 42, 84, 42),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: Tween<double>(begin: 0.98, end: 1).animate(animation), child: child),
                      );
                    },
                    child: Hero(
                      key: ValueKey(currentSource.key),
                      tag: 'offer-lightbox-${currentSource.key}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: _PreviewImage(
                          source: currentSource,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                          missingLabel: 'Brak podglądu',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 22,
              left: 28,
              child: Text(
                '${_index + 1} / ${widget.images.length}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontWeight: FontWeight.w700),
              ),
            ),
            Positioned(
              top: 18,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                tooltip: 'Zamknij',
              ),
            ),
            Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: _PreviewLightboxArrow(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: () => _move(-1),
                ),
              ),
            ),
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: _PreviewLightboxArrow(
                  icon: Icons.arrow_forward_ios_rounded,
                  onPressed: () => _move(1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewLightboxArrow extends StatelessWidget {
  const _PreviewLightboxArrow({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _PreviewGalleryCategory {
  const _PreviewGalleryCategory({
    required this.title,
    required this.images,
  });

  final String title;
  final List<_PreviewMediaImageSource> images;
}

class _PreviewImage extends StatefulWidget {
  const _PreviewImage({
    required this.source,
    required this.width,
    required this.height,
    required this.fit,
    required this.missingLabel,
  });

  final _PreviewMediaImageSource source;
  final double width;
  final double height;
  final BoxFit fit;
  final String missingLabel;

  @override
  State<_PreviewImage> createState() => _PreviewImageState();
}

class _PreviewImageState extends State<_PreviewImage> {
  late String _activeSource;
  bool _usingFallback = false;

  @override
  void initState() {
    super.initState();
    _resetSource();
  }

  @override
  void didUpdateWidget(covariant _PreviewImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source.key != widget.source.key) {
      _resetSource();
    }
  }

  void _resetSource() {
    _activeSource = widget.source.primarySource;
    _usingFallback = false;
  }

  Widget _handleError(double width, double height) {
    final fallbackSource = widget.source.fallbackSource?.trim();
    if (!_usingFallback && fallbackSource != null && fallbackSource.isNotEmpty && fallbackSource != _activeSource) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _activeSource = fallbackSource;
          _usingFallback = true;
        });
      });

      return SizedBox(width: width, height: height);
    }

    return _inlineMissingImage(width, height);
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = _activeSource.startsWith('assets/')
        ? Image.asset(
            _activeSource,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => _handleError(widget.width, widget.height),
          )
        : Image.network(
            _resolveAbsolutePreviewUrl(_activeSource),
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => _handleError(widget.width, widget.height),
          );

    return imageWidget;
  }

  Widget _inlineMissingImage(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFEDE7DB),
      alignment: Alignment.center,
      child: Text(widget.missingLabel, style: const TextStyle(color: Colors.black45)),
    );
  }
}

class _PreviewSectionCard extends StatelessWidget {
  const _PreviewSectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.sectionTint = VeloPrimePalette.bronzeDeep,
    this.borderStrength = 0.10,
    this.backgroundImageSource,
  });

  final String title;
  final Widget child;
  final String? subtitle;
  final Color sectionTint;
  final double borderStrength;
  final _PreviewMediaImageSource? backgroundImageSource;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: _previewSurfaceDecoration(
            tint: sectionTint,
            borderStrength: borderStrength,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.05, color: Color(0xFF1D1D1F))),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              subtitle!,
              style: const TextStyle(color: Color(0xFF6E6E73), height: 1.75, fontSize: 15),
            ),
          ],
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

class _PreviewPdfStrip extends StatelessWidget {
  const _PreviewPdfStrip({required this.onPressed, this.backgroundImageSource});

  final VoidCallback onPressed;
  final _PreviewMediaImageSource? backgroundImageSource;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: _previewSurfaceDecoration(
            tint: VeloPrimePalette.bronzeDeep,
            radius: 28,
            fillStrength: 0.03,
            borderStrength: 0.10,
            shadowStrength: 0.04,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 760;

          final descriptionBlock = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PreviewCircleIcon(
                icon: Icons.description_outlined,
                foregroundColor: VeloPrimePalette.bronzeDeep,
                backgroundColor: Color(0xFFFFF8ED),
                borderColor: Color(0x33BE933E),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PDF z kartą modelu i wyposażenia',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1D1D1F)),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Dokument z kartą modelu i szczegółami konfiguracji przygotowanej dla klienta.',
                      style: TextStyle(color: Color(0xFF4E4E56), fontSize: 13, height: 1.55),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actionButton = FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: VeloPrimePalette.bronzeDeep,
              foregroundColor: const Color(0xFF181512),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Pobierz PDF'),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                descriptionBlock,
                const SizedBox(height: 16),
                actionButton,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: descriptionBlock),
              const SizedBox(width: 20),
              actionButton,
            ],
          );
        },
      ),
    );
  }
}

class _PreviewValueSection extends StatelessWidget {
  const _PreviewValueSection({
    required this.backgroundImageSource,
    required this.listPriceLabel,
    required this.discountLabel,
    required this.discountPercentLabel,
    required this.effectivePriceLabel,
    required this.secondaryPriceLabel,
    required this.pricingDisplayMode,
  });

  final _PreviewMediaImageSource? backgroundImageSource;
  final String listPriceLabel;
  final String discountLabel;
  final String discountPercentLabel;
  final String effectivePriceLabel;
  final String secondaryPriceLabel;
  final String pricingDisplayMode;

  @override
  Widget build(BuildContext context) {
    return _PreviewSectionCard(
      title: 'Cena katalogowa, rabat i cena po rabacie',
      subtitle: 'Sekcja cenowa ma pozostać maksymalnie spokojna: czytelna hierarchia, mniej podziałów i jedna dominująca liczba.',
      sectionTint: VeloPrimePalette.bronzeDeep,
      borderStrength: 0.36,
      backgroundImageSource: backgroundImageSource,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cards = [
            _PreviewPricingStatCard(label: 'Cena katalogowa', value: listPriceLabel),
            _PreviewPricingStatCard(label: 'Rabat', value: '$discountLabel  •  $discountPercentLabel'),
            _PreviewPricingStatCard(label: 'Cena po rabacie', value: effectivePriceLabel, accent: true),
          ];

          return Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: cards
                    .map(
                      (card) => SizedBox(
                        width: constraints.maxWidth >= 1040
                            ? (constraints.maxWidth - 24) / 3
                            : constraints.maxWidth >= 640
                                ? (constraints.maxWidth - 12) / 2
                                : constraints.maxWidth,
                        child: card,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              _PreviewFinalPriceCard(
                effectivePriceLabel: effectivePriceLabel,
                secondaryPriceLabel: secondaryPriceLabel,
                pricingDisplayMode: pricingDisplayMode,
                discountPercentLabel: discountPercentLabel,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PreviewFinancingSection extends StatelessWidget {
  const _PreviewFinancingSection({
    required this.backgroundImageSource,
    required this.insights,
    required this.pricingDisplayMode,
    required this.financingVariant,
    required this.primaryFinalPriceLabel,
    required this.secondaryFinalPriceLabel,
    required this.disclaimer,
  });

  final _PreviewMediaImageSource? backgroundImageSource;
  final _PreviewFinancingInsights insights;
  final String pricingDisplayMode;
  final String financingVariant;
  final String primaryFinalPriceLabel;
  final String secondaryFinalPriceLabel;
  final String disclaimer;

  @override
  Widget build(BuildContext context) {
    final summaryRows = [
      ('Cena końcowa', primaryFinalPriceLabel, true),
      ('Drugi tryb ceny', secondaryFinalPriceLabel, false),
      ('Okres', insights.termLabel ?? 'Do ustalenia', false),
      ('Wpłata własna', insights.depositLabel ?? 'Do ustalenia', false),
      ('Wykup', insights.buyoutLabel ?? 'Do ustalenia', false),
      ('Wariant', financingVariant, false),
    ];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _previewSurfaceDecoration(
        tint: const Color(0xFF8A7441),
        fillStrength: 0.025,
        borderStrength: 0.36,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Finansowanie',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.05, color: Color(0xFF1D1D1F)),
          ),
          const SizedBox(height: 10),
          const Text(
            'Spokojna prezentacja raty, parametrów i ceny końcowej bez dodatkowego tła fotograficznego.',
            style: TextStyle(color: Color(0xFF6E6E73), height: 1.75, fontSize: 15),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 860;
              final primaryPanel = Container(
                padding: const EdgeInsets.all(24),
                decoration: _previewSurfaceDecoration(
                  tint: VeloPrimePalette.bronzeDeep,
                  radius: 32,
                  fillStrength: 0.03,
                  borderStrength: 0.36,
                  shadowStrength: 0.03,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF263B61), Color(0xFF35527E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0E2038).withValues(alpha: 0.14),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Szacowana rata miesięczna',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Color(0xFFDDE8FF)),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            insights.monthlyRateLabel ?? 'Do uzupełnienia po pełnej kalkulacji',
                            style: const TextStyle(color: Colors.white, fontSize: 38, height: 0.98, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            pricingDisplayMode == 'netto' ? 'Cena końcowa netto' : 'Cena końcowa brutto',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFDDE8FF)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            primaryFinalPriceLabel,
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            pricingDisplayMode == 'netto' ? 'Cena końcowa brutto' : 'Cena końcowa netto',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFBFD8FF)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            secondaryFinalPriceLabel,
                            style: const TextStyle(color: Color(0xFFDDE8FF), fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '${insights.summaryLabel} Wartości pokazujemy w trybie $pricingDisplayMode.',
                            style: const TextStyle(color: Color(0xFFE5EDFF), height: 1.55),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
              final summaryPanel = Container(
                padding: const EdgeInsets.all(22),
                decoration: _previewSurfaceDecoration(
                  tint: const Color(0xFF8A7441),
                  radius: 32,
                  fillStrength: 0.025,
                  borderStrength: 0.36,
                  shadowStrength: 0.03,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Parametry',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.9, color: Color(0xFF6E6E73)),
                    ),
                    const SizedBox(height: 14),
                    ...summaryRows.map(
                      (row) => _PreviewFinanceSummaryRow(
                        label: row.$1,
                        value: row.$2,
                        emphasize: row.$3,
                      ),
                    ),
                  ],
                ),
              );

              if (isCompact) {
                return Column(
                  children: [
                    primaryPanel,
                    const SizedBox(height: 16),
                    summaryPanel,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 21, child: primaryPanel),
                  const SizedBox(width: 16),
                  Expanded(flex: 19, child: summaryPanel),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            '$disclaimer Szczegółowe wyliczenie jest przygotowywane po weryfikacji zdolności finansowej klienta oraz po potwierdzeniu okresu finansowania, wpłaty własnej i wykupu.',
            style: const TextStyle(color: Color(0xFF6E6E73), height: 1.6, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PreviewContactSection extends StatelessWidget {
  const _PreviewContactSection({
    required this.backgroundImageSource,
    required this.customerName,
    required this.customerEmail,
    required this.notes,
    required this.offerNumber,
    required this.commissionCode,
    required this.validUntilLabel,
    required this.specificationStatus,
    required this.pricingDisplayMode,
    required this.formalNotice,
    required this.canSendEmail,
  });

  final _PreviewMediaImageSource? backgroundImageSource;
  final String customerName;
  final String? customerEmail;
  final String notes;
  final String offerNumber;
  final String? commissionCode;
  final String validUntilLabel;
  final String specificationStatus;
  final String pricingDisplayMode;
  final String formalNotice;
  final bool canSendEmail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: _previewSurfaceDecoration(
        tint: const Color(0xFF8A7441),
        fillStrength: 0.025,
        borderStrength: 0.36,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Oferta gotowa do wysłania',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.05, color: Color(0xFF1D1D1F)),
          ),
          const SizedBox(height: 10),
          const Text(
            'To jest końcowy snapshot do prezentacji klientowi. Wysyłka odbywa się z górnej belki przez adres e-mail klienta.',
            style: TextStyle(color: Color(0xFF6E6E73), height: 1.7, fontSize: 16),
          ),
          const SizedBox(height: 20),
          _PreviewDeliveryCard(
            customerName: customerName,
            customerEmail: customerEmail,
            canSendEmail: canSendEmail,
          ),
          const SizedBox(height: 12),
          _PreviewCalloutBox(
            title: 'Dodatkowe ustalenia',
            value: notes,
            tint: Colors.white,
          ),
          const SizedBox(height: 12),
          _PreviewInfoGrid(items: [
            _PreviewInfoItem('Numer oferty', offerNumber, secondaryValue: commissionCode),
            _PreviewInfoItem('Ważna do', validUntilLabel),
            _PreviewInfoItem('Specyfikacja', specificationStatus),
            _PreviewInfoItem('Prezentacja cen', pricingDisplayMode),
          ]),
          const SizedBox(height: 12),
          _PreviewCalloutBox(
            title: 'Zastrzeżenie formalne',
            value: formalNotice,
            tint: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _PreviewCircleIcon extends StatelessWidget {
  const _PreviewCircleIcon({
    required this.icon,
    this.foregroundColor = const Color(0xFF243247),
    this.backgroundColor,
    this.borderColor,
  });

  final IconData icon;
  final Color foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? const Color(0xFFE8EBF0)),
      ),
      child: Icon(icon, size: 20, color: foregroundColor),
    );
  }
}

class _PreviewPricingStatCard extends StatelessWidget {
  const _PreviewPricingStatCard({required this.label, required this.value, this.accent = false});

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _previewSurfaceDecoration(
        tint: accent ? VeloPrimePalette.bronzeDeep : const Color(0xFF8A7441),
        radius: 24,
        fillStrength: accent ? 0.07 : 0.025,
        borderStrength: accent ? 0.44 : 0.36,
        shadowStrength: accent ? 0.05 : 0.02,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: VeloPrimePalette.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: accent ? 24 : 20, fontWeight: accent ? FontWeight.w700 : FontWeight.w600, color: const Color(0xFF1D1D1F))),
        ],
      ),
    );
  }
}

class _PreviewFinalPriceCard extends StatelessWidget {
  const _PreviewFinalPriceCard({
    required this.effectivePriceLabel,
    required this.secondaryPriceLabel,
    required this.pricingDisplayMode,
    required this.discountPercentLabel,
  });

  final String effectivePriceLabel;
  final String secondaryPriceLabel;
  final String pricingDisplayMode;
  final String discountPercentLabel;

  @override
  Widget build(BuildContext context) {
    final primaryLabel = pricingDisplayMode == 'netto' ? 'Cena końcowa netto' : 'Cena końcowa brutto';
    final secondaryLabel = pricingDisplayMode == 'netto' ? 'Równowartość brutto' : 'Równowartość netto';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF263B61), Color(0xFF35527E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E2038).withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(primaryLabel, style: const TextStyle(fontSize: 12, color: Color(0xFFDDE8FF), fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(
            effectivePriceLabel,
            style: const TextStyle(fontSize: 38, height: 1.02, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined, size: 18, color: Color(0xFFDDE8FF)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$secondaryLabel: $secondaryPriceLabel',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Rabat procentowy: $discountPercentLabel',
            style: const TextStyle(fontSize: 12, color: Color(0xFFE5EDFF), fontWeight: FontWeight.w700),
          ),
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
        border: Border.all(color: Color.alphaBlend(const Color(0x14000000), tint)),
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

class _PreviewDeliveryCard extends StatelessWidget {
  const _PreviewDeliveryCard({
    required this.customerName,
    required this.customerEmail,
    required this.canSendEmail,
  });

  final String customerName;
  final String? customerEmail;
  final bool canSendEmail;

  @override
  Widget build(BuildContext context) {
    final normalizedEmail = customerEmail?.trim();
    final hasRecipient = normalizedEmail != null && normalizedEmail.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF263B61), Color(0xFF35527E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF8EA6D0).withValues(alpha: 0.36), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E2038).withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 420;
          final badge = Container(
            width: isCompact ? 72 : 88,
            height: isCompact ? 72 : 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.14),
              border: Border.all(color: const Color(0xFFDDE8FF).withValues(alpha: 0.34), width: 1.6),
            ),
            child: Icon(
              Icons.mark_email_read_outlined,
              size: isCompact ? 34 : 40,
              color: Colors.white,
            ),
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kanał doręczenia',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.9,
                  color: Color(0xFFDDE8FF),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                customerName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                hasRecipient ? 'Adres klienta gotowy do użycia' : 'Adres klienta wymaga uzupełnienia',
                style: const TextStyle(color: Color(0xFFDDE8FF), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                hasRecipient ? normalizedEmail! : 'Brak adresu e-mail klienta w danych tej oferty.',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                canSendEmail
                    ? 'Użyj przycisku „Wyślij e-mailem” w górnej belce, aby przekazać klientowi finalną wersję oferty.'
                    : 'Najpierw wygeneruj wersję oferty, a dopiero potem wyślij ją klientowi e-mailem.',
                style: const TextStyle(color: Color(0xFFE5EDFF), height: 1.55),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFDDE8FF).withValues(alpha: 0.30)),
                ),
                child: Text(
                  hasRecipient ? 'Wysyłka klientowska: e-mail' : 'Wysyłka wstrzymana do czasu uzupełnienia e-maila',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [badge, const SizedBox(height: 16), details],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [badge, const SizedBox(width: 16), Expanded(child: details)],
          );
        },
      ),
    );
  }
}
class _PreviewFinanceSummaryRow extends StatelessWidget {
  const _PreviewFinanceSummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x1FBE933E)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF6E6E73)),
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                fontWeight: FontWeight.w700,
                color: emphasize ? const Color(0xFF1D1D1F) : const Color(0xFF3A3A40),
              ),
            ),
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
              decoration: _previewSurfaceDecoration(
                tint: const Color(0xFF8A7441),
                radius: 20,
                fillStrength: 0.025,
                borderStrength: 0.20,
                shadowStrength: 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: const TextStyle(fontSize: 12, color: VeloPrimePalette.muted)),
                  const SizedBox(height: 6),
                  Text(item.value, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (item.secondaryValue?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.secondaryValue!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6A5D45),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
          .toList(),
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
  const _PreviewInfoItem(this.label, this.value, {this.secondaryValue});

  final String label;
  final String value;
  final String? secondaryValue;
}

class _PreviewHeroMetaPill extends StatelessWidget {
  const _PreviewHeroMetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFE9D3A0)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE8EEF7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewTechnicalItem {
  const _PreviewTechnicalItem(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

class _PreviewFinancingInsights {
  const _PreviewFinancingInsights({
    required this.summaryLabel,
    this.monthlyRateLabel,
    this.termLabel,
    this.depositLabel,
    this.buyoutLabel,
  });

  final String summaryLabel;
  final String? monthlyRateLabel;
  final String? termLabel;
  final String? depositLabel;
  final String? buyoutLabel;
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

Color _previewTechnicalTint(int index) {
  return index == 0 ? VeloPrimePalette.bronzeDeep : const Color(0xFF8A7441);
}

BoxDecoration _previewSurfaceDecoration({
  required Color tint,
  double radius = 36,
  double fillStrength = 0.025,
  double borderStrength = 0.10,
  double shadowStrength = 0.04,
}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: tint.withValues(alpha: borderStrength)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF13284A).withValues(alpha: shadowStrength),
        blurRadius: 28,
        offset: const Offset(0, 12),
      ),
    ],
  );
}

String? _formatCommissionCode(num? salespersonCommission, bool isNetPricing) {
  if (salespersonCommission == null) {
    return null;
  }

  final normalized = salespersonCommission.round();
  if (normalized <= 0) {
    return null;
  }

  return '$normalized${isNetPricing ? 'N' : 'B'}';
}

Future<void> _openPreviewLightbox(BuildContext context, List<_PreviewMediaImageSource> images, _PreviewMediaImageSource selectedSource) {
  if (images.isEmpty) {
    return Future.value();
  }

  final normalizedImages = images.where((item) => item.primarySource.trim().isNotEmpty).toList(growable: false);
  if (normalizedImages.isEmpty) {
    return Future.value();
  }

  final initialIndex = normalizedImages.indexWhere((item) => item.key == selectedSource.key);

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Podgląd zdjęcia',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _PreviewLightboxDialog(
        images: normalizedImages,
        initialIndex: initialIndex >= 0 ? initialIndex : 0,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: child,
      );
    },
  );
}

const String _defaultFinancingDisclaimer =
    'Prezentowane raty są orientacyjne i obliczone na podstawie parametrów wprowadzonych do kalkulatora. '
    'Ostateczna decyzja finansowa, wysokość rat oraz warunki umowy są ustalane przez instytucję finansującą '
    'po pełnej analizie zdolności kredytowej klienta. Oferta nie stanowi wiążącej oferty finansowania zgodnie z Kodeksem cywilnym.';

_PreviewFinancingInsights _extractFinancingInsights(String? summary, String? variant) {
  final normalizedSummary = (summary ?? '').trim();
  final normalizedVariant = (variant ?? '').trim();
  final fallbackSummary = normalizedSummary.isNotEmpty
      ? normalizedSummary
      : (normalizedVariant.isNotEmpty ? normalizedVariant : 'Warunki finansowania zostaną doprecyzowane po pełnej kalkulacji.');

  String? capture(RegExp pattern) {
    final match = pattern.firstMatch(fallbackSummary);
    return match?.group(1)?.trim();
  }

  final moneyFragment = r'[\d\s.,]+\s*(?:zł|PLN)';
  final monthlyRate = capture(RegExp('rata\\s*(?:od)?\\s*($moneyFragment)', caseSensitive: false));
  final term = capture(RegExp(r'(\d+\s*mies\.)', caseSensitive: false));
  final deposit = capture(RegExp('wpłata\\s*($moneyFragment)', caseSensitive: false));
  final buyout = capture(RegExp(r'wykup\s*([\d\s.,]+%)', caseSensitive: false));

  return _PreviewFinancingInsights(
    summaryLabel: fallbackSummary,
    monthlyRateLabel: monthlyRate == null ? null : 'od $monthlyRate',
    termLabel: term,
    depositLabel: deposit,
    buyoutLabel: buyout,
  );
}

bool _isCompanyCustomer(String? customerType) {
  final normalized = customerType?.trim().toLowerCase() ?? '';
  return normalized.contains('firm') || normalized == 'b2b' || normalized == 'company';
}

String _formatPowertrainType(String? powertrainType) {
  final normalized = powertrainType?.trim().toLowerCase() ?? '';
  if (normalized.contains('electric') || normalized.contains('ev') || normalized.contains('elek')) {
    return 'Elektryczny';
  }

  if (normalized.contains('hybrid') || normalized.contains('phev') || normalized.contains('hev') || normalized.contains('hyb')) {
    return 'Hybrydowy';
  }

  if (normalized.contains('petrol') || normalized.contains('diesel') || normalized.contains('fuel') || normalized.contains('spalin')) {
    return 'Spalinowy';
  }

  return 'Do uzupełnienia';
}

class _PreviewAdvisorAvatar extends StatelessWidget {
  const _PreviewAdvisorAvatar({
    required this.avatarUrl,
    required this.name,
    required this.size,
  });

  final String? avatarUrl;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = _buildImage();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.26), width: 2),
        gradient: const LinearGradient(
          colors: [Color(0xFFF7F1E5), Color(0xFFEAD9B3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: image ?? Center(
        child: Text(
          _buildInitials(name),
          style: TextStyle(fontSize: size * 0.28, fontWeight: FontWeight.w800, color: const Color(0xFF7A5B20)),
        ),
      ),
    );
  }

  Widget? _buildImage() {
    final value = avatarUrl?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.startsWith('data:image/')) {
      UriData? uriData;
      try {
        uriData = UriData.parse(value);
      } catch (_) {
        uriData = null;
      }

      final bytes = uriData?.contentAsBytes();
      if (bytes == null) {
        return null;
      }

      return Image.memory(bytes, fit: BoxFit.cover);
    }

    return Image.network(value, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const SizedBox.shrink());
  }
}

String _buildInitials(String value) {
  final parts = value.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2).toList(growable: false);
  if (parts.isEmpty) {
    return 'VP';
  }

  return parts.map((part) => part.characters.first.toUpperCase()).join();
}

_ParsedCatalogKey? _parseCatalogKey(String? catalogKey) {
  final normalized = catalogKey?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  final parts = normalized.split('::');
  if (parts.length < 3) {
    return null;
  }

  return _ParsedCatalogKey(
    brand: parts[0],
    model: parts[1],
    version: parts[2],
    year: parts.length > 3 && parts[3].trim().isNotEmpty ? parts[3].trim() : null,
  );
}

class _ParsedCatalogKey {
  const _ParsedCatalogKey({
    required this.brand,
    required this.model,
    required this.version,
    required this.year,
  });

  final String brand;
  final String model;
  final String version;
  final String? year;
}