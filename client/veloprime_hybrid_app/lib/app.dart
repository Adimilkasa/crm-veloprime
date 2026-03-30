import 'package:flutter/material.dart';

import 'core/presentation/veloprime_ui.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/bootstrap/data/bootstrap_repository.dart';
import 'features/bootstrap/models/bootstrap_payload.dart';
import 'features/account/data/account_repository.dart';
import 'features/commissions/data/commissions_repository.dart';
import 'features/leads/data/leads_repository.dart';
import 'features/offers/data/offers_repository.dart';
import 'features/pricing/data/pricing_repository.dart';
import 'features/shell/presentation/crm_shell_page.dart';
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
  late final LeadsRepository _leadsRepository = LeadsRepository(_apiClient);
  late final OffersRepository _offersRepository = OffersRepository(_apiClient);
  late final PricingRepository _pricingRepository = PricingRepository(_apiClient);
  late final UpdateRepository _updateRepository = UpdateRepository(_apiClient);
  late final UsersRepository _usersRepository = UsersRepository(_apiClient);

  BootstrapPayload? _bootstrap;
  SessionInfo? _session;
  bool _isChecking = false;
  String? _error;

  Future<void> _handleLogin(String email, String password) async {
    setState(() {
      _isChecking = true;
      _error = null;
    });

    try {
      await _authRepository.login(email: email, password: password);
      final bootstrap = await _bootstrapRepository.loadBootstrap();
      final comparison = await _updateRepository.compareVersions(
        const ClientVersionPayload(
          dataVersion: 'v1',
          assetsVersion: 'v1',
          applicationVersion: 'v3',
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _session = bootstrap.session;
        _bootstrap = bootstrap;
        _isChecking = false;
        _error = null;
      });

      if (comparison.requiresAnyUpdate && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => UpdateGatePage(comparison: comparison),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isChecking = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _refreshBootstrap() async {
    final bootstrap = await _bootstrapRepository.loadBootstrap();

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
      home: _session == null || _bootstrap == null
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
              leadsRepository: _leadsRepository,
              offersRepository: _offersRepository,
              pricingRepository: _pricingRepository,
              usersRepository: _usersRepository,
              onRefreshBootstrap: _refreshBootstrap,
            ),
    );
  }
}