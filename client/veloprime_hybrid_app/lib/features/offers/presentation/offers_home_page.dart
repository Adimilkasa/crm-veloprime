import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/presentation/veloprime_ui.dart';
import '../../bootstrap/models/bootstrap_payload.dart';
import '../../leads/data/leads_repository.dart';
import '../../leads/models/lead_models.dart';
import '../data/offers_repository.dart';
import '../models/offer_detail.dart';
import 'offer_document_preview_page.dart';

enum _OfferFlowMode { system, free }

class OfferWorkspaceLaunchRequest {
  const OfferWorkspaceLaunchRequest({
    required this.leadId,
    required this.leadName,
    this.offerId,
  });

  final String leadId;
  final String leadName;
  final String? offerId;
}

class OffersHomePage extends StatefulWidget {
  const OffersHomePage({
    super.key,
    required this.session,
    required this.bootstrap,
    required this.leadsRepository,
    required this.offersRepository,
    required this.onOpenLeads,
    required this.workspaceLaunchNotifier,
  });

  final SessionInfo session;
  final BootstrapPayload bootstrap;
  final LeadsRepository leadsRepository;
  final OffersRepository offersRepository;
  final VoidCallback onOpenLeads;
  final ValueNotifier<OfferWorkspaceLaunchRequest?> workspaceLaunchNotifier;

  @override
  State<OffersHomePage> createState() => _OffersHomePageState();
}

class _OffersHomePageState extends State<OffersHomePage> {
  late List<ManagedOfferSummary> _offers;
  late List<OfferLeadOption> _leadOptions;
  String? _selectedOfferId;
  OfferDetail? _activeOffer;
  bool _isLoadingOffer = false;
  bool _isSavingOffer = false;
  bool _isCreatingPdf = false;
  bool _isOpeningPreview = false;
  bool _isCreateInlineOpen = false;
  String _createLeadSearchQuery = '';
  String? _createFeedback;
  String? _editorFeedback;
  _OfferFlowMode? _flowMode;

  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerEmailController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _customerRegionController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _financingTermController = TextEditingController();
  final TextEditingController _financingInputController = TextEditingController();
  final TextEditingController _buyoutPercentController = TextEditingController();
  final TextEditingController _validUntilController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _customerType = 'PRIVATE';
  String _financingVariant = '';
  String? _selectedPricingKey;

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pl_PL',
    symbol: 'PLN',
    decimalDigits: 0,
  );

  static final NumberFormat _plainAmountFormat = NumberFormat.decimalPattern('pl_PL');

  late final List<TextEditingController> _livePreviewControllers = [
    _discountController,
    _financingTermController,
    _financingInputController,
    _buyoutPercentController,
    _validUntilController,
  ];

  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _offers = List<ManagedOfferSummary>.from(widget.bootstrap.offers);
    _leadOptions = List<OfferLeadOption>.from(widget.bootstrap.leadOptions);
    _selectedOfferId = _offers.isEmpty ? null : _offers.first.id;

    for (final controller in _livePreviewControllers) {
      controller.addListener(_handleLivePreviewChanged);
    }

    widget.workspaceLaunchNotifier.addListener(_handleWorkspaceLaunchRequest);

    if (_selectedOfferId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadOffer(_selectedOfferId!);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleWorkspaceLaunchRequest();
    });
  }

  @override
  void didUpdateWidget(covariant OffersHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.workspaceLaunchNotifier != widget.workspaceLaunchNotifier) {
      oldWidget.workspaceLaunchNotifier.removeListener(_handleWorkspaceLaunchRequest);
      widget.workspaceLaunchNotifier.addListener(_handleWorkspaceLaunchRequest);
    }
  }

  @override
  void dispose() {
    widget.workspaceLaunchNotifier.removeListener(_handleWorkspaceLaunchRequest);

    for (final controller in _livePreviewControllers) {
      controller.removeListener(_handleLivePreviewChanged);
    }

    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _customerRegionController.dispose();
    _discountController.dispose();
    _financingTermController.dispose();
    _financingInputController.dispose();
    _buyoutPercentController.dispose();
    _validUntilController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleLivePreviewChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _handleWorkspaceLaunchRequest() async {
    final request = widget.workspaceLaunchNotifier.value;
    if (request == null || _isSavingOffer) {
      return;
    }

    widget.workspaceLaunchNotifier.value = null;

    if (request.offerId != null && request.offerId!.isNotEmpty) {
      await _openExistingOfferInWorkspace(
        request.offerId!,
        editorMessage: 'Oferta ${request.leadName} została otwarta w głównym workspace Ofert / PDF.',
      );
      return;
    }

    await _createOfferForLead(
      request.leadId,
      editorMessage: 'Szkic oferty dla ${request.leadName} został otwarty w workspace Ofert / PDF.',
    );
  }

  Future<void> _openExistingOfferInWorkspace(String offerId, {String? editorMessage}) async {
    await _loadOffer(offerId);

    if (!mounted) {
      return;
    }

    setState(() {
      _isCreateInlineOpen = false;
      _createFeedback = null;
      _editorFeedback = editorMessage ?? 'Oferta została otwarta w workspace Ofert / PDF.';
    });
  }

  void _handleCustomerTypeChanged(String value) {
    final validVariants = value == 'BUSINESS'
        ? const ['leasing operacyjny', 'wynajem długoterminowy']
        : const ['kredyt', 'leasing konsumencki', 'wynajem'];

    setState(() {
      _customerType = value;
      if (!validVariants.contains(_financingVariant)) {
        _financingVariant = '';
      }
    });
  }

  ManagedOfferSummary? get _selectedOffer {
    if (_selectedOfferId == null) {
      return _offers.isEmpty ? null : _offers.first;
    }

    return _offers.where((offer) => offer.id == _selectedOfferId).cast<ManagedOfferSummary?>().firstWhere((offer) => offer != null, orElse: () => _offers.isEmpty ? null : _offers.first);
  }

  OfferPricingOption? get _selectedPricingOption {
    if (_selectedPricingKey == null || _selectedPricingKey!.isEmpty) {
      return null;
    }

    return widget.bootstrap.pricingOptions.where((option) => option.key == _selectedPricingKey).cast<OfferPricingOption?>().firstWhere((option) => option != null, orElse: () => null);
  }

  List<OfferLeadOption> get _filteredLeadOptions {
    final query = _createLeadSearchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _leadOptions;
    }

    return _leadOptions.where((lead) {
      return [lead.label, lead.modelName, lead.contact, lead.ownerName]
          .whereType<String>()
          .any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  _OfferFlowMode get _currentFlowMode {
    if (_activeOffer?.leadId != null && _activeOffer!.leadId!.isNotEmpty) {
      return _OfferFlowMode.system;
    }

    return _flowMode ?? _OfferFlowMode.free;
  }

  String _buildOfferTitle() {
    final selectedPricing = _selectedPricingOption;
    final customerName = _customerNameController.text.trim();
    final modelLabel = selectedPricing != null
        ? '${selectedPricing.brand} ${selectedPricing.model} ${selectedPricing.version}'.trim()
        : 'Nowa oferta PDF';

    if (customerName.isEmpty) {
      return modelLabel;
    }

    return '$modelLabel • $customerName';
  }

  Map<String, dynamic> _buildEditorPayload() {
    return {
      'title': _buildOfferTitle(),
      'status': _activeOffer?.status ?? 'DRAFT',
      'customerName': _customerNameController.text.trim(),
      'customerEmail': _customerEmailController.text.trim(),
      'customerPhone': _customerPhoneController.text.trim(),
      'customerRegion': _customerRegionController.text.trim(),
      'pricingCatalogKey': _selectedPricingKey ?? '',
      'customerType': _customerType,
      'discountValue': _discountController.text.trim(),
      'financingVariant': _financingVariant.trim(),
      'financingTermMonths': _financingTermController.text.trim(),
      'financingInputValue': _financingInputController.text.trim(),
      'financingBuyoutPercent': _buyoutPercentController.text.trim(),
      'validUntil': _validUntilController.text.trim(),
      'notes': _notesController.text.trim(),
    };
  }

  num? _parseNumber(String value) {
    if (value.trim().isEmpty) {
      return null;
    }

    return num.tryParse(value.replaceAll(',', '.'));
  }

  num? get _buyoutPercent => _parseNumber(_buyoutPercentController.text);
  num? get _downPayment => _parseNumber(_financingInputController.text);
  int? get _termMonths => int.tryParse(_financingTermController.text.trim());
  num? get _discountValue => _parseNumber(_discountController.text);
  bool get _isBusinessCustomer => _customerType == 'BUSINESS';

  num? get _discountValueGross {
    final discount = _discountValue;
    if (discount == null) {
      return null;
    }

    return _isBusinessCustomer ? discount * 1.23 : discount;
  }

  num? get _discountValueNet {
    final discount = _discountValue;
    if (discount == null) {
      return null;
    }

    return _isBusinessCustomer ? discount : discount / 1.23;
  }

  num? get _remainingDiscountBudget {
    final availableDiscountGross = _selectedPricingOption?.marginPoolGross ?? _activeOffer?.calculation?.availableDiscount;
    if (availableDiscountGross == null) {
      return null;
    }

    final availableDisplay = _isBusinessCustomer ? availableDiscountGross / 1.23 : availableDiscountGross;
    final usedDisplay = _discountValue ?? 0;
    final remaining = availableDisplay - usedDisplay;
    return remaining < 0 ? 0 : remaining;
  }

  int? get _maxAllowedBuyoutPercent {
    switch (_termMonths) {
      case 24:
        return 70;
      case 36:
        return 60;
      case 48:
        return 50;
      case 60:
        return 40;
      case 71:
        return 30;
      default:
        return null;
    }
  }

  String? get _buyoutValidationMessage {
    final maxBuyout = _maxAllowedBuyoutPercent;
    final buyout = _buyoutPercent;
    final term = _termMonths;
    if (maxBuyout == null || buyout == null || term == null) {
      return null;
    }
    if (buyout <= maxBuyout) {
      return null;
    }

    return 'Maksymalny wykup dla $term mies. to $maxBuyout%.';
  }

  num? get _previewGrossPrice {
    final selectedPricingPrice = _selectedPricingOption?.listPriceGross;
    final calculationPrice = _activeOffer?.calculation?.finalPriceGross;
    final currentPrice = _activeOffer?.totalGross;
    final basePrice = selectedPricingPrice ?? calculationPrice ?? currentPrice;
    if (basePrice == null) {
      return null;
    }

    final discount = _discountValueGross ?? 0;
    final computed = basePrice - discount;
    return computed < 0 ? 0 : computed;
  }

  num? get _previewNetPrice {
    final gross = _previewGrossPrice;
    if (gross == null) {
      return _activeOffer?.calculation?.finalPriceNet ?? _activeOffer?.totalNet;
    }

    return gross / 1.23;
  }

  num? get _estimatedInstallment {
    final term = _termMonths;
    final calculationBase = _isBusinessCustomer ? _previewNetPrice : _previewGrossPrice;
    if (calculationBase == null || term == null || term <= 0) {
      return null;
    }

    final downPayment = _downPayment ?? 0;
    final buyoutPercent = _buyoutPercent ?? 0;
    final buyoutValue = calculationBase * (buyoutPercent / 100);
    final totalLeaseCost = calculationBase * 1.2;
    final installment = (totalLeaseCost - downPayment - buyoutValue) / term;
    if (installment <= 0) {
      return 0;
    }

    return num.parse(installment.toStringAsFixed(2));
  }

  void _populateForm(OfferDetail detail) {
    _customerNameController.text = detail.customerName;
    _customerEmailController.text = detail.customerEmail ?? '';
    _customerPhoneController.text = detail.customerPhone ?? '';
    _customerRegionController.text = '';
    _discountController.text = detail.calculation?.appliedDiscount.toString() ?? '';
    _financingTermController.text = detail.financingTermMonths?.toString() ?? '';
    _financingInputController.text = detail.financingInputValue?.toString() ?? '';
    _buyoutPercentController.text = detail.financingBuyoutPercent?.toString() ?? '';
    _validUntilController.text = _toDateInput(detail.validUntil);
    _notesController.text = detail.notes ?? '';
    _customerType = detail.customerType.isEmpty ? 'PRIVATE' : detail.customerType;
    _financingVariant = detail.financingVariant ?? '';
    final pricingCatalogKey = detail.pricingCatalogKey?.trim();
    _selectedPricingKey = pricingCatalogKey == null || pricingCatalogKey.isEmpty ? null : pricingCatalogKey;
  }

  Future<void> _loadOffer(String offerId) async {
    setState(() {
      _selectedOfferId = offerId;
      _isLoadingOffer = true;
      _editorFeedback = null;
    });

    try {
      final detail = await widget.offersRepository.fetchOfferDetail(offerId);
      if (!mounted) {
        return;
      }

      setState(() {
        _activeOffer = detail;
        _populateForm(detail);
        _flowMode = detail.leadId != null && detail.leadId!.isNotEmpty ? _OfferFlowMode.system : _OfferFlowMode.free;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _editorFeedback = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOffer = false;
        });
      }
    }
  }

  void _replaceOffer(OfferDetail detail) {
    final summary = _mapDetailToSummary(detail);

    setState(() {
      _offers = [
        summary,
        ..._offers.where((offer) => offer.id != detail.id),
      ];
      _selectedOfferId = detail.id;
      _activeOffer = detail;
    });
  }

  OfferLeadOption _mapLeadOption(ManagedLeadDetail lead) {
    final contact = [lead.email, lead.phone]
        .whereType<String>()
        .firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');

    return OfferLeadOption(
      id: lead.id,
      label: lead.fullName,
      modelName: lead.interestedModel,
      contact: contact.isEmpty ? null : contact,
      ownerName: lead.salespersonName,
    );
  }

  Future<void> _createFreeOffer() async {
    setState(() {
      _isSavingOffer = true;
      _createFeedback = 'Tworzymy nowy szkic oferty w aplikacji...';
      _editorFeedback = null;
    });

    try {
      final created = await widget.offersRepository.createOffer({
        'title': '',
        'customerType': 'PRIVATE',
      });

      if (!mounted) {
        return;
      }

      _replaceOffer(created);
      _populateForm(created);

      setState(() {
        _isCreateInlineOpen = false;
        _createLeadSearchQuery = '';
        _createFeedback = null;
        _flowMode = _OfferFlowMode.free;
        _editorFeedback = 'Nowy szkic oferty został otwarty bez przechodzenia do modułu leadów.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _createFeedback = 'Nie udało się utworzyć szkicu oferty. $error';
        _editorFeedback = _createFeedback;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingOffer = false;
        });
      }
    }
  }

  Future<void> _createOfferForLead(String leadId, {String? editorMessage}) async {
    setState(() {
      _isSavingOffer = true;
      _createFeedback = 'Tworzymy szkic oferty dla wybranego klienta...';
    });

    try {
      final created = await widget.offersRepository.createOffer({
        'leadId': leadId,
        'title': '',
        'customerType': 'PRIVATE',
      });

      if (!mounted) {
        return;
      }

      _replaceOffer(created);
      _populateForm(created);
      setState(() {
        _flowMode = _OfferFlowMode.system;
        _isCreateInlineOpen = false;
        _editorFeedback = editorMessage ?? 'Szkic oferty dla wybranego klienta został utworzony w tym samym workspace.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _createFeedback = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingOffer = false;
        });
      }
    }
  }

  Future<OfferDetail?> _ensureLeadForOffer(OfferDetail offer) async {
    final currentLeadId = offer.leadId?.trim() ?? '';
    if (currentLeadId.isNotEmpty) {
      return offer;
    }

    final customerName = _customerNameController.text.trim();
    final customerEmail = _customerEmailController.text.trim();
    final customerPhone = _customerPhoneController.text.trim();
    final customerRegion = _customerRegionController.text.trim();

    if (customerName.isEmpty) {
      if (mounted) {
        setState(() {
          _editorFeedback = 'Aby zapisać klienta w kanbanie, podaj imię i nazwisko.';
        });
      }
      return null;
    }

    if (customerEmail.isEmpty && customerPhone.isEmpty) {
      if (mounted) {
        setState(() {
          _editorFeedback = 'Aby zapisać klienta w kanbanie, podaj email lub telefon.';
        });
      }
      return null;
    }

    final linkedOffer = await widget.offersRepository.createLeadForOffer(
      offerId: offer.id,
      fullName: customerName,
      email: customerEmail,
      phone: customerPhone,
      region: customerRegion,
    );

    if (!mounted) {
      return linkedOffer;
    }

    _replaceOffer(linkedOffer);
    _populateForm(linkedOffer);
    setState(() {
      _flowMode = _OfferFlowMode.system;
      _editorFeedback = 'Utworzono leada w kanbanie i przypięto ofertę do pipeline.';
    });

    return linkedOffer;
  }

  Future<OfferDetail?> _saveActiveOfferForPreview() async {
    final offer = _activeOffer;
    if (offer == null || _isSavingOffer) {
      return offer;
    }

    final buyoutValidationMessage = _buyoutValidationMessage;
    if (buyoutValidationMessage != null) {
      setState(() {
        _editorFeedback = buyoutValidationMessage;
      });
      return null;
    }

    setState(() {
      _isSavingOffer = true;
      _editorFeedback = 'Zapisujemy ofertę przed otwarciem podglądu...';
    });

    try {
      final saved = await widget.offersRepository.updateOffer(
        offerId: offer.id,
        payload: _buildEditorPayload(),
      );

      if (!mounted) {
        return saved;
      }

      _replaceOffer(saved);
      _populateForm(saved);
      return _ensureLeadForOffer(saved);
    } catch (error) {
      if (mounted) {
        setState(() {
          _editorFeedback = 'Nie udało się zapisać oferty przed podglądem. $error';
        });
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isSavingOffer = false;
        });
      }
    }
  }

  Future<void> _openPreview(ManagedOfferSummary offer, {String? versionId}) async {
    if (_isOpeningPreview) {
      return;
    }

    final savedOffer = versionId == null ? await _saveActiveOfferForPreview() : _activeOffer;
    if (versionId == null && savedOffer == null) {
      return;
    }

    setState(() {
      _isOpeningPreview = true;
      _editorFeedback = versionId == null
          ? 'Otwieramy podgląd zapisanej oferty...'
          : 'Otwieramy podgląd dokumentu PDF...';
    });

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OfferDocumentPreviewPage(
          offerId: savedOffer?.id ?? offer.id,
          versionId: versionId,
          repository: widget.offersRepository,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _isOpeningPreview = false;
      });
    }
  }

  Future<void> _createPdfForSelected() async {
    final offer = _activeOffer;
    if (offer == null || _isCreatingPdf) {
      return;
    }

    final buyoutValidationMessage = _buyoutValidationMessage;
    if (buyoutValidationMessage != null) {
      setState(() {
        _editorFeedback = buyoutValidationMessage;
      });
      return;
    }

    setState(() {
      _isCreatingPdf = true;
      _editorFeedback = 'Zapisujemy ofertę i przygotowujemy dokument PDF...';
    });

    try {
      final saved = await widget.offersRepository.updateOffer(
        offerId: offer.id,
        payload: _buildEditorPayload(),
      );

      if (!mounted) {
        return;
      }

      _replaceOffer(saved);
      _populateForm(saved);

      final offerWithLead = await _ensureLeadForOffer(saved);

      if (offerWithLead == null) {
        return;
      }

      final version = await widget.offersRepository.createPdfVersion(offerId: offerWithLead.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _editorFeedback = 'Przygotowano wersję PDF ${version.versionNumber} dla ${offerWithLead.number}. Otwieram podgląd dokumentu.';
      });

      await _openPreview(_mapDetailToSummary(offerWithLead), versionId: version.id);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _editorFeedback = 'Nie udało się przygotować PDF. $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSummary = _selectedOffer;
    final activeOffer = _activeOffer;
    final isFreeMode = _currentFlowMode == _OfferFlowMode.free;

    return Material(
      type: MaterialType.transparency,
      child: VeloPrimeShell(
        decorateBackground: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1180;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InlineOffersWorkspaceHeader(
                        offers: _offers,
                        selectedOfferId: activeSummary?.id,
                        session: widget.session,
                        isSavingOffer: _isSavingOffer,
                        dateFormat: _dateFormat,
                        currentFlowMode: _currentFlowMode,
                        onSelectOffer: (offerId) => _loadOffer(offerId),
                        onCreateForSystemCustomer: () {
                          setState(() {
                            _isCreateInlineOpen = true;
                            _createFeedback = null;
                            _createLeadSearchQuery = '';
                            _flowMode = _OfferFlowMode.system;
                          });
                        },
                        onCreateFreeOffer: _createFreeOffer,
                      ),
                      if (_isCreateInlineOpen) ...[
                        const SizedBox(height: 18),
                        _InlineLeadPicker(
                          query: _createLeadSearchQuery,
                          leadOptions: _filteredLeadOptions,
                          feedback: _createFeedback,
                          isBusy: _isSavingOffer,
                          onQueryChanged: (value) {
                            setState(() {
                              _createLeadSearchQuery = value;
                            });
                          },
                          onClose: () {
                            setState(() {
                              _isCreateInlineOpen = false;
                              _createLeadSearchQuery = '';
                              _createFeedback = null;
                            });
                          },
                          onSelectLead: _createOfferForLead,
                        ),
                      ],
                      const SizedBox(height: 18),
                      if (_isLoadingOffer)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: VeloPrimeWorkspaceState(
                            tint: VeloPrimePalette.bronzeDeep,
                            eyebrow: 'Oferty',
                            title: 'Ladujemy aktywna oferte',
                            message: 'Przygotowujemy kalkulacje, finansowanie i sekcje dokumentu.',
                            isLoading: true,
                          ),
                        )
                      else if (activeOffer == null)
                        _OfferEmptyState(
                          onCreateFreeOffer: _createFreeOffer,
                          onCreateForSystemCustomer: () {
                            setState(() {
                              _isCreateInlineOpen = true;
                              _flowMode = _OfferFlowMode.system;
                            });
                          },
                        )
                      else if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _OfferEditorWorkspace(
                                offer: activeOffer,
                                isFreeMode: isFreeMode,
                                customerNameController: _customerNameController,
                                customerEmailController: _customerEmailController,
                                customerPhoneController: _customerPhoneController,
                                customerRegionController: _customerRegionController,
                                discountController: _discountController,
                                financingTermController: _financingTermController,
                                financingInputController: _financingInputController,
                                buyoutPercentController: _buyoutPercentController,
                                validUntilController: _validUntilController,
                                notesController: _notesController,
                                customerType: _customerType,
                                financingVariant: _financingVariant,
                                pricingOptions: widget.bootstrap.pricingOptions,
                                selectedPricingKey: _selectedPricingKey,
                                selectedPricingOption: _selectedPricingOption,
                                feedback: _editorFeedback,
                                isSaving: _isSavingOffer,
                                isOpeningPreview: _isOpeningPreview,
                                isCreatingPdf: _isCreatingPdf,
                                currencyFormat: _currencyFormat,
                                plainAmountFormat: _plainAmountFormat,
                                remainingDiscountBudget: _remainingDiscountBudget,
                                onCustomerTypeChanged: _handleCustomerTypeChanged,
                                onFinancingVariantChanged: (value) => setState(() => _financingVariant = value),
                                onPricingChanged: (value) => setState(() => _selectedPricingKey = value),
                                onOpenPreview: activeSummary == null || _isSavingOffer ? null : () => _openPreview(activeSummary!),
                                onCreatePdf: _createPdfForSelected,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 4,
                              child: _OfferResultsPanel(
                                offer: activeOffer,
                                customerType: _customerType,
                                financingVariant: _financingVariant,
                                selectedPricingOption: _selectedPricingOption,
                                previewGrossPrice: _previewGrossPrice,
                                previewNetPrice: _previewNetPrice,
                                estimatedInstallment: _estimatedInstallment,
                                termMonths: _termMonths,
                                downPayment: _downPayment,
                                buyoutPercent: _buyoutPercent,
                                discountValue: _discountValue,
                                discountValueGross: _discountValueGross,
                                discountValueNet: _discountValueNet,
                                validUntil: _validUntilController.text.trim().isEmpty ? activeOffer.validUntil : _validUntilController.text.trim(),
                                dateFormat: _dateFormat,
                                currencyFormat: _currencyFormat,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _OfferEditorWorkspace(
                              offer: activeOffer,
                              isFreeMode: isFreeMode,
                              customerNameController: _customerNameController,
                              customerEmailController: _customerEmailController,
                              customerPhoneController: _customerPhoneController,
                              customerRegionController: _customerRegionController,
                              discountController: _discountController,
                              financingTermController: _financingTermController,
                              financingInputController: _financingInputController,
                              buyoutPercentController: _buyoutPercentController,
                              validUntilController: _validUntilController,
                              notesController: _notesController,
                              customerType: _customerType,
                              financingVariant: _financingVariant,
                              pricingOptions: widget.bootstrap.pricingOptions,
                              selectedPricingKey: _selectedPricingKey,
                              selectedPricingOption: _selectedPricingOption,
                              feedback: _editorFeedback,
                              isSaving: _isSavingOffer,
                              isOpeningPreview: _isOpeningPreview,
                              isCreatingPdf: _isCreatingPdf,
                              currencyFormat: _currencyFormat,
                              plainAmountFormat: _plainAmountFormat,
                              remainingDiscountBudget: _remainingDiscountBudget,
                              onCustomerTypeChanged: _handleCustomerTypeChanged,
                              onFinancingVariantChanged: (value) => setState(() => _financingVariant = value),
                              onPricingChanged: (value) => setState(() => _selectedPricingKey = value),
                              onOpenPreview: activeSummary == null || _isSavingOffer ? null : () => _openPreview(activeSummary!),
                              onCreatePdf: _createPdfForSelected,
                            ),
                            const SizedBox(height: 18),
                            _OfferResultsPanel(
                              offer: activeOffer,
                              customerType: _customerType,
                              financingVariant: _financingVariant,
                              selectedPricingOption: _selectedPricingOption,
                              previewGrossPrice: _previewGrossPrice,
                              previewNetPrice: _previewNetPrice,
                              estimatedInstallment: _estimatedInstallment,
                              termMonths: _termMonths,
                              downPayment: _downPayment,
                              buyoutPercent: _buyoutPercent,
                              discountValue: _discountValue,
                              discountValueGross: _discountValueGross,
                              discountValueNet: _discountValueNet,
                              validUntil: _validUntilController.text.trim().isEmpty ? activeOffer.validUntil : _validUntilController.text.trim(),
                              dateFormat: _dateFormat,
                              currencyFormat: _currencyFormat,
                            ),
                          ],
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

String _toDateInput(String? value) {
  if (value == null || value.isEmpty) {
    return '';
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  final month = parsed.month.toString().padLeft(2, '0');
  final day = parsed.day.toString().padLeft(2, '0');
  return '${parsed.year}-$month-$day';
}

class _InlineOffersWorkspaceHeader extends StatelessWidget {
  const _InlineOffersWorkspaceHeader({
    required this.offers,
    required this.selectedOfferId,
    required this.session,
    required this.isSavingOffer,
    required this.dateFormat,
    required this.currentFlowMode,
    required this.onSelectOffer,
    required this.onCreateForSystemCustomer,
    required this.onCreateFreeOffer,
  });

  final List<ManagedOfferSummary> offers;
  final String? selectedOfferId;
  final SessionInfo session;
  final bool isSavingOffer;
  final DateFormat dateFormat;
  final _OfferFlowMode currentFlowMode;
  final ValueChanged<String> onSelectOffer;
  final VoidCallback onCreateForSystemCustomer;
  final Future<void> Function() onCreateFreeOffer;

  @override
  Widget build(BuildContext context) {
    final selectedOffer = offers.where((offer) => offer.id == selectedOfferId).cast<ManagedOfferSummary?>().firstWhere((offer) => offer != null, orElse: () => offers.isEmpty ? null : offers.first);

    return VeloPrimeWorkspacePanel(
      tint: VeloPrimePalette.bronzeDeep,
      radius: 30,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const VeloPrimeSectionEyebrow(label: 'Oferty PDF'),
                    const SizedBox(height: 6),
                    const Text(
                      'Generator ofert',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Zalogowano jako ${session.fullName} (${session.role}). Każda nowa oferta startuje z realnego leada w pipeline, także gdy zakładasz klienta bezpośrednio z tego modułu.',
                      style: const TextStyle(color: VeloPrimePalette.muted, height: 1.55),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: isSavingOffer ? null : onCreateForSystemCustomer,
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: const Text('Oferta dla klienta w systemie'),
                      ),
                      FilledButton.icon(
                        onPressed: isSavingOffer ? null : onCreateFreeOffer,
                        icon: const Icon(Icons.add),
                        label: Text(isSavingOffer ? 'Tworzenie...' : 'Nowy klient i oferta'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (selectedOffer != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: VeloPrimePalette.bronzeDeep.withValues(alpha: 0.12))),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (offers.length > 1)
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 320, maxWidth: 440),
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedOffer.id,
                          decoration: veloPrimeInputDecoration('Aktywna oferta'),
                        items: offers
                            .map(
                              (offer) => DropdownMenuItem<String>(
                                value: offer.id,
                                child: Text('${offer.number} • ${offer.customerName}'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            onSelectOffer(value);
                          }
                        },
                      ),
                    ),
                  _HeaderChip(label: selectedOffer.number),
                  _HeaderChip(label: 'Klient: ${selectedOffer.customerName}'),
                  _HeaderChip(label: currentFlowMode == _OfferFlowMode.system ? 'Workflow z leada' : 'Starszy szkic bez leada'),
                  _HeaderChip(label: 'Ważna do: ${_formatNullableDate(selectedOffer.validUntil, dateFormat) ?? 'Bez terminu'}'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineLeadPicker extends StatelessWidget {
  const _InlineLeadPicker({
    required this.query,
    required this.leadOptions,
    required this.feedback,
    required this.isBusy,
    required this.onQueryChanged,
    required this.onClose,
    required this.onSelectLead,
  });

  final String query;
  final List<OfferLeadOption> leadOptions;
  final String? feedback;
  final bool isBusy;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClose;
  final ValueChanged<String> onSelectLead;

  @override
  Widget build(BuildContext context) {
    return VeloPrimeWorkspacePanel(
      tint: VeloPrimePalette.sea,
      radius: 30,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VeloPrimeSectionEyebrow(label: 'Workflow z leada'),
                    SizedBox(height: 6),
                    Text('Wybierz klienta z systemu', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink)),
                    SizedBox(height: 8),
                    Text(
                      'To jest podstawowa ścieżka pracy zgodna z webem i pipeline handlowym. Najpierw wybierasz leada, dopiero potem konfigurujesz ofertę PDF.',
                      style: TextStyle(color: VeloPrimePalette.muted, height: 1.55),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: isBusy ? null : onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: onQueryChanged,
            decoration: veloPrimeInputDecoration('Wyszukaj leada', hintText: 'Klient, model albo kontakt').copyWith(prefixIcon: const Icon(Icons.search)),
          ),
          if (feedback != null) ...[
            const SizedBox(height: 12),
            Text(feedback!, style: const TextStyle(color: Color(0xFFA64B45))),
          ],
          const SizedBox(height: 16),
          if (leadOptions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text('Brak leadów pasujących do wyszukiwania.'),
            )
          else
            ...leadOptions.map(
              (lead) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: isBusy ? null : () => onSelectLead(lead.id),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: VeloPrimePalette.sea.withValues(alpha: 0.16)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lead.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text('${lead.modelName ?? 'Model do uzupełnienia'}${lead.contact != null ? ' • ${lead.contact}' : ''}', style: const TextStyle(fontSize: 12, color: VeloPrimePalette.muted)),
                              ],
                            ),
                          ),
                          Text(isBusy ? 'Tworzę...' : 'Wybierz', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: VeloPrimePalette.bronzeDeep)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OfferEmptyState extends StatelessWidget {
  const _OfferEmptyState({required this.onCreateFreeOffer, required this.onCreateForSystemCustomer});

  final Future<void> Function() onCreateFreeOffer;
  final VoidCallback onCreateForSystemCustomer;

  @override
  Widget build(BuildContext context) {
    return VeloPrimeWorkspacePanel(
      tint: VeloPrimePalette.bronzeDeep,
      radius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 54),
      child: Column(
        children: [
          const Text('Każda nowa oferta powinna startować z leada. Możesz wybrać klienta z systemu albo utworzyć nowego klienta bez wychodzenia z modułu Ofert / PDF.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, height: 1.6, color: VeloPrimePalette.muted)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onCreateForSystemCustomer,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Klient z systemu'),
              ),
              FilledButton.icon(
                onPressed: onCreateFreeOffer,
                icon: const Icon(Icons.add),
                label: const Text('Nowy klient i oferta'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfferEditorWorkspace extends StatelessWidget {
  const _OfferEditorWorkspace({
    required this.offer,
    required this.isFreeMode,
    required this.customerNameController,
    required this.customerEmailController,
    required this.customerPhoneController,
    required this.customerRegionController,
    required this.discountController,
    required this.financingTermController,
    required this.financingInputController,
    required this.buyoutPercentController,
    required this.validUntilController,
    required this.notesController,
    required this.customerType,
    required this.financingVariant,
    required this.pricingOptions,
    required this.selectedPricingKey,
    required this.selectedPricingOption,
    required this.feedback,
    required this.isSaving,
    required this.isOpeningPreview,
    required this.isCreatingPdf,
    required this.currencyFormat,
    required this.plainAmountFormat,
    required this.remainingDiscountBudget,
    required this.onCustomerTypeChanged,
    required this.onFinancingVariantChanged,
    required this.onPricingChanged,
    required this.onOpenPreview,
    required this.onCreatePdf,
  });

  final OfferDetail offer;
  final bool isFreeMode;
  final TextEditingController customerNameController;
  final TextEditingController customerEmailController;
  final TextEditingController customerPhoneController;
  final TextEditingController customerRegionController;
  final TextEditingController discountController;
  final TextEditingController financingTermController;
  final TextEditingController financingInputController;
  final TextEditingController buyoutPercentController;
  final TextEditingController validUntilController;
  final TextEditingController notesController;
  final String customerType;
  final String financingVariant;
  final List<OfferPricingOption> pricingOptions;
  final String? selectedPricingKey;
  final OfferPricingOption? selectedPricingOption;
  final String? feedback;
  final bool isSaving;
  final bool isOpeningPreview;
  final bool isCreatingPdf;
  final NumberFormat currencyFormat;
  final NumberFormat plainAmountFormat;
  final num? remainingDiscountBudget;
  final ValueChanged<String> onCustomerTypeChanged;
  final ValueChanged<String> onFinancingVariantChanged;
  final ValueChanged<String?> onPricingChanged;
  final VoidCallback? onOpenPreview;
  final VoidCallback? onCreatePdf;

  List<String> get _financingVariants {
    if (customerType == 'BUSINESS') {
      return const ['leasing operacyjny', 'wynajem długoterminowy'];
    }
    return const ['kredyt', 'leasing konsumencki', 'wynajem'];
  }

  int? get _selectedTermMonths => int.tryParse(financingTermController.text.trim());

  num? get _discountBudget => remainingDiscountBudget;

  int? get _maxAllowedBuyoutPercent {
    switch (_selectedTermMonths) {
      case 24:
        return 70;
      case 36:
        return 60;
      case 48:
        return 50;
      case 60:
        return 40;
      case 71:
        return 30;
      default:
        return null;
    }
  }

  String? get _buyoutValidationMessage {
    final maxBuyout = _maxAllowedBuyoutPercent;
    final buyout = num.tryParse(buyoutPercentController.text.replaceAll(',', '.'));
    final term = _selectedTermMonths;
    if (maxBuyout == null || buyout == null || term == null) {
      return null;
    }
    if (buyout <= maxBuyout) {
      return null;
    }

    return 'Maks. wykup dla $term mies. to $maxBuyout%';
  }

  Future<void> _pickValidUntil(BuildContext context) async {
    final parsedControllerDate = DateTime.tryParse(validUntilController.text.trim());
    final parsedOfferDate = DateTime.tryParse(offer.validUntil ?? '');
    final initialDate = parsedControllerDate ?? parsedOfferDate ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: 'Wybierz termin ważności',
      cancelText: 'Anuluj',
      confirmText: 'Wybierz',
    );

    if (picked == null) {
      return;
    }

    validUntilController.text = _toDateInput(picked.toIso8601String());
  }

  @override
  Widget build(BuildContext context) {
    final backgroundVisual = VeloPrimeBackgroundVisualScope.of(context);
    final previewTint = Color.alphaBlend(backgroundVisual.primaryGlow.withValues(alpha: 0.52), VeloPrimePalette.sea);
    final pdfTint = Color.alphaBlend(backgroundVisual.secondaryGlow.withValues(alpha: 0.5), VeloPrimePalette.bronzeDeep);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isFreeMode)
          _EditorSection(
            title: 'Sekcja 1 · Klient',
            subtitle: 'Tryb pomocniczy poza pipeline. Tylko wtedy budujesz klienta ręcznie bez startu z leada.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionSubheader(
                  title: 'DANE KONTAKTOWE',
                  subtitle: 'Ten blok jest wyjątkiem od standardowego workflow. Używaj go tylko wtedy, gdy oferta nie startuje z leada w CRM.',
                ),
                const SizedBox(height: 8),
                _EditorFormBand(
                  title: 'Profil klienta',
                  subtitle: 'Podstawowe dane, od których zaczyna się wycena i dokument PDF.',
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      _FieldShell(width: 212, child: TextField(controller: customerNameController, decoration: veloPrimeInputDecoration('Imię i nazwisko'))),
                      _FieldShell(width: 170, child: TextField(controller: customerRegionController, decoration: veloPrimeInputDecoration('Miejscowość'))),
                      _FieldShell(width: 212, child: TextField(controller: customerEmailController, decoration: veloPrimeInputDecoration('Email'))),
                      _FieldShell(width: 170, child: TextField(controller: customerPhoneController, decoration: veloPrimeInputDecoration('Telefon'))),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          _EditorSection(
            title: 'Sekcja 1 · Workflow z leada',
            subtitle: 'To jest podstawowa ścieżka pracy. Dane klienta są już powiązane z leadem, więc przechodzisz od razu do konfiguracji oferty.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionSubheader(
                  title: 'POWIĄZANIE Z CRM',
                  subtitle: 'Ta oferta korzysta z istniejącego leada i zachowuje ten sam kanoniczny proces co webowy generator ofert.',
                ),
                const SizedBox(height: 8),
                _EditorFormBand(
                  title: 'Kontekst klienta',
                  subtitle: 'Ten blok tylko potwierdza źródło i powiązanie oferty z istniejącym rekordem CRM.',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _EditorInfoTile(label: 'Klient', value: offer.customerName),
                      _EditorInfoTile(label: 'Model', value: (offer.modelName ?? '').isNotEmpty ? offer.modelName! : 'Do uzupełnienia'),
                      _EditorInfoTile(label: 'Lead', value: offer.leadId ?? 'Lead systemowy'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        _EditorSection(
          title: 'Sekcja 2 · Konfiguracja oferty',
          subtitle: 'Wybór modelu i warunków. Model samochodu, typ klienta, kolor, rabat i finansowanie w jednym miejscu.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionSubheader(
                title: 'KONFIGURACJA BAZOWA',
                subtitle: 'Najpierw ustaw typ klienta, scenariusz finansowania i konkretny model, dopiero później warunki handlowe.',
              ),
              const SizedBox(height: 8),
              _EditorFormBand(
                title: 'Profil oferty',
                subtitle: 'To jest rdzeń konfiguracji. Te trzy pola ustalają scenariusz całej oferty.',
                child: Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _FieldShell(
                      width: 220,
                      child: _StyledDropdownField<String>(
                        initialValue: customerType,
                        items: const [
                          DropdownMenuItem(value: 'PRIVATE', child: Text('Klient prywatny')),
                          DropdownMenuItem(value: 'BUSINESS', child: Text('Firma')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            onCustomerTypeChanged(value);
                          }
                        },
                        decoration: veloPrimeInputDecoration('Typ klienta'),
                      ),
                    ),
                    _FieldShell(
                      width: 280,
                      child: _StyledDropdownField<String>(
                        initialValue: _financingVariants.contains(financingVariant) ? financingVariant : null,
                        items: _financingVariants.map((variant) => DropdownMenuItem<String>(value: variant, child: Text(variant))).toList(),
                        onChanged: (value) => onFinancingVariantChanged(value ?? ''),
                        decoration: veloPrimeInputDecoration('Wariant finansowania'),
                      ),
                    ),
                    _FieldShell(
                      width: 360,
                      child: _StyledDropdownField<String>(
                        initialValue: selectedPricingKey,
                        selectedItemBuilder: (context) => pricingOptions
                            .map(
                              (option) => Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  option.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        items: pricingOptions
                            .map(
                              (option) => DropdownMenuItem<String>(
                                value: option.key,
                                child: Text(
                                  option.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: onPricingChanged,
                        decoration: veloPrimeInputDecoration('Wybierz model samochodu'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _EditorFormBand(
                title: 'Warunki cenowe',
                subtitle: 'Tutaj ustawiasz to, co klient zobaczy na końcu: rabat i ważność oferty.',
                accent: const Color(0xFFFFFBF2),
                headerTrailing: _discountBudget == null
                    ? null
                    : Text(
                        'Dyspozycja: ${plainAmountFormat.format(_discountBudget)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF8A7441)),
                      ),
                child: Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _FieldShell(width: 180, child: TextField(controller: discountController, decoration: veloPrimeInputDecoration('Rabat klienta'))),
                    _FieldShell(
                      width: 220,
                      child: TextField(
                        controller: validUntilController,
                        readOnly: true,
                        onTap: () => _pickValidUntil(context),
                        decoration: veloPrimeInputDecoration('Ważna do').copyWith(
                          hintText: 'Wybierz z kalendarza',
                          suffixIcon: const Icon(Icons.calendar_month_outlined, color: Color(0xFFB2862F)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _EditorFormBand(
                title: 'Warunki finansowania',
                subtitle: 'Ten blok steruje ratą i scenariuszem leasingu lub kredytu.',
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final fieldWidth = (constraints.maxWidth - 28) / 3;
                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _FieldShell(
                          width: fieldWidth,
                          child: _StyledDropdownField<int>(
                            initialValue: _selectedTermMonths,
                            items: const [24, 36, 48, 60, 71]
                                .map((months) => DropdownMenuItem<int>(value: months, child: Text('$months miesięcy')))
                                .toList(),
                            onChanged: (value) {
                              financingTermController.text = value?.toString() ?? '';
                            },
                            decoration: veloPrimeInputDecoration('Okres'),
                          ),
                        ),
                        _FieldShell(
                          width: fieldWidth,
                          child: TextField(controller: financingInputController, decoration: veloPrimeInputDecoration('Wpłata własna')),
                        ),
                        _FieldShell(
                          width: fieldWidth,
                          child: TextField(
                            controller: buyoutPercentController,
                            decoration: veloPrimeInputDecoration('Wykup (%)').copyWith(
                              helperText: _buyoutValidationMessage == null && _maxAllowedBuyoutPercent != null ? 'Maks. $_maxAllowedBuyoutPercent%' : null,
                              errorText: _buyoutValidationMessage,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              _EditorFormBand(
                title: 'Notatki i uwagi',
                subtitle: 'Miejsce na kontekst operacyjny, który nie wchodzi w strukturę wyceny.',
                child: TextField(
                  controller: notesController,
                  maxLines: 5,
                  decoration: veloPrimeInputDecoration('Notatki'),
                ),
              ),
              if (feedback != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFFFF6E8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x40E2C46F)),
                  ),
                  child: Text(feedback!, style: const TextStyle(color: Color(0xFF555555), height: 1.5)),
                ),
              ],
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isStacked = constraints.maxWidth < 760;
                  final previewButton = OutlinedButton.icon(
                    onPressed: isOpeningPreview ? null : onOpenPreview,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: previewTint,
                      side: BorderSide(color: previewTint.withValues(alpha: 0.34)),
                      backgroundColor: Colors.white.withValues(alpha: 0.7),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    icon: isOpeningPreview
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.1,
                              valueColor: AlwaysStoppedAnimation<Color>(previewTint),
                            ),
                          )
                        : const Icon(Icons.search_rounded),
                    label: Text(isOpeningPreview ? 'Otwieranie podglądu...' : 'Podgląd dokumentu'),
                  );
                  final pdfButton = FilledButton.icon(
                    onPressed: isCreatingPdf ? null : onCreatePdf,
                    style: FilledButton.styleFrom(
                      backgroundColor: pdfTint,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    icon: isCreatingPdf
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.1, color: Colors.white),
                          )
                        : const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(isCreatingPdf ? 'Przygotowuję PDF...' : 'Wygeneruj ofertę PDF'),
                  );

                  if (isStacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        previewButton,
                        const SizedBox(height: 10),
                        pdfButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: previewButton),
                      const SizedBox(width: 12),
                      Expanded(child: pdfButton),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OfferResultsPanel extends StatelessWidget {
  const _OfferResultsPanel({
    required this.offer,
    required this.customerType,
    required this.financingVariant,
    required this.selectedPricingOption,
    required this.previewGrossPrice,
    required this.previewNetPrice,
    required this.estimatedInstallment,
    required this.termMonths,
    required this.downPayment,
    required this.buyoutPercent,
    required this.discountValue,
    required this.discountValueGross,
    required this.discountValueNet,
    required this.validUntil,
    required this.dateFormat,
    required this.currencyFormat,
  });

  final OfferDetail offer;
  final String customerType;
  final String financingVariant;
  final OfferPricingOption? selectedPricingOption;
  final num? previewGrossPrice;
  final num? previewNetPrice;
  final num? estimatedInstallment;
  final int? termMonths;
  final num? downPayment;
  final num? buyoutPercent;
  final num? discountValue;
  final num? discountValueGross;
  final num? discountValueNet;
  final String? validUntil;
  final DateFormat dateFormat;
  final NumberFormat currencyFormat;

  bool get _isBusinessCustomer => customerType == 'BUSINESS';

  num? get _catalogGrossPrice => selectedPricingOption?.listPriceGross ?? offer.calculation?.listPriceGross ?? offer.totalGross;

  num? get _catalogNetPrice {
    final catalogGross = _catalogGrossPrice;
    if (catalogGross == null) {
      return offer.totalNet ?? offer.calculation?.finalPriceNet;
    }

    return catalogGross / 1.23;
  }

  num? get _finalPrimaryPrice => _isBusinessCustomer ? previewNetPrice : previewGrossPrice;

  num? get _finalSecondaryPrice => _isBusinessCustomer ? previewGrossPrice : previewNetPrice;

  num? get _catalogPrimaryPrice => _isBusinessCustomer ? _catalogNetPrice : _catalogGrossPrice;

  num? get _catalogSecondaryPrice => _isBusinessCustomer ? _catalogGrossPrice : _catalogNetPrice;

  num? get _discountPrimaryValue => _isBusinessCustomer ? discountValueNet : discountValueGross;

  String get _primaryPriceLabel => _isBusinessCustomer ? 'Cena katalogowa netto' : 'Cena katalogowa brutto';

  String get _secondaryPriceLabel => _isBusinessCustomer ? 'Brutto' : 'Netto';

  @override
  Widget build(BuildContext context) {
    final hasDiscount = (discountValue ?? 0) > 0;
    final backgroundVisual = VeloPrimeBackgroundVisualScope.of(context);
    final summaryTop = Color.alphaBlend(
      backgroundVisual.primaryGlow.withValues(alpha: 0.82),
      const Color(0xFF263B61),
    );
    final summaryBottom = Color.alphaBlend(
      backgroundVisual.secondaryGlow.withValues(alpha: 0.74),
      const Color(0xFF35527E),
    );
    final summaryBorder = Color.alphaBlend(
      backgroundVisual.secondaryGlow.withValues(alpha: 0.58),
      Colors.white.withValues(alpha: 0.26),
    );
    final summaryGlow = Color.alphaBlend(
      backgroundVisual.primaryGlow.withValues(alpha: 0.4),
      const Color(0x120E2038),
    );
    final summaryGlowSoft = Color.alphaBlend(
      backgroundVisual.secondaryGlow.withValues(alpha: 0.34),
      const Color(0x100E2038),
    );
    final summaryAccentText = Color.alphaBlend(
      backgroundVisual.secondaryGlow.withValues(alpha: 0.72),
      const Color(0xFFE7F1FF),
    );
    final summaryMetaText = Color.alphaBlend(
      backgroundVisual.overlayTint.withValues(alpha: 0.78),
      const Color(0xFFE5EDFF),
    );
    final summaryMetricBackground = Color.alphaBlend(
      backgroundVisual.overlayTint.withValues(alpha: 0.24),
      const Color(0x14243A63),
    );
    final summaryMetricBorder = Color.alphaBlend(
      backgroundVisual.secondaryGlow.withValues(alpha: 0.42),
      Colors.white.withValues(alpha: 0.12),
    );
    final summaryChipBackground = Color.alphaBlend(
      backgroundVisual.primaryGlow.withValues(alpha: 0.18),
      const Color(0x1222355E),
    );
    final summaryChipBorder = Color.alphaBlend(
      backgroundVisual.secondaryGlow.withValues(alpha: 0.42),
      Colors.white.withValues(alpha: 0.1),
    );

    return VeloPrimeWorkspacePanel(
      tint: VeloPrimePalette.bronzeDeep,
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VeloPrimeSectionEyebrow(label: 'Panel wynikowy'),
                    SizedBox(height: 6),
                    Text('Podgląd oferty przed PDF', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusStyle(offer.status).background,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _statusStyle(offer.status).foreground.withValues(alpha: 0.18)),
                ),
                child: Text(_statusStyle(offer.status).label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: _statusStyle(offer.status).foreground)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _WorkspaceMiniPill(label: offer.number, tone: _MiniPillTone.cool),
              _WorkspaceMiniPill(label: offer.customerName.isEmpty ? 'Klient do uzupełnienia' : offer.customerName, tone: _MiniPillTone.cool),
              _WorkspaceMiniPill(label: selectedPricingOption != null ? '${selectedPricingOption!.brand} ${selectedPricingOption!.model}' : (offer.modelName ?? 'Model do uzupełnienia'), tone: _MiniPillTone.cool),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [summaryTop, summaryBottom],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: summaryBorder),
              boxShadow: [
                BoxShadow(
                  color: summaryGlow,
                  spreadRadius: 0.5,
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: summaryGlowSoft,
                  blurRadius: 14,
                ),
                BoxShadow(
                  color: summaryGlowSoft,
                  blurRadius: 24,
                ),
                BoxShadow(
                  color: Color(0x140E2038),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasDiscount ? 'CENA PO RABACIE' : _primaryPriceLabel.toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: summaryAccentText),
                ),
                const SizedBox(height: 8),
                Text(
                  _finalPrimaryPrice != null ? currencyFormat.format(_finalPrimaryPrice) : 'Do ustalenia',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.05, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  _finalSecondaryPrice != null ? '$_secondaryPriceLabel ${currencyFormat.format(_finalSecondaryPrice)}' : '$_secondaryPriceLabel do ustalenia',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: summaryMetaText),
                ),
                if (hasDiscount) ...[
                  const SizedBox(height: 14),
                  Text(
                    _catalogPrimaryPrice != null ? currencyFormat.format(_catalogPrimaryPrice) : 'Do ustalenia',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0x88FFFFFF),
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Color(0xCCFFFFFF),
                      decorationThickness: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _discountPrimaryValue != null ? 'Rabat klienta: ${currencyFormat.format(_discountPrimaryValue)}' : 'Rabat klienta: Brak',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: summaryAccentText),
                  ),
                ],
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = (constraints.maxWidth - 24) / 3;
                    return Row(
                      children: [
                        Expanded(
                          child: _ResultMiniMetric(
                            width: itemWidth,
                            label: 'Rata',
                            value: estimatedInstallment != null ? currencyFormat.format(estimatedInstallment) : 'Brak',
                            backgroundColor: summaryMetricBackground,
                            borderColor: summaryMetricBorder,
                            labelColor: summaryAccentText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ResultMiniMetric(
                            width: itemWidth,
                            label: 'Wpłata',
                            value: downPayment != null ? currencyFormat.format(downPayment) : 'Brak',
                            backgroundColor: summaryMetricBackground,
                            borderColor: summaryMetricBorder,
                            labelColor: summaryAccentText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ResultMiniMetric(
                            width: itemWidth,
                            label: 'Wykup',
                            value: buyoutPercent != null ? '$buyoutPercent%' : 'Brak',
                            backgroundColor: summaryMetricBackground,
                            borderColor: summaryMetricBorder,
                            labelColor: summaryAccentText,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DarkScenarioChip(
                      label: hasDiscount ? 'Cena katalogowa ${_catalogPrimaryPrice != null ? currencyFormat.format(_catalogPrimaryPrice) : 'Do ustalenia'}' : 'Cena pomocnicza ${_catalogSecondaryPrice != null ? currencyFormat.format(_catalogSecondaryPrice) : 'Do ustalenia'}',
                      backgroundColor: summaryChipBackground,
                      borderColor: summaryChipBorder,
                      foregroundColor: summaryMetaText,
                    ),
                    _DarkScenarioChip(
                      label: termMonths != null ? '$termMonths mies.' : 'Brak okresu',
                      backgroundColor: summaryChipBackground,
                      borderColor: summaryChipBorder,
                      foregroundColor: summaryMetaText,
                    ),
                    _DarkScenarioChip(
                      label: financingVariant.isEmpty ? 'Brak wariantu' : financingVariant,
                      backgroundColor: summaryChipBackground,
                      borderColor: summaryChipBorder,
                      foregroundColor: summaryMetaText,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _WorkspaceStat(label: 'Rabat klienta', value: discountValue != null ? currencyFormat.format(discountValue) : 'Brak', compact: true)),
              const SizedBox(width: 12),
              Expanded(child: _WorkspaceStat(label: 'Status roboczy', value: _statusStyle(offer.status).label, compact: true)),
            ],
          ),
          const SizedBox(height: 16),
          _PanelCard(
            title: 'Finansowanie',
            subtitle: 'Scenariusz klienta przed wygenerowaniem dokumentu.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KeyValueLine(label: 'Typ klienta', value: customerType == 'BUSINESS' ? 'Firma' : 'Klient prywatny'),
                _KeyValueLine(label: 'Wariant', value: financingVariant.isEmpty ? 'Brak' : financingVariant),
                _KeyValueLine(label: 'Okres', value: termMonths != null ? '$termMonths mies.' : 'Brak'),
                _KeyValueLine(label: 'Wpłata własna', value: downPayment != null ? currencyFormat.format(downPayment) : 'Brak'),
                _KeyValueLine(label: 'Wykup', value: buyoutPercent != null ? '$buyoutPercent%' : 'Brak'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _PanelCard(
            title: 'Konfiguracja oferty',
            subtitle: 'Najważniejsze dane, które trafią do dokumentu PDF.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KeyValueLine(label: 'Klient', value: offer.customerName.isEmpty ? 'Do uzupełnienia' : offer.customerName),
                _KeyValueLine(label: 'Model', value: selectedPricingOption?.label ?? offer.modelName ?? 'Do uzupełnienia'),
                _KeyValueLine(label: 'Ważna do', value: _formatNullableDate(validUntil, dateFormat) ?? 'Bez terminu'),
                _KeyValueLine(label: 'Status oferty', value: _statusStyle(offer.status).label),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: veloPrimeWorkspacePanelDecoration(
        tint: VeloPrimePalette.bronzeDeep,
        radius: 18,
        surfaceOpacity: 0.88,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: VeloPrimePalette.bronzeDeep)),
          if (hasSubtitle) ...[
            const SizedBox(height: 5),
            Text(subtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.45, color: Color(0xFF585042))),
            const SizedBox(height: 14),
          ] else
            const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}

class _SectionSubheader extends StatelessWidget {
  const _SectionSubheader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.7, color: Color(0xFF8A7441)),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5, color: Color(0xFF5A5144)),
        ),
      ],
    );
  }
}

class _EditorFormBand extends StatelessWidget {
  const _EditorFormBand({
    required this.title,
    required this.subtitle,
    required this.child,
    this.accent = Colors.white,
    this.headerTrailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Color accent;
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(VeloPrimePalette.bronzeDeep.withValues(alpha: 0.03), accent),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VeloPrimePalette.bronzeDeep.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink),
                ),
              ),
              if (headerTrailing != null) ...[
                const SizedBox(width: 12),
                headerTrailing!,
              ],
            ],
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.45, color: Color(0xFF5F5547)),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EditorInfoTile extends StatelessWidget {
  const _EditorInfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VeloPrimePalette.bronzeDeep.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6A5D45)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink),
          ),
        ],
      ),
    );
  }
}

class _StyledDropdownField<T> extends StatelessWidget {
  const _StyledDropdownField({
    required this.initialValue,
    required this.items,
    required this.onChanged,
    required this.decoration,
    this.selectedItemBuilder,
  });

  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final InputDecoration decoration;
  final List<Widget> Function(BuildContext context)? selectedItemBuilder;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: initialValue,
      isExpanded: true,
      menuMaxHeight: 320,
      borderRadius: BorderRadius.circular(14),
      dropdownColor: const Color(0xFFFFFCF6),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFB2862F)),
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: VeloPrimePalette.ink),
      selectedItemBuilder: selectedItemBuilder,
      items: items,
      onChanged: onChanged,
      decoration: decoration,
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VeloPrimePalette.bronzeDeep.withValues(alpha: 0.12)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: VeloPrimePalette.muted)),
    );
  }
}

ManagedOfferSummary _mapDetailToSummary(OfferDetail detail) {
  return ManagedOfferSummary(
    id: detail.id,
    number: detail.number,
    status: detail.status,
    title: detail.title,
    customerName: detail.customerName,
    modelName: detail.modelName,
    ownerName: detail.ownerName,
    totalGross: detail.totalGross,
    validUntil: detail.validUntil,
    updatedAt: detail.updatedAt,
    financingVariant: detail.financingVariant,
  );
}

class _WorkspaceStat extends StatelessWidget {
  const _WorkspaceStat({required this.label, required this.value, this.compact = false});

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: VeloPrimePalette.bronzeDeep.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: VeloPrimePalette.muted)),
          SizedBox(height: compact ? 6 : 8),
          Text(value, style: TextStyle(fontSize: compact ? 16 : 18, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink)),
        ],
      ),
    );
  }
}

class _ResultMiniMetric extends StatelessWidget {
  const _ResultMiniMetric({
    required this.label,
    required this.value,
    this.width = 140,
    this.backgroundColor = const Color(0x16F5F9FF),
    this.borderColor = const Color(0x3F9EC5FF),
    this.labelColor = const Color(0xFFBFD8FF),
  });

  final String label;
  final String value;
  final double width;
  final Color backgroundColor;
  final Color borderColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: labelColor)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }
}

class _DarkScenarioChip extends StatelessWidget {
  const _DarkScenarioChip({
    required this.label,
    this.backgroundColor = const Color(0x1622355E),
    this.borderColor = const Color(0x3F9EC5FF),
    this.foregroundColor = const Color(0xFFDDE8FF),
  });

  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: foregroundColor),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VeloPrimePalette.bronzeDeep.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: VeloPrimePalette.muted, height: 1.5),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _KeyValueLine extends StatelessWidget {
  const _KeyValueLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: VeloPrimePalette.muted),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, height: 1.45, color: VeloPrimePalette.ink),
            ),
          ),
        ],
      ),
    );
  }
}

enum _MiniPillTone { neutral, cool }

class _WorkspaceMiniPill extends StatelessWidget {
  const _WorkspaceMiniPill({required this.label, this.tone = _MiniPillTone.neutral});

  final String label;
  final _MiniPillTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tone == _MiniPillTone.cool ? const Color(0xFFF7F5FF) : Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone == _MiniPillTone.cool ? VeloPrimePalette.sea.withValues(alpha: 0.16) : VeloPrimePalette.bronzeDeep.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B6B6B)),
      ),
    );
  }
}

String _formatDate(DateTime value, DateFormat format) => format.format(value);

String? _formatNullableDate(String? value, DateFormat format) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  return _formatDate(parsed, format);
}

_OfferStatusStyle _statusStyle(String status) {
  switch (status.toUpperCase()) {
    case 'DRAFT':
      return const _OfferStatusStyle(
        label: 'Szkic',
        background: Color(0xFFF4E9CD),
        foreground: Color(0xFF4E4537),
      );
    case 'READY':
      return const _OfferStatusStyle(
        label: 'Gotowa',
        background: Color(0xFFF7EFD8),
        foreground: Color(0xFF8A7441),
      );
    case 'APPROVED':
      return const _OfferStatusStyle(
        label: 'Zatwierdzona',
        background: Color(0xFFD9E8DE),
        foreground: Color(0xFF245236),
      );
    case 'REJECTED':
      return const _OfferStatusStyle(
        label: 'Odrzucona',
        background: Color(0xFFF6D9D5),
        foreground: Color(0xFF7D2C22),
      );
    default:
      return _OfferStatusStyle(
        label: status,
        background: const Color(0xFFEDEDED),
        foreground: Colors.black87,
      );
  }
}

class _OfferStatusStyle {
  const _OfferStatusStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}
