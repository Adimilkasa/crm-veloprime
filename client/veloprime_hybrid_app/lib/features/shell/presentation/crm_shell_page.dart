import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/config/client_artifact_versions.dart';
import '../../../core/presentation/veloprime_ui.dart';
import '../../account/data/account_repository.dart';
import '../../account/presentation/change_password_page.dart';
import '../../bootstrap/models/bootstrap_payload.dart';
import '../../commissions/data/commissions_repository.dart';
import '../../commissions/presentation/commissions_home_page.dart';
import '../../customers/data/customers_repository.dart';
import '../../customers/presentation/customers_home_page.dart';
import '../../dashboard/presentation/dashboard_home_page.dart';
import '../../leads/data/leads_repository.dart';
import '../../leads/presentation/lead_detail_page.dart';
import '../../leads/presentation/leads_home_page.dart';
import '../../offers/data/offers_repository.dart';
import '../../offers/presentation/offers_home_page.dart';
import '../../pricing/data/pricing_repository.dart';
import '../../pricing/presentation/pricing_home_page.dart';
import '../../reminders/data/reminders_repository.dart';
import '../../reminders/models/reminder_models.dart';
import '../../update/data/update_repository.dart';
import '../../update/models/update_models.dart';
import '../../update/presentation/update_admin_page.dart';
import '../../update/presentation/update_gate_page.dart';
import '../../users/data/users_repository.dart';
import '../../users/presentation/users_home_page.dart';
import 'module_placeholder_page.dart';

class _BackgroundPreset {
  const _BackgroundPreset({
    required this.key,
    required this.label,
    required this.description,
    required this.assetPath,
    required this.overlayGradient,
    required this.overlayColor,
    required this.primaryGlow,
    required this.secondaryGlow,
    required this.swatchOverlay,
  });

  final String key;
  final String label;
  final String description;
  final String assetPath;
  final Gradient overlayGradient;
  final Color overlayColor;
  final Color primaryGlow;
  final Color secondaryGlow;
  final Gradient swatchOverlay;
}

final _backgroundPresets = <_BackgroundPreset>[
  const _BackgroundPreset(
    key: 'Biały',
    label: 'Biały',
    description: 'Jasny wariant z miękkim studyjnym światłem i spokojnym tłem pracy.',
    assetPath: 'assets/backgrounds/Biały.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xD9FFFDF8), Color(0xC7F5F1EA), Color(0xBAEEE8DF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x52FFFDF9),
    primaryGlow: Color(0x18EEDBB2),
    secondaryGlow: Color(0x12D7E7FF),
    swatchOverlay: LinearGradient(
      colors: [Color(0x12FFFFFF), Color(0x3AFFF4E0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  const _BackgroundPreset(
    key: 'Błękitny',
    label: 'Błękitny',
    description: 'Domyślne tło. Najczystszy, spokojny błękit dla całej aplikacji.',
    assetPath: 'assets/backgrounds/Błękitny.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xAAFCFEFF), Color(0x7AEAF4FF), Color(0x8FCFDBF3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x3DE7F3FF),
    primaryGlow: Color(0x304A90E2),
    secondaryGlow: Color(0x1ABCE4FF),
    swatchOverlay: LinearGradient(
      colors: [Color(0x10FFFFFF), Color(0x221B5FBC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  const _BackgroundPreset(
    key: 'Dark',
    label: 'Dark',
    description: 'Najmocniejszy wieczorny wariant z ciemniejszą sceną i neonem.',
    assetPath: 'assets/backgrounds/Dark.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xB30A1431), Color(0x95112654), Color(0x8A09101F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x6407111F),
    primaryGlow: Color(0x3B3FA9FF),
    secondaryGlow: Color(0x309A59FF),
    swatchOverlay: LinearGradient(
      colors: [Color(0x16000000), Color(0x3A0B1F52)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  const _BackgroundPreset(
    key: 'Granatowy',
    label: 'Granatowy',
    description: 'Głęboki kadr z większym kontrastem i mocnym nocnym charakterem.',
    assetPath: 'assets/backgrounds/Granatowy.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xB6081535), Color(0x940D214F), Color(0x8A0B1229)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x60081227),
    primaryGlow: Color(0x382675FF),
    secondaryGlow: Color(0x264ED7FF),
    swatchOverlay: LinearGradient(
      colors: [Color(0x18000000), Color(0x2E0D2250)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  const _BackgroundPreset(
    key: 'Indygo',
    label: 'Indygo',
    description: 'Chłodny, ciemniejszy balans z lekkim technologicznym sznytem.',
    assetPath: 'assets/backgrounds/Indygo.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xA60B1636), Color(0x84162758), Color(0x82111A40)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x540B1635),
    primaryGlow: Color(0x2E5866FF),
    secondaryGlow: Color(0x22D45CFF),
    swatchOverlay: LinearGradient(
      colors: [Color(0x16000000), Color(0x2A1E2566)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  const _BackgroundPreset(
    key: 'Lawendowy',
    label: 'Lawendowy',
    description: 'Jaśniejszy, chłodny wariant z bardziej miękkim światłem tła.',
    assetPath: 'assets/backgrounds/Lawendowy.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xA9FFFDFE), Color(0x7FD9DDFD), Color(0x8EBBC8F2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x34EEF0FF),
    primaryGlow: Color(0x244F7CFF),
    secondaryGlow: Color(0x1ADDDCFF),
    swatchOverlay: LinearGradient(
      colors: [Color(0x10FFFFFF), Color(0x241C2E66)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  const _BackgroundPreset(
    key: 'Niebieski',
    label: 'Niebieski',
    description: 'Niebieskie tło z mocniejszą energią i wyraźniejszym kontrastem.',
    assetPath: 'assets/backgrounds/Niebieski.png',
    overlayGradient: LinearGradient(
      colors: [Color(0x9AFBFEFF), Color(0x5BD6E5FF), Color(0x78B2C7EA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x34DCEEFF),
    primaryGlow: Color(0x26549EEF),
    secondaryGlow: Color(0x1ABEE0FF),
    swatchOverlay: LinearGradient(
      colors: [Color(0x10FFFFFF), Color(0x2011346D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  const _BackgroundPreset(
    key: 'Różowy',
    label: 'Różowy',
    description: 'Subtelnie bardziej miękki wariant z cieplejszym światłem na kartach.',
    assetPath: 'assets/backgrounds/Różowy.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xACFFFDFE), Color(0x83F2DBEC), Color(0x85E2C9DC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x32FBE6EF),
    primaryGlow: Color(0x20C57D9A),
    secondaryGlow: Color(0x18FDBDD0),
    swatchOverlay: LinearGradient(
      colors: [Color(0x10FFFFFF), Color(0x22A44E79)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  const _BackgroundPreset(
    key: 'Szary',
    label: 'Szary',
    description: 'Neutralne tło do dłuższej pracy, z najmniejszą ilością koloru.',
    assetPath: 'assets/backgrounds/Szary.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xB7FFFFFF), Color(0x8BECEEF3), Color(0x8FDEE4EC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x32F6F9FC),
    primaryGlow: Color(0x180E1B34),
    secondaryGlow: Color(0x149EBDE7),
    swatchOverlay: LinearGradient(
      colors: [Color(0x10FFFFFF), Color(0x22000000)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  const _BackgroundPreset(
    key: 'Wiśniowy',
    label: 'Wiśniowy',
    description: 'Mocniejszy, bardziej charakterystyczny wariant z ciepłym akcentem.',
    assetPath: 'assets/backgrounds/Wiśniowy.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xB90D1732), Color(0x8F421433), Color(0x7F1A0D1E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x56210B19),
    primaryGlow: Color(0x28CF5E72),
    secondaryGlow: Color(0x18A85BFF),
    swatchOverlay: LinearGradient(
      colors: [Color(0x18000000), Color(0x2A4B1125)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  const _BackgroundPreset(
    key: 'Zielony',
    label: 'Zielony',
    description: 'Świeży wariant z chłodnym światłem i spokojniejszym rytmem ekranu.',
    assetPath: 'assets/backgrounds/Zielony.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xAEFFFDF8), Color(0x82E0F4E9), Color(0x85CAE8D7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x36E4F5EA),
    primaryGlow: Color(0x221F8F6A),
    secondaryGlow: Color(0x18A3F0D0),
    swatchOverlay: LinearGradient(
      colors: [Color(0x10FFFFFF), Color(0x224D8457)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  const _BackgroundPreset(
    key: 'Złoty',
    label: 'Złoty',
    description: 'Najbardziej premium wariant z cieplejszym złotym odbiciem.',
    assetPath: 'assets/backgrounds/Złoty.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xBCFFFDF8), Color(0x94F4E6C6), Color(0x8FE0CEAE)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x42FFF3D6),
    primaryGlow: Color(0x2AD4A84F),
    secondaryGlow: Color(0x18FFD998),
    swatchOverlay: LinearGradient(
      colors: [Color(0x10FFFFFF), Color(0x28B5801A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  const _BackgroundPreset(
    key: 'Żółty',
    label: 'Żółty',
    description: 'Jaśniejszy wariant z wyraźnym słonecznym wejściem w tle.',
    assetPath: 'assets/backgrounds/Żółty.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xC4FFFDF8), Color(0xA5FFF0BE), Color(0x96F3D89A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x48FFF0B5),
    primaryGlow: Color(0x2DEFCB58),
    secondaryGlow: Color(0x14FFD96A),
    swatchOverlay: LinearGradient(
      colors: [Color(0x10FFFFFF), Color(0x28D6A542)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  const _BackgroundPreset(
    key: 'propozycja',
    label: 'propozycja',
    description: 'Alternatywny wariant tła o bardziej wyrazistym kontraście.',
    assetPath: 'assets/backgrounds/propozycja.png',
    overlayGradient: LinearGradient(
      colors: [Color(0x8EFFFDFE), Color(0x66CFDCF5), Color(0x73B2C4E6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x2FE1EEFF),
    primaryGlow: Color(0x225B89E7),
    secondaryGlow: Color(0x1AC8D8FF),
    swatchOverlay: LinearGradient(
      colors: [Color(0x10FFFFFF), Color(0x2013316A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
];

class CrmShellPage extends StatefulWidget {
  const CrmShellPage({
    super.key,
    required this.session,
    required this.bootstrap,
    required this.accountRepository,
    required this.commissionsRepository,
    required this.customersRepository,
    required this.leadsRepository,
    required this.offersRepository,
    required this.pricingRepository,
    required this.remindersRepository,
    required this.updateRepository,
    required this.usersRepository,
    required this.onRefreshBootstrap,
    required this.onLogout,
  });

  final SessionInfo session;
  final BootstrapPayload bootstrap;
  final AccountRepository accountRepository;
  final CommissionsRepository commissionsRepository;
  final CustomersRepository customersRepository;
  final LeadsRepository leadsRepository;
  final OffersRepository offersRepository;
  final PricingRepository pricingRepository;
  final RemindersRepository remindersRepository;
  final UpdateRepository updateRepository;
  final UsersRepository usersRepository;
  final Future<void> Function() onRefreshBootstrap;
  final Future<void> Function() onLogout;

  @override
  State<CrmShellPage> createState() => _CrmShellPageState();
}

class _CrmShellPageState extends State<CrmShellPage> with WindowListener {
  static const Duration _updateCheckInterval = Duration(minutes: 5);
  static const String _backgroundPreferenceKey = 'crm_shell_background_preset';
  static const String _dashboardRoute = 'dashboard';
  static const String _leadsRoute = 'leads';
  static const String _customersRoute = 'customers';
  static const String _vehiclesRoute = 'vehicles';
  static const String _offersRoute = 'offers';
  static const String _commissionsRoute = 'commissions';
  static const String _pricingRoute = 'pricing';
  static const String _updatesRoute = 'updates';
  static const String _accountRoute = 'account';
  static const String _usersRoute = 'users';

  String _selectedRoute = _dashboardRoute;
  String _backgroundPresetKey = 'Błękitny';
  late final ValueNotifier<OfferWorkspaceLaunchRequest?> _offerWorkspaceLaunchNotifier = ValueNotifier<OfferWorkspaceLaunchRequest?>(null);
  Timer? _updateCheckTimer;
  bool _isCheckingForUpdates = false;
  bool _isUpdateGateOpen = false;
  bool _isExitFlowActive = false;
  bool _isClosingWindow = false;
  String? _lastPromptedUpdateSignature;
  List<ManagedReminderInfo> _reminders = const [];
  bool _isLoadingReminders = false;

  @override
  void initState() {
    super.initState();
    _restoreBackgroundPreset();
    _startUpdatePolling();
    unawaited(_loadReminders(silent: true));
    unawaited(_configureWindowCloseHandling());
  }

  @override
  void dispose() {
    _updateCheckTimer?.cancel();
    _offerWorkspaceLaunchNotifier.dispose();
    if (!kIsWeb && Platform.isWindows) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _configureWindowCloseHandling() async {
    if (kIsWeb || !Platform.isWindows) {
      return;
    }

    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
  }

  @override
  Future<void> onWindowClose() async {
    await _requestSafeClose();
  }

  Future<bool> _confirmSessionExit(_SessionExitMode mode) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _ExitSyncDialog(
            repository: widget.leadsRepository,
            mode: mode,
          ),
        ) ??
        false;
  }

  Future<void> _requestSafeClose() async {
    if (kIsWeb || !Platform.isWindows || _isClosingWindow || _isExitFlowActive) {
      return;
    }

    _isExitFlowActive = true;
    final shouldClose = await _confirmSessionExit(_SessionExitMode.closeApp);
    _isExitFlowActive = false;

    if (!shouldClose || !mounted) {
      return;
    }

    _isClosingWindow = true;
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }

  Future<void> _startLogoutFlow() async {
    if (_isExitFlowActive) {
      return;
    }

    _isExitFlowActive = true;
    final shouldLogout = await _confirmSessionExit(_SessionExitMode.logout);
    _isExitFlowActive = false;

    if (!shouldLogout || !mounted) {
      return;
    }

    try {
      await widget.onLogout();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się wylogować. $error')),
      );
    }
  }

  _BackgroundPreset get _activeBackgroundPreset {
    return _backgroundPresets.firstWhere(
      (preset) => preset.key == _backgroundPresetKey,
      orElse: () => _backgroundPresets.firstWhere(
        (preset) => preset.key == 'Błękitny',
        orElse: () => _backgroundPresets.first,
      ),
    );
  }

  Future<void> _restoreBackgroundPreset() async {
    final preferences = await SharedPreferences.getInstance();
    final savedKey = preferences.getString(_backgroundPreferenceKey);

    if (!mounted || savedKey == null) {
      return;
    }

    if (_backgroundPresets.any((preset) => preset.key == savedKey)) {
      setState(() {
        _backgroundPresetKey = savedKey;
      });
    }
  }

  Future<void> _setBackgroundPreset(String value) async {
    if (!_backgroundPresets.any((preset) => preset.key == value)) {
      return;
    }

    setState(() {
      _backgroundPresetKey = value;
    });

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_backgroundPreferenceKey, value);
  }

  void _startUpdatePolling() {
    _updateCheckTimer?.cancel();
    _updateCheckTimer = Timer.periodic(_updateCheckInterval, (_) {
      _checkForPublishedUpdates();
    });
  }

  String _buildUpdateSignature(VersionComparisonResult comparison) {
    final pendingItems = comparison.items.where((item) => item.requiresUpdate).toList()
      ..sort((left, right) => left.artifactType.compareTo(right.artifactType));

    return pendingItems
        .map((item) => '${item.artifactType}:${item.currentVersion ?? 'brak'}>${item.publishedVersion}:${item.priority}')
        .join('|');
  }

  Future<bool> _synchronizePublishedData() async {
    await widget.onRefreshBootstrap();

    if (!mounted) {
      return false;
    }

    final comparison = await widget.updateRepository.compareVersions(
      ClientVersionPayload(
        dataVersion: ClientArtifactVersions.syncedDataVersion,
        assetsVersion: ClientArtifactVersions.syncedAssetsVersion,
        applicationVersion: ClientArtifactVersions.syncedApplicationVersion,
      ),
    );

    if (!mounted) {
      return false;
    }

    final requiresOnlyApplicationUpdate = comparison.items.any((item) => item.requiresUpdate && item.artifactType == 'APPLICATION');
    final synchronized = !comparison.requiresAnyUpdate || requiresOnlyApplicationUpdate;

    if (synchronized) {
      _lastPromptedUpdateSignature = requiresOnlyApplicationUpdate ? _buildUpdateSignature(comparison) : null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dane i materialy zostaly zsynchronizowane z centrala.')),
      );
    }

    return synchronized;
  }

  Future<void> _checkForPublishedUpdates() async {
    if (!mounted || _isCheckingForUpdates || _isUpdateGateOpen) {
      return;
    }

    _isCheckingForUpdates = true;

    try {
      final comparison = await widget.updateRepository.compareVersions(
        ClientVersionPayload(
          dataVersion: ClientArtifactVersions.syncedDataVersion,
          assetsVersion: ClientArtifactVersions.syncedAssetsVersion,
          applicationVersion: ClientArtifactVersions.syncedApplicationVersion,
        ),
      );

      if (!mounted || !comparison.requiresAnyUpdate) {
        if (!comparison.requiresAnyUpdate) {
          _lastPromptedUpdateSignature = null;
        }

        return;
      }

      final signature = _buildUpdateSignature(comparison);

      if (signature == _lastPromptedUpdateSignature) {
        return;
      }

      _lastPromptedUpdateSignature = signature;
      _isUpdateGateOpen = true;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => UpdateGatePage(
            comparison: comparison,
            onSynchronizeSystemData: comparison.items.any((item) => item.requiresUpdate && item.artifactType != 'APPLICATION')
                ? _synchronizePublishedData
                : null,
          ),
        ),
      );
    } catch (_) {
      // Keep polling lightweight and silent during normal work.
    } finally {
      _isUpdateGateOpen = false;
      _isCheckingForUpdates = false;
    }
  }

  void _openMainTab(String route) {
    setState(() => _selectedRoute = route);
  }

  void _openDestination(String route) {
    setState(() => _selectedRoute = route);
  }

  void _openAccountPage() {
    _openDestination(_accountRoute);
  }

  void _openUsersPage() {
    _openDestination(_usersRoute);
  }

  void _openUpdatesPage() {
    _openDestination(_updatesRoute);
  }

  Future<void> _openOffersWorkspaceForLead(OfferWorkspaceLaunchRequest request) async {
    try {
      await widget.onRefreshBootstrap();
    } catch (_) {
      // Open the workspace even when the shared refresh is temporarily unavailable.
    }

    _offerWorkspaceLaunchNotifier.value = request;
    _openMainTab(_offersRoute);
  }

  Future<void> _synchronizeLocalChanges() async {
    final synchronized = await widget.leadsRepository.synchronizeNow();

    if (!mounted) {
      return;
    }

    final snapshot = widget.leadsRepository.syncSnapshot.value;
    if (synchronized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokalne zmiany zostaly zsynchronizowane.')),
      );
      return;
    }

    final errorMessage = snapshot.lastError;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          errorMessage == null || errorMessage.isEmpty
              ? 'Nie udalo sie jeszcze zsynchronizowac wszystkich lokalnych zmian.'
              : 'Synchronizacja lokalnych zmian nie powiodla sie.\n$errorMessage',
        ),
      ),
    );
  }

  Future<void> _loadReminders({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _isLoadingReminders = true;
      });
    }

    try {
      final reminders = await widget.remindersRepository.fetchActiveReminders();

      if (!mounted) {
        return;
      }

      setState(() {
        _reminders = reminders;
        _isLoadingReminders = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingReminders = false;
      });
    }
  }

  Future<void> _handleRemindersChanged() async {
    await _loadReminders(silent: true);
  }

  Future<void> _completeReminder(String reminderId) async {
    try {
      await widget.remindersRepository.completeReminder(reminderId);
      await _loadReminders(silent: true);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Przypomnienie zostało oznaczone jako wykonane.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _openReminderLead(ManagedReminderInfo reminder) async {
    if ((reminder.leadId ?? '').isEmpty) {
      _openMainTab(_leadsRoute);
      return;
    }

    try {
      final payload = await widget.leadsRepository.fetchLeadDetail(reminder.leadId!);

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LeadDetailPage(
            session: widget.session,
            bootstrap: widget.bootstrap,
            repository: widget.leadsRepository,
            offersRepository: widget.offersRepository,
            remindersRepository: widget.remindersRepository,
            initialPayload: payload,
            onRemindersChanged: _handleRemindersChanged,
            onOpenOfferWorkspaceForLead: _openOffersWorkspaceForLead,
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadReminders(silent: true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Color _navColorForLabel(String label) {
    switch (label) {
      case 'Dashboard':
        return VeloPrimePalette.bronzeDeep;
      case 'Oferty / PDF':
        return VeloPrimePalette.bronzeDeep;
      case 'Prowizje':
        return const Color(0xFF2F855A);
      case 'Polityka cenowa':
        return const Color(0xFF8B5E34);
      case 'Publikacje':
        return VeloPrimePalette.violet;
      case 'Leady':
        return VeloPrimePalette.sea;
      case 'Klienci':
        return VeloPrimePalette.olive;
      case 'Samochody':
        return VeloPrimePalette.rose;
      default:
        return VeloPrimePalette.muted;
    }
  }

  Color _accentForDestination(_ShellDestination destination) {
    return destination.accentColor ?? _navColorForLabel(destination.label);
  }

  List<_ShellDestination> get _primaryDestinations => [
        _ShellDestination(
          route: _dashboardRoute,
          eyebrow: 'Przegląd CRM',
          label: 'Dashboard',
          description:
              'Szybki wgląd w pipeline, aktywność zespołu i najważniejsze KPI bez wychodzenia z głównego widoku.',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          accentColor: VeloPrimePalette.bronzeDeep,
          page: DashboardHomePage(
            session: widget.session,
            bootstrap: widget.bootstrap,
            reminders: _reminders,
            onOpenLeads: () => _openMainTab(_leadsRoute),
            onOpenOffers: () => _openMainTab(_offersRoute),
            onOpenCustomers: () => _openMainTab(_customersRoute),
            onOpenVehicles: () => _openMainTab(_vehiclesRoute),
            onOpenReminder: _openReminderLead,
            onCompleteReminder: _completeReminder,
          ),
        ),
        _ShellDestination(
          route: _leadsRoute,
          eyebrow: 'Sprzedaż',
          label: 'Leady',
          description:
              'Bieżąca praca handlowa, kwalifikacja kontaktów i przejścia do oferty w jednym strumieniu.',
          icon: Icons.view_kanban_outlined,
          selectedIcon: Icons.view_kanban,
          accentColor: VeloPrimePalette.sea,
          page: LeadsHomePage(
            session: widget.session,
            bootstrap: widget.bootstrap,
            repository: widget.leadsRepository,
            offersRepository: widget.offersRepository,
            remindersRepository: widget.remindersRepository,
            onRemindersChanged: _handleRemindersChanged,
            onRefreshBootstrap: widget.onRefreshBootstrap,
            onOpenOfferWorkspaceForLead: _openOffersWorkspaceForLead,
          ),
        ),
        _ShellDestination(
          route: _customersRoute,
          eyebrow: 'Baza klientów',
          label: 'Klienci',
          description:
              'Docelowe miejsce dla historii współpracy, relacji i obsługi klienta.',
          icon: Icons.groups_2_outlined,
          selectedIcon: Icons.groups_2,
          accentColor: VeloPrimePalette.olive,
          page: CustomersHomePage(
            session: widget.session,
            bootstrap: widget.bootstrap,
            customersRepository: widget.customersRepository,
            repository: widget.leadsRepository,
            offersRepository: widget.offersRepository,
            remindersRepository: widget.remindersRepository,
            onRemindersChanged: _handleRemindersChanged,
            onOpenOfferWorkspaceForLead: _openOffersWorkspaceForLead,
          ),
        ),
        _ShellDestination(
            route: _vehiclesRoute,
          eyebrow: 'Oferta modelowa',
          label: 'Samochody',
          description:
              'Docelowe miejsce dla katalogu modeli, wersji i materiałów produktowych.',
          icon: Icons.directions_car_outlined,
          selectedIcon: Icons.directions_car,
          accentColor: VeloPrimePalette.rose,
          page: ModulePlaceholderPage(
            eyebrow: 'Samochody',
            title: 'Moduł samochodów jest w przygotowaniu.',
            subtitle:
                'Docelowo tutaj będzie pełny katalog modeli, stanów i materiałów produktowych. Obecnie możesz pracować z ofertami lub dashboardem.',
            icon: Icons.directions_car_outlined,
            accentColor: VeloPrimePalette.rose,
            primaryAction: FilledButton.icon(
              onPressed: () => _openMainTab(_offersRoute),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Przejdź do ofert'),
            ),
            secondaryAction: OutlinedButton.icon(
              onPressed: () => _openMainTab(_dashboardRoute),
              icon: const Icon(Icons.dashboard_outlined),
              label: const Text('Wróć do dashboardu'),
            ),
          ),
        ),
        _ShellDestination(
          route: _offersRoute,
          eyebrow: 'Oferta PDF',
          label: 'Oferty / PDF',
          description:
              'Miejsce do przygotowania, kalkulacji i finalizacji oferty dla klienta.',
          icon: Icons.description_outlined,
          selectedIcon: Icons.description,
          accentColor: VeloPrimePalette.bronzeDeep,
          page: OffersHomePage(
            session: widget.session,
            bootstrap: widget.bootstrap,
            leadsRepository: widget.leadsRepository,
            offersRepository: widget.offersRepository,
            onRefreshBootstrap: widget.onRefreshBootstrap,
            onOpenLeads: () => _openMainTab(_leadsRoute),
            workspaceLaunchNotifier: _offerWorkspaceLaunchNotifier,
          ),
        ),
        if (widget.session.role == 'ADMIN' ||
            widget.session.role == 'DIRECTOR' ||
            widget.session.role == 'MANAGER')
          _ShellDestination(
            route: _commissionsRoute,
            eyebrow: 'Prowizje',
            label: 'Prowizje',
            description:
                'Konfiguracja prowizji zespołu według ról, modeli i zasad sprzedaży.',
            icon: Icons.percent_outlined,
            selectedIcon: Icons.percent,
            accentColor: const Color(0xFF2F855A),
            page: CommissionsHomePage(
              session: widget.session,
              repository: widget.commissionsRepository,
              embeddedInShell: true,
            ),
          ),
        if (widget.session.role == 'ADMIN')
          _ShellDestination(
            route: _pricingRoute,
            eyebrow: 'Polityka cenowa',
            label: 'Polityka cenowa',
            description:
                'Miejsce zarządzania katalogiem cen i danymi modeli dla ofert.',
            icon: Icons.request_quote_outlined,
            selectedIcon: Icons.request_quote,
            accentColor: const Color(0xFF8B5E34),
            page: PricingHomePage(
              session: widget.session,
              repository: widget.pricingRepository,
              embeddedInShell: true,
              onPricingCatalogChanged: widget.onRefreshBootstrap,
            ),
          ),
      ];

  List<_ShellDestination> get _secondaryDestinations => [
        _ShellDestination(
          route: _accountRoute,
          eyebrow: 'Konto',
          label: 'Konto',
          description: 'Ustawienia bezpieczeństwa i zmiana hasła w tej samej nawigacji co reszta CRM.',
          icon: Icons.lock_outline,
          selectedIcon: Icons.lock,
          accentColor: VeloPrimePalette.sea,
          page: ChangePasswordPage(
            repository: widget.accountRepository,
            embeddedInShell: true,
          ),
        ),
        if (widget.session.role == 'ADMIN')
          _ShellDestination(
            route: _usersRoute,
            eyebrow: 'Administracja',
            label: 'Użytkownicy',
            description: 'Zarządzanie kontami użytkowników bez wychodzenia z głównego shellu CRM.',
            icon: Icons.admin_panel_settings_outlined,
            selectedIcon: Icons.admin_panel_settings,
            accentColor: const Color(0xFFC53030),
            page: UsersHomePage(
              repository: widget.usersRepository,
              embeddedInShell: true,
            ),
          ),
        if (widget.session.role == 'ADMIN')
          _ShellDestination(
            route: _updatesRoute,
            eyebrow: 'Publikacje',
            label: 'Publikacje',
            description: 'Publikacja wersji DATA, ASSETS i APPLICATION oraz kontrola manifestu aktualizacji.',
            icon: Icons.publish_outlined,
            selectedIcon: Icons.publish,
            accentColor: VeloPrimePalette.violet,
            page: UpdateAdminPage(
              repository: widget.updateRepository,
              embeddedInShell: true,
              onManifestChanged: widget.onRefreshBootstrap,
            ),
          ),
      ];

  List<_ShellDestination> get _allDestinations => [
        ..._primaryDestinations,
        ..._secondaryDestinations,
      ];

  @override
  Widget build(BuildContext context) {
    final primaryDestinations = _primaryDestinations;
    final destinations = _allDestinations;
    final activePreset = _activeBackgroundPreset;
    final selectedIndex = destinations.indexWhere((destination) => destination.route == _selectedRoute);
    final resolvedIndex = selectedIndex == -1 ? 0 : selectedIndex;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: activePreset.overlayColor),
                child: Image.asset(
                  activePreset.assetPath,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: activePreset.overlayGradient),
              ),
            ),
            Positioned(
              top: -130,
              left: -40,
              child: Container(
                width: 360,
                height: 240,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [activePreset.primaryGlow, const Color(0x00000000)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -70,
              right: -40,
              child: Container(
                width: 260,
                height: 180,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      activePreset.secondaryGlow,
                      const Color(0x00000000),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF173E86), Color(0xFF0F2D67), Color(0xFF0A2455)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0x335F8DDF)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40102040),
                            blurRadius: 34,
                            offset: Offset(0, 18),
                          ),
                          BoxShadow(
                            color: Color(0x26245FBD),
                            blurRadius: 22,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const _ShellBrandBlock(),
                          const SizedBox(width: 24),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ...List.generate(primaryDestinations.length,
                                      (index) {
                                    final destination = primaryDestinations[index];
                                    final selected = destination.route == _selectedRoute;

                                    return Padding(
                                      padding: EdgeInsets.only(
                                        right: index == primaryDestinations.length - 1
                                            ? 0
                                            : 8,
                                      ),
                                      child: _ShellNavChip(
                                        icon: selected
                                            ? destination.selectedIcon
                                            : destination.icon,
                                        label: destination.label,
                                        selected: selected,
                                        iconColor:
                                            _accentForDestination(destination),
                                        onTap: () => _openMainTab(destination.route),
                                      ),
                                    );
                                  }),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    tooltip: 'Więcej',
                                    offset: const Offset(0, 12),
                                    color: VeloPrimePalette.overlay,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                      side: const BorderSide(
                                        color: VeloPrimePalette.line,
                                      ),
                                    ),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem<String>(
                                        enabled: false,
                                        value: 'header',
                                        child: _PopupHeader(
                                          title: 'Sekcje dodatkowe',
                                          subtitle:
                                              'Rzadziej używane moduły dostępne z jednego miejsca.',
                                        ),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'account',
                                        child: _MoreMenuTile(
                                          icon: Icons.lock_outline,
                                          label: 'Konto',
                                          iconColor:
                                              VeloPrimePalette.bronzeDeep,
                                        ),
                                      ),
                                      if (widget.session.role == 'ADMIN')
                                        const PopupMenuItem<String>(
                                          value: 'updates',
                                          child: _MoreMenuTile(
                                            icon: Icons.publish_outlined,
                                            label: 'Publikacje',
                                            iconColor: VeloPrimePalette.violet,
                                          ),
                                        ),
                                      if (widget.session.role == 'ADMIN')
                                        const PopupMenuItem<String>(
                                          value: 'users',
                                          child: _MoreMenuTile(
                                            icon: Icons
                                                .admin_panel_settings_outlined,
                                            label: 'Użytkownicy',
                                            iconColor: Color(0xFFC53030),
                                          ),
                                        ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'account') {
                                        _openAccountPage();
                                      }
                                      if (value == 'updates') {
                                        _openUpdatesPage();
                                      }
                                      if (value == 'users') {
                                        _openUsersPage();
                                      }
                                    },
                                    child: const _ShellMoreChip(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _SessionIdentityChip(
                                label: 'Użytkownik',
                                value: widget.session.fullName,
                              ),
                              ValueListenableBuilder<LeadSyncSnapshot>(
                                valueListenable: widget.leadsRepository.syncSnapshot,
                                builder: (context, snapshot, _) {
                                  return _ShellSyncActions(
                                    snapshot: snapshot,
                                    onSyncNow: snapshot.isSyncing
                                        ? null
                                        : _synchronizeLocalChanges,
                                  );
                                },
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Tło',
                                offset: const Offset(0, 12),
                                color: VeloPrimePalette.overlay,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                  side: const BorderSide(
                                    color: VeloPrimePalette.line,
                                  ),
                                ),
                                itemBuilder: (context) => [
                                  const PopupMenuItem<String>(
                                    enabled: false,
                                    value: 'title',
                                    child: _PopupHeader(
                                      title: 'Tło aplikacji',
                                      subtitle:
                                          'Każdy użytkownik może dobrać własny wariant wizualny.',
                                    ),
                                  ),
                                  ..._backgroundPresets.map(
                                    (preset) => PopupMenuItem<String>(
                                      value: preset.key,
                                      child: _BackgroundPresetTile(
                                        preset: preset,
                                        selected:
                                            preset.key == _backgroundPresetKey,
                                      ),
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'title') {
                                    return;
                                  }

                                  _setBackgroundPreset(value);
                                },
                                child: const _ShellIconButton(
                                  icon: Icons.palette_outlined,
                                  label: 'Tło',
                                ),
                              ),
                              _ReminderBellButton(
                                count: _reminders.length,
                                isLoading: _isLoadingReminders,
                                onTap: () async {
                                  await showDialog<void>(
                                    context: context,
                                    barrierColor: Colors.black.withValues(alpha: 0.22),
                                    builder: (_) => _ReminderCenterDialog(
                                      reminders: _reminders,
                                      onRefresh: _handleRemindersChanged,
                                      onOpenReminder: _openReminderLead,
                                      onCompleteReminder: _completeReminder,
                                    ),
                                  );
                                },
                              ),
                              _ShellIconButton(
                                icon: Icons.logout_rounded,
                                label: 'Wyloguj',
                                onTap: _startLogoutFlow,
                              ),
                              if (!kIsWeb && Platform.isWindows)
                                _ShellIconButton(
                                  icon: Icons.power_settings_new_rounded,
                                  label: 'Zamknij',
                                  onTap: _requestSafeClose,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1720),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                          child: VeloPrimeBackgroundVisualScope(
                            data: VeloPrimeBackgroundVisualData(
                              overlayTint: activePreset.overlayColor,
                              primaryGlow: activePreset.primaryGlow,
                              secondaryGlow: activePreset.secondaryGlow,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(34),
                              child: IndexedStack(
                                index: resolvedIndex,
                                children: destinations
                                    .map((destination) => destination.page)
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SessionExitMode { closeApp, logout }

class _ShellDestination {
  const _ShellDestination({
    required this.route,
    required this.eyebrow,
    required this.label,
    required this.description,
    required this.icon,
    required this.selectedIcon,
    required this.page,
    this.accentColor,
  });

  final String route;
  final String eyebrow;
  final String label;
  final String description;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
  final Color? accentColor;
}

class _ShellBrandBlock extends StatelessWidget {
  const _ShellBrandBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'VELO PRIME',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'CRM sprzedażowy',
          style: TextStyle(
            color: Color(0xBBD8E5FF),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          ClientArtifactVersions.releaseLabel,
          style: const TextStyle(
            color: Color(0x99D8E5FF),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _ShellNavChip extends StatelessWidget {
  const _ShellNavChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [
                      Color(0xFFFFE8A9),
                      Color(0xFFF4C96A),
                      Color(0xFFD7A648),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0x22000000), Color(0x1AFFFFFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? const Color(0x66D6A542) : const Color(0x1FFFFFFF),
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? const Color(0x22D6A542)
                    : const Color(0x16081426),
                blurRadius: selected ? 20 : 10,
                offset: Offset(0, selected ? 8 : 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0x12FFFFFF)
                      : const Color(0x1FFFFFFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: selected ? const Color(0xFF5F4416) : Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? const Color(0xFF503A12) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellMoreChip extends StatelessWidget {
  const _ShellMoreChip();

  @override
  Widget build(BuildContext context) {
    return const _ShellIconButton(
      icon: Icons.expand_more,
      label: 'Więcej',
      trailingIcon: Icons.expand_more,
      leadingIconOnly: false,
    );
  }
}

class _ShellIconButton extends StatelessWidget {
  const _ShellIconButton({
    required this.icon,
    this.label,
    this.square = false,
    this.trailingIcon,
    this.leadingIconOnly = true,
    this.onTap,
  });

  final IconData icon;
  final String? label;
  final bool square;
  final IconData? trailingIcon;
  final bool leadingIconOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = square
        ? SizedBox(
            width: 42,
            height: 42,
            child: Center(
              child: Icon(icon, size: 18, color: Colors.white),
            ),
          )
        : SizedBox(
            height: 42,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: const Color(0xFFFFD271)),
                if ((label ?? '').isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
                if (trailingIcon != null && !leadingIconOnly) ...[
                  const SizedBox(width: 4),
                  Icon(
                    trailingIcon,
                    size: 16,
                    color: const Color(0xFFD8E5FF),
                  ),
                ],
              ],
            ),
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding:
              square ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0x22FFFFFF), Color(0x11000000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x22FFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12081426),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ReminderBellButton extends StatelessWidget {
  const _ReminderBellButton({
    required this.count,
    required this.isLoading,
    required this.onTap,
  });

  final int count;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _ShellIconButton(
          icon: isLoading ? Icons.notifications_active_outlined : Icons.notifications_none,
          square: true,
          onTap: onTap,
        ),
        if (count > 0)
          Positioned(
            right: -2,
            top: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFC53030),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReminderCenterDialog extends StatelessWidget {
  const _ReminderCenterDialog({
    required this.reminders,
    required this.onRefresh,
    required this.onOpenReminder,
    required this.onCompleteReminder,
  });

  final List<ManagedReminderInfo> reminders;
  final Future<void> Function() onRefresh;
  final Future<void> Function(ManagedReminderInfo reminder) onOpenReminder;
  final Future<void> Function(String reminderId) onCompleteReminder;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: VeloPrimeWorkspacePanel(
          tint: VeloPrimePalette.violet,
          radius: 32,
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VeloPrimeSectionEyebrow(label: 'Przypomnienia', color: VeloPrimePalette.violet),
              const SizedBox(height: 12),
              const Text(
                'Centrum przypomnień zespołu',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink, height: 1.08),
              ),
              const SizedBox(height: 10),
              Text(
                reminders.isEmpty
                    ? 'Nie masz aktywnych przypomnień. Nowe zadania możesz ustawiać bezpośrednio na karcie leada.'
                    : 'Tu trafiają wszystkie aktywne przypomnienia widoczne w Twojej strukturze. Możesz od razu wejść w sprawę albo zamknąć zadanie po wykonaniu.',
                style: const TextStyle(color: VeloPrimePalette.muted, height: 1.6),
              ),
              const SizedBox(height: 22),
              if (reminders.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: VeloPrimePalette.line),
                  ),
                  child: const Text('Brak aktywnych przypomnień.'),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 480),
                  child: SingleChildScrollView(
                    child: Column(
                      children: reminders
                          .map(
                            (reminder) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ReminderListCard(
                                reminder: reminder,
                                onOpen: () async {
                                  Navigator.of(context).pop();
                                  await onOpenReminder(reminder);
                                },
                                onComplete: () async {
                                  Navigator.of(context).pop();
                                  await onCompleteReminder(reminder.id);
                                },
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Zamknij'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      await onRefresh();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Odśwież'),
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

class _ReminderListCard extends StatelessWidget {
  const _ReminderListCard({
    required this.reminder,
    required this.onOpen,
    required this.onComplete,
  });

  final ManagedReminderInfo reminder;
  final VoidCallback onOpen;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final remindAt = DateTime.tryParse(reminder.remindAt);
    final isOverdue = remindAt != null && remindAt.isBefore(DateTime.now());
    final accent = isOverdue ? const Color(0xFFC53030) : VeloPrimePalette.violet;

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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
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
                    Text(reminder.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink)),
                    const SizedBox(height: 6),
                    Text(
                      _formatReminderDateTime(reminder.remindAt),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: accent),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color.alphaBlend(accent.withValues(alpha: 0.08), Colors.white),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.18)),
                ),
                child: Text(
                  isOverdue ? 'PILNE' : 'AKTYWNE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accent),
                ),
              ),
            ],
          ),
          if ((reminder.note ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(reminder.note!, style: const TextStyle(fontSize: 14, height: 1.55, color: VeloPrimePalette.muted)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if ((reminder.leadName ?? '').isNotEmpty)
                VeloPrimeBadge(label: 'Lead', value: reminder.leadName!),
              if ((reminder.ownerName ?? '').isNotEmpty)
                VeloPrimeBadge(label: 'Opiekun', value: reminder.ownerName!),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: onComplete,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Oznacz jako zrobione'),
              ),
              OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text((reminder.leadId ?? '').isNotEmpty ? 'Otwórz lead' : 'Przejdź do leadów'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatReminderDateTime(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  return '${parsed.day.toString().padLeft(2, '0')}.${parsed.month.toString().padLeft(2, '0')}.${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
}

class _ShellSyncActions extends StatelessWidget {
  const _ShellSyncActions({
    required this.snapshot,
    required this.onSyncNow,
  });

  final LeadSyncSnapshot snapshot;
  final VoidCallback? onSyncNow;

  Color get _accentColor {
    switch (snapshot.phase) {
      case LeadSyncPhase.syncing:
        return const Color(0xFF9ED0FF);
      case LeadSyncPhase.error:
        return const Color(0xFFFFB2A3);
      case LeadSyncPhase.pending:
        return const Color(0xFFFFD271);
      case LeadSyncPhase.synchronized:
        return const Color(0xFF9CE7C1);
    }
  }

  IconData get _icon {
    switch (snapshot.phase) {
      case LeadSyncPhase.syncing:
        return Icons.sync;
      case LeadSyncPhase.error:
        return Icons.sync_problem_rounded;
      case LeadSyncPhase.pending:
        return Icons.pending_actions_rounded;
      case LeadSyncPhase.synchronized:
        return Icons.cloud_done_rounded;
    }
  }

  String get _title {
    switch (snapshot.phase) {
      case LeadSyncPhase.syncing:
        return 'Trwa synchronizacja';
      case LeadSyncPhase.error:
        return 'Błąd synchronizacji';
      case LeadSyncPhase.pending:
        return 'Oczekują zmiany';
      case LeadSyncPhase.synchronized:
        return 'Zsynchronizowano';
    }
  }

  String get _subtitle {
    if (snapshot.isSyncing) {
      return snapshot.pendingChanges > 0
          ? '${snapshot.pendingChanges} zmian w kolejce'
          : 'Wysyłamy zmiany do centrali';
    }
    if ((snapshot.lastError ?? '').isNotEmpty) {
      return snapshot.pendingChanges > 0
          ? '${snapshot.pendingChanges} zmian czeka na ponowną próbę'
          : 'Ostatnia próba nie powiodła się';
    }
    if (snapshot.pendingChanges > 0) {
      return '${snapshot.pendingChanges} zmian gotowych do wysłania';
    }

    final lastSuccess = snapshot.lastSuccessfulSyncAt;
    if (lastSuccess == null) {
      return 'Brak oczekujących zmian';
    }

    final hour = lastSuccess.hour.toString().padLeft(2, '0');
    final minute = lastSuccess.minute.toString().padLeft(2, '0');
    return 'Ostatni flush $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0x22000000), Color(0x1AFFFFFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x1FFFFFFF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: snapshot.isSyncing
                    ? Padding(
                        padding: const EdgeInsets.all(7),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                        ),
                      )
                    : Icon(_icon, size: 16, color: _accentColor),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _subtitle,
                    style: const TextStyle(
                      color: Color(0xBBD8E5FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _ShellIconButton(
          icon: snapshot.isSyncing ? Icons.sync : Icons.sync_rounded,
          label: snapshot.isSyncing ? 'Synchronizujemy...' : 'Synchronizuj teraz',
          leadingIconOnly: false,
          onTap: onSyncNow,
        ),
      ],
    );
  }
}

class _ExitSyncDialog extends StatefulWidget {
  const _ExitSyncDialog({required this.repository, required this.mode});

  final LeadsRepository repository;
  final _SessionExitMode mode;

  @override
  State<_ExitSyncDialog> createState() => _ExitSyncDialogState();
}

class _ExitSyncDialogState extends State<_ExitSyncDialog> {
  bool _isSynchronizing = true;
  int _remainingChanges = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_runFinalSynchronization());
  }

  Future<void> _runFinalSynchronization() async {
    final synchronized = await widget.repository.synchronizeNow();

    if (!mounted) {
      return;
    }

    final snapshot = widget.repository.syncSnapshot.value;
    if (synchronized) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isSynchronizing = false;
      _remainingChanges = snapshot.pendingChanges;
      _errorMessage = snapshot.lastError;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: VeloPrimeWorkspacePanel(
          tint: VeloPrimePalette.bronzeDeep,
          radius: 30,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VeloPrimeSectionEyebrow(
                label: widget.mode == _SessionExitMode.logout ? 'Wylogowanie' : 'Zamykanie aplikacji',
                color: VeloPrimePalette.bronzeDeep,
              ),
              const SizedBox(height: 12),
              Text(
                widget.mode == _SessionExitMode.logout
                    ? 'Próbujemy wypchnąć lokalne zmiany przed wylogowaniem.'
                    : 'Próbujemy wypchnąć lokalne zmiany przed zamknięciem.',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: VeloPrimePalette.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isSynchronizing
                  ? widget.mode == _SessionExitMode.logout
                    ? 'Wylogowanie jest chwilowo wstrzymane do czasu zakończenia próby synchronizacji.'
                    : 'Standardowe zamknięcie jest chwilowo wstrzymane do czasu zakończenia próby synchronizacji.'
                  : widget.mode == _SessionExitMode.logout
                    ? 'Nie wszystkie zmiany udało się wysłać. Możesz wrócić do aplikacji albo mimo ostrzeżenia wylogować się już teraz.'
                    : 'Nie wszystkie zmiany udało się wysłać. Możesz wrócić do aplikacji albo wymusić wyjście po dodatkowym ostrzeżeniu.',
                style: const TextStyle(color: VeloPrimePalette.muted, height: 1.6),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Color.alphaBlend(
                        VeloPrimePalette.bronzeDeep.withValues(alpha: 0.06),
                        Colors.white,
                      ),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: VeloPrimePalette.lineStrong),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _isSynchronizing
                            ? const Color(0x140F2D67)
                            : const Color(0x14A63B2B),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: _isSynchronizing
                          ? const Padding(
                              padding: EdgeInsets.all(11),
                              child: CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          : const Icon(
                              Icons.sync_problem_rounded,
                              color: Color(0xFFA63B2B),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSynchronizing
                                ? 'Finalna synchronizacja trwa'
                                : 'Synchronizacja zatrzymała się na błędzie',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: VeloPrimePalette.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isSynchronizing
                                ? 'Wysyłamy oczekujące zmiany do centrali.'
                                : _errorMessage == null || _errorMessage!.isEmpty
                                    ? 'Pozostało $_remainingChanges zmian w kolejce.'
                                    : _errorMessage!,
                            style: const TextStyle(
                              color: VeloPrimePalette.muted,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (_isSynchronizing)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.mode == _SessionExitMode.logout
                        ? 'Po udanej synchronizacji nastąpi automatyczne wylogowanie.'
                        : 'Po udanej synchronizacji aplikacja zamknie się automatycznie.',
                    style: const TextStyle(
                      color: VeloPrimePalette.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Wróć do aplikacji'),
                    ),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.warning_amber_rounded),
                      label: Text(widget.mode == _SessionExitMode.logout ? 'Wyloguj mimo to' : 'Wyjdź mimo to'),
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

class _SessionIdentityChip extends StatelessWidget {
  const _SessionIdentityChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x18FFFFFF), Color(0x12000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFD271),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _PopupHeader extends StatelessWidget {
  const _PopupHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: VeloPrimePalette.bronzeDeep,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Color(0xFF5F5A4F),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreMenuTile extends StatelessWidget {
  const _MoreMenuTile({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF8F5F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: VeloPrimePalette.line),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: VeloPrimePalette.ink,
          ),
        ),
      ],
    );
  }
}

class _BackgroundPresetTile extends StatelessWidget {
  const _BackgroundPresetTile({required this.preset, required this.selected});

  final _BackgroundPreset preset;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(preset.assetPath),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: VeloPrimePalette.line),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: preset.swatchOverlay,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                preset.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: VeloPrimePalette.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                preset.description,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: VeloPrimePalette.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFF9F4E8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFF8F5F0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? const Color(0x33BE933E) : VeloPrimePalette.line,
            ),
          ),
          child: Icon(
            Icons.check,
            size: 16,
            color: selected ? VeloPrimePalette.bronzeDeep : Colors.transparent,
          ),
        ),
      ],
    );
  }
}
