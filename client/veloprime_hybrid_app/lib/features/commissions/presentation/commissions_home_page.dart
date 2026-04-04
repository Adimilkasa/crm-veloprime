import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/presentation/veloprime_ui.dart';
import '../../bootstrap/models/bootstrap_payload.dart';
import '../data/commissions_repository.dart';
import '../models/commission_models.dart';

class CommissionsHomePage extends StatefulWidget {
  const CommissionsHomePage({
    super.key,
    required this.session,
    required this.repository,
    this.embeddedInShell = false,
  });

  final SessionInfo session;
  final CommissionsRepository repository;
  final bool embeddedInShell;

  @override
  State<CommissionsHomePage> createState() => _CommissionsHomePageState();
}

class _CommissionsHomePageState extends State<CommissionsHomePage> {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy HH:mm');
  static const Color _accentColor = Color(0xFF2F855A);

  CommissionsWorkspaceData? _workspace;
  List<CommissionRuleModel> _draftRules = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSyncing = false;
  String? _error;
  String? _feedback;
  bool _isSuccessFeedback = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? targetUserId}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final workspace = await widget.repository.fetchWorkspace(targetUserId: targetUserId);

      if (!mounted) {
        return;
      }

      setState(() {
        _applyWorkspace(workspace);
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

  void _applyWorkspace(CommissionsWorkspaceData workspace) {
    _workspace = workspace;
    _draftRules = workspace.rules;
  }

  void _updateRuleType(String ruleId, String valueType) {
    setState(() {
      _draftRules = _draftRules
          .map((rule) => rule.id == ruleId ? rule.copyWith(valueType: valueType) : rule)
          .toList();
    });
  }

  void _updateRuleValue(String ruleId, String rawValue) {
    final trimmed = rawValue.trim();
    final nextValue = trimmed.isEmpty ? null : num.tryParse(trimmed.replaceAll(',', '.'));

    setState(() {
      _draftRules = _draftRules
          .map(
            (rule) => rule.id == ruleId
                ? rule.copyWith(value: nextValue, clearValue: trimmed.isEmpty)
                : rule,
          )
          .toList();
    });
  }

  Future<void> _saveRules() async {
    final workspace = _workspace;
    if (workspace == null || workspace.targetUserId == null || !workspace.editable) {
      return;
    }

    setState(() {
      _isSaving = true;
      _feedback = null;
      _error = null;
    });

    try {
      final saved = await widget.repository.saveRules(
        targetUserId: workspace.targetUserId!,
        rules: _draftRules,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _applyWorkspace(saved);
        _feedback = 'Lista prowizji zostala zapisana. Istniejace wpisy zostaly zachowane, a nowe modele wymagaja tylko uzupelnienia brakow.';
        _isSuccessFeedback = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _feedback = error.toString();
        _isSuccessFeedback = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _syncWorkspace() async {
    final workspace = _workspace;

    setState(() {
      _isSyncing = true;
      _feedback = null;
      _error = null;
    });

    try {
      final synced = await widget.repository.syncWorkspace(
        targetUserId: workspace?.targetUserId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _applyWorkspace(synced);
        _feedback = 'Lista modeli do prowizji zostala zsynchronizowana jawnie z CRM.';
        _isSuccessFeedback = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _feedback = error.toString();
        _isSuccessFeedback = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Map<String, List<CommissionRuleModel>> get _groupedRules {
    final groups = <String, List<CommissionRuleModel>>{};

    for (final rule in _draftRules) {
      groups.putIfAbsent(rule.brand, () => <CommissionRuleModel>[]).add(rule);
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final workspace = _workspace;
    final content = _isLoading
        ? const VeloPrimeWorkspaceState(
            tint: _accentColor,
            eyebrow: 'Prowizje',
            title: 'Ladujemy liste prowizji',
            message: 'Przygotowujemy konfiguracje dyrektora i managera per model.',
            isLoading: true,
          )
        : _error != null
            ? VeloPrimeWorkspaceState(
                tint: VeloPrimePalette.rose,
                eyebrow: 'Prowizje',
                title: 'Nie udalo sie pobrac listy prowizji',
                message: _error!,
                icon: Icons.warning_amber_rounded,
              )
            : workspace == null
                ? const VeloPrimeWorkspaceState(
                    tint: _accentColor,
                    eyebrow: 'Prowizje',
                    title: 'Brak danych prowizyjnych',
                    message: 'Najpierw zapisz polityke cenowa i dodaj dyrektorow lub managerow.',
                    icon: Icons.percent_outlined,
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VeloPrimeWorkspacePanel(
                          tint: _accentColor,
                          radius: 30,
                          padding: const EdgeInsets.all(28),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 1040;
                              final copy = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const VeloPrimeSectionEyebrow(label: 'Prowizje struktury', color: _accentColor),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Prowizje dyrektora i managera per model',
                                    style: TextStyle(
                                      color: VeloPrimePalette.ink,
                                      fontSize: 34,
                                      height: 1.05,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Po zmianie polityki cenowej CRM synchronizuje liste modeli z prowizjami. Istniejace wpisy zostaja zachowane, a nowe pozycje pojawiaja sie jako brakujace do uzupelnienia.',
                                    style: TextStyle(
                                      color: VeloPrimePalette.muted.withValues(alpha: 0.96),
                                      fontSize: 15,
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _CommissionPill(label: 'Rola', value: _roleLabel(widget.session.role), tint: _accentColor),
                                      _CommissionPill(label: 'Lacznie', value: '${workspace.summary.total}', tint: _accentColor),
                                      _CommissionPill(label: 'Uzupelnione', value: '${workspace.summary.configured}', tint: _accentColor),
                                      _CommissionPill(label: 'Brakujace', value: '${workspace.summary.missing}', tint: _accentColor),
                                    ],
                                  ),
                                ],
                              );
                              final meta = _CommissionInfoCard(
                                title: 'Ostatnia synchronizacja',
                                value: _formatDate(workspace.updatedAt),
                                subtitle: 'Ostatni zapis: ${workspace.updatedBy ?? 'brak autora'}',
                                tint: _accentColor,
                              );

                              if (!isWide) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    copy,
                                    const SizedBox(height: 20),
                                    meta,
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 3, child: copy),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 2, child: meta),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 1140;
                            final sidebar = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                VeloPrimeWorkspacePanel(
                                  tint: _accentColor,
                                  radius: 28,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.manage_accounts_outlined, color: _accentColor),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Zakres konfiguracji',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Administrator moze podejrzec kazda liste. Dyrektor i manager edytuja wlasna konfiguracje, a synchronizacja listy modeli jest uruchamiana jawnie.',
                                        style: TextStyle(color: VeloPrimePalette.muted, height: 1.55),
                                      ),
                                      const SizedBox(height: 16),
                                      if (widget.session.role == 'ADMIN')
                                        DropdownButtonFormField<String>(
                                          initialValue: workspace.targetUserId,
                                          decoration: const InputDecoration(labelText: 'Uzytkownik'),
                                          items: workspace.users
                                              .map(
                                                (user) => DropdownMenuItem<String>(
                                                  value: user.id,
                                                  child: Text('${user.fullName} (${user.role == 'DIRECTOR' ? 'Dyrektor' : 'Manager'})'),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (value) {
                                            if (value == null || value == workspace.targetUserId) {
                                              return;
                                            }
                                            _load(targetUserId: value);
                                          },
                                        )
                                      else
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.72),
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(color: _accentColor.withValues(alpha: 0.14)),
                                          ),
                                          child: Text(
                                            workspace.users.firstWhere(
                                              (user) => user.id == workspace.targetUserId,
                                              orElse: () => const CommissionUserOption(id: '', fullName: 'Brak uzytkownika', role: 'MANAGER'),
                                            ).fullName,
                                            style: const TextStyle(fontWeight: FontWeight.w600, color: VeloPrimePalette.ink),
                                          ),
                                        ),
                                      if (_feedback != null) ...[
                                        const SizedBox(height: 16),
                                        _CommissionFeedbackBox(
                                          message: _feedback!,
                                          isSuccess: _isSuccessFeedback,
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: _isSaving || _isSyncing ? null : _syncWorkspace,
                                          icon: _isSyncing
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Icon(Icons.sync_outlined),
                                          label: Text(_isSyncing ? 'Synchronizujemy...' : 'Synchronizuj liste modeli'),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.icon(
                                          onPressed: _isSaving || _isSyncing || !workspace.editable || workspace.targetUserId == null ? null : _saveRules,
                                          icon: _isSaving
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Icon(Icons.save_outlined),
                                          label: Text(_isSaving ? 'Zapisujemy...' : 'Zapisz liste prowizji'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const VeloPrimeWorkspacePanel(
                                  tint: _accentColor,
                                  radius: 28,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.rule_folder_outlined, color: _accentColor),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Zasada dzialania',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Text('Uzupelniasz tylko brakujace pozycje po zmianie katalogu.', style: TextStyle(color: VeloPrimePalette.muted, height: 1.55)),
                                      SizedBox(height: 14),
                                      Text('1. Aktualizacja polityki cenowej nie usuwa starych prowizji.', style: TextStyle(color: VeloPrimePalette.muted, height: 1.55)),
                                      SizedBox(height: 6),
                                      Text('2. Nowy model lub wersja dodaje tylko nowa pozycje do listy.', style: TextStyle(color: VeloPrimePalette.muted, height: 1.55)),
                                      SizedBox(height: 6),
                                      Text('3. Wartosc mozna ustawic kwotowo albo procentowo dla kazdej pozycji osobno.', style: TextStyle(color: VeloPrimePalette.muted, height: 1.55)),
                                    ],
                                  ),
                                ),
                              ],
                            );

                            final listPanel = VeloPrimeWorkspacePanel(
                              tint: _accentColor,
                              radius: 28,
                              child: _draftRules.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 44),
                                      child: Center(
                                        child: Text(
                                          'Brak pozycji prowizyjnych. Najpierw zapisz polityke cenowa i dodaj dyrektorow lub managerow.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: VeloPrimePalette.muted, height: 1.55),
                                        ),
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const VeloPrimeSectionEyebrow(label: 'Lista robocza', color: _accentColor),
                                        const SizedBox(height: 14),
                                        for (final entry in _groupedRules.entries) ...[
                                          Container(
                                            width: double.infinity,
                                            margin: const EdgeInsets.only(bottom: 14),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.68),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: _accentColor.withValues(alpha: 0.14)),
                                            ),
                                            child: Text(
                                              entry.key,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.3,
                                                color: _accentColor,
                                              ),
                                            ),
                                          ),
                                          ...entry.value.map((rule) => _CommissionRuleCard(
                                                rule: rule,
                                                editable: workspace.editable,
                                                onTypeChanged: (value) => _updateRuleType(rule.id, value),
                                                onValueChanged: (value) => _updateRuleValue(rule.id, value),
                                              )),
                                        ],
                                      ],
                                    ),
                            );

                            if (!isWide) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [sidebar, const SizedBox(height: 18), listPanel],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: 340, child: sidebar),
                                const SizedBox(width: 20),
                                Expanded(child: listPanel),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  );

    if (widget.embeddedInShell) {
      return content;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VeloPrimeShell(
        decorateBackground: false,
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
        child: content,
      ),
    );
  }
}

class _CommissionRuleCard extends StatelessWidget {
  const _CommissionRuleCard({
    required this.rule,
    required this.editable,
    required this.onTypeChanged,
    required this.onValueChanged,
  });

  final CommissionRuleModel rule;
  final bool editable;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onValueChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x1F2F855A)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          final cells = [
            _RuleInfo(label: 'Marka', value: rule.brand),
            _RuleInfo(label: 'Model', value: rule.model),
            _RuleInfo(label: 'Wersja', value: rule.version),
            _RuleInfo(label: 'Rocznik', value: rule.year ?? '—'),
          ];
          final controls = isWide
              ? Row(
                  children: [
                    Expanded(child: _typeSelector()),
                    const SizedBox(width: 12),
                    Expanded(child: _valueField()),
                  ],
                )
              : Column(
                  children: [
                    _typeSelector(),
                    const SizedBox(height: 12),
                    _valueField(),
                  ],
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: cells,
              ),
              const SizedBox(height: 14),
              controls,
            ],
          );
        },
      ),
    );
  }

  Widget _typeSelector() {
    return DropdownButtonFormField<String>(
      initialValue: rule.valueType,
      decoration: const InputDecoration(labelText: 'Typ'),
      items: const [
        DropdownMenuItem<String>(value: 'AMOUNT', child: Text('Kwota')),
        DropdownMenuItem<String>(value: 'PERCENT', child: Text('Procent')),
      ],
      onChanged: editable
          ? (value) {
              if (value != null) {
                onTypeChanged(value);
              }
            }
          : null,
    );
  }

  Widget _valueField() {
    return _CommissionValueField(
      key: ValueKey('commission-${rule.id}'),
      value: rule.value?.toString() ?? '',
      enabled: editable,
      hintText: rule.valueType == 'PERCENT' ? 'np. 10' : 'np. 3000',
      onChanged: onValueChanged,
    );
  }
}

class _CommissionValueField extends StatefulWidget {
  const _CommissionValueField({
    super.key,
    required this.value,
    required this.enabled,
    required this.hintText,
    required this.onChanged,
  });

  final String value;
  final bool enabled;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  State<_CommissionValueField> createState() => _CommissionValueFieldState();
}

class _CommissionValueFieldState extends State<_CommissionValueField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _CommissionValueField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: widget.onChanged,
      decoration: InputDecoration(labelText: 'Wartosc', hintText: widget.hintText),
    );
  }
}

class _RuleInfo extends StatelessWidget {
  const _RuleInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VeloPrimePalette.lineStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: VeloPrimePalette.muted)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink)),
        ],
      ),
    );
  }
}

class _CommissionPill extends StatelessWidget {
  const _CommissionPill({
    required this.label,
    required this.value,
    required this.tint,
  });

  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tint)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink)),
        ],
      ),
    );
  }
}

class _CommissionInfoCard extends StatelessWidget {
  const _CommissionInfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.tint,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.88),
            Color.alphaBlend(tint.withValues(alpha: 0.08), Colors.white),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tint.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tint)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: VeloPrimePalette.muted, height: 1.45)),
        ],
      ),
    );
  }
}

class _CommissionFeedbackBox extends StatelessWidget {
  const _CommissionFeedbackBox({
    required this.message,
    required this.isSuccess,
  });

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final background = isSuccess ? const Color(0xFFF4FBF8) : const Color(0xFFFFF5F4);
    final border = isSuccess ? const Color(0xFFD9ECE4) : const Color(0xFFF1D4D2);
    final foreground = isSuccess ? const Color(0xFF3F7D64) : const Color(0xFFA64B45);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Text(message, style: TextStyle(color: foreground, height: 1.45)),
    );
  }
}

String _roleLabel(String role) {
  switch (role) {
    case 'ADMIN':
      return 'Administrator';
    case 'DIRECTOR':
      return 'Dyrektor';
    case 'MANAGER':
      return 'Manager';
    default:
      return 'Handlowiec';
  }
}

String _formatDate(String? value) {
  if (value == null || value.isEmpty) {
    return 'Brak synchronizacji';
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  return _CommissionsHomePageState._dateFormat.format(parsed);
}