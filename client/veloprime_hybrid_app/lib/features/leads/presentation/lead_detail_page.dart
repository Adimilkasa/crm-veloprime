import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/presentation/veloprime_ui.dart';
import '../../bootstrap/models/bootstrap_payload.dart';
import '../data/leads_repository.dart';
import '../models/lead_models.dart';
import '../../offers/data/offers_repository.dart';
import '../../offers/presentation/offers_home_page.dart';
import '../../reminders/data/reminders_repository.dart';

class LeadDetailPage extends StatefulWidget {
  const LeadDetailPage({
    super.key,
    required this.session,
    required this.bootstrap,
    required this.repository,
    required this.offersRepository,
    required this.remindersRepository,
    required this.initialPayload,
    required this.onRemindersChanged,
    required this.onOpenOfferWorkspaceForLead,
  });

  final SessionInfo session;
  final BootstrapPayload bootstrap;
  final LeadsRepository repository;
  final OffersRepository offersRepository;
  final RemindersRepository remindersRepository;
  final LeadDetailPayload initialPayload;
  final Future<void> Function() onRemindersChanged;
  final Future<void> Function(OfferWorkspaceLaunchRequest request) onOpenOfferWorkspaceForLead;

  @override
  State<LeadDetailPage> createState() => _LeadDetailPageState();
}

class _LeadDetailPageState extends State<LeadDetailPage> {
  static final DateFormat _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  static const String _internalInfoPrefix = 'WEW::';

  late LeadDetailPayload _payload;
  bool _isUpdatingStage = false;
  bool _isAddingEntry = false;
  bool _isUploadingAttachment = false;
  bool _isCreatingReminder = false;
  bool _isCreatingOffer = false;

  bool get _isAdmin => widget.session.role == 'ADMIN';

  @override
  void initState() {
    super.initState();
    _payload = widget.initialPayload;
    unawaited(_reloadLeadSilently());
  }

  Future<void> _moveStage(String stageId, {String? acceptedOfferId}) async {
    setState(() {
      _isUpdatingStage = true;
    });

    try {
      final nextPayload = await widget.repository.moveLeadToStage(
        leadId: _payload.lead.id,
        stageId: stageId,
        acceptedOfferId: acceptedOfferId,
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

  Future<void> _handleStageChange(String stageId) async {
    final nextStage = _payload.stages.where((entry) => entry.id == stageId).firstOrNull;

    if (nextStage == null) {
      _showError('Nie znaleziono wybranego etapu.');
      return;
    }

    if (nextStage.kind != 'WON') {
      await _moveStage(stageId);
      return;
    }

    if (_payload.lead.linkedOffers.isEmpty) {
      _showError('Przed oznaczeniem leada jako wygrany przypnij do niego ofertę.');
      return;
    }

    var currentPayload = _payload;

    if (currentPayload.lead.attachments.isEmpty) {
      final shouldUpload = await showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.22),
        builder: (context) => const _LeadAttachmentRequiredDialog(),
      );

      if (shouldUpload != true) {
        return;
      }

      final uploaded = await _pickAttachment();
      if (!uploaded || !mounted) {
        return;
      }

      currentPayload = _payload;
    }

    final acceptedOfferId = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (context) => _LeadAcceptedOfferDialog(
        offers: currentPayload.lead.linkedOffers,
        initialOfferId: currentPayload.lead.acceptedOfferId,
      ),
    );

    if (acceptedOfferId == null || acceptedOfferId.isEmpty) {
      return;
    }

    await _moveStage(stageId, acceptedOfferId: acceptedOfferId);
  }

  Future<bool> _pickAttachment() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Dokumenty i załączniki',
          extensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'doc', 'docx', 'xls', 'xlsx'],
        ),
      ],
    );

    if (file == null) {
      return false;
    }

    setState(() {
      _isUploadingAttachment = true;
    });

    try {
      final nextPayload = await widget.repository.uploadAttachment(
        leadId: _payload.lead.id,
        filePath: file.path,
        fileName: file.name,
      );

      if (!mounted) {
        return false;
      }

      setState(() {
        _payload = nextPayload;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Załącznik został dodany do leada.')),
      );
      return true;
    } catch (error) {
      _showError(error.toString());
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAttachment = false;
        });
      }
    }
  }

  Future<void> _openAttachment(LeadAttachmentModel attachment) async {
    try {
      final opened = await launchUrl(Uri.parse(attachment.fileUrl), mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        _showError('Nie udało się otworzyć załącznika ${attachment.fileName}.');
      }
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _addReminder() async {
    final result = await showDialog<_LeadReminderInputResult>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (context) => _LeadReminderDialog(leadName: _payload.lead.fullName),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _isCreatingReminder = true;
    });

    try {
      await widget.remindersRepository.createReminder(
        title: result.title,
        note: result.note,
        remindAt: result.remindAt,
        leadId: _payload.lead.id,
      );
      await widget.onRemindersChanged();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Przypomnienie zostało zapisane.')),
      );
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingReminder = false;
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
      final normalizedKind = kind == 'INTERNAL' ? 'INFO' : kind;
      final normalizedLabel = kind == 'INTERNAL'
          ? '$_internalInfoPrefix${result.label?.trim() ?? ''}'
          : result.label;

      final nextPayload = await widget.repository.addDetailEntry(
        leadId: _payload.lead.id,
        kind: normalizedKind,
        label: normalizedLabel,
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

  Future<void> _reloadLeadSilently() async {
    try {
      await _reloadLead();
    } catch (_) {
      // Keep cached payload visible when backend is temporarily unavailable.
    }
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

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _isInternalInfoEntry(LeadDetailEntryModel entry) {
    return entry.kind == 'INFO' && entry.label.startsWith(_internalInfoPrefix);
  }

  String _displayEntryLabel(LeadDetailEntryModel entry) {
    if (_isInternalInfoEntry(entry)) {
      return entry.label.substring(_internalInfoPrefix.length).trim();
    }

    return entry.label;
  }

  @override
  Widget build(BuildContext context) {
    final lead = _payload.lead;
    final stage = _payload.stages.where((entry) => entry.id == lead.stageId).firstOrNull;
    final internalEntries = lead.details.where(_isInternalInfoEntry).toList();
    final informationEntries = lead.details.where((entry) => entry.kind == 'INFO' && !_isInternalInfoEntry(entry)).toList();
    final commentEntries = lead.details.where((entry) => entry.kind == 'COMMENT').toList();
    final nextActionLabel = _formatNullableDate(lead.nextActionAt, _dateFormat) ?? 'Brak terminu';
    final refreshedAtLabel = _formatNullableDate(lead.updatedAt, _dateTimeFormat) ?? '-';
    final primaryContact = lead.phone ?? lead.email ?? 'Brak danych kontaktowych';
    final acceptedOffer = lead.linkedOffers.where((offer) => offer.id == lead.acceptedOfferId).firstOrNull;

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
                    padding: const EdgeInsets.all(22),
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
                                    const SizedBox(height: 14),
                                    const VeloPrimeSectionEyebrow(label: 'Lead', color: VeloPrimePalette.sea),
                                    const SizedBox(height: 12),
                                    Text(
                                      lead.fullName,
                                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink, height: 1.02),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Etap ${stage?.name ?? lead.stageId} • kontakt $primaryContact • opiekun ${lead.salespersonName ?? 'Nie przypisano'}',
                                      style: const TextStyle(fontSize: 13, height: 1.5, color: VeloPrimePalette.muted),
                                    ),
                                    const SizedBox(height: 14),
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
                                flex: 3,
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
                              const SizedBox(height: 14),
                              const VeloPrimeSectionEyebrow(label: 'Lead', color: VeloPrimePalette.sea),
                              const SizedBox(height: 12),
                              Text(
                                lead.fullName,
                                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink, height: 1.04),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Etap ${stage?.name ?? lead.stageId} • kontakt $primaryContact',
                                style: const TextStyle(fontSize: 13, height: 1.5, color: VeloPrimePalette.muted),
                              ),
                              const SizedBox(height: 14),
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
                            _MetricCard(label: 'Dokumenty', value: '${lead.attachments.length}', accent: VeloPrimePalette.olive),
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
                              _DetailCard(
                                title: 'Kontakt i obsługa',
                                subtitle: 'Kompaktowy podgląd danych klienta i bieżącej opieki bez rozbijania na osobne boksy.',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _KeyValueLine(label: 'Telefon', value: lead.phone ?? 'Brak telefonu'),
                                    _KeyValueLine(label: 'Email', value: lead.email ?? 'Brak adresu email'),
                                    _KeyValueLine(label: 'Region', value: lead.region ?? 'Brak regionu'),
                                    _KeyValueLine(label: 'Przełożony', value: lead.managerName ?? 'Nie przypisano'),
                                    _KeyValueLine(label: 'Opiekun', value: lead.salespersonName ?? 'Nie przypisano'),
                                    _KeyValueLine(
                                      label: 'Wygrana oferta',
                                      value: acceptedOffer == null ? 'Jeszcze nie wybrano' : '${acceptedOffer.number} • ${acceptedOffer.title}',
                                    ),
                                    _KeyValueLine(label: 'Następna akcja', value: nextActionLabel),
                                    _KeyValueLine(label: 'Aktualizacja', value: refreshedAtLabel),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              _DetailCard(
                                title: 'Dokumenty klienta',
                                subtitle: 'Umowy, potwierdzenia i inne załączniki wymagane przed oznaczeniem leada jako wygrany.',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (lead.attachments.isEmpty)
                                      const Text(
                                        'Brak załączników. Przed przejściem do Wygrane dodaj przynajmniej jeden dokument.',
                                        style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF666666)),
                                      )
                                    else
                                      ...lead.attachments.map(
                                        (attachment) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: _LeadAttachmentCard(
                                            attachment: attachment,
                                            dateLabel: _formatNullableDate(attachment.createdAt, _dateTimeFormat) ?? '-',
                                            onOpen: () => _openAttachment(attachment),
                                          ),
                                        ),
                                      ),
                                    FilledButton.tonalIcon(
                                      onPressed: _isUploadingAttachment ? null : _pickAttachment,
                                      icon: const Icon(Icons.attach_file_rounded),
                                      label: Text(_isUploadingAttachment ? 'Wysyłanie...' : 'Dodaj dokument'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              _DetailCard(
                                title: 'Oferty klienta',
                                subtitle: 'Powiązane oferty i szybkie przejście do dokumentu.',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (lead.linkedOffers.isEmpty)
                                      const Text(
                                        'Ten klient nie ma jeszcze przypisanej oferty. Możesz przygotować pierwszą ofertę od razu z tego widoku.',
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
                              const SizedBox(height: 16),
                              _DetailCard(
                                title: 'Obsługa wewnętrzna',
                                subtitle: _isAdmin
                                    ? 'Długofalowe informacje operacyjne widoczne dla całego zespołu. Dodawanie tylko przez administratora.'
                                    : 'Długofalowe informacje operacyjne widoczne dla całego zespołu. Tylko administrator może dodawać nowe wpisy.',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (internalEntries.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 8),
                                        child: Text(
                                          'Brak wpisów wewnętrznych. Tu mogą trafiać statusy typu podpisana umowa, wydanie auta albo inne ustalenia długoterminowe.',
                                          style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF666666)),
                                        ),
                                      )
                                    else
                                      ...internalEntries.map(
                                        (entry) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: _HistoryEntryCard(
                                            title: _displayEntryLabel(entry).isNotEmpty ? _displayEntryLabel(entry) : 'Informacja wewnętrzna',
                                            value: entry.value,
                                            author: entry.authorName,
                                            dateLabel: _formatNullableDate(entry.createdAt, _dateTimeFormat) ?? '-',
                                            accent: VeloPrimePalette.olive,
                                          ),
                                        ),
                                      ),
                                    if (_isAdmin) ...[
                                      const SizedBox(height: 6),
                                      FilledButton.tonalIcon(
                                        onPressed: _isAddingEntry ? null : () => _addEntry(kind: 'INTERNAL'),
                                        icon: const Icon(Icons.admin_panel_settings_outlined),
                                        label: const Text('Dodaj wpis wewnętrzny'),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if ((lead.message ?? '').isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _DetailCard(
                                  title: 'Pierwotna wiadomość',
                                  subtitle: 'Źródłowa notatka z początku obsługi leada.',
                                  child: Text(
                                    lead.message!,
                                    style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF555555)),
                                  ),
                                ),
                              ],
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
                                              _handleStageChange(value);
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
                                          onPressed: _isCreatingReminder ? null : _addReminder,
                                          icon: const Icon(Icons.alarm_add_outlined),
                                          label: Text(_isCreatingReminder ? 'Zapisywanie...' : 'Ustaw przypomnienie'),
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
                              _KeyValueLine(
                                label: 'Wygrana oferta',
                                value: acceptedOffer == null ? 'Jeszcze nie wybrano' : '${acceptedOffer.number} • ${acceptedOffer.title}',
                              ),
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
                                        _handleStageChange(value);
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
                                    onPressed: _isCreatingReminder ? null : _addReminder,
                                    icon: const Icon(Icons.alarm_add_outlined),
                                    label: Text(_isCreatingReminder ? 'Zapisywanie...' : 'Ustaw przypomnienie'),
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
                          title: 'Obsługa wewnętrzna',
                          subtitle: _isAdmin
                              ? 'Wpisy długoterminowe widoczne dla zespołu. Dodawanie tylko przez administratora.'
                              : 'Wpisy długoterminowe widoczne dla zespołu. Tylko administrator może dodawać nowe wpisy.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (internalEntries.isEmpty)
                                const Text('Brak wpisów wewnętrznych.')
                              else
                                ...internalEntries.map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _HistoryEntryCard(
                                      title: _displayEntryLabel(entry).isNotEmpty ? _displayEntryLabel(entry) : 'Informacja wewnętrzna',
                                      value: entry.value,
                                      author: entry.authorName,
                                      dateLabel: _formatNullableDate(entry.createdAt, _dateTimeFormat) ?? '-',
                                      accent: VeloPrimePalette.olive,
                                    ),
                                  ),
                                ),
                              if (_isAdmin)
                                FilledButton.tonalIcon(
                                  onPressed: _isAddingEntry ? null : () => _addEntry(kind: 'INTERNAL'),
                                  icon: const Icon(Icons.admin_panel_settings_outlined),
                                  label: const Text('Dodaj wpis wewnętrzny'),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _DetailCard(
                          title: 'Dokumenty klienta',
                          subtitle: 'Załączniki przypięte do sprawy i wymagane przy wygraniu leada.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (lead.attachments.isEmpty)
                                const Text('Brak załączników. Dodaj dokument przed przejściem do Wygrane.')
                              else
                                ...lead.attachments.map(
                                  (attachment) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _LeadAttachmentCard(
                                      attachment: attachment,
                                      dateLabel: _formatNullableDate(attachment.createdAt, _dateTimeFormat) ?? '-',
                                      onOpen: () => _openAttachment(attachment),
                                    ),
                                  ),
                                ),
                              FilledButton.tonalIcon(
                                onPressed: _isUploadingAttachment ? null : _pickAttachment,
                                icon: const Icon(Icons.attach_file_rounded),
                                label: Text(_isUploadingAttachment ? 'Wysyłanie...' : 'Dodaj dokument'),
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
                        if ((lead.message ?? '').isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _DetailCard(
                            title: 'Pierwotna wiadomość',
                            subtitle: 'Źródłowa notatka z początku obsługi leada.',
                            child: Text(
                              lead.message!,
                              style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF555555)),
                            ),
                          ),
                        ],
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

class _LeadReminderInputResult {
  const _LeadReminderInputResult({
    required this.title,
    required this.note,
    required this.remindAt,
  });

  final String title;
  final String? note;
  final String remindAt;
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

    if (widget.kind != 'COMMENT' && label.isEmpty) {
      setState(() {
        _error = widget.kind == 'INTERNAL' ? 'Podaj tytul wpisu wewnetrznego.' : 'Podaj tytul informacji.';
      });
      return;
    }

    if (value.isEmpty) {
      setState(() {
        _error = widget.kind == 'COMMENT'
            ? 'Wpisz tresc komentarza.'
            : widget.kind == 'INTERNAL'
                ? 'Wpisz tresc wpisu wewnetrznego.'
                : 'Wpisz komentarz lub informacje.';
      });
      return;
    }

    Navigator.of(context).pop(
      _LeadEntryInputResult(
        label: widget.kind == 'COMMENT' ? null : label,
        value: value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isComment = widget.kind == 'COMMENT';
    final isInternal = widget.kind == 'INTERNAL';
    final accent = isComment
      ? VeloPrimePalette.bronzeDeep
      : isInternal
        ? VeloPrimePalette.olive
        : VeloPrimePalette.sea;

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
                label: isComment
                    ? 'Komentarz'
                    : isInternal
                        ? 'Wpis wewnetrzny'
                        : 'Informacja',
                color: accent,
              ),
              const SizedBox(height: 12),
              Text(
                isComment
                    ? 'Dodaj komentarz do historii leada'
                    : isInternal
                        ? 'Dodaj wpis do obslugi wewnetrznej klienta'
                        : 'Dodaj nowa informacje do karty klienta',
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
                    : isInternal
                        ? 'To miejsce na informacje dlugoterminowe po stronie administracyjnej, na przyklad podpisana umowa, rezerwacja auta albo status wydania.'
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
                  decoration: veloPrimeInputDecoration(isInternal ? 'Tytul wpisu wewnetrznego' : 'Tytul informacji'),
                ),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: _valueController,
                minLines: isComment ? 6 : 5,
                maxLines: isComment ? 10 : 8,
                decoration: veloPrimeInputDecoration(isInternal ? 'Opis wpisu wewnetrznego' : 'Komentarz / informacja').copyWith(errorText: _error),
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

class _LeadAttachmentCard extends StatelessWidget {
  const _LeadAttachmentCard({
    required this.attachment,
    required this.dateLabel,
    required this.onOpen,
  });

  final LeadAttachmentModel attachment;
  final String dateLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF7FAF2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: VeloPrimePalette.olive.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: VeloPrimePalette.olive.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.description_outlined, color: VeloPrimePalette.olive),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatFileSize(attachment.sizeBytes)} • $dateLabel',
                  style: const TextStyle(fontSize: 11, letterSpacing: 0.5, color: Color(0xFF8A826F)),
                ),
                if ((attachment.uploadedByName ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Dodał: ${attachment.uploadedByName!}',
                      style: const TextStyle(fontSize: 11, letterSpacing: 0.5, color: Color(0xFF8A826F)),
                    ),
                  ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Otwórz'),
          ),
        ],
      ),
    );
  }
}

class _LeadAttachmentRequiredDialog extends StatelessWidget {
  const _LeadAttachmentRequiredDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: VeloPrimeWorkspacePanel(
          tint: VeloPrimePalette.olive,
          radius: 32,
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VeloPrimeSectionEyebrow(label: 'Dokument wymagany', color: VeloPrimePalette.olive),
              const SizedBox(height: 12),
              const Text(
                'Przed przeniesieniem leada do Wygrane dodaj dokument',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink, height: 1.08),
              ),
              const SizedBox(height: 12),
              const Text(
                'Może to być podpisana umowa, zamówienie, potwierdzenie wpłaty albo inny dokument finalizujący sprawę. Bez załącznika lead nie przejdzie do sekcji Wygrane.',
                style: TextStyle(color: VeloPrimePalette.muted, height: 1.6),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Anuluj'),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.attach_file_rounded),
                    label: const Text('Dodaj dokument'),
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

class _LeadAcceptedOfferDialog extends StatefulWidget {
  const _LeadAcceptedOfferDialog({
    required this.offers,
    required this.initialOfferId,
  });

  final List<LeadOfferSummary> offers;
  final String? initialOfferId;

  @override
  State<_LeadAcceptedOfferDialog> createState() => _LeadAcceptedOfferDialogState();
}

class _LeadAcceptedOfferDialogState extends State<_LeadAcceptedOfferDialog> {
  String? _selectedOfferId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedOfferId = widget.initialOfferId ?? widget.offers.firstOrNull?.id;
  }

  void _submit() {
    if ((_selectedOfferId ?? '').isEmpty) {
      setState(() {
        _error = 'Wybierz ofertę, która została zaakceptowana przez klienta.';
      });
      return;
    }

    Navigator.of(context).pop(_selectedOfferId);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: VeloPrimeWorkspacePanel(
          tint: VeloPrimePalette.sea,
          radius: 32,
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VeloPrimeSectionEyebrow(label: 'Wygrana oferta', color: VeloPrimePalette.sea),
              const SizedBox(height: 12),
              const Text(
                'Wskaż ofertę zaakceptowaną przez klienta',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink, height: 1.08),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ta informacja zostanie zapisana na leadzie i będzie punktem wejścia do dalszej obsługi klienta po stronie administracyjnej.',
                style: TextStyle(color: VeloPrimePalette.muted, height: 1.6),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _selectedOfferId,
                borderRadius: BorderRadius.circular(22),
                isExpanded: true,
                decoration: veloPrimeInputDecoration('Zaakceptowana oferta').copyWith(errorText: _error),
                items: widget.offers
                    .map(
                      (offer) => DropdownMenuItem<String>(
                        value: offer.id,
                        child: Text('${offer.number} • ${offer.title}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedOfferId = value;
                    _error = null;
                  });
                },
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
                    label: const Text('Zapisz i przenieś'),
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

class _LeadReminderDialog extends StatefulWidget {
  const _LeadReminderDialog({required this.leadName});

  final String leadName;

  @override
  State<_LeadReminderDialog> createState() => _LeadReminderDialogState();
}

class _LeadReminderDialogState extends State<_LeadReminderDialog> {
  static final DateFormat _dialogDateFormat = DateFormat('dd.MM.yyyy');
  static final DateFormat _dialogDateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 2));
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Kontakt z klientem ${widget.leadName}';
    final initial = DateTime.now().add(const Duration(hours: 2));
    _selectedDate = DateTime(initial.year, initial.month, initial.day);
    _selectedTime = TimeOfDay(hour: initial.hour, minute: initial.minute);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: 'Wybierz dzień przypomnienia',
      cancelText: 'Anuluj',
      confirmText: 'Wybierz',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDate = picked;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Wybierz godzinę przypomnienia',
      cancelText: 'Anuluj',
      confirmText: 'Wybierz',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedTime = picked;
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (title.isEmpty) {
      setState(() {
        _error = 'Podaj tytuł przypomnienia.';
      });
      return;
    }

    Navigator.of(context).pop(
      _LeadReminderInputResult(
        title: title,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        remindAt: scheduledAt.toIso8601String(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduledPreview = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: VeloPrimeWorkspacePanel(
          tint: VeloPrimePalette.violet,
          radius: 32,
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VeloPrimeSectionEyebrow(label: 'Przypomnienie', color: VeloPrimePalette.violet),
              const SizedBox(height: 12),
              const Text(
                'Ustaw przypomnienie do tego leada',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink, height: 1.08),
              ),
              const SizedBox(height: 12),
              const Text(
                'Przypomnienie trafi do dzwonka w górnej nawigacji i pojawi się na dashboardzie, gdy termin będzie aktywny.',
                style: TextStyle(color: VeloPrimePalette.muted, height: 1.6),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: veloPrimeInputDecoration('Tytuł przypomnienia').copyWith(errorText: _error),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _noteController,
                minLines: 3,
                maxLines: 5,
                decoration: veloPrimeInputDecoration('Notatka operacyjna (opcjonalnie)'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text('Dzień: ${_dialogDateFormat.format(_selectedDate)}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text('Godzina: ${_selectedTime.format(context)}'),
                  ),
                  VeloPrimeBadge(label: 'Termin', value: _dialogDateTimeFormat.format(scheduledPreview)),
                ],
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
                    label: const Text('Zapisz przypomnienie'),
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

String _formatFileSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  return '$bytes B';
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
