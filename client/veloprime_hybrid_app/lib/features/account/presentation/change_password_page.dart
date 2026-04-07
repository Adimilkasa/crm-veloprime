import 'package:file_selector/file_selector.dart';
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
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  AccountProfile? _profile;
  bool _isLoadingProfile = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _profileError;
  String? _profileNotice;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final profile = await widget.repository.fetchProfile();
      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
        _isLoadingProfile = false;
        _profileError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingProfile = false;
        _profileError = error.toString();
      });
    }
  }

  Future<void> _pickAvatar() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Obrazy', extensions: ['png', 'jpg', 'jpeg', 'webp']),
      ],
    );
    if (file == null) {
      return;
    }

    setState(() {
      _isUploadingAvatar = true;
      _profileError = null;
      _profileNotice = null;
    });

    try {
      final result = await widget.repository
          .uploadAvatar(filePath: file.path, fileName: file.name);
      if (!mounted) {
        return;
      }

      setState(() {
        _profile = result.profile;
        _profileNotice = result.warning?.trim().isNotEmpty == true
            ? result.warning!.trim()
            : null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                _profileNotice ?? 'Zdjęcie przedstawiciela zostało zapisane.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _profileError = error.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _removeAvatar() async {
    setState(() {
      _isUploadingAvatar = true;
      _profileError = null;
      _profileNotice = null;
    });

    try {
      final result = await widget.repository.removeAvatar();
      if (!mounted) {
        return;
      }

      setState(() {
        _profile = result.profile;
        _profileNotice = result.warning?.trim().isNotEmpty == true
            ? result.warning!.trim()
            : null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                _profileNotice ?? 'Zdjęcie przedstawiciela zostało usunięte.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _profileError = error.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      setState(() {
        _passwordError = 'Nowe hasla nie sa identyczne.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _passwordError = null;
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
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      if (!widget.embeddedInShell) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _passwordError = error.toString();
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
                    const copy = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VeloPrimeSectionEyebrow(
                            label: 'Security', color: accentColor),
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
                            Color.alphaBlend(
                                accentColor.withValues(alpha: 0.08),
                                Colors.white),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: accentColor.withValues(alpha: 0.14)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const VeloPrimeSectionEyebrow(
                              label: 'Akcje', color: accentColor),
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
                              const VeloPrimeBadge(
                                  label: 'Obszar', value: 'Sesja + konto'),
                            ],
                          ),
                        ],
                      ),
                    );

                    if (!isWide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          copy,
                          const SizedBox(height: 20),
                          actionPanel
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(flex: 3, child: copy),
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
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: VeloPrimeWorkspacePanel(
                    tint: accentColor,
                    radius: 30,
                    child: _isLoadingProfile
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 760;
                              final profile = _profile;
                              final avatar = _AccountAvatar(
                                avatarUrl: profile?.avatarUrl,
                                fullName: profile?.fullName ??
                                    'Przedstawiciel VeloPrime',
                                size: isWide ? 136 : 112,
                              );

                              final details = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const VeloPrimeSectionEyebrow(
                                      label: 'Profil przedstawiciela',
                                      color: accentColor),
                                  const SizedBox(height: 12),
                                  Text(
                                    profile?.fullName ?? 'Aktualny użytkownik',
                                    style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: VeloPrimePalette.ink),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    profile == null
                                        ? 'Pobieramy dane konta oraz zdjęcie, które będzie widoczne w wygenerowanej ofercie.'
                                        : 'To zdjęcie będzie wykorzystywane w sekcji opiekuna oferty w aplikacji i w publicznym linku dla klienta.',
                                    style: const TextStyle(
                                        color: VeloPrimePalette.muted,
                                        height: 1.6),
                                  ),
                                  const SizedBox(height: 18),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      if (profile != null)
                                        VeloPrimeBadge(
                                            label: 'Email',
                                            value: profile.email),
                                      if (profile?.phone != null &&
                                          profile!.phone!.trim().isNotEmpty)
                                        VeloPrimeBadge(
                                            label: 'Telefon',
                                            value: profile.phone!),
                                      if (profile != null)
                                        VeloPrimeBadge(
                                            label: 'Rola', value: profile.role),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      FilledButton.icon(
                                        onPressed: _isUploadingAvatar
                                            ? null
                                            : _pickAvatar,
                                        icon: _isUploadingAvatar
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white),
                                              )
                                            : const Icon(
                                                Icons.add_a_photo_outlined),
                                        label: Text(_isUploadingAvatar
                                            ? 'Wysyłanie...'
                                            : 'Dodaj lub zmień zdjęcie'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: _isUploadingAvatar ||
                                                profile?.avatarUrl == null
                                            ? null
                                            : _removeAvatar,
                                        icon: const Icon(
                                            Icons.delete_outline_rounded),
                                        label: const Text('Usuń zdjęcie'),
                                      ),
                                    ],
                                  ),
                                  if (_profileError != null) ...[
                                    const SizedBox(height: 16),
                                    _AccountFeedbackBanner(
                                      message: _profileError!,
                                      icon: Icons.error_outline_rounded,
                                      tone: const Color(0xFFB94A48),
                                      background: const Color(0xFFFFF1EF),
                                      foreground: const Color(0xFF7A231B),
                                    ),
                                  ],
                                  if (_profileNotice != null) ...[
                                    const SizedBox(height: 16),
                                    _AccountFeedbackBanner(
                                      message: _profileNotice!,
                                      icon: Icons.info_outline_rounded,
                                      tone: const Color(0xFFD4A84F),
                                      background: const Color(0xFFFFF8E8),
                                      foreground: const Color(0xFF6D5317),
                                    ),
                                  ],
                                ],
                              );

                              if (!isWide) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Align(
                                        alignment: Alignment.centerLeft,
                                        child: avatar),
                                    const SizedBox(height: 18),
                                    details,
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  avatar,
                                  const SizedBox(width: 24),
                                  Expanded(child: details),
                                ],
                              );
                            },
                          ),
                  ),
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
                        const VeloPrimeSectionEyebrow(
                            label: 'Zmiana hasla', color: accentColor),
                        const SizedBox(height: 12),
                        const Text(
                          'Nowe dane logowania',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: VeloPrimePalette.ink),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Wprowadz obecne haslo, a nastepnie ustaw nowy wariant dla konta. Proces pozostaje bez zmian.',
                          style: TextStyle(
                              color: VeloPrimePalette.muted, height: 1.6),
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
                          decoration:
                              veloPrimeInputDecoration('Powtorz nowe haslo'),
                        ),
                        if (_passwordError != null) ...[
                          const SizedBox(height: 14),
                          _AccountFeedbackBanner(
                            message: _passwordError!,
                            icon: Icons.error_outline_rounded,
                            tone: const Color(0xFFB94A48),
                            background: const Color(0xFFFFF1EF),
                            foreground: const Color(0xFF7A231B),
                          ),
                        ],
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
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
                  child: const VeloPrimeWorkspacePanel(
                    tint: accentColor,
                    radius: 28,
                    surfaceOpacity: 0.68,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VeloPrimeSectionEyebrow(
                            label: 'Wskazowki', color: accentColor),
                        SizedBox(height: 12),
                        Text(
                          'Po zapisaniu nowe haslo zaczyna obowiazywac dla konta powiazanego z aktualna sesja.',
                          style: TextStyle(
                              color: VeloPrimePalette.muted, height: 1.6),
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

class _AccountFeedbackBanner extends StatelessWidget {
  const _AccountFeedbackBanner({
    required this.message,
    required this.icon,
    required this.tone,
    required this.background,
    required this.foreground,
  });

  final String message;
  final IconData icon;
  final Color tone;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tone, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({
    required this.avatarUrl,
    required this.fullName,
    required this.size,
  });

  final String? avatarUrl;
  final String fullName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = _buildImage();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF2FB), Color(0xFFD9E3F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF13284A).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: image ??
          Center(
            child: Icon(Icons.person_rounded,
                size: size * 0.44, color: const Color(0xFF355274)),
          ),
    );
  }

  Widget? _buildImage() {
    final value = avatarUrl?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.startsWith('data:image/')) {
      UriData? uriData;
      try {
        uriData = UriData.parse(value);
      } catch (_) {
        uriData = null;
      }

      final bytes = uriData?.contentAsBytes();
      if (bytes == null) {
        return null;
      }

      return Image.memory(bytes, fit: BoxFit.cover);
    }

    return Image.network(value,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink());
  }
}
