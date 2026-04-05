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
  final Future<void> Function(OfferWorkspaceLaunchRequest request) onOpenOfferWorkspaceForLead;

  @override
  State<CustomersHomePage> createState() => _CustomersHomePageState();
}

class _CustomersHomePageState extends State<CustomersHomePage> {
  final TextEditingController _searchController = TextEditingController();
  LeadsOverview? _overview;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = _overview == null;
      _error = null;
    });

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
    ManagedCustomerWorkspace? initialWorkspace;
    var customerId = lead.customerId?.trim() ?? '';

    if (customerId.isEmpty) {
      try {
        initialWorkspace = await widget.customersRepository.createCustomerFromLead(lead.id);
        customerId = initialWorkspace.customer.id;
      } catch (error) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
        return;
      }
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
        initialWorkspace: initialWorkspace,
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

  List<ManagedLeadSummary> _customerLeads(LeadsOverview overview) {
    final wonStageIds = overview.stages.where((stage) => stage.kind == 'WON').map((stage) => stage.id).toSet();
    final query = _searchController.text.trim().toLowerCase();

    return overview.leads.where((lead) {
      if (!wonStageIds.contains(lead.stageId)) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final acceptedOffer = lead.linkedOffers.where((offer) => offer.id == lead.acceptedOfferId).firstOrNull;
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

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    final customers = overview == null ? const <ManagedLeadSummary>[] : _customerLeads(overview);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VeloPrimeShell(
        decorateBackground: false,
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VeloPrimeWorkspacePanel(
                tint: VeloPrimePalette.olive,
                radius: 30,
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const VeloPrimeSectionEyebrow(label: 'Klienci', color: VeloPrimePalette.olive),
                    const SizedBox(height: 12),
                    const Text(
                      'Wygrane leady zamienione w aktywnych klientów.',
                      style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink, height: 1.04),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.session.role == 'ADMIN'
                          ? 'To widok operacyjny po sprzedaży: zaakceptowana oferta, komplet dokumentów i odpowiedzialny opiekun. Administrator może wejść dalej do karty klienta i kontynuować obsługę.'
                          : 'To widok operacyjny po sprzedaży: zaakceptowana oferta, komplet dokumentów i odpowiedzialny opiekun. Dla ról nieadministracyjnych moduł pozostaje przeglądowy.',
                      style: const TextStyle(color: VeloPrimePalette.muted, height: 1.6),
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        VeloPrimeMetricCard(label: 'Klienci aktywni', value: '${customers.length}', accentColor: VeloPrimePalette.olive),
                        VeloPrimeMetricCard(
                          label: 'Z dokumentami',
                          value: '${customers.where((entry) => entry.attachmentCount > 0).length}',
                          accentColor: VeloPrimePalette.sea,
                        ),
                        VeloPrimeMetricCard(
                          label: 'Bez wybranej oferty',
                          value: '${customers.where((entry) => (entry.acceptedOfferId ?? '').isEmpty).length}',
                          accentColor: VeloPrimePalette.bronzeDeep,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: veloPrimeInputDecoration('Szukaj klienta, opiekuna, modelu albo numeru oferty').copyWith(
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
              else if ((_error ?? '').isNotEmpty)
                VeloPrimeWorkspacePanel(
                  tint: VeloPrimePalette.rose,
                  radius: 28,
                  child: Text(_error!, style: const TextStyle(color: VeloPrimePalette.ink)),
                )
              else if (customers.isEmpty)
                const VeloPrimeWorkspacePanel(
                  tint: VeloPrimePalette.olive,
                  radius: 28,
                  child: Text(
                    'Brak klientów wynikających z etapu Wygrane. Gdy lead zostanie wygrany i dostanie zaakceptowaną ofertę, pojawi się tutaj automatycznie.',
                    style: TextStyle(color: VeloPrimePalette.muted, height: 1.6),
                  ),
                )
              else
                Column(
                  children: customers
                      .map(
                        (lead) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _CustomerLeadCard(
                            lead: lead,
                            canEdit: widget.session.role == 'ADMIN',
                            onOpenLead: () => _openLeadWorkspace(lead),
                            onOpenCustomer: widget.session.role == 'ADMIN' ? () => _openCustomerCard(lead) : null,
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerLeadCard extends StatelessWidget {
  const _CustomerLeadCard({
    required this.lead,
    required this.canEdit,
    required this.onOpenLead,
    required this.onOpenCustomer,
  });

  final ManagedLeadSummary lead;
  final bool canEdit;
  final VoidCallback onOpenLead;
  final VoidCallback? onOpenCustomer;

  @override
  Widget build(BuildContext context) {
    final acceptedOffer = lead.linkedOffers.where((offer) => offer.id == lead.acceptedOfferId).firstOrNull;

    return VeloPrimeWorkspacePanel(
      tint: VeloPrimePalette.olive,
      radius: 28,
      padding: const EdgeInsets.all(22),
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
                    Text(lead.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink, height: 1.08)),
                    const SizedBox(height: 8),
                    Text(
                      [lead.interestedModel, lead.region, lead.salespersonName].whereType<String>().where((value) => value.trim().isNotEmpty).join(' • '),
                      style: const TextStyle(color: VeloPrimePalette.muted, height: 1.5),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (canEdit && onOpenCustomer != null)
                    FilledButton.tonalIcon(
                      onPressed: onOpenCustomer,
                      icon: Icon((lead.customerId ?? '').isEmpty ? Icons.person_add_alt_1_outlined : Icons.badge_outlined),
                      label: Text((lead.customerId ?? '').isEmpty ? 'Utwórz kartę klienta' : 'Karta klienta'),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: onOpenLead,
                    icon: Icon(canEdit ? Icons.open_in_new_rounded : Icons.visibility_outlined),
                    label: Text(canEdit ? 'Otwórz lead' : 'Podgląd klienta'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if ((lead.phone ?? '').isNotEmpty) VeloPrimeBadge(label: 'Telefon', value: lead.phone!),
              if ((lead.email ?? '').isNotEmpty) VeloPrimeBadge(label: 'Email', value: lead.email!),
              VeloPrimeBadge(label: 'Karta klienta', value: (lead.customerId ?? '').isEmpty ? 'Brak' : 'Aktywna'),
              VeloPrimeBadge(label: 'Dokumenty', value: '${lead.attachmentCount}'),
              VeloPrimeBadge(label: 'Finalizacja', value: _formatWonDate(lead.acceptedAt ?? lead.updatedAt)),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFF7FAF2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: VeloPrimePalette.lineStrong),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Zaakceptowana oferta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: VeloPrimePalette.muted)),
                const SizedBox(height: 8),
                if (acceptedOffer == null)
                  const Text('Oferta nie została jeszcze poprawnie zapisana na leadzie.', style: TextStyle(color: VeloPrimePalette.muted))
                else ...[
                  Text('${acceptedOffer.number} • ${acceptedOffer.title}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink)),
                  const SizedBox(height: 6),
                  Text('Status: ${_formatOfferStatus(acceptedOffer.status)} • Aktualizacja: ${_formatWonDate(acceptedOffer.updatedAt)}', style: const TextStyle(color: VeloPrimePalette.muted, height: 1.5)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerAdminDialog extends StatefulWidget {
  const _CustomerAdminDialog({
    required this.repository,
    required this.customerId,
    required this.lead,
    this.initialWorkspace,
  });

  final CustomersRepository repository;
  final String customerId;
  final ManagedLeadSummary lead;
  final ManagedCustomerWorkspace? initialWorkspace;

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
      final workspace = widget.initialWorkspace ?? await widget.repository.fetchCustomerWorkspace(widget.customerId);

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
      final updated = await widget.repository.updateCustomer(widget.customerId, {
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
    final ownerOptions = workspace?.ownerOptions ?? const <ManagedCustomerOwnerOption>[];

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
                          const VeloPrimeSectionEyebrow(label: 'Karta klienta', color: VeloPrimePalette.olive),
                          const SizedBox(height: 10),
                          Text(
                            widget.lead.fullName,
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink, height: 1.05),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Edycja zapisuje prawdziwy rekord klienta i synchronizuje podstawowe dane kontaktowe z powiązanymi leadami.',
                            style: TextStyle(color: VeloPrimePalette.muted, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
                else if ((_error ?? '').isNotEmpty && customer == null)
                  Text(_error!, style: const TextStyle(color: VeloPrimePalette.rose, height: 1.6))
                else ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      VeloPrimeBadge(label: 'Leady', value: '${customer?.leadCount ?? 0}'),
                      VeloPrimeBadge(label: 'Oferty', value: '${customer?.offerCount ?? 0}'),
                      if ((customer?.ownerName ?? '').isNotEmpty) VeloPrimeBadge(label: 'Właściciel', value: customer!.ownerName!),
                      VeloPrimeBadge(label: 'Aktualizacja', value: _formatWonDate(customer?.updatedAt)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedOwnerId,
                    decoration: veloPrimeInputDecoration('Właściciel klienta'),
                    items: [
                      const DropdownMenuItem<String>(value: '', child: Text('Bez przypisanego właściciela')),
                      ...ownerOptions.map(
                        (option) => DropdownMenuItem<String>(
                          value: option.id,
                          child: Text('${option.fullName} • ${_formatUserRole(option.role)}'),
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
                          decoration: veloPrimeInputDecoration('Imię i nazwisko'),
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
                    decoration: veloPrimeInputDecoration('Notatki klienta niezależne od leada'),
                  ),
                  const SizedBox(height: 18),
                  _CustomerHistorySection(
                    leads: workspace?.relatedLeads ?? const <ManagedCustomerLeadHistoryItem>[],
                    offers: workspace?.relatedOffers ?? const <ManagedCustomerOfferHistoryItem>[],
                  ),
                  if ((_error ?? '').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(_error!, style: const TextStyle(color: VeloPrimePalette.rose, height: 1.6)),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        child: const Text('Zamknij'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2.2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_isSaving ? 'Zapisywanie...' : 'Zapisz kartę klienta'),
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink),
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
                  ? const [Text('Brak leadów w historii klienta.', style: TextStyle(color: VeloPrimePalette.muted, height: 1.6))]
                  : leads
                      .map(
                        (lead) => _CustomerHistoryLine(
                          title: lead.fullName,
                          subtitle: '${lead.stageLabel}${(lead.salespersonName ?? '').isEmpty ? '' : ' • ${lead.salespersonName}'}',
                          meta: _formatWonDate(lead.acceptedAt ?? lead.updatedAt),
                        ),
                      )
                      .toList(),
            ),
            _CustomerHistoryPanel(
              title: 'Powiązane oferty',
              width: 320,
              children: offers.isEmpty
                  ? const [Text('Brak ofert w historii klienta.', style: TextStyle(color: VeloPrimePalette.muted, height: 1.6))]
                  : offers
                      .map(
                        (offer) => _CustomerHistoryLine(
                          title: '${offer.number} • ${offer.title}',
                          subtitle: '${_formatOfferStatus(offer.status)}${(offer.ownerName ?? '').isEmpty ? '' : ' • ${offer.ownerName}'}',
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
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink)),
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: VeloPrimePalette.ink, height: 1.3)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: VeloPrimePalette.muted, height: 1.5)),
          const SizedBox(height: 2),
          Text(meta, style: const TextStyle(fontSize: 12, color: VeloPrimePalette.muted)),
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