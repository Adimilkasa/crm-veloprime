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
          final commercialSummary = customer.financingSummary != null && customer.financingSummary!.trim().isNotEmpty
              ? customer.financingSummary!
              : customer.financingVariant ?? 'Warunki ustalane indywidualnie';
          final effectivePriceLabel = _isCompanyCustomer(document.payload.internal.customerType)
              ? customer.finalNetLabel
              : customer.finalGrossLabel;
          final heroAttributes = [
            _PreviewHeroAttribute(label: 'Model', value: customer.modelName ?? document.title),
            _PreviewHeroAttribute(label: 'Kolor', value: customer.selectedColorName ?? 'Bazowy'),
            _PreviewHeroAttribute(label: 'Napęd', value: _formatPowertrainType(document.payload.internal.powertrainType)),
          ];
          final heroSupportMessage = specDocumentSource != null
              ? 'W ofercie znajdziesz specyfikację modelu, najważniejsze parametry techniczne, wycenę oraz przygotowany wariant finansowania.'
              : 'W ofercie znajdziesz najważniejsze parametry techniczne, wycenę, materiały modelu oraz przygotowany wariant finansowania.';
          final pricingDisplayMode = _isCompanyCustomer(document.payload.internal.customerType) ? 'netto' : 'brutto';
          final financingInsights = _extractFinancingInsights(customer.financingSummary, customer.financingVariant);
          final generatedAtLabel = _formatNullableDate(document.payload.createdAt, _dateFormat) ?? '-';
          final validUntilLabel = _formatNullableDate(customer.validUntil) ?? 'Do potwierdzenia';
          final deliverySummary = canSendEmail
              ? 'Ta wersja dokumentu jest gotowa do wysyłki klientowi i stanowi podstawę dla widoku online oferty.'
              : 'Po zapisaniu wersji dokument będzie gotowy do wysyłki klientowi i publikacji w widoku online oferty.';
          final formalNotice = customer.financingDisclaimer ?? _defaultFinancingDisclaimer;
          final technicalItems = <_PreviewTechnicalItem>[
            _PreviewTechnicalItem(Icons.directions_car_filled_outlined, 'Model', customer.modelName ?? document.title),
            _PreviewTechnicalItem(Icons.palette_outlined, 'Kolor konfiguracji', customer.selectedColorName ?? document.payload.internal.selectedColorName ?? 'Bazowy'),
            _PreviewTechnicalItem(Icons.bolt_outlined, 'Typ napędu', _formatPowertrainType(document.payload.internal.powertrainType)),
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
                          heroAttributes: heroAttributes,
                          supportingMessage: heroSupportMessage,
                        ),
                        if (specDocumentSource != null) ...[
                          const SizedBox(height: 16),
                          _PreviewPdfStrip(
                            onPressed: () => _openDocumentSource(specDocumentSource, 'specyfikacja-modelu'),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _PreviewSectionCard(
                          title: 'Konfiguracja techniczna',
                          subtitle: 'Najważniejsze parametry przygotowane dla tej konfiguracji pojazdu.',
                          child: _PreviewTechnicalGrid(items: technicalItems),
                        ),
                        const SizedBox(height: 20),
                        _PreviewSectionCard(
                          title: 'Materiały modelu',
                          subtitle: 'Galeria pokazuje sylwetkę modelu, detale i wnętrze przygotowane dla tej oferty.',
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
                          disclaimer: customer.financingDisclaimer ?? _defaultFinancingDisclaimer,
                        ),
                        const SizedBox(height: 20),
                        _PreviewSectionCard(
                          title: 'Opiekun oferty',
                          subtitle: 'Dane kontaktowe opiekuna i dodatkowe uwagi do tej oferty.',
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
                                title: 'Uwagi do oferty',
                                value: customer.notes?.isNotEmpty == true
                                    ? customer.notes!
                                    : 'Brak dodatkowych uwag do oferty.',
                                tint: const Color(0xFFF3EFE7),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _PreviewSectionCard(
                          title: 'Finalizacja i status dokumentu',
                          subtitle: 'Tu znajdują się status wersji online, termin ważności i formalne informacje do potwierdzenia oferty.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PreviewCalloutBox(
                                title: 'Status wersji online',
                                value: deliverySummary,
                                tint: const Color(0xFFEAF1F8),
                              ),
                              const SizedBox(height: 12),
                              _PreviewInfoGrid(items: [
                                _PreviewInfoItem('Numer oferty', customer.offerNumber),
                                _PreviewInfoItem('Wersja dokumentu', 'v${document.payload.versionNumber}'),
                                _PreviewInfoItem('Wygenerowano', generatedAtLabel),
                                _PreviewInfoItem('Ważna do', validUntilLabel),
                                _PreviewInfoItem('Specyfikacja', specDocumentSource != null ? 'PDF dostępny' : 'Brak osobnego PDF'),
                                _PreviewInfoItem('Typ klienta', _formatCustomerType(document.payload.internal.customerType)),
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
    required this.heroAttributes,
    required this.supportingMessage,
  });

  final OfferDocumentSnapshot document;
  final String? heroImageSource;
  final String contactLine;
  final List<_PreviewHeroAttribute> heroAttributes;
  final String supportingMessage;

  @override
  Widget build(BuildContext context) {
    final customer = document.payload.customer;
    final modelLabel = customer.modelName ?? document.title;
    final colorLabel = customer.selectedColorName ?? 'kolor bazowy';
    final powertrainLabel = _formatPowertrainType(document.payload.internal.powertrainType);
    final customerNarrative = 'Konfiguracja $modelLabel w kolorze $colorLabel z napędem $powertrainLabel została przygotowana do prezentacji klientowi.';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;
        final heroHeight = isCompact ? 420.0 : 470.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: Container(
            height: heroHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3EC),
              border: Border.all(color: Colors.white.withValues(alpha: 0.54)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF13284A).withValues(alpha: 0.14),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (heroImageSource != null)
                  _PreviewImage(
                    source: heroImageSource!,
                    height: heroHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    missingLabel: 'Podgląd grafiki modelu jest niedostępny',
                  )
                else
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          Color(0xFFFAF6EE),
                          Color(0xFFECE5D9),
                          Color(0xFFD9E5F4),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.24),
                        const Color(0xFF0E1624).withValues(alpha: 0.68),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(isCompact ? 24 : 34, isCompact ? 24 : 30, isCompact ? 24 : 34, isCompact ? 24 : 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VeloPrimeSectionEyebrow(label: 'Oferta dla klienta', color: Color(0xFFF2DEAE)),
                      const SizedBox(height: 12),
                      Text(
                        customer.customerName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        modelLabel,
                        style: TextStyle(
                          fontSize: isCompact ? 30 : 38,
                          height: 1.08,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isCompact ? 320 : 440),
                        child: Text(
                          customerNarrative,
                          style: TextStyle(
                            fontSize: isCompact ? 15 : 16,
                            height: 1.45,
                            color: Colors.white.withValues(alpha: 0.86),
                          ),
                        ),
                      ),
                      const Spacer(),
                      _PreviewGlassCard(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 16 : 18,
                          vertical: isCompact ? 14 : 16,
                        ),
                        child: isCompact
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contactLine,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.45,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _PreviewHeroAttributesRow(attributes: heroAttributes),
                                  const SizedBox(height: 12),
                                  Text(
                                    supportingMessage,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: Colors.white.withValues(alpha: 0.76),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Kontakt klienta',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.0,
                                            color: Colors.white.withValues(alpha: 0.68),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          contactLine,
                                          style: TextStyle(
                                            fontSize: 13,
                                            height: 1.45,
                                            color: Colors.white.withValues(alpha: 0.82),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 5,
                                    child: _PreviewHeroAttributesRow(attributes: heroAttributes),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      supportingMessage,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.5,
                                        color: Colors.white.withValues(alpha: 0.76),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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

class _PreviewGlassCard extends StatelessWidget {
  const _PreviewGlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PreviewHeroAttributesRow extends StatelessWidget {
  const _PreviewHeroAttributesRow({required this.attributes});

  final List<_PreviewHeroAttribute> attributes;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: attributes
          .map(
            (attribute) => Container(
              constraints: const BoxConstraints(minWidth: 124, maxWidth: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    attribute.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                      color: Colors.white.withValues(alpha: 0.64),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    attribute.value,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PreviewHeroSummary extends StatelessWidget {
  const _PreviewHeroSummary({
    required this.offerNumber,
    required this.createdAtLabel,
    required this.effectivePriceLabel,
    required this.commercialSummary,
  });

  final String offerNumber;
  final String createdAtLabel;
  final String effectivePriceLabel;
  final String commercialSummary;

  @override
  Widget build(BuildContext context) {
    return _PreviewGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wartość końcowa',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            effectivePriceLabel,
            style: const TextStyle(
              fontSize: 30,
              height: 1.05,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            commercialSummary,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PreviewPill(label: 'Numer oferty', value: offerNumber, dark: true),
              _PreviewPill(label: 'Wygenerowano', value: createdAtLabel, dark: true),
            ],
          ),
        ],
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
    final heroImageSource = media.heroSource;
    final galleryImages = media.gallerySources.where((item) => item != heroImageSource).toList(growable: false);
    final featuredGallerySource = galleryImages.isNotEmpty
        ? galleryImages.first
        : (heroImageSource ?? (media.gallerySources.isNotEmpty ? media.gallerySources.first : null));
    final spotlightImages = galleryImages.skip(galleryImages.isNotEmpty ? 1 : 0).take(4).toList(growable: false);

    if (featuredGallerySource == null && spotlightImages.isEmpty) {
      return const _MissingImagePlaceholder(label: 'Brak grafik modelu dla tego dokumentu');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 860;
            final featuredPanel = _PreviewGalleryHeroTile(
              source: featuredGallerySource!,
              allImages: media.gallerySources,
              title: 'Galeria modelu',
            );
            final thumbnailsPanel = _PreviewGalleryThumbnailColumn(
              images: spotlightImages,
              allImages: media.gallerySources,
            );

            if (isCompact) {
              return Column(
                children: [
                  featuredPanel,
                  const SizedBox(height: 14),
                  thumbnailsPanel,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 13, child: featuredPanel),
                const SizedBox(width: 16),
                Expanded(flex: 7, child: thumbnailsPanel),
              ],
            );
          },
        ),
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
      _PreviewGalleryCategory(title: 'Zewnętrze', images: exteriorImages),
      _PreviewGalleryCategory(title: 'Wnętrze', images: interiorImages),
      _PreviewGalleryCategory(title: 'Detale', images: detailImages),
    ];

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
      height: 240,
      title: title,
      subtitle: 'Otwórz podgląd zdjęcia',
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
        final tileWidth = constraints.maxWidth > 320 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

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
                    height: 84,
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

class _PreviewGalleryCategorySection extends StatelessWidget {
  const _PreviewGalleryCategorySection({
    required this.category,
    required this.allImages,
  });

  final _PreviewGalleryCategory category;
  final List<String> allImages;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(category.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: category.images
              .map(
                (image) => SizedBox(
                  width: 180,
                  child: _PreviewImageActionTile(
                    source: image,
                    allImages: allImages,
                    height: 126,
                    title: category.title,
                    borderRadius: 24,
                  ),
                ),
              )
              .toList(),
        ),
      ],
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
                          const SizedBox(height: 4),
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
    return VeloPrimeWorkspacePanel(
      tint: VeloPrimePalette.sea,
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(color: Colors.black54, height: 1.55),
            ),
          ],
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VeloPrimePalette.lineStrong),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 10,
        spacing: 12,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PreviewCircleIcon(icon: Icons.description_outlined),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Specyfikacja pojazdu dostępna do pobrania',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Plik zawiera szczegółową kartę modelu i wyposażenia.',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Pobierz PDF'),
          ),
        ],
      ),
    );
  }
}

class _PreviewTechnicalGrid extends StatelessWidget {
  const _PreviewTechnicalGrid({required this.items});

  final List<_PreviewTechnicalItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1040 ? 3 : width >= 700 ? 2 : 1;
        final tileWidth = columns == 1 ? width : (width - (14 * (columns - 1))) / columns;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: items
              .map(
                (item) => SizedBox(
                  width: tileWidth,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.84),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: VeloPrimePalette.lineStrong),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF101F3B).withValues(alpha: 0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PreviewCircleIcon(icon: item.icon),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.label, style: const TextStyle(fontSize: 12, color: VeloPrimePalette.muted)),
                              const SizedBox(height: 4),
                              Text(item.value, style: const TextStyle(fontWeight: FontWeight.w800, height: 1.3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
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
      title: 'Wartość pojazdu',
      subtitle: 'Eksponujemy cenę końcową w trybie zgodnym z typem klienta oraz zostawiamy pełny kontekst rabatu.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 540;
          final left = Column(
            children: [
              _PreviewPricingStatCard(label: 'Cena katalogowa', value: listPriceLabel),
              const SizedBox(height: 12),
              _PreviewPricingStatCard(label: 'Rabat', value: discountLabel),
              const SizedBox(height: 12),
              _PreviewPricingStatCard(label: 'Rabat procentowy', value: discountPercentLabel),
            ],
          );
          final right = _PreviewFinalPriceCard(
            effectivePriceLabel: effectivePriceLabel,
            secondaryPriceLabel: secondaryPriceLabel,
            pricingDisplayMode: pricingDisplayMode,
          );

          if (isCompact) {
            return Column(
              children: [
                left,
                const SizedBox(height: 14),
                right,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right),
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
    required this.disclaimer,
  });

  final _PreviewFinancingInsights insights;
  final String pricingDisplayMode;
  final String financingVariant;
  final String disclaimer;

  @override
  Widget build(BuildContext context) {
    final displayHint = pricingDisplayMode == 'netto'
        ? 'Dla klienta firmowego pokazujemy wartości netto.'
        : 'Dla klienta prywatnego pokazujemy wartości brutto.';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF13284A), Color(0xFF1D3B63), Color(0xFF27537C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF11213D).withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Twoja miesięczna rata',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            displayHint,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.74), height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insights.monthlyRateLabel ?? 'Do uzupełnienia po pełnej kalkulacji',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  insights.summaryLabel,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.82), height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _PreviewDarkInfoChip(label: 'Okres finansowania', value: insights.termLabel ?? '-'),
              _PreviewDarkInfoChip(label: 'Wpłata własna', value: insights.depositLabel ?? '-'),
              _PreviewDarkInfoChip(label: 'Wykup', value: insights.buyoutLabel ?? '-'),
              _PreviewDarkInfoChip(label: 'Typ finansowania', value: financingVariant),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            disclaimer,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              height: 1.6,
              fontSize: 12,
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
  const _PreviewPricingStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VeloPrimePalette.lineStrong),
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
  });

  final String effectivePriceLabel;
  final String secondaryPriceLabel;
  final String pricingDisplayMode;

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
                const Icon(Icons.receipt_long_outlined, size: 18, color: VeloPrimePalette.sea),
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
        ],
      ),
    );
  }
}

class _PreviewDarkInfoChip extends StatelessWidget {
  const _PreviewDarkInfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.64))),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, height: 1.35)),
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
  const _PreviewPill({required this.label, required this.value, this.dark = false});

  final String label;
  final String value;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.2) : VeloPrimePalette.lineStrong),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: dark ? Colors.white : null),
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

class _PreviewHeroAttribute {
  const _PreviewHeroAttribute({required this.label, required this.value});

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

String _formatCustomerType(String? customerType) {
  if (_isCompanyCustomer(customerType)) {
    return 'Klient firmowy';
  }

  if ((customerType ?? '').trim().isEmpty) {
    return 'Klient indywidualny';
  }

  return 'Klient indywidualny';
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
          colors: [Color(0xFF15305B), Color(0xFF25507D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF11213D).withValues(alpha: 0.18),
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
                'Opiekun oferty',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: Colors.white.withValues(alpha: 0.7),
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
                style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                advisorLine,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.84), height: 1.55),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onContact,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD6AD56),
                  foregroundColor: const Color(0xFF1C1711),
                ),
                icon: const Icon(Icons.call_outlined),
                label: const Text('Skontaktuj się'),
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
          colors: [Color(0xFFE8EEF8), Color(0xFFD7E2F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: image ?? Center(
        child: Text(
          _buildInitials(name),
          style: TextStyle(fontSize: size * 0.28, fontWeight: FontWeight.w800, color: const Color(0xFF264266)),
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