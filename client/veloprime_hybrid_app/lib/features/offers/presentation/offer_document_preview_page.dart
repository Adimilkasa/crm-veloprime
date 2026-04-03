import 'dart:io';
import 'dart:ui';

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

  Future<OfferDocumentSnapshot> _loadDocument() async {
    try {
      return await widget.repository.fetchDocumentSnapshot(
        offerId: widget.offerId,
        versionId: widget.versionId,
      );
    } catch (error) {
      final initialDocument = widget.initialDocument;
      if (initialDocument != null) {
        return initialDocument;
      }

      rethrow;
    }
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

  Future<void> _contactAdvisor(OfferDocumentAdvisorSnapshot advisor) async {
    Uri? uri;
    if (advisor.email != null && advisor.email!.trim().isNotEmpty) {
      uri = Uri(
        scheme: 'mailto',
        path: advisor.email!.trim(),
      );
    } else if (advisor.phone != null && advisor.phone!.trim().isNotEmpty) {
      uri = Uri(
        scheme: 'tel',
        path: advisor.phone!.replaceAll(' ', ''),
      );
    }

    if (uri == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak danych kontaktowych opiekuna oferty.')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się uruchomić kontaktu z opiekunem.')),
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
          final validUntilLabel = _formatNullableDate(customer.validUntil) ?? 'Do potwierdzenia';
          final commercialSummary = customer.financingSummary != null && customer.financingSummary!.trim().isNotEmpty
              ? customer.financingSummary!
              : customer.financingVariant ?? 'Warunki ustalane indywidualnie';
          final effectivePriceLabel = _isCompanyCustomer(document.payload.internal.customerType)
              ? customer.finalNetLabel
              : customer.finalGrossLabel;
          final heroSupportMessage = specDocumentSource != null
              ? 'To produkcyjna wersja oferty przygotowana dla klienta, z prezentacją modelu, konfiguracji, specyfikacji i warunków finansowych.'
              : 'To produkcyjna wersja oferty przygotowana dla klienta, z prezentacją modelu, konfiguracji i warunków finansowych.';
          final pricingDisplayMode = _isCompanyCustomer(document.payload.internal.customerType) ? 'netto' : 'brutto';
          final financingInsights = _extractFinancingInsights(customer.financingSummary, customer.financingVariant);
          final generatedAtLabel = _formatNullableDate(document.payload.createdAt, _dateFormat) ?? '-';
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
            if (document.payload.internal.powerHp?.trim().isNotEmpty == true)
              _PreviewTechnicalItem(Icons.flash_on_outlined, 'Moc', document.payload.internal.powerHp!.trim()),
            if (document.payload.internal.systemPowerHp?.trim().isNotEmpty == true)
              _PreviewTechnicalItem(Icons.electric_bolt_outlined, 'Moc układu', document.payload.internal.systemPowerHp!.trim()),
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
          if (baseColorName != null && baseColorName.isNotEmpty) {
            technicalItems.add(
              _PreviewTechnicalItem(Icons.format_paint_outlined, 'Kolor bazowy modelu', baseColorName),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 104),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PreviewHeroCard(
                          document: document,
                          heroImageSource: heroImageSource,
                          contactLine: contactLine,
                          supportingMessage: heroSupportMessage,
                          effectivePriceLabel: effectivePriceLabel,
                          generatedAtLabel: generatedAtLabel,
                          commercialSummary: commercialSummary,
                            customerLine: [customer.customerName, customer.customerEmail, customer.customerPhone]
                              .whereType<String>()
                              .where((item) => item.trim().isNotEmpty)
                              .join(' • '),
                        ),
                        if (specDocumentSource != null) ...[
                          const SizedBox(height: 16),
                          _PreviewPdfStrip(
                            onPressed: () => _openDocumentSource(specDocumentSource, 'specyfikacja-modelu'),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _PreviewSectionCard(
                          title: 'Najważniejsze dane',
                          subtitle: 'Najpierw to, co klient powinien zrozumieć od razu. Kluczowe parametry są większe, reszta lżejsza i spokojniejsza wizualnie.',
                          child: _PreviewTechnicalSection(
                            items: technicalItems,
                            metaItems: [
                              'Oferta dla ${customer.customerName}',
                              'Opiekun: ${advisor.fullName.isNotEmpty ? advisor.fullName : document.payload.internal.ownerName}',
                              'Ważna do $validUntilLabel',
                              'Ceny w trybie $pricingDisplayMode',
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _PreviewSectionCard(
                          title: 'Galeria',
                          subtitle: 'Sekcyjna prezentacja auta: zewnętrze, wnętrze i detale.',
                          child: _AssetGallery(
                            media: resolvedMedia,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _PreviewValueSection(
                          listPriceLabel: customer.listPriceLabel,
                          discountLabel: customer.discountLabel,
                          discountPercentLabel: customer.discountPercentLabel,
                          effectivePriceLabel: effectivePriceLabel,
                          secondaryPriceLabel: pricingDisplayMode == 'netto' ? customer.finalGrossLabel : customer.finalNetLabel,
                          pricingDisplayMode: pricingDisplayMode,
                        ),
                        const SizedBox(height: 20),
                        _PreviewFinancingSection(
                          insights: financingInsights,
                          pricingDisplayMode: pricingDisplayMode,
                          financingVariant: customer.financingVariant ?? 'Do uzupełnienia',
                          primaryFinalPriceLabel: pricingDisplayMode == 'netto' ? customer.finalNetLabel : customer.finalGrossLabel,
                          secondaryFinalPriceLabel: pricingDisplayMode == 'netto' ? customer.finalGrossLabel : customer.finalNetLabel,
                          disclaimer: customer.financingDisclaimer ?? _defaultFinancingDisclaimer,
                        ),
                        const SizedBox(height: 20),
                        _PreviewSectionCard(
                          title: 'Porozmawiajmy o tej konfiguracji',
                          subtitle: 'To jest końcówka tej oferty: kontakt z opiekunem i przejście do realnej rozmowy o finansowaniu, wariancie i kolejnych krokach.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PreviewAdvisorCard(
                                advisor: advisor,
                                fallbackName: document.payload.internal.ownerName,
                                advisorLine: advisorLine,
                                onContact: () => _contactAdvisor(advisor),
                              ),
                              const SizedBox(height: 12),
                              _PreviewCalloutBox(
                                title: 'Wskazówki do rozmowy',
                                value: customer.notes?.isNotEmpty == true
                                    ? customer.notes!
                                    : 'Brak dodatkowych uwag do oferty.',
                                tint: const Color(0xFFF3EFE7),
                              ),
                              const SizedBox(height: 12),
                              _PreviewInfoGrid(items: [
                                _PreviewInfoItem('Numer oferty', customer.offerNumber),
                                _PreviewInfoItem('Ważna do', validUntilLabel),
                                _PreviewInfoItem('Specyfikacja', specDocumentSource != null ? 'PDF dostępny' : 'Brak PDF'),
                                _PreviewInfoItem('Tryb cen', pricingDisplayMode),
                              ]),
                              const SizedBox(height: 12),
                              _PreviewCalloutBox(
                                title: 'Zastrzeżenie formalne',
                                value: formalNotice,
                                tint: const Color(0xFFF7F1E5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _PreviewStickyTopBar(
                    hasSpecification: specDocumentSource != null,
                    canSendEmail: canSendEmail,
                    isSendingEmail: _isSendingEmail,
                    onBack: () => Navigator.of(context).pop(),
                    onOpenSpecification: specDocumentSource == null
                        ? null
                        : () => _openDocumentSource(specDocumentSource, 'specyfikacja-modelu'),
                    onSendOffer: canSendEmail ? () => _sendOfferByEmail(document) : null,
                  ),
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
    required this.contactLine,
    required this.supportingMessage,
    required this.effectivePriceLabel,
    required this.generatedAtLabel,
    required this.commercialSummary,
    required this.customerLine,
  });

  final OfferDocumentSnapshot document;
  final String? heroImageSource;
  final String contactLine;
  final String supportingMessage;
  final String effectivePriceLabel;
  final String generatedAtLabel;
  final String commercialSummary;
  final String customerLine;

  @override
  Widget build(BuildContext context) {
    final customer = document.payload.customer;
    final modelLabel = customer.modelName ?? document.title;
    final advisorName = document.payload.advisor.fullName.isNotEmpty
        ? document.payload.advisor.fullName
        : document.payload.internal.ownerName;
    final validUntilLabel = _formatNullableDate(customer.validUntil) ?? 'Do potwierdzenia';
    final customerNarrative = customer.selectedColorName?.trim().isNotEmpty == true
      ? '$modelLabel w kolorze ${customer.selectedColorName!.trim()}. Konfiguracja przygotowana tak, by od pierwszego ekranu pokazać charakter auta i koszt wejścia.'
      : '$modelLabel. Konfiguracja przygotowana tak, by od pierwszego ekranu pokazać charakter auta i koszt wejścia.';
    final rateLabel = commercialSummary.contains('zł') ? commercialSummary : null;
    final primaryValue = effectivePriceLabel.trim().isNotEmpty ? effectivePriceLabel : 'Indywidualna oferta dopasowana do konfiguracji';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;

        return ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: Container(
            constraints: BoxConstraints(minHeight: isCompact ? 560 : 680),
            decoration: BoxDecoration(
              color: const Color(0xFFE6EBF2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 34,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (heroImageSource != null)
                  _PreviewImage(
                    source: heroImageSource!,
                    height: isCompact ? 560 : 680,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    missingLabel: 'Podgląd grafiki modelu jest niedostępny',
                  )
                else
                  Container(color: const Color(0xFFB8C4D5)),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromRGBO(7, 12, 18, 0.08),
                        Color.fromRGBO(7, 12, 18, 0.22),
                        Color.fromRGBO(7, 12, 18, 0.58),
                        Color.fromRGBO(245, 245, 247, 0.96),
                      ],
                      stops: [0, 0.18, 0.72, 1],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromRGBO(7, 12, 18, 0.68),
                        Color.fromRGBO(7, 12, 18, 0.34),
                        Color.fromRGBO(7, 12, 18, 0.1),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(isCompact ? 24 : 34, isCompact ? 26 : 32, isCompact ? 24 : 34, isCompact ? 28 : 34),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: Text(
                          'Oferta dla ${customer.customerName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Text(
                          modelLabel,
                          style: TextStyle(
                            fontSize: isCompact ? 44 : 72,
                            height: 0.92,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Text(
                          supportingMessage.isNotEmpty ? supportingMessage : customerNarrative,
                          style: TextStyle(
                            fontSize: isCompact ? 17 : 19,
                            height: 1.6,
                            color: Colors.white.withValues(alpha: 0.84),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        customerNarrative,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        rateLabel ?? 'Cena dla tej konfiguracji',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: Colors.white.withValues(alpha: 0.68),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        primaryValue,
                        style: TextStyle(
                          fontSize: isCompact ? 38 : 52,
                          height: 0.98,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dane klienta',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: Colors.white.withValues(alpha: 0.66),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              customerLine.isNotEmpty ? customerLine : 'Dane klienta do uzupełnienia',
                              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.white.withValues(alpha: 0.84)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Opiekun: $advisorName • Ważna do: $validUntilLabel • Wygenerowano: $generatedAtLabel',
                        style: TextStyle(fontSize: 14, height: 1.6, color: Colors.white.withValues(alpha: 0.74)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        contactLine,
                        style: TextStyle(fontSize: 14, height: 1.6, color: Colors.white.withValues(alpha: 0.68)),
                      ),
                    ],
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
    final keyItems = items.take(2).toList(growable: false);
    final standardItems = items.skip(2).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 760;
            final tileWidth = isCompact ? constraints.maxWidth : (constraints.maxWidth - 14) / 2;

            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: keyItems
                  .map(
                    (item) => SizedBox(
                      width: tileWidth,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PreviewCircleIcon(icon: item.icon),
                            const SizedBox(height: 14),
                            Text(item.label, style: const TextStyle(fontSize: 12, color: VeloPrimePalette.muted)),
                            const SizedBox(height: 6),
                            Text(item.value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.1)),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        if (standardItems.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: standardItems
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: VeloPrimePalette.lineStrong),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label, style: const TextStyle(fontSize: 12, color: VeloPrimePalette.muted)),
                        const SizedBox(height: 4),
                        Text(item.value, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F2E9).withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.52)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF13284A).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
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
                  label: 'Otwórz specyfikację PDF',
                ),
              if (canSendEmail)
                _PreviewTopBarButton(
                  onPressed: isSendingEmail ? null : onSendOffer,
                  icon: isSendingEmail ? null : Icons.alternate_email_outlined,
                  label: isSendingEmail ? 'Wysyłamy ofertę...' : 'Wyślij ofertę',
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
        ),
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
    final backgroundColor = isPrimary ? const Color(0xFFD4A84F) : Colors.white.withValues(alpha: 0.76);
    final foregroundColor = isPrimary ? const Color(0xFF23180A) : const Color(0xFF243247);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: isPrimary ? 0.18 : 0.64)),
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
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.1, color: Color(0xFF1D1D1F)),
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
                    Expanded(flex: 15, child: featuredPanel),
                    if (thumbnails.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Expanded(flex: 5, child: thumbnailsPanel),
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
    required this.heroSource,
    required this.gallerySources,
    required this.categories,
  });

  final String? specSource;
  final String? heroSource;
  final List<String> gallerySources;
  final List<_PreviewGalleryCategory> categories;

  factory _ResolvedPreviewMedia.fromDocument(OfferDocumentSnapshot document, LocalOfferAssetBundle fallbackAssets) {
    List<String> normalizeList(List<String> items) {
      return items.where((item) => item.trim().isNotEmpty).toSet().toList(growable: false);
    }

    List<String> pick(List<String> primary, List<String> fallback) {
      final normalizedPrimary = normalizeList(primary);
      if (normalizedPrimary.isNotEmpty) {
        return normalizedPrimary;
      }

      return normalizeList(fallback);
    }

    final premiumImages = pick(document.assets.premiumImages, fallbackAssets.premiumImages);
    final exteriorImages = pick(document.assets.exteriorImages, fallbackAssets.exteriorImages);
    final interiorImages = pick(document.assets.interiorImages, fallbackAssets.interiorImages);
    final detailImages = pick(document.assets.detailImages, fallbackAssets.detailImages);

    final gallerySources = <String>{
      ...premiumImages,
      ...exteriorImages,
      ...interiorImages,
      ...detailImages,
    }.toList(growable: false);

    final heroSource = [
      ...premiumImages,
      ...exteriorImages,
      ...detailImages,
      if (fallbackAssets.heroImageAsset != null) fallbackAssets.heroImageAsset!,
    ].where((item) => item.trim().isNotEmpty).cast<String?>().firstWhere((item) => item != null, orElse: () => null);

    final categories = [
      _PreviewGalleryCategory(title: 'Wybrane kadry', images: premiumImages),
      _PreviewGalleryCategory(title: 'Zewnętrze', images: exteriorImages),
      _PreviewGalleryCategory(title: 'Wnętrze', images: interiorImages),
      _PreviewGalleryCategory(title: 'Detale', images: detailImages),
    ].where((category) => category.images.isNotEmpty).toList(growable: false);

    return _ResolvedPreviewMedia(
      specSource: document.assets.specPdfUrl?.trim().isNotEmpty == true ? document.assets.specPdfUrl : fallbackAssets.specPdfAssetPath,
      heroSource: heroSource,
      gallerySources: gallerySources,
      categories: categories,
    );
  }
}

class _PreviewGalleryHeroTile extends StatelessWidget {
  const _PreviewGalleryHeroTile({
    required this.source,
    required this.allImages,
    required this.title,
  });

  final String source;
  final List<String> allImages;
  final String title;

  @override
  Widget build(BuildContext context) {
    return _PreviewImageActionTile(
      source: source,
      allImages: allImages,
      height: 260,
      title: title,
      subtitle: 'Otwórz pełną galerię',
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

  final List<String> images;
  final List<String> allImages;

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
                    height: 72,
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

  final String source;
  final List<String> allImages;
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
                          Colors.black.withValues(alpha: 0.18),
                          Colors.black.withValues(alpha: 0.48),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: Column(
                      crossAxisAlignment: overlayAlignment == Alignment.bottomLeft
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 18),
                          Text(subtitle!, style: TextStyle(color: Colors.white.withValues(alpha: 0.76), fontSize: 12)),
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

  final List<String> images;
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
                      key: ValueKey(currentSource),
                      tag: 'offer-lightbox-$currentSource',
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
  final List<String> images;
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
    this.subtitle,
  });

  final String title;
  final Widget child;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withValues(alpha: 0.74)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.05, color: Color(0xFF1D1D1F))),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              subtitle!,
              style: const TextStyle(color: Color(0xFF6E6E73), height: 1.7, fontSize: 16),
            ),
          ],
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _PreviewPdfStrip extends StatelessWidget {
  const _PreviewPdfStrip({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EDE2),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 10,
        spacing: 16,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PreviewCircleIcon(icon: Icons.description_outlined),
              SizedBox(width: 14),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PDF z kartą modelu i wyposażenia',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1D1D1F)),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Krótki dokument z techniczną specyfikacją i szczegółami konfiguracji przygotowanej dla klienta.',
                      style: TextStyle(color: Color(0xFF4E4E56), fontSize: 13, height: 1.55),
                    ),
                  ],
                ),
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFBE933E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Pobierz PDF'),
          ),
        ],
      ),
    );
  }
}

class _PreviewValueSection extends StatelessWidget {
  const _PreviewValueSection({
    required this.listPriceLabel,
    required this.discountLabel,
    required this.discountPercentLabel,
    required this.effectivePriceLabel,
    required this.secondaryPriceLabel,
    required this.pricingDisplayMode,
  });

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
      subtitle: 'Ta sekcja porządkuje podstawy wyceny, ale prowadzi klienta do najważniejszego pytania: jak wygląda finalna propozycja zakupu tej konfiguracji.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cards = [
            _PreviewPricingStatCard(label: 'Cena katalogowa', value: listPriceLabel),
            _PreviewPricingStatCard(label: 'Rabat', value: discountLabel),
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
    required this.insights,
    required this.pricingDisplayMode,
    required this.financingVariant,
    required this.primaryFinalPriceLabel,
    required this.secondaryFinalPriceLabel,
    required this.disclaimer,
  });

  final _PreviewFinancingInsights insights;
  final String pricingDisplayMode;
  final String financingVariant;
  final String primaryFinalPriceLabel;
  final String secondaryFinalPriceLabel;
  final String disclaimer;

  @override
  Widget build(BuildContext context) {
    final displayHint = pricingDisplayMode == 'netto'
        ? 'Dla klienta firmowego pokazujemy wartości netto.'
        : 'Dla klienta prywatnego pokazujemy wartości brutto.';

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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 860;
              final primaryPanel = Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D1F),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D1D1F).withValues(alpha: 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finanse',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Najważniejsza liczba tej oferty',
                      style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.02),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Rata miesięczna',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.68), fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      insights.monthlyRateLabel ?? 'Do uzupełnienia po pełnej kalkulacji',
                      style: const TextStyle(color: Colors.white, fontSize: 44, height: 0.98, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$displayHint ${insights.summaryLabel}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.76), height: 1.65),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pricingDisplayMode == 'netto' ? 'Cena końcowa netto' : 'Cena końcowa brutto',
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.58)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            primaryFinalPriceLabel,
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            pricingDisplayMode == 'netto' ? 'Cena końcowa brutto' : 'Cena końcowa netto',
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.52)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            secondaryFinalPriceLabel,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.84), fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
              final summaryPanel = Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.74),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Podsumowanie',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Color(0xFF6E6E73)),
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
            style: const TextStyle(
              color: Color(0xFF5E6168),
              height: 1.6,
              fontSize: 12,
            ),
          ),
        ],
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
          bottom: BorderSide(color: Color(0xFFD9D9DE)),
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

class _PreviewCircleIcon extends StatelessWidget {
  const _PreviewCircleIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF6EFE1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 20, color: VeloPrimePalette.bronzeDeep),
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
      decoration: BoxDecoration(
        color: accent ? const Color(0xFFF8F0E1) : Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent ? const Color(0xFFD9BE84) : VeloPrimePalette.lineStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: VeloPrimePalette.muted)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
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
          colors: [Color(0xFFFBF7EF), Color(0xFFF2E7D3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x1A111111)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(primaryLabel, style: const TextStyle(fontSize: 12, color: VeloPrimePalette.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(
            effectivePriceLabel,
            style: const TextStyle(fontSize: 34, height: 1.05, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined, size: 18, color: VeloPrimePalette.bronzeDeep),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$secondaryLabel: $secondaryPriceLabel',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Rabat procentowy: $discountPercentLabel',
            style: const TextStyle(fontSize: 12, color: VeloPrimePalette.muted, fontWeight: FontWeight.w700),
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

Future<void> _openPreviewLightbox(BuildContext context, List<String> images, String selectedSource) {
  if (images.isEmpty) {
    return Future.value();
  }

  final normalizedImages = images.where((item) => item.trim().isNotEmpty).toList(growable: false);
  if (normalizedImages.isEmpty) {
    return Future.value();
  }

  final initialIndex = normalizedImages.indexOf(selectedSource);

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

  final monthlyRate = capture(RegExp(r'rata\s*(?:od)?\s*([\d\s.,]+\s*zł)', caseSensitive: false));
  final term = capture(RegExp(r'(\d+\s*mies\.)', caseSensitive: false));
  final deposit = capture(RegExp(r'wpłata\s*([\d\s.,]+\s*zł)', caseSensitive: false));
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

class _PreviewAdvisorCard extends StatelessWidget {
  const _PreviewAdvisorCard({
    required this.advisor,
    required this.fallbackName,
    required this.advisorLine,
    required this.onContact,
  });

  final OfferDocumentAdvisorSnapshot advisor;
  final String fallbackName;
  final String advisorLine;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final name = advisor.fullName.isNotEmpty ? advisor.fullName : fallbackName;
    final role = advisor.role.trim().isNotEmpty ? advisor.role : 'SALES';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFBE933E), Color(0xFFD4A84F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B6A2D).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 420;
          final avatar = _PreviewAdvisorAvatar(
            avatarUrl: advisor.avatarUrl,
            name: name,
            size: isCompact ? 72 : 88,
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Porozmawiajmy o tej ofercie',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: const Color(0xFFF7F1E5).withValues(alpha: 0.84),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                role,
                style: TextStyle(color: const Color(0xFFF7F1E5).withValues(alpha: 0.84), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                'Indywidualne dopasowanie warunków i dalszych kroków zakupu',
                style: TextStyle(
                  color: const Color(0xFFF7F1E5).withValues(alpha: 0.96),
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                advisorLine,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.84), height: 1.55),
              ),
              const SizedBox(height: 12),
              Text(
                'Jeśli chcesz doprecyzować wariant finansowania, konfigurację lub kolejne kroki zakupu, skontaktuj się bezpośrednio z opiekunem tej oferty.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.78), height: 1.55),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onContact,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFBE933E),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.call_outlined),
                label: const Text('Skontaktuj się z opiekunem'),
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [avatar, const SizedBox(height: 16), details],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [avatar, const SizedBox(width: 16), Expanded(child: details)],
          );
        },
      ),
    );
  }
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