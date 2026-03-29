import 'package:flutter/material.dart';

import '../../../core/presentation/veloprime_ui.dart';
import '../models/update_models.dart';

class UpdateGatePage extends StatelessWidget {
  const UpdateGatePage({super.key, required this.comparison});

  final VersionComparisonResult comparison;

  @override
  Widget build(BuildContext context) {
    final pendingItems = comparison.items.where((item) => item.requiresUpdate).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VeloPrimeShell(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  VeloPrimeWorkspacePanel(
                    tint: VeloPrimePalette.sea,
                    radius: 32,
                    child: Column(
                      children: [
                        const VeloPrimeSectionEyebrow(label: 'Aktualizacja systemu', color: VeloPrimePalette.sea),
                        const SizedBox(height: 18),
                        const SizedBox(
                          width: 88,
                          height: 88,
                          child: CircularProgressIndicator(strokeWidth: 7),
                        ),
                        const SizedBox(height: 26),
                        const Text(
                          'Trwa aktualizacja systemu',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Wykryto nowsza publikacje centrali. Przed dalsza praca klient lokalny musi zostac zsynchronizowany.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: VeloPrimePalette.muted, height: 1.6),
                        ),
                        const SizedBox(height: 26),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: VeloPrimePalette.lineStrong),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const VeloPrimeSectionEyebrow(label: 'Pakiety do synchronizacji', color: VeloPrimePalette.sea),
                              const SizedBox(height: 16),
                              ...pendingItems.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Color.alphaBlend(VeloPrimePalette.sea.withValues(alpha: 0.06), Colors.white),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: VeloPrimePalette.lineStrong),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(item.artifactType, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Lokalnie: ${item.currentVersion ?? 'brak'} | Centrala: ${item.publishedVersion}',
                                                style: const TextStyle(color: VeloPrimePalette.muted, height: 1.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        VeloPrimeBadge(label: 'Priorytet', value: item.priority),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'To nadal ekran przejsciowy, ale wizualnie jest juz spojny z reszta produktu. Kolejny etap to finalny przebieg aktualizacji z rzeczywistym pobieraniem paczek.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: VeloPrimePalette.muted, height: 1.6),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Wroc do aplikacji'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}