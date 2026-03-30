import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/presentation/veloprime_ui.dart';
import '../../bootstrap/models/bootstrap_payload.dart';
import '../data/leads_repository.dart';
import '../models/lead_models.dart';
import '../../offers/data/offers_repository.dart';
import '../../offers/presentation/offers_home_page.dart';

class LeadDetailPage extends StatefulWidget {
  const LeadDetailPage({
    super.key,
    required this.session,
    required this.bootstrap,
    required this.repository,
    required this.offersRepository,
    required this.initialPayload,
    required this.onOpenOfferWorkspaceForLead,
  });

  final SessionInfo session;
  final BootstrapPayload bootstrap;
  final LeadsRepository repository;
  final OffersRepository offersRepository;
  final LeadDetailPayload initialPayload;
  final Future<void> Function(OfferWorkspaceLaunchRequest request) onOpenOfferWorkspaceForLead;

  @override
  State<LeadDetailPage> createState() => _LeadDetailPageState();
}

class _LeadDetailPageState extends State<LeadDetailPage> {
  static final DateFormat _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  late LeadDetailPayload _payload;
  bool _isUpdatingStage = false;
  bool _isAddingEntry = false;
  bool _isCreatingOffer = false;

  @override
  void initState() {
    super.initState();
    _payload = widget.initialPayload;
  }

  Future<void> _moveStage(String stageId) async {
    setState(() {
      _isUpdatingStage = true;
    });

    try {
      final nextPayload = await widget.repository.moveLeadToStage(
        leadId: _payload.lead.id,
        stageId: stageId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _payload = nextPayload;
      });
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStage = false;
        });
      }
    }
  }

  Future<void> _addEntry({required String kind}) async {
    final result = await showDialog<_LeadEntryInputResult>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (context) => _LeadEntryDialog(kind: kind),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _isAddingEntry = true;
    });

    try {
      final nextPayload = await widget.repository.addDetailEntry(
        leadId: _payload.lead.id,
        kind: kind,
        label: result.label,
        value: result.value,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _payload = nextPayload;
      });
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isAddingEntry = false;
        });
      }
    }
  }

  Future<void> _reloadLead() async {
    final nextPayload = await widget.repository.fetchLeadDetail(_payload.lead.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _payload = nextPayload;
    });
  }

  Future<void> _openOffer(String offerId) async {
    await widget.onOpenOfferWorkspaceForLead(
      OfferWorkspaceLaunchRequest(
        leadId: _payload.lead.id,
        leadName: _payload.lead.fullName,
        offerId: offerId,
      ),
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  Future<void> _createOfferForLead() async {
    setState(() {
      _isCreatingOffer = true;
    });

    try {
      await widget.onOpenOfferWorkspaceForLead(
        OfferWorkspaceLaunchRequest(
          leadId: _payload.lead.id,
          leadName: _payload.lead.fullName,
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingOffer = false;
        });
      }
    }
  }

  List<OfferLeadOption> _buildLeadOptions() {
    final currentLead = OfferLeadOption(
      id: _payload.lead.id,
      label: _payload.lead.fullName,
      modelName: _payload.lead.interestedModel,
      contact: _payload.lead.phone ?? _payload.lead.email,
      ownerName: _payload.lead.salespersonName,
    );

    final others = widget.bootstrap.leadOptions.where((lead) => lead.id != currentLead.id);
    return [currentLead, ...others];
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lead = _payload.lead;
    final stage = _payload.stages.where((entry) => entry.id == lead.stageId).firstOrNull;
    final informationEntries = lead.details.where((entry) => entry.kind == 'INFO').toList();
    final commentEntries = lead.details.where((entry) => entry.kind == 'COMMENT').toList();
    final nextActionLabel = _formatNullableDate(lead.nextActionAt, _dateFormat) ?? 'Brak terminu';
    final refreshedAtLabel = _formatNullableDate(lead.updatedAt, _dateTimeFormat) ?? '-';
    final primaryContact = lead.phone ?? lead.email ?? 'Brak danych kontaktowych';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VeloPrimeShell(
        decorateBackground: true,
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1180;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VeloPrimeWorkspacePanel(
                    tint: VeloPrimePalette.sea,
                    radius: 30,
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => Navigator.of(context).pop(),
                                      icon: const Icon(Icons.arrow_back_outlined),
                                      label: const Text('Powrót do leadów'),
                                    ),
                                    const SizedBox(height: 18),
                                    const VeloPrimeSectionEyebrow(label: 'Lead workspace', color: VeloPrimePalette.sea),
                                    const SizedBox(height: 16),
                                    Text(
                                      lead.fullName,
                                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink, height: 1.02),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Widok ma prowadzić od kontaktu i kontekstu do działania: zmiany etapu, historii i szybkiego przejścia do oferty bez ciężkiego, archiwalnego wyglądu.',
                                      style: TextStyle(fontSize: 14, height: 1.65, color: VeloPrimePalette.muted),
                                    ),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        _DetailBadge(label: lead.source),
                                        if ((lead.interestedModel ?? '').isNotEmpty) _DetailBadge(label: lead.interestedModel!),
                                        if ((lead.region ?? '').isNotEmpty) _DetailBadge(label: lead.region!),
                                        _DetailBadge(label: 'Etap: ${stage?.name ?? lead.stageId}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                flex: 4,
                                child: _LeadActionPanel(
                                  primaryContact: primaryContact,
                                  ownerName: lead.salespersonName ?? 'Nie przypisano',
                                  nextActionLabel: nextActionLabel,
                                  onRefresh: _loadSafe,
                                  onCreateOffer: _isCreatingOffer ? null : _createOfferForLead,
                                  isCreatingOffer: _isCreatingOffer,
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.arrow_back_outlined),
                                label: const Text('Powrót do leadów'),
                              ),
                              const SizedBox(height: 18),
                              const VeloPrimeSectionEyebrow(label: 'Lead workspace', color: VeloPrimePalette.sea),
                              const SizedBox(height: 16),
                              Text(
                                lead.fullName,
                                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink, height: 1.04),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Pełny obraz kontaktu, aktywności i powiązanych ofert w jednym miejscu, ale już w lżejszym układzie do codziennej pracy.',
                                style: TextStyle(fontSize: 14, height: 1.65, color: VeloPrimePalette.muted),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _DetailBadge(label: lead.source),
                                  if ((lead.interestedModel ?? '').isNotEmpty) _DetailBadge(label: lead.interestedModel!),
                                  if ((lead.region ?? '').isNotEmpty) _DetailBadge(label: lead.region!),
                                  _DetailBadge(label: 'Etap: ${stage?.name ?? lead.stageId}'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _LeadActionPanel(
                                primaryContact: primaryContact,
                                ownerName: lead.salespersonName ?? 'Nie przypisano',
                                nextActionLabel: nextActionLabel,
                                onRefresh: _loadSafe,
                                onCreateOffer: _isCreatingOffer ? null : _createOfferForLead,
                                isCreatingOffer: _isCreatingOffer,
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            _MetricCard(label: 'Etap', value: stage?.name ?? lead.stageId, accent: const Color(0xFF9D7B27)),
                            _MetricCard(label: 'Oferty', value: '${lead.linkedOffers.length}', accent: const Color(0xFF4A90E2)),
                            _MetricCard(label: 'Wpisy', value: '${lead.details.length}', accent: const Color(0xFF3F7D64)),
                            _MetricCard(label: 'Aktywność', value: _formatNullableDate(lead.updatedAt, _dateFormat) ?? '-', accent: VeloPrimePalette.violet),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _DetailCard(
                                      title: 'Kontakt',
                                      subtitle: 'Najważniejsze dane kontaktowe klienta.',
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _KeyValueLine(label: 'Telefon', value: lead.phone ?? 'Brak telefonu'),
                                          _KeyValueLine(label: 'Email', value: lead.email ?? 'Brak adresu email'),
                                          _KeyValueLine(label: 'Region', value: lead.region ?? 'Brak regionu'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _DetailCard(
                                      title: 'Obsługa',
                                      subtitle: 'Status opieki i rytm dalszej pracy.',
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _KeyValueLine(label: 'Przełożony', value: lead.managerName ?? 'Nie przypisano'),
                                          _KeyValueLine(label: 'Opiekun', value: lead.salespersonName ?? 'Nie przypisano'),
                                          _KeyValueLine(label: 'Następna akcja', value: nextActionLabel),
                                          _KeyValueLine(label: 'Aktualizacja', value: refreshedAtLabel),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if ((lead.message ?? '').isNotEmpty) ...[
                                _DetailCard(
                                  title: 'Notatka startowa',
                                  subtitle: 'Pierwotna wiadomość leada.',
                                  child: Text(
                                    lead.message!,
                                    style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF555555)),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              _DetailCard(
                                title: 'Oferty klienta',
                                subtitle: 'Powiązane oferty PDF oraz szybkie przejście do dokumentu.',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (lead.linkedOffers.isEmpty)
                                      const Text(
                                        'Ten lead nie ma jeszcze przypisanej oferty. Możesz od razu utworzyć pierwszy dokument PDF dla tego klienta.',
                                        style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF666666)),
                                      )
                                    else
                                      ...lead.linkedOffers.map(
                                        (offer) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: _OfferLinkCard(
                                            title: offer.title,
                                            number: offer.number,
                                            status: _formatStatus(offer.status),
                                            versionCount: offer.versionCount,
                                            updatedAt: _formatNullableDate(offer.updatedAt, _dateTimeFormat) ?? '-',
                                            onOpen: () => _openOffer(offer.id),
                                          ),
                                        ),
                                      ),
                                    FilledButton.icon(
                                      onPressed: _isCreatingOffer ? null : _createOfferForLead,
                                      icon: const Icon(Icons.description_outlined),
                                      label: Text(lead.linkedOffers.isEmpty ? 'Stwórz nową ofertę' : 'Nowa oferta dla tego klienta'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DetailCard(
                                title: 'Akcje operacyjne',
                                subtitle: 'Zmiana etapu, przypisania i szybkie wpisy do historii.',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    DropdownButtonFormField<String>(
                                      initialValue: lead.stageId,
                                      borderRadius: BorderRadius.circular(22),
                                      isExpanded: true,
                                      decoration: veloPrimeInputDecoration('Etap pipeline'),
                                      items: _payload.stages
                                          .map(
                                            (entry) => DropdownMenuItem<String>(
                                              value: entry.id,
                                              child: Text(entry.name),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: _isUpdatingStage
                                          ? null
                                          : (value) {
                                              if (value == null || value == lead.stageId) {
                                                return;
                                              }
                                              _moveStage(value);
                                            },
                                    ),
                                    const SizedBox(height: 14),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        FilledButton.tonalIcon(
                                          onPressed: _isAddingEntry ? null : () => _addEntry(kind: 'INFO'),
                                          icon: const Icon(Icons.info_outline),
                                          label: const Text('Dodaj informację'),
                                        ),
                                        FilledButton.tonalIcon(
                                          onPressed: _isAddingEntry ? null : () => _addEntry(kind: 'COMMENT'),
                                          icon: const Icon(Icons.comment_outlined),
                                          label: const Text('Dodaj komentarz'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              _DetailCard(
                                title: 'Informacje i historia',
                                subtitle: 'Podział na informacje i komentarze z widocznym autorem każdego wpisu.',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (lead.details.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 8),
                                        child: Text('Nie ma jeszcze wpisów. Dodaj własną informację albo komentarz do tego leada.'),
                                      )
                                    else ...[
                                      _HistorySection(
                                        title: 'Informacje',
                                        accent: const Color(0xFF4A90E2),
                                        entries: informationEntries,
                                        dateFormat: _dateTimeFormat,
                                      ),
                                      const SizedBox(height: 16),
                                      _HistorySection(
                                        title: 'Komentarze',
                                        accent: VeloPrimePalette.bronzeDeep,
                                        entries: commentEntries,
                                        dateFormat: _dateTimeFormat,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailCard(
                          title: 'Kontakt i obsługa',
                          subtitle: 'Podstawowe dane klienta i status opieki.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _KeyValueLine(label: 'Telefon', value: lead.phone ?? 'Brak telefonu'),
                              _KeyValueLine(label: 'Email', value: lead.email ?? 'Brak adresu email'),
                              _KeyValueLine(label: 'Opiekun', value: lead.salespersonName ?? 'Nie przypisano'),
                              _KeyValueLine(label: 'Następna akcja', value: nextActionLabel),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _DetailCard(
                          title: 'Akcje operacyjne',
                          subtitle: 'Zmiana etapu i szybkie wpisy do historii.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: lead.stageId,
                                borderRadius: BorderRadius.circular(22),
                                isExpanded: true,
                                decoration: veloPrimeInputDecoration('Etap pipeline'),
                                items: _payload.stages
                                    .map(
                                      (entry) => DropdownMenuItem<String>(
                                        value: entry.id,
                                        child: Text(entry.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _isUpdatingStage
                                    ? null
                                    : (value) {
                                        if (value == null || value == lead.stageId) {
                                          return;
                                        }
                                        _moveStage(value);
                                      },
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  FilledButton.icon(
                                    onPressed: _isCreatingOffer ? null : _createOfferForLead,
                                    icon: const Icon(Icons.note_add_outlined),
                                    label: Text(_isCreatingOffer ? 'Tworzenie oferty...' : 'Nowa oferta'),
                                  ),
                                  FilledButton.tonalIcon(
                                    onPressed: _isAddingEntry ? null : () => _addEntry(kind: 'INFO'),
                                    icon: const Icon(Icons.info_outline),
                                    label: const Text('Dodaj informację'),
                                  ),
                                  FilledButton.tonalIcon(
                                    onPressed: _isAddingEntry ? null : () => _addEntry(kind: 'COMMENT'),
                                    icon: const Icon(Icons.comment_outlined),
                                    label: const Text('Dodaj komentarz'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _DetailCard(
                          title: 'Powiązane oferty',
                          subtitle: 'Szybkie przejście do dokumentów PDF powiązanych z klientem.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (lead.linkedOffers.isEmpty)
                                const Text('Ten lead nie ma jeszcze przypisanych ofert.')
                              else
                                ...lead.linkedOffers.map(
                                  (offer) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _OfferLinkCard(
                                      title: offer.title,
                                      number: offer.number,
                                      status: _formatStatus(offer.status),
                                      versionCount: offer.versionCount,
                                      updatedAt: _formatNullableDate(offer.updatedAt, _dateTimeFormat) ?? '-',
                                      onOpen: () => _openOffer(offer.id),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _DetailCard(
                          title: 'Historia',
                          subtitle: 'Wszystkie informacje i komentarze klienta.',
                          child: lead.details.isEmpty
                              ? const Text('Brak wpisów w historii leada.')
                              : Column(
                                  children: lead.details
                                      .map(
                                        (entry) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: _HistoryEntryCard(
                                            title: entry.label.isNotEmpty ? entry.label : (entry.kind == 'COMMENT' ? 'Komentarz' : 'Informacja'),
                                            value: entry.value,
                                            author: entry.authorName,
                                            dateLabel: _formatNullableDate(entry.createdAt, _dateTimeFormat) ?? '-',
                                            accent: entry.kind == 'COMMENT' ? VeloPrimePalette.bronzeDeep : const Color(0xFF4A90E2),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _loadSafe() async {
    try {
      await _reloadLead();
    } catch (error) {
      _showError(error.toString());
    }
  }
}

class _LeadEntryInputResult {
  const _LeadEntryInputResult({
    required this.label,
    required this.value,
  });

  final String? label;
  final String value;
}

class _LeadEntryDialog extends StatefulWidget {
  const _LeadEntryDialog({required this.kind});

  final String kind;

  @override
  State<_LeadEntryDialog> createState() => _LeadEntryDialogState();
}

class _LeadEntryDialogState extends State<_LeadEntryDialog> {
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _labelController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _submit() {
    final label = _labelController.text.trim();
    final value = _valueController.text.trim();

    if (widget.kind == 'INFO' && label.isEmpty) {
      setState(() {
        _error = 'Podaj tytul informacji.';
      });
      return;
    }

    if (value.isEmpty) {
      setState(() {
        _error = widget.kind == 'COMMENT' ? 'Wpisz tresc komentarza.' : 'Wpisz komentarz lub informacje.';
      });
      return;
    }

    Navigator.of(context).pop(
      _LeadEntryInputResult(
        label: widget.kind == 'INFO' ? label : null,
        value: value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isComment = widget.kind == 'COMMENT';
    final accent = isComment ? VeloPrimePalette.bronzeDeep : VeloPrimePalette.sea;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: VeloPrimeWorkspacePanel(
          tint: accent,
          radius: 32,
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VeloPrimeSectionEyebrow(
                label: isComment ? 'Komentarz' : 'Informacja',
                color: accent,
              ),
              const SizedBox(height: 12),
              Text(
                isComment ? 'Dodaj komentarz do historii leada' : 'Dodaj nowa informacje do karty klienta',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: VeloPrimePalette.ink,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isComment
                    ? 'Komentarz zapisze sie w historii aktywnosci i bedzie widoczny od razu na karcie leada.'
                    : 'Nadaj wpisowi czytelny tytul, a w tresci zapisz kontekst, ustalenie lub dodatkowa informacje operacyjna.',
                style: const TextStyle(
                  color: VeloPrimePalette.muted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 22),
              if (!isComment) ...[
                TextField(
                  controller: _labelController,
                  decoration: veloPrimeInputDecoration('Tytul informacji'),
                ),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: _valueController,
                minLines: isComment ? 6 : 5,
                maxLines: isComment ? 10 : 8,
                decoration: veloPrimeInputDecoration('Komentarz / informacja').copyWith(errorText: _error),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Anuluj'),
                  ),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Zapisz wpis'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 196,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.96), Color.alphaBlend(accent.withValues(alpha: 0.06), const Color(0xFFFFFCF8))],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D111111),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: VeloPrimePalette.muted, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: accent, height: 1.1)),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return VeloPrimeWorkspacePanel(
      tint: VeloPrimePalette.sea,
      radius: 28,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 13, height: 1.5, color: VeloPrimePalette.muted)),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _DetailBadge extends StatelessWidget {
  const _DetailBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color.alphaBlend(VeloPrimePalette.bronze.withValues(alpha: 0.06), Colors.white),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VeloPrimePalette.bronze.withValues(alpha: 0.16)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6C614E))),
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: VeloPrimePalette.lineStrong),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: Color(0xFF8A826F))),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 14, height: 1.5, color: VeloPrimePalette.ink)),
          ],
        ),
      ),
    );
  }
}

class _LeadActionPanel extends StatelessWidget {
  const _LeadActionPanel({
    required this.primaryContact,
    required this.ownerName,
    required this.nextActionLabel,
    required this.onRefresh,
    required this.onCreateOffer,
    required this.isCreatingOffer,
  });

  final String primaryContact;
  final String ownerName;
  final String nextActionLabel;
  final VoidCallback onRefresh;
  final VoidCallback? onCreateOffer;
  final bool isCreatingOffer;

  @override
  Widget build(BuildContext context) {
    return VeloPrimeWorkspacePanel(
      tint: VeloPrimePalette.sea,
      radius: 24,
      surfaceOpacity: 0.68,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Szybkie akcje',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink),
          ),
          const SizedBox(height: 8),
          const Text(
            'Najkrótsza droga od podglądu klienta do kolejnego kroku sprzedażowego.',
            style: TextStyle(fontSize: 12, height: 1.55, color: VeloPrimePalette.muted),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreateOffer,
            icon: const Icon(Icons.note_add_outlined),
            label: Text(isCreatingOffer ? 'Tworzenie oferty...' : 'Nowa oferta'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Odśwież dane'),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              VeloPrimeBadge(label: 'Kontakt', value: primaryContact),
              VeloPrimeBadge(label: 'Opiekun', value: ownerName),
              VeloPrimeBadge(label: 'Następna akcja', value: nextActionLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfferLinkCard extends StatelessWidget {
  const _OfferLinkCard({
    required this.title,
    required this.number,
    required this.status,
    required this.versionCount,
    required this.updatedAt,
    required this.onOpen,
  });

  final String title;
  final String number;
  final String status;
  final int versionCount;
  final String updatedAt;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF9F6F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: VeloPrimePalette.lineStrong),
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
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink)),
                    const SizedBox(height: 4),
                    Text('$number • aktualizacja $updatedAt', style: const TextStyle(fontSize: 11, letterSpacing: 0.6, color: Color(0xFF8A826F))),
                  ],
                ),
              ),
              _DetailBadge(label: status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Wersje: $versionCount', style: const TextStyle(fontSize: 11, letterSpacing: 0.6, color: Color(0xFF8A826F))),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('PDF'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.title,
    required this.accent,
    required this.entries,
    required this.dateFormat,
  });

  final String title;
  final Color accent;
  final List<LeadDetailEntryModel> entries;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.3, color: accent)),
            const Spacer(),
            Text('${entries.length} wpisów', style: const TextStyle(fontSize: 11, letterSpacing: 0.6, color: Color(0xFF8A826F))),
          ],
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Color.alphaBlend(accent.withValues(alpha: 0.05), Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.16)),
            ),
            child: const Text('Brak wpisów w tej sekcji.', style: TextStyle(color: Color(0xFF8A826F))),
          )
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HistoryEntryCard(
                title: entry.label.isNotEmpty ? entry.label : title.substring(0, title.length - 1),
                value: entry.value,
                author: entry.authorName,
                dateLabel: _formatNullableDate(entry.createdAt, dateFormat) ?? '-',
                accent: accent,
              ),
            ),
          ),
      ],
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    required this.title,
    required this.value,
    required this.author,
    required this.dateLabel,
    required this.accent,
  });

  final String title;
  final String value;
  final String? author;
  final String dateLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.alphaBlend(accent.withValues(alpha: 0.06), Colors.white),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink)),
              ),
              Text(dateLabel, style: const TextStyle(fontSize: 11, letterSpacing: 0.6, color: Color(0xFF8A826F))),
            ],
          ),
          if ((author ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Autor: ${author!}', style: const TextStyle(fontSize: 11, letterSpacing: 0.6, color: Color(0xFF8A826F))),
          ],
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF555555))),
        ],
      ),
    );
  }
}


String _formatStatus(String value) {
  switch (value.toUpperCase()) {
    case 'DRAFT':
      return 'Szkic';
    case 'READY':
      return 'Gotowa';
    case 'APPROVED':
      return 'Zatwierdzona';
    case 'REJECTED':
      return 'Odrzucona';
    default:
      return value;
  }
}

String? _formatNullableDate(String? value, DateFormat format) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  return format.format(parsed);
}
