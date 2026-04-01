import 'package:flutter/material.dart';

import '../../../core/presentation/veloprime_ui.dart';

class ModulePlaceholderPage extends StatelessWidget {
  const ModulePlaceholderPage({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.primaryAction,
    this.secondaryAction,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      if (secondaryAction != null) secondaryAction!,
      if (primaryAction != null) primaryAction!,
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VeloPrimeShell(
        decorateBackground: false,
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
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
                    final isWide = constraints.maxWidth >= 1040;
                    final copy = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VeloPrimeSectionEyebrow(label: eyebrow),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            color: VeloPrimePalette.ink,
                            fontSize: 38,
                            height: 1.04,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: VeloPrimePalette.muted,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                      ],
                    );

                    final actionPanel = actions.isEmpty
                        ? null
                        : Container(
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
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: actions,
                            ),
                          );

                    if (!isWide || actionPanel == null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          copy,
                          if (actionPanel != null) ...[
                            const SizedBox(height: 20),
                            actionPanel,
                          ],
                        ],
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
              const SizedBox(height: 24),
              VeloPrimeWorkspacePanel(
                tint: accentColor,
                radius: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.lerp(accentColor, Colors.white, 0.78) ?? Colors.white,
                            Color.lerp(accentColor, Colors.white, 0.92) ?? Colors.white,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: accentColor.withValues(alpha: 0.16)),
                      ),
                      child: Icon(icon, size: 34, color: accentColor),
                    ),
                    const SizedBox(height: 20),
                    VeloPrimeSectionEyebrow(label: 'Status modułu', color: accentColor),
                    const SizedBox(height: 18),
                    const Text(
                      'Moduł jest dostępny w głównej nawigacji CRM.',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: VeloPrimePalette.ink),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Ta sekcja będzie rozwijana w kolejnych etapach. Na ten moment możesz kontynuować pracę w aktywnych modułach systemu.',
                      style: TextStyle(color: VeloPrimePalette.muted, height: 1.55),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: const [
                        _PlaceholderPill(label: 'Status', value: 'W przygotowaniu'),
                        _PlaceholderPill(label: 'Nawigacja', value: 'Zakładka główna CRM'),
                        _PlaceholderPill(label: 'Rekomendacja', value: 'Pracuj w aktywnych modułach'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderPill extends StatelessWidget {
  const _PlaceholderPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VeloPrimePalette.lineStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: VeloPrimePalette.muted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink),
          ),
        ],
      ),
    );
  }
}