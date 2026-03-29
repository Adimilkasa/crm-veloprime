import 'package:flutter/material.dart';

import '../../../core/presentation/veloprime_ui.dart';
import '../data/account_repository.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({
    super.key,
    required this.repository,
    this.onBack,
    this.embeddedInShell = false,
  });

  final AccountRepository repository;
  final VoidCallback? onBack;
  final bool embeddedInShell;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      setState(() {
        _error = 'Nowe hasla nie sa identyczne.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await widget.repository.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: newPassword,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Haslo zostalo zmienione.')),
      );
      Navigator.of(context).pop();
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
    const accentColor = VeloPrimePalette.sea;
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VeloPrimeWorkspacePanel(
                tint: accentColor,
                radius: 30,
                padding: const EdgeInsets.all(28),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 980;
                    final copy = const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VeloPrimeSectionEyebrow(label: 'Security', color: accentColor),
                        SizedBox(height: 12),
                        Text(
                          'Konto i bezpieczenstwo bez opuszczania klienta desktopowego.',
                          style: TextStyle(
                            color: VeloPrimePalette.ink,
                            fontSize: 38,
                            height: 1.04,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Zmiana hasla pozostaje ta sama operacja, ale jest teraz osadzona w tym samym workspace co leady, oferty i administracja.',
                          style: TextStyle(
                            color: VeloPrimePalette.muted,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                      ],
                    );

                    final actionPanel = Container(
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
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  label: const Text('Powrot'),
                                ),
                              const VeloPrimeBadge(label: 'Obszar', value: 'Sesja + konto'),
                            ],
                          ),
                        ],
                      ),
                    );

                    if (!isWide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [copy, const SizedBox(height: 20), actionPanel],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: copy),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: actionPanel),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: VeloPrimeWorkspacePanel(
                    tint: accentColor,
                    radius: 30,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const VeloPrimeSectionEyebrow(label: 'Zmiana hasla', color: accentColor),
                        const SizedBox(height: 12),
                        const Text(
                          'Nowe dane logowania',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Wprowadz obecne haslo, a nastepnie ustaw nowy wariant dla konta. Proces pozostaje bez zmian.',
                          style: TextStyle(color: VeloPrimePalette.muted, height: 1.6),
                        ),
                        const SizedBox(height: 22),
                        TextField(
                          controller: _currentPasswordController,
                          obscureText: true,
                          decoration: veloPrimeInputDecoration('Obecne haslo'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _newPasswordController,
                          obscureText: true,
                          decoration: veloPrimeInputDecoration('Nowe haslo'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: veloPrimeInputDecoration('Powtorz nowe haslo'),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(_error!, style: const TextStyle(color: Color(0xFF8E372A), fontWeight: FontWeight.w600)),
                        ],
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.lock_reset_rounded),
                          label: const Text('Zmien haslo'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: VeloPrimeWorkspacePanel(
                    tint: accentColor,
                    radius: 28,
                    surfaceOpacity: 0.68,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VeloPrimeSectionEyebrow(label: 'Wskazowki', color: accentColor),
                        SizedBox(height: 12),
                        Text(
                          'Po zapisaniu nowe haslo zaczyna obowiazywac dla konta powiazanego z aktualna sesja.',
                          style: TextStyle(color: VeloPrimePalette.muted, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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