import 'package:flutter/material.dart';

import 'core/config/client_artifact_versions.dart';
import 'core/presentation/veloprime_ui.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/bootstrap/data/bootstrap_repository.dart';
import 'features/bootstrap/models/bootstrap_payload.dart' hide UpdateManifestInfo;
import 'features/account/data/account_repository.dart';
import 'features/commissions/data/commissions_repository.dart';
import 'features/customers/data/customers_repository.dart';
import 'features/leads/data/leads_repository.dart';
import 'features/offers/data/offers_repository.dart';
import 'features/pricing/data/pricing_repository.dart';
import 'features/reminders/data/reminders_repository.dart';
import 'features/shell/presentation/crm_shell_page.dart';
import 'features/startup/presentation/startup_preparation_page.dart';
import 'features/update/data/update_repository.dart';
import 'features/update/models/update_models.dart';
import 'features/update/presentation/update_gate_page.dart';
import 'features/users/data/users_repository.dart';

class VeloPrimeApp extends StatefulWidget {
  const VeloPrimeApp({super.key});

  @override
  State<VeloPrimeApp> createState() => _VeloPrimeAppState();
}

class _VeloPrimeAppState extends State<VeloPrimeApp> {
  final ApiClient _apiClient = ApiClient();
  late final AuthRepository _authRepository = AuthRepository(_apiClient);
  late final BootstrapRepository _bootstrapRepository = BootstrapRepository(_apiClient);
  late final AccountRepository _accountRepository = AccountRepository(_apiClient);
  late final CommissionsRepository _commissionsRepository = CommissionsRepository(_apiClient);
  late final CustomersRepository _customersRepository = CustomersRepository(_apiClient);
  late final LeadsRepository _leadsRepository = LeadsRepository(_apiClient);
  late final OffersRepository _offersRepository = OffersRepository(_apiClient);
  late final PricingRepository _pricingRepository = PricingRepository(_apiClient);
  late final RemindersRepository _remindersRepository = RemindersRepository(_apiClient);
  late final UpdateRepository _updateRepository = UpdateRepository(_apiClient);
  late final UsersRepository _usersRepository = UsersRepository(_apiClient);

  BootstrapPayload? _bootstrap;
  SessionInfo? _session;
  bool _isChecking = false;
  String? _error;
  StartupPreparationState? _startupPreparationState;

  void _syncPublishedVersions(UpdateManifestInfo manifest) {
    ClientArtifactVersions.syncPublishedVersions(
      dataVersion: manifest.findVersion('DATA')?.version,
      assetsVersion: manifest.findVersion('ASSETS')?.version,
    );
  }

  Future<void> _handleLogin(String email, String password) async {
    setState(() {
      _isChecking = true;
      _error = null;
      _startupPreparationState = null;
    });

    try {
      await _authRepository.login(email: email, password: password);
      if (!mounted) {
        return;
      }

      setState(() {
        _isChecking = false;
        _error = null;
        _startupPreparationState = StartupPreparationState.initial();
      });

      await _prepareWorkspace();
    } catch (error) {
      ClientArtifactVersions.resetSessionSync();

      if (!mounted) {
        return;
      }

      setState(() {
        _isChecking = false;
        _error = error.toString();
        _startupPreparationState = null;
      });
    }
  }

  Future<void> _prepareWorkspace() async {
    _setPreparationStep(0, StartupPreparationStepStatus.active);

    try {
      final bootstrap = await _bootstrapRepository.loadBootstrap();
      _setPreparationStep(0, StartupPreparationStepStatus.completed);

      _setPreparationStep(1, StartupPreparationStepStatus.active);
      final manifest = await _updateRepository.fetchManifest();
      _syncPublishedVersions(manifest);
      _setPreparationStep(1, StartupPreparationStepStatus.completed);

      _setPreparationStep(2, StartupPreparationStepStatus.active);
      final comparison = await _updateRepository.compareVersions(
        ClientVersionPayload(
          dataVersion: ClientArtifactVersions.syncedDataVersion,
          assetsVersion: ClientArtifactVersions.syncedAssetsVersion,
          applicationVersion: ClientArtifactVersions.syncedApplicationVersion,
        ),
      );
      _setPreparationStep(2, StartupPreparationStepStatus.completed);

      _setPreparationStep(3, StartupPreparationStepStatus.active);
      await _warmCriticalStartupAssets();
      _setPreparationStep(3, StartupPreparationStepStatus.completed);

      if (!mounted) {
        return;
      }

      setState(() {
        _session = bootstrap.session;
        _bootstrap = bootstrap;
        _startupPreparationState = null;
      });

      if (comparison.requiresAnyUpdate && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => UpdateGatePage(comparison: comparison),
          ),
        );
      }
    } catch (error) {
      ClientArtifactVersions.resetSessionSync();
      _markPreparationFailure(error.toString());
    }
  }

  Future<void> _retryWorkspacePreparation() async {
    if (_startupPreparationState == null) {
      return;
    }

    setState(() {
      _startupPreparationState = StartupPreparationState.initial();
    });

    await _prepareWorkspace();
  }

  Future<void> _warmCriticalStartupAssets() async {
    await Future.wait([
      precacheImage(const AssetImage('assets/backgrounds/Błękitny.png'), context),
      precacheImage(const AssetImage('assets/branding/logo.png'), context),
      precacheImage(const AssetImage('assets/branding/app_icon.png'), context),
    ]);
  }

  void _setPreparationStep(int index, StartupPreparationStepStatus status) {
    final current = _startupPreparationState;
    if (current == null || index < 0 || index >= current.steps.length || !mounted) {
      return;
    }

    final steps = [...current.steps];
    steps[index] = steps[index].copyWith(status: status);

    if (status == StartupPreparationStepStatus.completed && index + 1 < steps.length) {
      final nextStep = steps[index + 1];
      if (nextStep.status == StartupPreparationStepStatus.pending) {
        steps[index + 1] = nextStep.copyWith(status: StartupPreparationStepStatus.active);
      }
    }

    setState(() {
      _startupPreparationState = current.copyWith(
        steps: steps,
        isWorking: steps.any((step) => step.status == StartupPreparationStepStatus.active),
        clearError: true,
      );
    });
  }

  void _markPreparationFailure(String errorMessage) {
    final current = _startupPreparationState;
    if (current == null || !mounted) {
      return;
    }

    final steps = [...current.steps];
    final activeIndex = steps.indexWhere((step) => step.status == StartupPreparationStepStatus.active);
    if (activeIndex >= 0) {
      steps[activeIndex] = steps[activeIndex].copyWith(status: StartupPreparationStepStatus.failed);
    }

    setState(() {
      _startupPreparationState = current.copyWith(
        steps: steps,
        isWorking: false,
        errorMessage: errorMessage,
      );
    });
  }

  Future<void> _refreshBootstrap() async {
    final results = await Future.wait([
      _bootstrapRepository.loadBootstrap(),
      _updateRepository.fetchManifest(),
    ]);
    final bootstrap = results[0] as BootstrapPayload;
    final manifest = results[1] as UpdateManifestInfo;

    _syncPublishedVersions(manifest);

    if (!mounted) {
      return;
    }

    setState(() {
      _session = bootstrap.session;
      _bootstrap = bootstrap;
    });
  }

  @override
  Widget build(BuildContext context) {
    const colorScheme = ColorScheme.light(
      primary: VeloPrimePalette.bronzeDeep,
      secondary: VeloPrimePalette.olive,
      surface: VeloPrimePalette.ivory,
      error: Color(0xFF9A3C2B),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: VeloPrimePalette.ink,
    );

    return MaterialApp(
      title: 'VeloPrime Hybrid Client',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: VeloPrimePalette.sand,
        useMaterial3: true,
        fontFamily: 'Segoe UI Variable Display',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink, height: 1.08),
          headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink, height: 1.12),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink),
          bodyLarge: TextStyle(fontSize: 16, color: VeloPrimePalette.ink, height: 1.58),
          bodyMedium: TextStyle(fontSize: 14, color: VeloPrimePalette.muted, height: 1.58),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: VeloPrimePalette.ink,
          elevation: 0,
          centerTitle: false,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: VeloPrimePalette.bronze,
            foregroundColor: const Color(0xFF181512),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            side: const BorderSide(color: Color(0x26BE933E)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: VeloPrimePalette.ink,
            side: const BorderSide(color: VeloPrimePalette.line),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            backgroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: VeloPrimePalette.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: VeloPrimePalette.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: VeloPrimePalette.bronze, width: 1.4),
          ),
          labelStyle: const TextStyle(color: VeloPrimePalette.muted),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: VeloPrimePalette.ink,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
        home: _startupPreparationState != null
          ? StartupPreparationPage(
            state: _startupPreparationState!,
            onRetry: _startupPreparationState!.isWorking ? null : _retryWorkspacePreparation,
          )
          : _session == null || _bootstrap == null
          ? LoginPage(
              isLoading: _isChecking,
              errorMessage: _error,
              onLogin: _handleLogin,
            )
          : CrmShellPage(
              session: _session!,
              bootstrap: _bootstrap!,
              accountRepository: _accountRepository,
              commissionsRepository: _commissionsRepository,
              customersRepository: _customersRepository,
              leadsRepository: _leadsRepository,
              offersRepository: _offersRepository,
              pricingRepository: _pricingRepository,
              remindersRepository: _remindersRepository,
              updateRepository: _updateRepository,
              usersRepository: _usersRepository,
              onRefreshBootstrap: _refreshBootstrap,
            ),
    );
  }
}