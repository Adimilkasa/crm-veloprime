import 'package:flutter/material.dart';

import '../../../core/presentation/veloprime_ui.dart';

enum StartupPreparationStepStatus { pending, active, completed, failed }

class StartupPreparationStep {
  const StartupPreparationStep({
    required this.label,
    required this.description,
    required this.status,
  });

  final String label;
  final String description;
  final StartupPreparationStepStatus status;

  StartupPreparationStep copyWith({
    String? label,
    String? description,
    StartupPreparationStepStatus? status,
  }) {
    return StartupPreparationStep(
      label: label ?? this.label,
      description: description ?? this.description,
      status: status ?? this.status,
    );
  }
}

class StartupPreparationState {
  const StartupPreparationState({
    required this.title,
    required this.subtitle,
    required this.steps,
    required this.isWorking,
    this.errorMessage,
  });

  final String title;
  final String subtitle;
  final List<StartupPreparationStep> steps;
  final bool isWorking;
  final String? errorMessage;

  factory StartupPreparationState.initial() {
    return const StartupPreparationState(
      title: 'Przygotowuję środowisko pracy',
      subtitle: 'Sprawdzamy centralę, wersje publikacji i krytyczne zasoby zanim pokażemy główny interfejs CRM.',
      isWorking: true,
      steps: [
        StartupPreparationStep(
          label: 'Pobieramy bootstrap CRM',
          description: 'Sesja, uprawnienia i dane startowe modułów.',
          status: StartupPreparationStepStatus.active,
        ),
        StartupPreparationStep(
          label: 'Sprawdzamy manifest publikacji',
          description: 'Wersje DATA, ASSETS i APPLICATION dostępne w centrali.',
          status: StartupPreparationStepStatus.pending,
        ),
        StartupPreparationStep(
          label: 'Porównujemy wersje klienta',
          description: 'Ocena, czy przed wejściem do CRM potrzebna jest dodatkowa akcja.',
          status: StartupPreparationStepStatus.pending,
        ),
        StartupPreparationStep(
          label: 'Dogrzewamy krytyczne assety',
          description: 'Tło startowe, branding i lokalne zasoby oferty gotowe do pierwszego renderu.',
          status: StartupPreparationStepStatus.pending,
        ),
      ],
    );
  }

  StartupPreparationState copyWith({
    String? title,
    String? subtitle,
    List<StartupPreparationStep>? steps,
    bool? isWorking,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StartupPreparationState(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      steps: steps ?? this.steps,
      isWorking: isWorking ?? this.isWorking,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class StartupPreparationPage extends StatelessWidget {
  const StartupPreparationPage({
    super.key,
    required this.state,
    this.onRetry,
  });

  final StartupPreparationState state;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final completedSteps = state.steps
        .where((step) => step.status == StartupPreparationStepStatus.completed)
        .length;
    final progress = state.steps.isEmpty ? 0.0 : completedSteps / state.steps.length;

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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1160),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 940;

                      final hero = VeloPrimeWorkspacePanel(
                        tint: VeloPrimePalette.bronzeDeep,
                        radius: 32,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const VeloPrimeSectionEyebrow(label: 'Start aplikacji'),
                            const SizedBox(height: 18),
                            Text(
                              state.title,
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                height: 1.04,
                                color: VeloPrimePalette.ink,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.subtitle,
                              style: const TextStyle(
                                fontSize: 16,
                                color: VeloPrimePalette.muted,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 28),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.08, 1.0),
                                minHeight: 10,
                                backgroundColor: const Color(0x140F2D67),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${completedSteps}/${state.steps.length} kroków zakończonych',
                              style: const TextStyle(
                                color: VeloPrimePalette.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );

                      final stepsCard = VeloPrimeWorkspacePanel(
                        tint: VeloPrimePalette.sea,
                        radius: 32,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const VeloPrimeSectionEyebrow(
                              label: 'Kroki przygotowania',
                              color: VeloPrimePalette.sea,
                            ),
                            const SizedBox(height: 18),
                            ...state.steps.asMap().entries.map(
                              (entry) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: entry.key == state.steps.length - 1 ? 0 : 14,
                                ),
                                child: _PreparationStepTile(step: entry.value),
                              ),
                            ),
                            if (state.errorMessage != null) ...[
                              const SizedBox(height: 18),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFF5F3), Color(0xFFFBE7E2)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0x20A64B45)),
                                ),
                                child: Text(
                                  state.errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFF8E372A),
                                    fontWeight: FontWeight.w600,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            if (!state.isWorking && onRetry != null)
                              FilledButton.icon(
                                onPressed: onRetry,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Spróbuj ponownie'),
                              ),
                          ],
                        ),
                      );

                      if (compact) {
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [hero, const SizedBox(height: 24), stepsCard],
                          ),
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: hero),
                          const SizedBox(width: 24),
                          Expanded(child: stepsCard),
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

class _PreparationStepTile extends StatelessWidget {
  const _PreparationStepTile({required this.step});

  final StartupPreparationStep step;

  Color get _accentColor {
    switch (step.status) {
      case StartupPreparationStepStatus.active:
        return VeloPrimePalette.sea;
      case StartupPreparationStepStatus.completed:
        return const Color(0xFF2F855A);
      case StartupPreparationStepStatus.failed:
        return const Color(0xFFA63B2B);
      case StartupPreparationStepStatus.pending:
        return VeloPrimePalette.muted;
    }
  }

  Widget _buildLeading() {
    switch (step.status) {
      case StartupPreparationStepStatus.active:
        return SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
          ),
        );
      case StartupPreparationStepStatus.completed:
        return Icon(Icons.check_circle_rounded, color: _accentColor, size: 20);
      case StartupPreparationStepStatus.failed:
        return Icon(Icons.error_rounded, color: _accentColor, size: 20);
      case StartupPreparationStepStatus.pending:
        return Icon(Icons.radio_button_unchecked_rounded, color: _accentColor, size: 18);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Color.alphaBlend(_accentColor.withValues(alpha: 0.06), Colors.white),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _accentColor.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(child: _buildLeading()),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: VeloPrimePalette.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  step.description,
                  style: const TextStyle(
                    color: VeloPrimePalette.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}