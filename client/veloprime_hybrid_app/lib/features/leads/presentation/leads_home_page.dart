import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/presentation/veloprime_ui.dart';
import '../../bootstrap/models/bootstrap_payload.dart';
import '../data/leads_repository.dart';
import '../models/lead_models.dart';
import '../../offers/data/offers_repository.dart';
import '../../offers/presentation/offers_home_page.dart';
import '../../reminders/data/reminders_repository.dart';
import 'lead_create_page.dart';
import 'lead_detail_page.dart';

class LeadsHomePage extends StatefulWidget {
  const LeadsHomePage({
    super.key,
    required this.session,
    required this.bootstrap,
    required this.repository,
    required this.offersRepository,
    required this.remindersRepository,
    required this.onRemindersChanged,
    required this.onRefreshBootstrap,
    required this.onOpenOfferWorkspaceForLead,
  });

  final SessionInfo session;
  final BootstrapPayload bootstrap;
  final LeadsRepository repository;
  final OffersRepository offersRepository;
  final RemindersRepository remindersRepository;
  final Future<void> Function() onRemindersChanged;
  final Future<void> Function() onRefreshBootstrap;
  final Future<void> Function(OfferWorkspaceLaunchRequest request)
      onOpenOfferWorkspaceForLead;

  @override
  State<LeadsHomePage> createState() => _LeadsHomePageState();
}

class _LeadsHomePageState extends State<LeadsHomePage> {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  static const String _allSalespeople = '__ALL__';
  static const String _unassignedSalespeople = '__UNASSIGNED__';
  static const String _allStageKinds = '__ALL__';

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _kanbanScrollController = ScrollController();
  LeadsOverview? _overview;
  bool _isLoading = true;
  String? _movingLeadId;
  String _selectedSalespersonFilter = _allSalespeople;
  String _selectedStageKindFilter = _allStageKinds;
  bool _onlyWithOffers = false;
  String? _error;

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

  Future<void> _openLead(String leadId) async {
    try {
      final cachedPayload =
          await widget.repository.readCachedLeadDetail(leadId);
      final payload =
          cachedPayload ?? await widget.repository.fetchLeadDetail(leadId);

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
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _openCreateLead(LeadsOverview overview) async {
    final payload = await showDialog<LeadDetailPayload>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (_) => LeadCreatePage(
        session: widget.session,
        repository: widget.repository,
        stages: overview.stages,
        salespeople: overview.salespeople,
        modal: true,
      ),
    );

    if (payload == null || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    try {
      await widget.onRefreshBootstrap();
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Lead zostal utworzony, ale nie udalo sie jeszcze odswiezyc list klientow w ofertach. $error',
            ),
          ),
        );
      }
    }

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

    try {
      await widget.onRefreshBootstrap();
    } catch (_) {
      // Leave the lead workspace responsive even if the shared bootstrap refresh fails.
    }

    await _load();
  }

  Future<void> _moveLead(String leadId, String stageId) async {
    final overview = _overview;
    if (overview == null) {
      return;
    }

    final existing =
        overview.leads.where((lead) => lead.id == leadId).firstOrNull;
    if (existing == null || existing.stageId == stageId) {
      return;
    }

    final targetStage = overview.stages.where((stage) => stage.id == stageId).firstOrNull;
    final acceptedOfferId = existing.acceptedOfferId?.trim();

    if (targetStage?.kind == 'WON') {
      if (existing.linkedOffers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Przed przeniesieniem do Wygrane przypnij do leada ofertę.')),
        );
        return;
      }

      if ((acceptedOfferId ?? '').isEmpty || existing.attachmentCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aby przenieść do Wygrane, otwórz leada, dodaj dokument i użyj przy ofercie akcji Ustaw jako wygraną.'),
          ),
        );
        return;
      }
    }

    final now = DateTime.now().toIso8601String();
    final nextOverview = LeadsOverview(
      leads: overview.leads
          .map((lead) => lead.id == leadId
              ? lead.copyWith(stageId: stageId, updatedAt: now)
              : lead)
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
      await widget.repository.moveLeadToStage(
        leadId: leadId,
        stageId: stageId,
        acceptedOfferId: targetStage?.kind == 'WON' ? acceptedOfferId : null,
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

  List<ManagedLeadSummary> _filterLeads(LeadsOverview overview) {
    final query = _searchController.text.trim().toLowerCase();

    return overview.leads.where((lead) {
      if (_selectedStageKindFilter != _allStageKinds) {
        final kind = _stageKind(overview, lead.stageId);
        if (kind != _selectedStageKindFilter) {
          return false;
        }
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

      if (_onlyWithOffers && lead.linkedOffers.isEmpty) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final fields = [
        lead.fullName,
        lead.email,
        lead.phone,
        lead.interestedModel,
        lead.region,
        lead.salespersonName,
        lead.source,
        lead.message,
      ];

      return fields.any((field) => (field ?? '').toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    final filteredLeads = overview == null
        ? const <ManagedLeadSummary>[]
        : _filterLeads(overview);
    final openCount = overview == null
        ? 0
        : filteredLeads
            .where((lead) => _stageKind(overview, lead.stageId) == 'OPEN')
            .length;
    final wonCount = overview == null
        ? 0
        : filteredLeads
            .where((lead) => _stageKind(overview, lead.stageId) == 'WON')
            .length;
    final lostCount = overview == null
        ? 0
        : filteredLeads
            .where((lead) => _stageKind(overview, lead.stageId) == 'LOST')
            .length;
    final holdCount = overview == null
        ? 0
        : filteredLeads
            .where((lead) => _stageKind(overview, lead.stageId) == 'HOLD')
            .length;
    final offersCount = filteredLeads.fold<int>(
        0, (count, lead) => count + lead.linkedOffers.length);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VeloPrimeShell(
        decorateBackground: false,
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
        child: _isLoading
            ? const VeloPrimeWorkspaceState(
                tint: Color(0xFF4E6EF2),
                eyebrow: 'Leady',
                title: 'Ładujemy pipeline leadów',
                message: 'Przygotowujemy kolumny, filtry i aktywne rekordy.',
                isLoading: true,
              )
            : _error != null
                ? VeloPrimeWorkspaceState(
                    tint: const Color(0xFFC05621),
                    eyebrow: 'Leady',
                    title: 'Nie udało się załadować leadów',
                    message: _error!,
                    icon: Icons.warning_amber_rounded,
                  )
                : overview == null
                    ? const VeloPrimeWorkspaceState(
                        tint: Color(0xFF4E6EF2),
                        eyebrow: 'Leady',
                        title: 'Brak leadów',
                        message:
                            'Po synchronizacji lub dodaniu pierwszego kontaktu pipeline pojawi się tutaj.',
                        icon: Icons.inbox_outlined,
                      )
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.fromLTRB(22, 22, 22, 20),
                              decoration: veloPrimeWorkspacePanelDecoration(
                                tint: const Color(0xFF4E6EF2),
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
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            VeloPrimeSectionEyebrow(
                                                label: 'Filtry operacyjne'),
                                            SizedBox(height: 12),
                                            Text(
                                              'Zawęź pipeline do właściwego wycinka pracy.',
                                              style: TextStyle(
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.08,
                                                  color: Color(0xFF23315C)),
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              'Ustaw zakres widoku, a potem przejdź do konkretnego klienta lub etapu sprzedaży.',
                                              style: TextStyle(
                                                  color: Color(0xFF66729C),
                                                  height: 1.55,
                                                  fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 18),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed:
                                                _isLoading ? null : _load,
                                            icon: const Icon(Icons.refresh),
                                            label: const Text('Odśwież'),
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 18,
                                                      vertical: 18),
                                              backgroundColor: Colors.white
                                                  .withValues(alpha: 0.68),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999)),
                                            ),
                                          ),
                                          FilledButton.icon(
                                            onPressed: _isLoading
                                                ? null
                                                : () =>
                                                    _openCreateLead(overview),
                                            icon: const Icon(Icons.add),
                                            label: const Text('Nowy lead'),
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF245CC6),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 22,
                                                      vertical: 18),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      _OverviewChip(
                                          label: 'Otwarte $openCount',
                                          tint: const Color(0xFF2B63D6)),
                                      _OverviewChip(
                                          label: 'Wygrane $wonCount',
                                          tint: VeloPrimePalette.sea),
                                      _OverviewChip(
                                          label: 'Utracone $lostCount',
                                          tint: const Color(0xFFB26B5B)),
                                      _OverviewChip(
                                          label: 'Wstrzymane $holdCount',
                                          tint: const Color(0xFF667085)),
                                      _OverviewChip(
                                          label: 'Oferty $offersCount',
                                          tint: const Color(0xFF4E6EF2)),
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
                                        child: _FilterDropdownField<String>(
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
                                      SizedBox(
                                        width: 240,
                                        child: _FilterDropdownField<String>(
                                          label: 'Typ etapu',
                                          initialValue:
                                              _selectedStageKindFilter,
                                          items: const [
                                            DropdownMenuItem<String>(
                                                value: _allStageKinds,
                                                child: Text('Wszystkie etapy')),
                                            DropdownMenuItem<String>(
                                                value: 'OPEN',
                                                child: Text('Aktywne')),
                                            DropdownMenuItem<String>(
                                                value: 'WON',
                                                child: Text('Wygrane')),
                                            DropdownMenuItem<String>(
                                                value: 'LOST',
                                                child: Text('Utracone')),
                                            DropdownMenuItem<String>(
                                                value: 'HOLD',
                                                child: Text('Wstrzymane')),
                                          ],
                                          onChanged: (value) {
                                            if (value == null) {
                                              return;
                                            }
                                            setState(() {
                                              _selectedStageKindFilter = value;
                                            });
                                          },
                                        ),
                                      ),
                                      FilterChip(
                                        selected: _onlyWithOffers,
                                        label: const Text('Tylko z ofertami'),
                                        onSelected: (value) {
                                          setState(() {
                                            _onlyWithOffers = value;
                                          });
                                        },
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.92),
                                        selectedColor: const Color(0xFFE9F0FF),
                                        side: const BorderSide(
                                            color: Color(0x1F3159B9)),
                                        labelStyle: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF24418A)),
                                      ),
                                      if (_selectedSalespersonFilter !=
                                              _allSalespeople ||
                                          _selectedStageKindFilter !=
                                              _allStageKinds ||
                                          _onlyWithOffers ||
                                          _searchController.text.isNotEmpty)
                                        TextButton.icon(
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _selectedSalespersonFilter =
                                                  _allSalespeople;
                                              _selectedStageKindFilter =
                                                  _allStageKinds;
                                              _onlyWithOffers = false;
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
                                                  'Klient, kontakt, model, region lub opiekun',
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
                                          '${overview.stages.length} etapów • ${filteredLeads.length}',
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
                                tint: const Color(0xFF245CC6),
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
                                                label: 'Pipeline'),
                                            SizedBox(height: 8),
                                            Text(
                                              'Przegląd etapów i ruch leadów.',
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
                                          'Kanban operacyjny',
                                          style: TextStyle(
                                              color: Color(0xFF67739D),
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
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
                                          children: overview.stages
                                              .map(
                                                (stage) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 18),
                                                  child: _KanbanStageColumn(
                                                    stage: stage,
                                                    leads: filteredLeads
                                                        .where((lead) =>
                                                            lead.stageId ==
                                                            stage.id)
                                                        .toList(),
                                                    dateFormat: _dateFormat,
                                                    movingLeadId: _movingLeadId,
                                                    onOpenLead: _openLead,
                                                    onMoveLead: _moveLead,
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

String _stageKind(LeadsOverview overview, String stageId) {
  return overview.stages
          .where((stage) => stage.id == stageId)
          .firstOrNull
          ?.kind ??
      'OPEN';
}

String _stageKindLabel(String kind) {
  switch (kind) {
    case 'WON':
      return 'Wygrane';
    case 'LOST':
      return 'Utracone';
    case 'HOLD':
      return 'Wstrzymane';
    default:
      return 'Otwarte';
  }
}

class _KanbanStageColumn extends StatefulWidget {
  const _KanbanStageColumn({
    required this.stage,
    required this.leads,
    required this.dateFormat,
    required this.movingLeadId,
    required this.onOpenLead,
    required this.onMoveLead,
  });

  final LeadStageInfo stage;
  final List<ManagedLeadSummary> leads;
  final DateFormat dateFormat;
  final String? movingLeadId;
  final ValueChanged<String> onOpenLead;
  final Future<void> Function(String leadId, String stageId) onMoveLead;

  @override
  State<_KanbanStageColumn> createState() => _KanbanStageColumnState();
}

class _KanbanStageColumnState extends State<_KanbanStageColumn> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final stageColor = _parseColor(widget.stage.color);
    final assignedCount = widget.leads
        .where((lead) => (lead.salespersonName ?? '').isNotEmpty)
        .length;
    final offersCount = widget.leads
        .fold<int>(0, (total, lead) => total + lead.linkedOffers.length);

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        setState(() {
          _isHovering = true;
        });
        return true;
      },
      onLeave: (_) {
        setState(() {
          _isHovering = false;
        });
      },
      onAcceptWithDetails: (details) async {
        setState(() {
          _isHovering = false;
        });
        await widget.onMoveLead(details.data, widget.stage.id);
      },
      builder: (context, candidateData, rejectedData) {
        final stageSurface = _stageSurface(stageColor);
        final stageHeaderSurface = _stageHeaderSurface(stageColor);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 336,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: stageSurface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: _isHovering
                  ? VeloPrimePalette.bronze.withValues(alpha: 0.28)
                  : stageColor.withValues(alpha: 0.16),
              width: _isHovering ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1F1F1F)
                    .withValues(alpha: _isHovering ? 0.08 : 0.045),
                blurRadius: _isHovering ? 30 : 22,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  gradient: stageHeaderSurface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: stageColor.withValues(alpha: 0.14)),
                ),
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
                              Text(
                                widget.stage.name,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: VeloPrimePalette.ink),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.leads.length} leadów',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6F6553),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.7),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                        color:
                                            stageColor.withValues(alpha: 0.28)),
                                  ),
                                  child: Text(
                                    _stageKindLabel(widget.stage.kind),
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: stageColor,
                                        letterSpacing: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${widget.leads.length}',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: VeloPrimePalette.ink,
                          height: 1),
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
                      label: 'Przypisane',
                      value: '$assignedCount/${widget.leads.length}',
                      accentColor: stageColor),
                  _StageStatPill(
                      label: 'Oferty',
                      value: '$offersCount',
                      accentColor: stageColor),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: widget.leads.isEmpty
                    ? Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 32),
                        decoration: BoxDecoration(
                          color: _isHovering
                              ? VeloPrimePalette.bronze.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: _isHovering
                                ? VeloPrimePalette.bronze
                                    .withValues(alpha: 0.36)
                                : const Color(0xFFE7DFD0),
                          ),
                        ),
                        child: Text(
                          _isHovering
                              ? 'Upuść leada, aby przenieść go do tego etapu.'
                              : 'Miejsce na pierwszego leada.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8A826F),
                              height: 1.45),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: widget.leads
                              .map(
                                (lead) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _LeadKanbanCard(
                                    lead: lead,
                                    dateFormat: widget.dateFormat,
                                    isMoving: widget.movingLeadId == lead.id,
                                    onOpenLead: widget.onOpenLead,
                                    stageColor: stageColor,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LeadKanbanCard extends StatefulWidget {
  const _LeadKanbanCard({
    required this.lead,
    required this.dateFormat,
    required this.isMoving,
    required this.onOpenLead,
    required this.stageColor,
  });

  final ManagedLeadSummary lead;
  final DateFormat dateFormat;
  final bool isMoving;
  final ValueChanged<String> onOpenLead;
  final Color stageColor;

  @override
  State<_LeadKanbanCard> createState() => _LeadKanbanCardState();
}

class _LeadKanbanCardState extends State<_LeadKanbanCard> {
  bool _isPointerHovering = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;
    final hasOwner = (lead.salespersonName ?? '').isNotEmpty;
    final cardGradient = _leadCardGradient(widget.stageColor, hasOwner);
    final metaGradient = _leadMetaGradient(widget.stageColor);
    final shortActivity = _formatCompactDate(lead.updatedAt) ?? '-';
    final nextAction = _formatActionDate(lead.nextActionAt);
    final primaryContact =
        lead.phone ?? lead.email ?? 'Brak danych kontaktowych';
    final primaryActionLabel = lead.linkedOffers.isNotEmpty
        ? 'Oferty ${lead.linkedOffers.length}'
        : 'Więcej';

    Widget buildCard({bool forFeedback = false}) {
      return Opacity(
        opacity: widget.isMoving ? 0.45 : 1,
        child: AnimatedScale(
          scale: _isDragging
              ? 1.02
              : _isPointerHovering
                  ? 1.012
                  : 1,
          duration: const Duration(milliseconds: 140),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            transform: Matrix4.translationValues(
                0, _isPointerHovering && !forFeedback ? -2 : 0, 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap:
                    widget.isMoving ? null : () => widget.onOpenLead(lead.id),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                  decoration: BoxDecoration(
                    gradient: cardGradient,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: hasOwner
                            ? const Color(0xCCDCE3F0)
                            : widget.stageColor.withValues(alpha: 0.22)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1F1F1F)
                            .withValues(alpha: hasOwner ? 0.05 : 0.07),
                        blurRadius: _isDragging
                            ? 32
                            : hasOwner
                                ? 24
                                : 28,
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
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _LeadTinyPill(
                                        label: lead.source,
                                        gradient: metaGradient),
                                    if ((lead.region ?? '').isNotEmpty)
                                      _LeadTinyPill(
                                          label: lead.region!,
                                          gradient: metaGradient),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
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
                                  shortActivity,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: widget.stageColor),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Icon(Icons.drag_indicator,
                                  color: Color(0xFFB09A63), size: 16),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        lead.interestedModel ?? 'Model nieokreślony',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF43537B)),
                      ),
                      const SizedBox(height: 12),
                      _LeadInfoStrip(
                        icon: lead.phone != null
                            ? Icons.call_outlined
                            : Icons.alternate_email,
                        label: primaryContact,
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
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _LeadStatusPill(
                            text: 'Opiekun: ${lead.salespersonName ?? 'Brak'}',
                            accent: hasOwner
                                ? const Color(0xFF5F5A4F)
                                : VeloPrimePalette.bronzeDeep,
                            background: hasOwner
                                ? Colors.white
                                : const Color(0xFFFFFAF0),
                            borderColor: hasOwner
                                ? const Color(0xFFE7DFD0)
                                : const Color(0xFFEFE0BA),
                          ),
                          if (lead.linkedOffers.isNotEmpty)
                            _LeadStatusPill(
                              text: 'Oferty: ${lead.linkedOffers.length}',
                              accent: const Color(0xFF355F99),
                              background:
                                  widget.stageColor.withValues(alpha: 0.12),
                              borderColor:
                                  widget.stageColor.withValues(alpha: 0.3),
                            ),
                          if (lead.detailCount > 0)
                            _LeadStatusPill(
                              text: 'Wpisy: ${lead.detailCount}',
                              accent: const Color(0xFF5F5A4F),
                              background: Colors.white,
                              borderColor:
                                  widget.stageColor.withValues(alpha: 0.22),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _LeadInfoStrip(
                              icon: Icons.person_outline,
                              label:
                                  'Opiekun: ${lead.salespersonName ?? 'Brak'}',
                              accent: widget.stageColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color.alphaBlend(
                                      widget.stageColor.withValues(alpha: 0.22),
                                      Colors.white),
                                  Color.alphaBlend(
                                      widget.stageColor.withValues(alpha: 0.44),
                                      Colors.white),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: widget.stageColor
                                      .withValues(alpha: 0.26)),
                            ),
                            child: Text(
                              primaryActionLabel,
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: widget.stageColor),
                            ),
                          ),
                        ],
                      ),
                      if ((lead.message ?? '').isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _LeadMessagePanel(
                          message: lead.message!,
                          accent: widget.stageColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final card = MouseRegion(
      onEnter: (_) => setState(() => _isPointerHovering = true),
      onExit: (_) => setState(() => _isPointerHovering = false),
      cursor: SystemMouseCursors.grab,
      child: buildCard(),
    );

    return Draggable<String>(
      data: lead.id,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      maxSimultaneousDrags: widget.isMoving ? 0 : 1,
      onDragStarted: () => setState(() => _isDragging = true),
      onDragEnd: (_) => setState(() => _isDragging = false),
      onDraggableCanceled: (_, __) => setState(() => _isDragging = false),
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

LinearGradient _stageSurface(Color stageColor) {
  return LinearGradient(
    colors: [
      Color.alphaBlend(stageColor.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.76)),
      Color.alphaBlend(
          stageColor.withValues(alpha: 0.05), const Color(0xB8F9F7FC)),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

LinearGradient _stageHeaderSurface(Color stageColor) {
  return LinearGradient(
    colors: [
      Color.alphaBlend(stageColor.withValues(alpha: 0.24),
          Colors.white.withValues(alpha: 0.86)),
      Color.alphaBlend(
          stageColor.withValues(alpha: 0.08), const Color(0xCCFFFCF8)),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

LinearGradient _leadCardGradient(Color stageColor, bool hasOwner) {
  return LinearGradient(
    colors: hasOwner
        ? [
            Colors.white.withValues(alpha: 0.92),
            Color.alphaBlend(
                stageColor.withValues(alpha: 0.04), const Color(0xE8FFFCF8)),
          ]
        : [
            Color.alphaBlend(
                stageColor.withValues(alpha: 0.1), const Color(0xE8FFFBF3)),
            Colors.white.withValues(alpha: 0.92),
          ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

LinearGradient _leadMetaGradient(Color stageColor) {
  return LinearGradient(
    colors: [
      Colors.white.withValues(alpha: 0.74),
      Color.alphaBlend(stageColor.withValues(alpha: 0.04),
          Colors.white.withValues(alpha: 0.7)),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

String? _formatCompactDate(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  return DateFormat('dd.MM HH:mm').format(parsed);
}

String? _formatActionDate(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  return DateFormat('dd.MM.yyyy • HH:mm').format(parsed);
}

class _LeadTinyPill extends StatelessWidget {
  const _LeadTinyPill({required this.label, required this.gradient});

  final String label;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VeloPrimePalette.lineStrong),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 9,
            letterSpacing: 0.8,
            color: Color(0xFF6A604D),
            fontWeight: FontWeight.w800),
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
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.76),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 17, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 9.8,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5F5A4F)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 11.6,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF22315C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadMessagePanel extends StatelessWidget {
  const _LeadMessagePanel({required this.message, required this.accent});

  final String message;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notatka',
            style: TextStyle(
                fontSize: 9.8,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w800,
                color: accent),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 11.2, color: Color(0xFF666666), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _OverviewChip extends StatelessWidget {
  const _OverviewChip({
    required this.label,
    required this.tint,
  });

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Color.alphaBlend(tint.withValues(alpha: 0.08), Colors.white),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: tint,
            letterSpacing: 0.4),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 10,
            letterSpacing: 0.5,
            color: accent,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

Color _parseColor(String value) {
  final normalized = value.replaceFirst('#', '');
  final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
  return Color(int.tryParse(hex, radix: 16) ?? 0xFFD1D5DB);
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF6B6B6B),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  color: VeloPrimePalette.ink)),
        ],
      ),
    );
  }
}

class _FilterDropdownField<T> extends StatelessWidget {
  const _FilterDropdownField({
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
      isExpanded: true,
      items: items,
      onChanged: onChanged,
      dropdownColor: const Color(0xFFFFFEFB),
      borderRadius: BorderRadius.circular(22),
      menuMaxHeight: 320,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: VeloPrimePalette.bronzeDeep),
      style: const TextStyle(
        color: VeloPrimePalette.ink,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: veloPrimeInputDecoration(label).copyWith(
        fillColor: Colors.white.withValues(alpha: 0.8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0x33D6C5A0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0x66D4A84F), width: 1.4),
        ),
      ),
    );
  }
}
