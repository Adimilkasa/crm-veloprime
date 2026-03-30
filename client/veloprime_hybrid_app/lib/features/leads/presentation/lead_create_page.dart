import 'package:flutter/material.dart';

import '../../../core/presentation/veloprime_ui.dart';
import '../../bootstrap/models/bootstrap_payload.dart';
import '../data/leads_repository.dart';
import '../models/lead_models.dart';

class LeadCreatePage extends StatefulWidget {
  const LeadCreatePage({
    super.key,
    required this.session,
    required this.repository,
    required this.stages,
    required this.salespeople,
    this.modal = false,
  });

  final SessionInfo session;
  final LeadsRepository repository;
  final List<LeadStageInfo> stages;
  final List<SalespersonOption> salespeople;
  final bool modal;

  @override
  State<LeadCreatePage> createState() => _LeadCreatePageState();
}

class _LeadCreatePageState extends State<LeadCreatePage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String? _selectedStageId;
  String? _selectedSalespersonId;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedStageId = widget.stages.firstWhere(
      (stage) => stage.kind == 'OPEN',
      orElse: () => widget.stages.first,
    ).id;
    if (widget.session.role == 'ADMIN' ||
        widget.session.role == 'DIRECTOR' ||
        widget.session.role == 'MANAGER') {
      final selfOption = widget.salespeople.where((user) => user.id == widget.session.sub).firstOrNull;
      _selectedSalespersonId = selfOption?.id ?? widget.salespeople.firstOrNull?.id;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _regionController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final payload = await widget.repository.createLead({
        'source': 'Manual',
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'interestedModel': '',
        'region': _regionController.text.trim(),
        'message': _messageController.text.trim(),
        'stageId': _selectedStageId ?? '',
        'salespersonId': _selectedSalespersonId ?? '',
      });

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(payload);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAssignSalesperson = widget.session.role == 'ADMIN' ||
        widget.session.role == 'DIRECTOR' ||
        widget.session.role == 'MANAGER';

    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.modal ? 980 : 1120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            VeloPrimeWorkspacePanel(
              tint: VeloPrimePalette.sea,
              radius: 30,
              padding: const EdgeInsets.all(28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 920;
                  const copy = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VeloPrimeSectionEyebrow(label: 'Nowy lead', color: VeloPrimePalette.sea),
                      SizedBox(height: 12),
                      Text(
                        'Dodaj nowy kontakt bez wychodzenia z pipeline.',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          height: 1.06,
                          color: VeloPrimePalette.ink,
                        ),
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Na starcie zbieramy tylko dane potrzebne do rozpoczecia pracy handlowej. Model samochodu pozostaje decyzja na etapie przygotowania oferty.',
                        style: TextStyle(color: VeloPrimePalette.muted, height: 1.6),
                      ),
                    ],
                  );

                  final actions = Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.9),
                          Color.alphaBlend(VeloPrimePalette.sea.withValues(alpha: 0.08), Colors.white),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: VeloPrimePalette.sea.withValues(alpha: 0.14)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const VeloPrimeSectionEyebrow(label: 'Akcje', color: VeloPrimePalette.sea),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(widget.modal ? Icons.close_rounded : Icons.arrow_back_rounded),
                              label: Text(widget.modal ? 'Zamknij' : 'Powrot'),
                            ),
                            FilledButton.icon(
                              onPressed: _isSaving ? null : _save,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.person_add_alt_1_outlined),
                              label: const Text('Utworz leada'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );

                  if (!isWide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [copy, const SizedBox(height: 20), actions],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(flex: 3, child: copy),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: actions),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            VeloPrimeWorkspacePanel(
              tint: VeloPrimePalette.sea,
              radius: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VeloPrimeSectionEyebrow(label: 'Dane leada', color: VeloPrimePalette.sea),
                  const SizedBox(height: 12),
                  const Text(
                    'Kontakt i kwalifikacja',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: VeloPrimePalette.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Minimalny zestaw do rozpoczecia pracy: klient, etap, przypisanie i podstawowy komentarz operacyjny.',
                    style: TextStyle(color: VeloPrimePalette.muted, height: 1.55),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF5F3), Color(0xFFFBE7E2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0x20A64B45)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFF8E372A), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _FormFieldShell(
                        width: 420,
                        child: TextField(
                          controller: _fullNameController,
                          decoration: veloPrimeInputDecoration('Imie i nazwisko'),
                        ),
                      ),
                      _FormFieldShell(
                        width: 280,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedStageId,
                          items: widget.stages
                              .map(
                                (stage) => DropdownMenuItem<String>(
                                  value: stage.id,
                                  child: Text(stage.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStageId = value;
                            });
                          },
                          decoration: veloPrimeInputDecoration('Etap startowy'),
                        ),
                      ),
                      if (canAssignSalesperson)
                        _FormFieldShell(
                          width: 320,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedSalespersonId,
                            items: [
                              ...widget.salespeople.map(
                                (user) => DropdownMenuItem<String>(
                                  value: user.id,
                                  child: Text(user.fullName),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedSalespersonId = value == null || value.isEmpty ? _selectedSalespersonId : value;
                              });
                            },
                            decoration: veloPrimeInputDecoration('Opiekun'),
                          ),
                        ),
                      _FormFieldShell(
                        width: 320,
                        child: TextField(
                          controller: _emailController,
                          decoration: veloPrimeInputDecoration('Email'),
                        ),
                      ),
                      _FormFieldShell(
                        width: 220,
                        child: TextField(
                          controller: _phoneController,
                          decoration: veloPrimeInputDecoration('Telefon'),
                        ),
                      ),
                      _FormFieldShell(
                        width: 220,
                        child: TextField(
                          controller: _regionController,
                          decoration: veloPrimeInputDecoration('Miasto'),
                        ),
                      ),
                      _FormFieldShell(
                        width: 920,
                        child: TextField(
                          controller: _messageController,
                          maxLines: 5,
                          decoration: veloPrimeInputDecoration('Komentarz / wiadomosc'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.modal) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: SingleChildScrollView(child: content),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VeloPrimeShell(
        decorateBackground: true,
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
        child: SingleChildScrollView(child: content),
      ),
    );
  }
}

class _FormFieldShell extends StatelessWidget {
  const _FormFieldShell({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}
