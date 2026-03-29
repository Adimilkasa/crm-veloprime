import 'package:flutter/material.dart';

import '../../../core/presentation/veloprime_ui.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onLogin,
    required this.isLoading,
    required this.errorMessage,
  });

  final Future<void> Function(String email, String password) onLogin;
  final bool isLoading;
  final String? errorMessage;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController(text: 'admin@veloprime.pl');
  final _passwordController = TextEditingController(text: 'Admin123!');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/Błękitny.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xCCFDFEFF),
                    const Color(0x9FE7F2FF),
                    const Color(0xB5D8E5F7).withValues(alpha: 0.88),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            left: -30,
            child: Container(
              width: 340,
              height: 220,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x30D4A84F), Color(0x00D4A84F)],
                ),
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 300,
              height: 200,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x284A90E2), Color(0x004A90E2)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 920;

                      final hero = VeloPrimeWorkspacePanel(
                          tint: VeloPrimePalette.bronzeDeep,
                          radius: 32,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const VeloPrimeSectionEyebrow(label: 'VeloPrime CRM'),
                              const SizedBox(height: 18),
                              const Text(
                                'Premium desktop CRM dla codziennej pracy handlowej bez kompromisu na danych centrali.',
                                style: TextStyle(
                                  fontSize: 46,
                                  fontWeight: FontWeight.w700,
                                  height: 1.04,
                                  color: VeloPrimePalette.ink,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Oferty, leady, konta i polityka cenowa pozostaja zsynchronizowane z backendem, ale codzienna praca dostaje lzejszy, bardziej nowoczesny interfejs produktu.',
                                style: TextStyle(fontSize: 16, color: VeloPrimePalette.muted, height: 1.6),
                              ),
                              const SizedBox(height: 28),
                              Wrap(
                                spacing: 14,
                                runSpacing: 14,
                                children: const [
                                  VeloPrimeBadge(label: 'Tryb', value: 'Desktop workflow'),
                                  VeloPrimeBadge(label: 'Zrodlo prawdy', value: 'Centrala VeloPrime'),
                                  VeloPrimeBadge(label: 'Zakres', value: 'Oferty, leady, konta'),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.9),
                                      Color.alphaBlend(VeloPrimePalette.bronzeDeep.withValues(alpha: 0.08), Colors.white),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: VeloPrimePalette.bronzeDeep.withValues(alpha: 0.12)),
                                ),
                                child: const Text(
                                  'Po zalogowaniu klient pobierze bootstrap, sesje i aktualne konfiguracje pracy lokalnej.',
                                  style: TextStyle(color: VeloPrimePalette.muted, height: 1.6),
                                ),
                              ),
                            ],
                          ),
                      );

                      final form = ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: VeloPrimeWorkspacePanel(
                          tint: VeloPrimePalette.sea,
                          radius: 32,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const VeloPrimeSectionEyebrow(label: 'Logowanie', color: VeloPrimePalette.sea),
                              const SizedBox(height: 12),
                              const Text(
                                'Zaloguj się do centrali',
                                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Po zalogowaniu klient pobierze bootstrap, sesje i wersje danych wymagane do pracy lokalnej.',
                                style: TextStyle(color: VeloPrimePalette.muted, height: 1.5),
                              ),
                              const SizedBox(height: 24),
                              TextField(
                                controller: _emailController,
                                decoration: veloPrimeInputDecoration('Email', hintText: 'admin@veloprime.pl'),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: veloPrimeInputDecoration('Hasło'),
                              ),
                              if (widget.errorMessage != null) ...[
                                const SizedBox(height: 14),
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
                                    widget.errorMessage!,
                                    style: const TextStyle(color: Color(0xFF8E372A), fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 22),
                              FilledButton(
                                onPressed: widget.isLoading
                                    ? null
                                    : () => widget.onLogin(
                                          _emailController.text.trim(),
                                          _passwordController.text,
                                        ),
                                child: widget.isLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF181512)),
                                      )
                                    : const Text('Wejdź do CRM'),
                              ),
                            ],
                          ),
                        ),
                      );

                      if (compact) {
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: 520,
                                child: hero,
                              ),
                              const SizedBox(height: 24),
                              form,
                            ],
                          ),
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: hero),
                          const SizedBox(width: 28),
                          form,
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}