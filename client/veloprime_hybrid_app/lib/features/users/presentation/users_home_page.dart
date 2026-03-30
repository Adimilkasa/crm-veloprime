import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/presentation/veloprime_ui.dart';
import '../data/users_repository.dart';
import '../models/user_models.dart';

class UsersHomePage extends StatefulWidget {
  const UsersHomePage({
    super.key,
    required this.repository,
    this.onBack,
    this.embeddedInShell = false,
  });

  final UsersRepository repository;
  final VoidCallback? onBack;
  final bool embeddedInShell;

  @override
  State<UsersHomePage> createState() => _UsersHomePageState();
}

class _UsersHomePageState extends State<UsersHomePage> {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  UsersOverview? _overview;
  bool _isLoading = true;
  String? _error;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _teamController = TextEditingController();
  String _role = 'SALES';
  String? _reportsToUserId;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _regionController.dispose();
    _teamController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final overview = await widget.repository.fetchUsers();

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

  Future<void> _createUser() async {
    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final result = await widget.repository.createUser({
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
        'role': _role,
        'region': _regionController.text.trim(),
        'teamName': _teamController.text.trim(),
        'reportsToUserId': _reportsToUserId ?? '',
      });

      if (!mounted) {
        return;
      }

      _fullNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _passwordController.clear();
      _regionController.clear();
      _teamController.clear();
      setState(() {
        _role = 'SALES';
        _reportsToUserId = null;
      });

      await _load();

      if (!mounted) {
        return;
      }

      final tempPassword = result.temporaryPassword;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tempPassword == null || tempPassword.isEmpty
                ? 'Konto zostalo utworzone.'
                : 'Konto utworzone. Haslo tymczasowe: $tempPassword',
          ),
        ),
      );
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
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _toggleStatus(ManagedUserAccount user) async {
    try {
      await widget.repository.toggleStatus(user.id);
      if (!mounted) {
        return;
      }
      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _resetPassword(ManagedUserAccount user) async {
    try {
      final password = await widget.repository.resetPassword(user.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nowe haslo tymczasowe dla ${user.fullName}: $password')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    const accentColor = VeloPrimePalette.sea;
    final content = _isLoading
        ? const VeloPrimeWorkspaceState(
            tint: accentColor,
            eyebrow: 'Uzytkownicy',
            title: 'Ladujemy zespol i role',
            message: 'Przygotowujemy liste kont, role i relacje raportowania.',
            isLoading: true,
          )
        : _error != null
            ? VeloPrimeWorkspaceState(
                tint: VeloPrimePalette.rose,
                eyebrow: 'Uzytkownicy',
                title: 'Nie udalo sie pobrac danych uzytkownikow',
                message: _error!,
                icon: Icons.warning_amber_rounded,
              )
            : overview == null
                ? const VeloPrimeWorkspaceState(
                    tint: accentColor,
                    eyebrow: 'Uzytkownicy',
                    title: 'Brak danych uzytkownikow',
                    message: 'Konta pojawia sie tutaj po pierwszej synchronizacji lub dodaniu nowego uzytkownika.',
                    icon: Icons.manage_accounts_outlined,
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VeloPrimeWorkspacePanel(
                          tint: accentColor,
                          radius: 30,
                          padding: const EdgeInsets.all(28),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 1060;
                              final copy = const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  VeloPrimeSectionEyebrow(label: 'Uzytkownicy', color: accentColor),
                                  SizedBox(height: 12),
                                  Text(
                                    'Administracja kontami bez schodzenia do paneli technicznych.',
                                    style: TextStyle(
                                      color: VeloPrimePalette.ink,
                                      fontSize: 38,
                                      height: 1.04,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 14),
                                  Text(
                                    'Tworz konta, resetuj hasla i kontroluj aktywnosc uzytkownikow z jednego miejsca.',
                                    style: TextStyle(
                                      color: VeloPrimePalette.muted,
                                      fontSize: 15,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              );

                              final actions = Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.9),
                                      Color.alphaBlend(accentColor.withValues(alpha: 0.08), Colors.white),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: accentColor.withValues(alpha: 0.14)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const VeloPrimeSectionEyebrow(label: 'Akcje', color: accentColor),
                                    const SizedBox(height: 14),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        if (widget.onBack != null)
                                          OutlinedButton.icon(
                                            onPressed: widget.onBack,
                                            icon: const Icon(Icons.arrow_back_outlined),
                                            label: const Text('Powrot'),
                                          ),
                                        OutlinedButton.icon(
                                          onPressed: _load,
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Odswiez'),
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
                                  Expanded(flex: 3, child: copy),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 2, child: actions),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            VeloPrimeMetricCard(label: 'Wszystkie konta', value: '${overview.users.length}', accentColor: accentColor),
                            VeloPrimeMetricCard(
                              label: 'Aktywne',
                              value: '${overview.users.where((user) => user.isActive).length}',
                              accentColor: VeloPrimePalette.olive,
                            ),
                            VeloPrimeMetricCard(
                              label: 'Role systemowe',
                              value: '${overview.users.map((user) => user.role).toSet().length}',
                              accentColor: VeloPrimePalette.sea,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        VeloPrimeWorkspacePanel(
                          tint: accentColor,
                          radius: 30,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const VeloPrimeSectionEyebrow(label: 'Nowe konto', color: accentColor),
                              const SizedBox(height: 12),
                              const Text('Nowe konto', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink)),
                              const SizedBox(height: 8),
                              const Text(
                                'Tworzenie uzytkownika pozostaje w tym samym procesie, ale formularz jest teraz osadzony w tej samej warstwie roboczej co leady i oferty.',
                                style: TextStyle(color: VeloPrimePalette.muted, height: 1.6),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  _FormFieldShell(width: 320, child: TextField(controller: _fullNameController, decoration: veloPrimeInputDecoration('Imię i nazwisko'))),
                                  _FormFieldShell(width: 280, child: TextField(controller: _emailController, decoration: veloPrimeInputDecoration('Email'))),
                                  _FormFieldShell(width: 220, child: TextField(controller: _phoneController, decoration: veloPrimeInputDecoration('Telefon'))),
                                  _FormFieldShell(width: 280, child: TextField(controller: _passwordController, decoration: veloPrimeInputDecoration('Hasło startowe (opcjonalnie)'))),
                                  _FormFieldShell(
                                    width: 220,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _role,
                                      items: const [
                                        DropdownMenuItem(value: 'ADMIN', child: Text('Administrator')),
                                        DropdownMenuItem(value: 'DIRECTOR', child: Text('Dyrektor')),
                                        DropdownMenuItem(value: 'MANAGER', child: Text('Manager')),
                                        DropdownMenuItem(value: 'SALES', child: Text('Handlowiec')),
                                      ],
                                      onChanged: (value) {
                                        if (value == null) {
                                          return;
                                        }
                                        setState(() {
                                          _role = value;
                                        });
                                      },
                                      decoration: veloPrimeInputDecoration('Rola'),
                                    ),
                                  ),
                                  _FormFieldShell(width: 220, child: TextField(controller: _regionController, decoration: veloPrimeInputDecoration('Region'))),
                                  _FormFieldShell(width: 220, child: TextField(controller: _teamController, decoration: veloPrimeInputDecoration('Zespół'))),
                                  _FormFieldShell(
                                    width: 320,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _reportsToUserId,
                                      items: [
                                        const DropdownMenuItem<String>(value: '', child: Text('Brak przypisania')),
                                        ...overview.supervisors.map(
                                          (user) => DropdownMenuItem<String>(
                                            value: user.id,
                                            child: Text('${user.fullName} (${_roleLabel(user.role)})'),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _reportsToUserId = value == null || value.isEmpty ? null : value;
                                        });
                                      },
                                      decoration: veloPrimeInputDecoration('Przełożony'),
                                    ),
                                  ),
                                ],
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Text(_error!, style: const TextStyle(color: Color(0xFF8E372A), fontWeight: FontWeight.w600)),
                              ],
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _isCreating ? null : _createUser,
                                child: _isCreating
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Utwórz konto'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...overview.users.map(
                          (user) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: VeloPrimeWorkspacePanel(
                              tint: user.isActive ? VeloPrimePalette.olive : const Color(0xFF9B6B5C),
                              radius: 28,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        VeloPrimeSectionEyebrow(
                                          label: user.isActive ? 'Konto aktywne' : 'Konto zablokowane',
                                          color: user.isActive ? VeloPrimePalette.olive : const Color(0xFF9B6B5C),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(user.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 4),
                                        Text('${user.email} • ${user.phone ?? 'Brak telefonu'} • ${_roleLabel(user.role)}', style: const TextStyle(color: VeloPrimePalette.muted)),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 12,
                                          children: [
                                            VeloPrimeBadge(label: 'Status', value: user.isActive ? 'Aktywny' : 'Zablokowany'),
                                            VeloPrimeBadge(label: 'Region', value: user.region ?? 'Brak'),
                                            VeloPrimeBadge(label: 'Źródło', value: user.source),
                                            VeloPrimeBadge(label: 'Dodano', value: _formatDate(user.createdAt)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.88),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: VeloPrimePalette.lineStrong),
                                    ),
                                    child: Column(
                                      children: [
                                        OutlinedButton(
                                          onPressed: () => _toggleStatus(user),
                                          child: Text(user.isActive ? 'Zablokuj' : 'Aktywuj'),
                                        ),
                                        const SizedBox(height: 8),
                                        FilledButton.tonal(
                                          onPressed: () => _resetPassword(user),
                                          child: const Text('Reset hasła'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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

class _FormFieldShell extends StatelessWidget {
  const _FormFieldShell({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
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

String _formatDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  return _UsersHomePageState._dateFormat.format(parsed);
}