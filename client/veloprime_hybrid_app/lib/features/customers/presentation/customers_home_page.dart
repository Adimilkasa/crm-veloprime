import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/presentation/veloprime_ui.dart';
import '../../bootstrap/models/bootstrap_payload.dart';
import '../data/customers_repository.dart';
import '../models/customer_models.dart';
import '../../leads/data/leads_repository.dart';
import '../../leads/models/lead_models.dart';
import '../../leads/presentation/lead_detail_page.dart';
import '../../offers/data/offers_repository.dart';
import '../../offers/presentation/offers_home_page.dart';
import '../../reminders/data/reminders_repository.dart';

final DateFormat _customerDateFormat = DateFormat('dd.MM.yyyy');
final DateFormat _customerDateTimeFormat = DateFormat('dd.MM.yyyy • HH:mm');

const List<CustomerWorkflowStageInfo> _fallbackCustomerWorkflowStages = [
  CustomerWorkflowStageInfo(
    key: 'CUSTOMER_STAGE_1',
    label: 'Etap 1',
    color: '#D69B2B',
    order: 0,
  ),
  CustomerWorkflowStageInfo(
    key: 'CUSTOMER_STAGE_2',
    label: 'Etap 2',
    color: '#C56A4A',
    order: 1,
  ),
  CustomerWorkflowStageInfo(
    key: 'CUSTOMER_STAGE_3',
    label: 'Etap 3',
    color: '#7C5AC8',
    order: 2,
  ),
  CustomerWorkflowStageInfo(
    key: 'CUSTOMER_STAGE_4',
    label: 'Etap 4',
    color: '#2F9B63',
    order: 3,
  ),
  CustomerWorkflowStageInfo(
    key: 'CUSTOMER_STAGE_5',
    label: 'Etap 5',
    color: '#3C7DD9',
    order: 4,
  ),
  CustomerWorkflowStageInfo(
    key: 'CUSTOMER_STAGE_6',
    label: 'Etap 6',
    color: '#A95A96',
    order: 5,
  ),
  CustomerWorkflowStageInfo(
    key: 'CUSTOMER_STAGE_7',
    label: 'Etap 7',
    color: '#B7801A',
    order: 6,
  ),
  CustomerWorkflowStageInfo(
    key: 'CUSTOMER_STAGE_8',
    label: 'Etap 8',
    color: '#5E6C84',
    order: 7,
  ),
];

class CustomersHomePage extends StatefulWidget {
  const CustomersHomePage({
    super.key,
    required this.session,
    required this.bootstrap,
    required this.customersRepository,
    required this.repository,
    required this.offersRepository,
    required this.remindersRepository,
    required this.onRemindersChanged,
    required this.onOpenOfferWorkspaceForLead,
  });

  final SessionInfo session;
  final BootstrapPayload bootstrap;
  final CustomersRepository customersRepository;
  final LeadsRepository repository;
  final OffersRepository offersRepository;
  final RemindersRepository remindersRepository;
  final Future<void> Function() onRemindersChanged;
  final Future<void> Function(OfferWorkspaceLaunchRequest request)
      onOpenOfferWorkspaceForLead;

  @override
  State<CustomersHomePage> createState() => _CustomersHomePageState();
}

class _CustomersHomePageState extends State<CustomersHomePage> {
  static const String _allSalespeople = '__ALL__';
  static const String _unassignedSalespeople = '__UNASSIGNED__';

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _kanbanScrollController = ScrollController();
  LeadsOverview? _overview;
  bool _isLoading = true;
  String? _movingLeadId;
  String _selectedSalespersonFilter = _allSalespeople;
  String? _error;

  bool get _canManageCustomerWorkspace =>
      widget.session.role == 'ADMIN' ||
      widget.session.role == 'DIRECTOR' ||
      widget.session.role == 'MANAGER';

  bool get _canRenameCustomerStages => widget.session.role == 'ADMIN';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _kanbanScrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = _overview == null;
      _error = null;
    });

    final cachedOverview = await widget.repository.readCachedLeads();
    if (cachedOverview != null && mounted) {
      setState(() {
        _overview = cachedOverview;
        _isLoading = false;
      });
    }

    try {
      final overview = await widget.repository.fetchLeads();

      if (!mounted) {
        return;
      }

      setState(() {
        _overview = overview;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Set<String> _wonStageIds(LeadsOverview overview) {
    return overview.stages
        .where((stage) => stage.kind == 'WON')
        .map((stage) => stage.id)
        .toSet();
  }

  Future<void> _openLeadWorkspace(ManagedLeadSummary lead) async {
    final payload = await widget.repository.fetchLeadDetail(lead.id);

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LeadDetailPage(
          session: widget.session,
          bootstrap: widget.bootstrap,
          repository: widget.repository,
          offersRepository: widget.offersRepository,
          remindersRepository: widget.remindersRepository,
          initialPayload: payload,
          onRemindersChanged: widget.onRemindersChanged,
          onOpenOfferWorkspaceForLead: widget.onOpenOfferWorkspaceForLead,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _load();
  }

  Future<void> _openCustomerCard(ManagedLeadSummary lead) async {
    var customerId = lead.customerId?.trim() ?? '';

    if (customerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Obsługę klienta kontynuujesz na istniejącej karcie leada. Ten widok nie zakłada nowej karty klienta.',
          ),
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    final updated = await showDialog<ManagedCustomerRecord>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CustomerAdminDialog(
        repository: widget.customersRepository,
        customerId: customerId,
        lead: lead,
      ),
    );

    if (updated == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Zapisano kartę klienta ${updated.fullName}.')),
    );

    await _load();
  }

  Future<void> _moveCustomerWorkflowStage(
    String leadId,
    String customerWorkflowStage,
  ) async {
    final overview = _overview;
    if (overview == null) {
      return;
    }

    final existing =
        overview.leads.where((lead) => lead.id == leadId).firstOrNull;
    if (existing == null ||
        _customerStageKey(existing, overview.customerWorkflowStages) ==
            customerWorkflowStage) {
      return;
    }

    final now = DateTime.now().toIso8601String();
    final nextOverview = LeadsOverview(
      leads: overview.leads
          .map(
            (lead) => lead.id == leadId
                ? lead.copyWith(
                    customerWorkflowStage: customerWorkflowStage,
                    updatedAt: now,
                  )
                : lead,
          )
          .toList(),
      stages: overview.stages,
      salespeople: overview.salespeople,
      customerWorkflowStages: overview.customerWorkflowStages,
    );

    setState(() {
      _movingLeadId = leadId;
      _overview = nextOverview;
    });

    try {
      await widget.repository.updateCustomerWorkflowStage(
        leadId: leadId,
        customerWorkflowStage: customerWorkflowStage,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _overview = overview;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _movingLeadId = null;
        });
      }
    }
  }

  List<CustomerWorkflowStageInfo> _customerWorkflowStages(
    LeadsOverview? overview,
  ) {
    final stages = overview?.customerWorkflowStages ?? const [];
    if (stages.isEmpty) {
      return _fallbackCustomerWorkflowStages;
    }

    return [...stages]
      ..sort((left, right) => left.order.compareTo(right.order));
  }

  String _normalizeCustomerStageKey(
    String? value,
    List<CustomerWorkflowStageInfo> stages,
  ) {
    final trimmed = (value ?? '').trim();
    final fallbackKey = stages.isEmpty
        ? _fallbackCustomerWorkflowStages.first.key
        : stages.first.key;

    switch (trimmed) {
      case 'NEW_CUSTOMER':
        return 'CUSTOMER_STAGE_1';
      case 'IN_PROGRESS':
        return 'CUSTOMER_STAGE_2';
      case 'FORMALITIES':
        return 'CUSTOMER_STAGE_3';
      case 'COMPLETED':
        return 'CUSTOMER_STAGE_4';
      default:
        if (trimmed.isEmpty) {
          return fallbackKey;
        }

        return stages.any((stage) => stage.key == trimmed)
            ? trimmed
            : fallbackKey;
    }
  }

  Future<void> _renameCustomerWorkflowStage(
    CustomerWorkflowStageInfo stage,
  ) async {
    final controller = TextEditingController(text: stage.label);
    final nextLabel = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Zmień nazwę ${stage.label}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nazwa etapu',
            hintText: 'Wpisz nazwę etapu',
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
    controller.dispose();

    final normalizedLabel = (nextLabel ?? '').trim();
    if (normalizedLabel.isEmpty || normalizedLabel == stage.label) {
      return;
    }

    try {
      final updatedOverview =
          await widget.repository.updateCustomerWorkflowStageLabel(
        stageKey: stage.key,
        label: normalizedLabel,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _overview = updatedOverview;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  List<ManagedLeadSummary> _customerLeads(LeadsOverview overview) {
    final wonStageIds = _wonStageIds(overview);
    final query = _searchController.text.trim().toLowerCase();

    return overview.leads.where((lead) {
      if (!wonStageIds.contains(lead.stageId)) {
        return false;
      }

      if (_selectedSalespersonFilter == _unassignedSalespeople) {
        if ((lead.salespersonName ?? '').isNotEmpty) {
          return false;
        }
      } else if (_selectedSalespersonFilter != _allSalespeople) {
        if ((lead.salespersonName ?? '') != _selectedSalespersonFilter) {
          return false;
        }
      }

      if (query.isEmpty) {
        return true;
      }

      final acceptedOffer = lead.linkedOffers
          .where((offer) => offer.id == lead.acceptedOfferId)
          .firstOrNull;
      final haystack = [
        lead.fullName,
        lead.email,
        lead.phone,
        lead.interestedModel,
        lead.region,
        lead.salespersonName,
        acceptedOffer?.number,
        acceptedOffer?.title,
      ].whereType<String>().join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList()
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
  }

  String _customerStageKey(
    ManagedLeadSummary lead,
    List<CustomerWorkflowStageInfo> customerWorkflowStages,
  ) {
    return _normalizeCustomerStageKey(
      lead.customerWorkflowStage,
      customerWorkflowStages,
    );
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    final customerWorkflowStages = _customerWorkflowStages(overview);
    final customers = overview == null
        ? const <ManagedLeadSummary>[]
        : _customerLeads(overview);
    final countsByStageKey = <String, int>{
      for (final stage in customerWorkflowStages) stage.key: 0,
    };
    for (final lead in customers) {
      final stageKey = _customerStageKey(lead, customerWorkflowStages);
      countsByStageKey[stageKey] = (countsByStageKey[stageKey] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VeloPrimeShell(
        decorateBackground: false,
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
        child: _isLoading
            ? const VeloPrimeWorkspaceState(
                tint: VeloPrimePalette.olive,
                eyebrow: 'Klienci',
                title: 'Ładujemy kanban klientów',
                message:
                    'Przygotowujemy wygrane sprawy i grupujemy je do obsługi posprzedażowej.',
                isLoading: true,
              )
            : _error != null
                ? VeloPrimeWorkspaceState(
                    tint: VeloPrimePalette.rose,
                    eyebrow: 'Klienci',
                    title: 'Nie udało się załadować klientów',
                    message: _error!,
                    icon: Icons.warning_amber_rounded,
                  )
                : overview == null
                    ? const VeloPrimeWorkspaceState(
                        tint: VeloPrimePalette.olive,
                        eyebrow: 'Klienci',
                        title: 'Brak danych klientów',
                        message:
                            'Po pobraniu leadów wygranych kanban klientów pojawi się tutaj.',
                        icon: Icons.groups_2_outlined,
                      )
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.fromLTRB(22, 22, 22, 20),
                              decoration: veloPrimeWorkspacePanelDecoration(
                                tint: VeloPrimePalette.olive,
                                radius: 30,
                                surfaceOpacity: 0.75,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const VeloPrimeSectionEyebrow(
                                                label: 'Klienci',
                                                color: VeloPrimePalette.olive),
                                            const SizedBox(height: 12),
                                            const Text(
                                              'Kanban klientów z 8 uniwersalnymi etapami.',
                                              style: TextStyle(
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.08,
                                                  color: Color(0xFF23315C)),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              _canRenameCustomerStages
                                                  ? 'Każdy lead z etapu Wygrane trafia tutaj od razu do pierwszej kolumny. Masz 8 uniwersalnych etapów i jako administrator możesz w dowolnym momencie zmienić ich nazwy.'
                                                  : 'Każdy lead z etapu Wygrane trafia tutaj od razu do pierwszej kolumny. Kanban pokazuje ręcznie ustawiony etap klienta w 8 uniwersalnych kolumnach.',
                                              style: const TextStyle(
                                                  color: Color(0xFF66729C),
                                                  height: 1.55,
                                                  fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 18),
                                      OutlinedButton.icon(
                                        onPressed: _isLoading ? null : _load,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Odśwież'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 18, vertical: 18),
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.68),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(999)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      _OverviewChip(
                                          label:
                                              'Wszystkie ${customers.length}',
                                          tint: VeloPrimePalette.olive),
                                      ...customerWorkflowStages.map(
                                        (stage) => _OverviewChip(
                                          label:
                                              '${stage.label} ${countsByStageKey[stage.key] ?? 0}',
                                          tint: _parseColor(stage.color),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Wrap(
                                    spacing: 14,
                                    runSpacing: 14,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 320,
                                        child: _CustomerFilterDropdownField<
                                            String>(
                                          label: 'Opiekun',
                                          initialValue:
                                              _selectedSalespersonFilter,
                                          items: [
                                            const DropdownMenuItem<String>(
                                                value: _allSalespeople,
                                                child: Text(
                                                    'Wszyscy opiekunowie')),
                                            const DropdownMenuItem<String>(
                                                value: _unassignedSalespeople,
                                                child: Text(
                                                    'Bez przypisanego opiekuna')),
                                            ...overview.salespeople.map(
                                              (user) =>
                                                  DropdownMenuItem<String>(
                                                      value: user.fullName,
                                                      child:
                                                          Text(user.fullName)),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            if (value == null) {
                                              return;
                                            }
                                            setState(() {
                                              _selectedSalespersonFilter =
                                                  value;
                                            });
                                          },
                                        ),
                                      ),
                                      if (_selectedSalespersonFilter !=
                                              _allSalespeople ||
                                          _searchController.text.isNotEmpty)
                                        TextButton.icon(
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _selectedSalespersonFilter =
                                                  _allSalespeople;
                                            });
                                          },
                                          icon: const Icon(
                                              Icons.filter_alt_off_outlined),
                                          label: const Text('Wyczyść filtry'),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.92),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                          color: const Color(0x183159B9)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.search,
                                            color: Color(0xFF274FA8)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: _searchController,
                                            onChanged: (_) => setState(() {}),
                                            decoration:
                                                veloPrimeInputDecoration(
                                              'Szukaj',
                                              hintText:
                                                  'Klient, model, region, opiekun lub numer oferty',
                                            ).copyWith(
                                              floatingLabelBehavior:
                                                  FloatingLabelBehavior.never,
                                              labelText: null,
                                              fillColor: Colors.transparent,
                                              hintStyle: const TextStyle(
                                                  color: Color(0xFF67739D),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 18),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(22),
                                                borderSide: const BorderSide(
                                                    color: Colors.transparent),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(22),
                                                borderSide: const BorderSide(
                                                    color: Colors.transparent),
                                              ),
                                              suffixIcon:
                                                  _searchController.text.isEmpty
                                                      ? null
                                                      : IconButton(
                                                          onPressed: () {
                                                            _searchController
                                                                .clear();
                                                            setState(() {});
                                                          },
                                                          icon: const Icon(
                                                              Icons.close),
                                                        ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${customers.length} rekordów',
                                          style: const TextStyle(
                                              color: Color(0xFF67739D),
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 26)),
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                              decoration: veloPrimeWorkspacePanelDecoration(
                                tint: VeloPrimePalette.olive,
                                radius: 34,
                                surfaceOpacity: 0.75,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            VeloPrimeSectionEyebrow(
                                                label: 'Workflow'),
                                            SizedBox(height: 8),
                                            Text(
                                              'Kanban operacyjny klientów.',
                                              style: TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.08,
                                                  color: Color(0xFF23315C)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.68),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                              color: const Color(0x1D3159B9)),
                                        ),
                                        child: const Text(
                                          'Kanban klientów',
                                          style: TextStyle(
                                              color: Color(0xFF67739D),
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  if (customers.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 14),
                                      child: Text(
                                        'Brak klientów w widoku. Kolumny są już gotowe do nazwania i każdy lead z etapu Wygrane pojawi się tutaj automatycznie.',
                                        style: TextStyle(
                                            color: VeloPrimePalette.muted,
                                            fontSize: 14,
                                            height: 1.5),
                                      ),
                                    ),
                                  Expanded(
                                    child: Scrollbar(
                                      controller: _kanbanScrollController,
                                      thumbVisibility: true,
                                      child: SingleChildScrollView(
                                        controller: _kanbanScrollController,
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: customerWorkflowStages
                                              .map(
                                                (stage) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 18),
                                                  child: _CustomerKanbanColumn(
                                                    stage: stage,
                                                    leads: customers
                                                        .where(
                                                          (lead) =>
                                                              _customerStageKey(
                                                                lead,
                                                                customerWorkflowStages,
                                                              ) ==
                                                              stage.key,
                                                        )
                                                        .toList(),
                                                    canEdit:
                                                      _canManageCustomerWorkspace,
                                                    movingLeadId: _movingLeadId,
                                                    onOpenLead:
                                                        _openLeadWorkspace,
                                                    onMoveLead:
                                                        _moveCustomerWorkflowStage,
                                                    onRenameStage:
                                                      _canRenameCustomerStages
                                                        ? _renameCustomerWorkflowStage
                                                        : null,
                                                    onOpenCustomer:
                                                      _canManageCustomerWorkspace
                                                            ? _openCustomerCard
                                                            : null,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}

class _CustomerFilterDropdownField<T> extends StatelessWidget {
  const _CustomerFilterDropdownField({
    required this.label,
    required this.initialValue,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: initialValue,
      items: items,
      onChanged: onChanged,
      borderRadius: BorderRadius.circular(20),
      decoration: veloPrimeInputDecoration(label).copyWith(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
      ),
    );
  }
}

class _CustomerKanbanColumn extends StatelessWidget {
  const _CustomerKanbanColumn({
    required this.stage,
    required this.leads,
    required this.canEdit,
    required this.movingLeadId,
    required this.onOpenLead,
    required this.onMoveLead,
    required this.onRenameStage,
    required this.onOpenCustomer,
  });

  final CustomerWorkflowStageInfo stage;
  final List<ManagedLeadSummary> leads;
  final bool canEdit;
  final String? movingLeadId;
  final Future<void> Function(ManagedLeadSummary lead) onOpenLead;
  final Future<void> Function(String leadId, String customerWorkflowStage)
      onMoveLead;
  final Future<void> Function(CustomerWorkflowStageInfo stage)? onRenameStage;
  final Future<void> Function(ManagedLeadSummary lead)? onOpenCustomer;

  @override
  Widget build(BuildContext context) {
    final stageColor = _parseColor(stage.color);
    final documentsCount =
        leads.fold<int>(0, (count, lead) => count + lead.attachmentCount);

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) async {
        await onMoveLead(details.data, stage.key);
      },
      builder: (context, candidateData, rejectedData) => Container(
        width: 336,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.alphaBlend(stageColor.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.76)),
              Color.alphaBlend(
                  stageColor.withValues(alpha: 0.05), const Color(0xB8F9F7FC)),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: candidateData.isNotEmpty
                ? VeloPrimePalette.bronze.withValues(alpha: 0.32)
                : stageColor.withValues(alpha: 0.16),
            width: candidateData.isNotEmpty ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.alphaBlend(stageColor.withValues(alpha: 0.24),
                        Colors.white.withValues(alpha: 0.86)),
                    Color.alphaBlend(stageColor.withValues(alpha: 0.08),
                        const Color(0xCCFFFCF8)),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: stageColor.withValues(alpha: 0.14)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage.label,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: VeloPrimePalette.ink),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Uniwersalny etap ${stage.order + 1} gotowy do własnej nazwy.',
                          style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF6F6553),
                              fontWeight: FontWeight.w600,
                              height: 1.45),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${leads.length}',
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: VeloPrimePalette.ink,
                              height: 1),
                        ),
                      ],
                    ),
                  ),
                  if (canEdit && onRenameStage != null)
                    IconButton(
                      tooltip: 'Zmień nazwę etapu',
                      onPressed: () => onRenameStage!(stage),
                      icon: Icon(Icons.edit_outlined, color: stageColor),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StageStatPill(
                    label: 'Karty',
                    value:
                        '${leads.where((lead) => (lead.customerId ?? '').isNotEmpty).length}/${leads.length}',
                    accentColor: stageColor),
                _StageStatPill(
                    label: 'Dokumenty',
                    value: '$documentsCount',
                    accentColor: stageColor),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: leads.isEmpty
                  ? Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 32),
                      decoration: BoxDecoration(
                        color: candidateData.isNotEmpty
                            ? VeloPrimePalette.bronze.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: candidateData.isNotEmpty
                              ? VeloPrimePalette.bronze.withValues(alpha: 0.36)
                              : const Color(0xFFE7DFD0),
                        ),
                      ),
                      child: Text(
                        'Brak klientów w tej kolumnie.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A826F),
                            height: 1.45),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: leads
                            .map(
                              (lead) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _CustomerKanbanCard(
                                  lead: lead,
                                  stageColor: stageColor,
                                  canEdit: canEdit,
                                  isMoving: movingLeadId == lead.id,
                                  onOpenLead: () => onOpenLead(lead),
                                  onOpenCustomer:
                                      (lead.customerId ?? '').isEmpty ||
                                              onOpenCustomer == null
                                          ? null
                                          : () => onOpenCustomer!(lead),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerKanbanCard extends StatefulWidget {
  const _CustomerKanbanCard({
    required this.lead,
    required this.stageColor,
    required this.canEdit,
    required this.isMoving,
    required this.onOpenLead,
    required this.onOpenCustomer,
  });

  final ManagedLeadSummary lead;
  final Color stageColor;
  final bool canEdit;
  final bool isMoving;
  final VoidCallback onOpenLead;
  final VoidCallback? onOpenCustomer;

  @override
  State<_CustomerKanbanCard> createState() => _CustomerKanbanCardState();
}

class _CustomerKanbanCardState extends State<_CustomerKanbanCard> {
  bool _isPointerHovering = false;

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;
    final acceptedOffer = lead.linkedOffers
        .where((offer) => offer.id == lead.acceptedOfferId)
        .firstOrNull;
    final hasCustomerCard = (lead.customerId ?? '').isNotEmpty;
    final hasDocuments = lead.attachmentCount > 0;
    final nextAction = _formatCustomerActionDate(lead.nextActionAt);

    Widget buildCard({bool forFeedback = false}) {
      return Opacity(
        opacity: widget.isMoving ? 0.45 : 1,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isPointerHovering = true),
          onExit: (_) => setState(() => _isPointerHovering = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            transform:
                Matrix4.translationValues(0, _isPointerHovering ? -2 : 0, 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: widget.onOpenLead,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.92),
                        Color.alphaBlend(
                            widget.stageColor.withValues(alpha: 0.05),
                            const Color(0xE8FFFCF8)),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: widget.stageColor.withValues(alpha: 0.22)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1F1F1F).withValues(alpha: 0.05),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.stageColor.withValues(alpha: 0.82),
                              widget.stageColor.withValues(alpha: 0.26),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lead.fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF22315C)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  [
                                    lead.interestedModel,
                                    lead.region,
                                    lead.salespersonName
                                  ]
                                      .whereType<String>()
                                      .where((value) => value.trim().isNotEmpty)
                                      .join(' • '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF43537B),
                                      height: 1.45),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.84),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: widget.stageColor
                                      .withValues(alpha: 0.18)),
                            ),
                            child: Text(
                              _formatWonDate(lead.acceptedAt ?? lead.updatedAt),
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: widget.stageColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _LeadStatusPill(
                            text: hasCustomerCard
                                ? 'Karta aktywna'
                                : 'Brak karty klienta',
                            accent: hasCustomerCard
                                ? const Color(0xFF2F855A)
                                : VeloPrimePalette.bronzeDeep,
                            background: hasCustomerCard
                                ? const Color(0xFFF0FFF4)
                                : const Color(0xFFFFFAF0),
                            borderColor: hasCustomerCard
                                ? const Color(0xFFC6F6D5)
                                : const Color(0xFFEFE0BA),
                          ),
                          _LeadStatusPill(
                            text: hasDocuments
                                ? 'Dokumenty: ${lead.attachmentCount}'
                                : 'Brak dokumentów',
                            accent: hasDocuments
                                ? const Color(0xFF355F99)
                                : const Color(0xFF9B2C2C),
                            background: hasDocuments
                                ? widget.stageColor.withValues(alpha: 0.12)
                                : const Color(0xFFFFF5F5),
                            borderColor: hasDocuments
                                ? widget.stageColor.withValues(alpha: 0.3)
                                : const Color(0xFFFDB8B8),
                          ),
                          if (lead.linkedOffers.isNotEmpty)
                            _LeadStatusPill(
                              text: 'Oferty: ${lead.linkedOffers.length}',
                              accent: const Color(0xFF5F5A4F),
                              background: Colors.white,
                              borderColor:
                                  widget.stageColor.withValues(alpha: 0.22),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _LeadInfoStrip(
                        icon: lead.phone != null
                            ? Icons.call_outlined
                            : Icons.alternate_email,
                        label: lead.phone ??
                            lead.email ??
                            'Brak danych kontaktowych',
                        accent: widget.stageColor,
                      ),
                      if (nextAction != null) ...[
                        const SizedBox(height: 10),
                        _LeadFocusPanel(
                          icon: Icons.event_available_outlined,
                          title: 'Najbliższy krok',
                          value: nextAction,
                          accent: widget.stageColor,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.92),
                              Color.alphaBlend(
                                  widget.stageColor.withValues(alpha: 0.04),
                                  Colors.white),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: widget.stageColor.withValues(alpha: 0.18)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Zaakceptowana oferta',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: Color(0xFF6A604D)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              acceptedOffer == null
                                  ? 'Brak przypisanej oferty kończącej sprzedaż.'
                                  : '${acceptedOffer.number} • ${acceptedOffer.title}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF35415F),
                                  height: 1.45),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (widget.canEdit && widget.onOpenCustomer != null)
                            FilledButton.tonalIcon(
                              onPressed: widget.onOpenCustomer,
                              icon: Icon(hasCustomerCard
                                  ? Icons.badge_outlined
                                  : Icons.person_add_alt_1_outlined),
                              label: Text(hasCustomerCard
                                  ? 'Karta klienta'
                                  : 'Karta klienta'),
                            ),
                          OutlinedButton.icon(
                            onPressed: widget.onOpenLead,
                            icon: Icon(widget.canEdit
                                ? Icons.open_in_new_rounded
                                : Icons.visibility_outlined),
                            label: Text(
                                widget.canEdit ? 'Otwórz lead' : 'Podgląd'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final card = buildCard();

    return Draggable<String>(
      data: lead.id,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      maxSimultaneousDrags: widget.canEdit && !widget.isMoving ? 1 : 0,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 280,
          child: Transform.rotate(
            angle: -0.015,
            child: buildCard(forFeedback: true),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: card),
      child: card,
    );
  }
}

class _OverviewChip extends StatelessWidget {
  const _OverviewChip({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Color.alphaBlend(tint.withValues(alpha: 0.14), Colors.white),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(color: tint, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _StageStatPill extends StatelessWidget {
  const _StageStatPill({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800, color: accentColor),
      ),
    );
  }
}

class _LeadStatusPill extends StatelessWidget {
  const _LeadStatusPill({
    required this.text,
    required this.accent,
    required this.background,
    required this.borderColor,
  });

  final String text;
  final Color accent;
  final Color background;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 10.5, fontWeight: FontWeight.w800, color: accent),
      ),
    );
  }
}

class _LeadInfoStrip extends StatelessWidget {
  const _LeadInfoStrip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 10.8,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF35415F)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadFocusPanel extends StatelessWidget {
  const _LeadFocusPanel({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.alphaBlend(accent.withValues(alpha: 0.12), Colors.white),
            Color.alphaBlend(
                accent.withValues(alpha: 0.03), const Color(0xFFFFFCF8)),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.76),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6A604D))),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF35415F))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _parseColor(String value) {
  final normalized = value.replaceFirst('#', '');
  final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
  return Color(int.tryParse(hex, radix: 16) ?? 0xFFD1D5DB);
}

String? _formatCustomerActionDate(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  return _customerDateTimeFormat.format(parsed);
}

class _CustomerAdminDialog extends StatefulWidget {
  const _CustomerAdminDialog({
    required this.repository,
    required this.customerId,
    required this.lead,
  });

  final CustomersRepository repository;
  final String customerId;
  final ManagedLeadSummary lead;

  @override
  State<_CustomerAdminDialog> createState() => _CustomerAdminDialogState();
}

class _CustomerAdminDialogState extends State<_CustomerAdminDialog> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  ManagedCustomerWorkspace? _workspace;
  ManagedCustomerRecord? _customer;
  String _selectedOwnerId = '';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _companyNameController.dispose();
    _taxIdController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final workspace =
          await widget.repository.fetchCustomerWorkspace(widget.customerId);

      if (!mounted) {
        return;
      }

      final customer = workspace.customer;
      _fullNameController.text = customer.fullName;
      _companyNameController.text = customer.companyName ?? '';
      _taxIdController.text = customer.taxId ?? '';
      _cityController.text = customer.city ?? '';
      _emailController.text = customer.email ?? '';
      _phoneController.text = customer.phone ?? '';
      _notesController.text = customer.notes ?? '';

      setState(() {
        _workspace = workspace;
        _customer = customer;
        _selectedOwnerId = customer.ownerId ?? '';
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final updated =
          await widget.repository.updateCustomer(widget.customerId, {
        'fullName': _fullNameController.text.trim(),
        'companyName': _companyNameController.text.trim(),
        'taxId': _taxIdController.text.trim(),
        'city': _cityController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'notes': _notesController.text.trim(),
        'ownerId': _selectedOwnerId,
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _customer = updated;
        _workspace = _workspace == null
            ? null
            : ManagedCustomerWorkspace(
                customer: updated,
                ownerOptions: _workspace!.ownerOptions,
                relatedLeads: _workspace!.relatedLeads,
                relatedOffers: _workspace!.relatedOffers,
              );
      });

      Navigator.of(context).pop(updated);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = _customer;
    final workspace = _workspace;
    final ownerOptions =
        workspace?.ownerOptions ?? const <ManagedCustomerOwnerOption>[];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: VeloPrimeWorkspacePanel(
          tint: VeloPrimePalette.olive,
          radius: 30,
          padding: const EdgeInsets.all(28),
          child: SingleChildScrollView(
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
                          const VeloPrimeSectionEyebrow(
                              label: 'Karta klienta',
                              color: VeloPrimePalette.olive),
                          const SizedBox(height: 10),
                          Text(
                            widget.lead.fullName,
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: VeloPrimePalette.ink,
                                height: 1.05),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Edycja zapisuje prawdziwy rekord klienta i synchronizuje podstawowe dane kontaktowe z powiązanymi leadami.',
                            style: TextStyle(
                                color: VeloPrimePalette.muted, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_isLoading)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator()))
                else if ((_error ?? '').isNotEmpty && customer == null)
                  Text(_error!,
                      style: const TextStyle(
                          color: VeloPrimePalette.rose, height: 1.6))
                else ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      VeloPrimeBadge(
                          label: 'Leady', value: '${customer?.leadCount ?? 0}'),
                      VeloPrimeBadge(
                          label: 'Oferty',
                          value: '${customer?.offerCount ?? 0}'),
                      if ((customer?.ownerName ?? '').isNotEmpty)
                        VeloPrimeBadge(
                            label: 'Właściciel', value: customer!.ownerName!),
                      VeloPrimeBadge(
                          label: 'Aktualizacja',
                          value: _formatWonDate(customer?.updatedAt)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedOwnerId,
                    decoration: veloPrimeInputDecoration('Właściciel klienta'),
                    items: [
                      const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Bez przypisanego właściciela')),
                      ...ownerOptions.map(
                        (option) => DropdownMenuItem<String>(
                          value: option.id,
                          child: Text(
                              '${option.fullName} • ${_formatUserRole(option.role)}'),
                        ),
                      ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _selectedOwnerId = value ?? '';
                            });
                          },
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      _CustomerFieldShell(
                        width: 320,
                        child: TextField(
                          controller: _fullNameController,
                          decoration:
                              veloPrimeInputDecoration('Imię i nazwisko'),
                        ),
                      ),
                      _CustomerFieldShell(
                        width: 240,
                        child: TextField(
                          controller: _companyNameController,
                          decoration: veloPrimeInputDecoration('Firma'),
                        ),
                      ),
                      _CustomerFieldShell(
                        width: 180,
                        child: TextField(
                          controller: _taxIdController,
                          decoration: veloPrimeInputDecoration('NIP'),
                        ),
                      ),
                      _CustomerFieldShell(
                        width: 220,
                        child: TextField(
                          controller: _cityController,
                          decoration: veloPrimeInputDecoration('Miejscowość'),
                        ),
                      ),
                      _CustomerFieldShell(
                        width: 280,
                        child: TextField(
                          controller: _emailController,
                          decoration: veloPrimeInputDecoration('Email'),
                        ),
                      ),
                      _CustomerFieldShell(
                        width: 220,
                        child: TextField(
                          controller: _phoneController,
                          decoration: veloPrimeInputDecoration('Telefon'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _notesController,
                    minLines: 4,
                    maxLines: 7,
                    decoration: veloPrimeInputDecoration(
                        'Notatki klienta niezależne od leada'),
                  ),
                  const SizedBox(height: 18),
                  _CustomerHistorySection(
                    leads: workspace?.relatedLeads ??
                        const <ManagedCustomerLeadHistoryItem>[],
                    offers: workspace?.relatedOffers ??
                        const <ManagedCustomerOfferHistoryItem>[],
                  ),
                  if ((_error ?? '').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(_error!,
                        style: const TextStyle(
                            color: VeloPrimePalette.rose, height: 1.6)),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Zamknij'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_isSaving
                            ? 'Zapisywanie...'
                            : 'Zapisz kartę klienta'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerFieldShell extends StatelessWidget {
  const _CustomerFieldShell({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}

class _CustomerHistorySection extends StatelessWidget {
  const _CustomerHistorySection({
    required this.leads,
    required this.offers,
  });

  final List<ManagedCustomerLeadHistoryItem> leads;
  final List<ManagedCustomerOfferHistoryItem> offers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historia klienta',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: VeloPrimePalette.ink),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _CustomerHistoryPanel(
              title: 'Powiązane leady',
              width: 320,
              children: leads.isEmpty
                  ? const [
                      Text('Brak leadów w historii klienta.',
                          style: TextStyle(
                              color: VeloPrimePalette.muted, height: 1.6))
                    ]
                  : leads
                      .map(
                        (lead) => _CustomerHistoryLine(
                          title: lead.fullName,
                          subtitle:
                              '${lead.stageLabel}${(lead.salespersonName ?? '').isEmpty ? '' : ' • ${lead.salespersonName}'}',
                          meta:
                              _formatWonDate(lead.acceptedAt ?? lead.updatedAt),
                        ),
                      )
                      .toList(),
            ),
            _CustomerHistoryPanel(
              title: 'Powiązane oferty',
              width: 320,
              children: offers.isEmpty
                  ? const [
                      Text('Brak ofert w historii klienta.',
                          style: TextStyle(
                              color: VeloPrimePalette.muted, height: 1.6))
                    ]
                  : offers
                      .map(
                        (offer) => _CustomerHistoryLine(
                          title: '${offer.number} • ${offer.title}',
                          subtitle:
                              '${_formatOfferStatus(offer.status)}${(offer.ownerName ?? '').isEmpty ? '' : ' • ${offer.ownerName}'}',
                          meta: _formatWonDate(offer.updatedAt),
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ],
    );
  }
}

class _CustomerHistoryPanel extends StatelessWidget {
  const _CustomerHistoryPanel({
    required this.title,
    required this.width,
    required this.children,
  });

  final String title;
  final double width;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: VeloPrimePalette.lineStrong),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: VeloPrimePalette.ink)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _CustomerHistoryLine extends StatelessWidget {
  const _CustomerHistoryLine({
    required this.title,
    required this.subtitle,
    required this.meta,
  });

  final String title;
  final String subtitle;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: VeloPrimePalette.ink,
                  height: 1.3)),
          const SizedBox(height: 2),
          Text(subtitle,
              style:
                  const TextStyle(color: VeloPrimePalette.muted, height: 1.5)),
          const SizedBox(height: 2),
          Text(meta,
              style:
                  const TextStyle(fontSize: 12, color: VeloPrimePalette.muted)),
        ],
      ),
    );
  }
}

String _formatWonDate(String? value) {
  if (value == null || value.isEmpty) {
    return 'Brak daty';
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  return _customerDateFormat.format(parsed);
}

String _formatOfferStatus(String status) {
  switch (status.toUpperCase()) {
    case 'APPROVED':
      return 'Zaakceptowana';
    case 'SENT':
      return 'Wysłana';
    case 'REJECTED':
      return 'Odrzucona';
    case 'EXPIRED':
      return 'Wygasła';
    default:
      return status;
  }
}

String _formatUserRole(String role) {
  switch (role.toUpperCase()) {
    case 'ADMIN':
      return 'Administrator';
    case 'DIRECTOR':
      return 'Dyrektor';
    case 'MANAGER':
      return 'Manager';
    case 'SALES':
      return 'Handlowiec';
    default:
      return role;
  }
}
