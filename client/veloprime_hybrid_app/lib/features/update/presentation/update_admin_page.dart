import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/client_artifact_versions.dart';
import '../../../core/presentation/veloprime_ui.dart';
import '../data/update_repository.dart';
import '../models/update_models.dart';

class UpdateAdminPage extends StatefulWidget {
  const UpdateAdminPage({
    super.key,
    required this.repository,
    this.embeddedInShell = false,
    this.onManifestChanged,
  });

  final UpdateRepository repository;
  final bool embeddedInShell;
  final Future<void> Function()? onManifestChanged;

  @override
  State<UpdateAdminPage> createState() => _UpdateAdminPageState();
}

class _UpdateAdminPageState extends State<UpdateAdminPage> {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy HH:mm');
  static const Color _accentColor = VeloPrimePalette.violet;
  static const List<String> _artifactOrder = ['DATA', 'ASSETS', 'APPLICATION'];

  UpdateManifestInfo? _manifest;
  VersionComparisonResult? _comparison;
  bool _isLoading = true;
  bool _isPublishing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        widget.repository.fetchManifest(),
        widget.repository.compareVersions(
          const ClientVersionPayload(
            dataVersion: ClientArtifactVersions.data,
            assetsVersion: ClientArtifactVersions.assets,
            applicationVersion: ClientArtifactVersions.application,
          ),
        ),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _manifest = results[0] as UpdateManifestInfo;
        _comparison = results[1] as VersionComparisonResult;
        _isLoading = false;
        _error = null;
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

  Future<void> _publishArtifact(String artifactType) async {
    final request = await showDialog<_PublishRequest>(
      context: context,
      builder: (context) => _PublishArtifactDialog(
        artifactType: artifactType,
        defaultPriority: artifactType == 'DATA' ? 'CRITICAL' : 'STANDARD',
      ),
    );

    if (request == null) {
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      final manifest = await widget.repository.publishUpdate(
        artifactType: artifactType,
        priority: request.priority,
        summary: request.summary,
      );
      final comparison = await widget.repository.compareVersions(
        const ClientVersionPayload(
          dataVersion: ClientArtifactVersions.data,
          assetsVersion: ClientArtifactVersions.assets,
          applicationVersion: ClientArtifactVersions.application,
        ),
      );

      if (widget.onManifestChanged != null) {
        await widget.onManifestChanged!();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _manifest = manifest;
        _comparison = comparison;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Publikacja $artifactType została zapisana.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  VersionComparisonItem? _comparisonFor(String artifactType) {
    final comparison = _comparison;
    if (comparison == null) {
      return null;
    }

    for (final item in comparison.items) {
      if (item.artifactType == artifactType) {
        return item;
      }
    }

    return null;
  }

  String _localVersionFor(String artifactType) {
    switch (artifactType) {
      case 'DATA':
        return ClientArtifactVersions.data;
      case 'ASSETS':
        return ClientArtifactVersions.assets;
      case 'APPLICATION':
        return ClientArtifactVersions.application;
      default:
        return '-';
    }
  }

  String _artifactTitle(String artifactType) {
    switch (artifactType) {
      case 'DATA':
        return 'Publikacja danych katalogu';
      case 'ASSETS':
        return 'Publikacja materiałów modelu';
      case 'APPLICATION':
        return 'Publikacja aplikacji';
      default:
        return artifactType;
    }
  }

  String _artifactDescription(String artifactType) {
    switch (artifactType) {
      case 'DATA':
        return 'Publikacja katalogu sprzedażowego, cen, wersji i palet kolorów dla całego zespołu po zapisaniu zmian przez administratora.';
      case 'ASSETS':
        return 'Publikacja zdjęć, grafik premium i PDF specyfikacji przypiętych do modeli po przygotowaniu materiałów.';
      case 'APPLICATION':
        return 'Wersjonowanie samej aplikacji instalowanej u handlowców i administratorów.';
      default:
        return 'Publikacja artefaktu systemowego.';
    }
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Jeszcze nie opublikowano';
    }

    try {
      return _dateFormat.format(DateTime.parse(value).toLocal());
    } catch (_) {
      return value;
    }
  }

  Widget _buildHero(UpdateManifestInfo manifest, VersionComparisonResult comparison) {
    final pendingCount = comparison.items.where((item) => item.requiresUpdate).length;
    final dataVersion = manifest.findVersion('DATA')?.version ?? 'v1';
    final assetsVersion = manifest.findVersion('ASSETS')?.version ?? 'v1';
    final applicationVersion = manifest.findVersion('APPLICATION')?.version ?? 'v1';

    return VeloPrimeWorkspacePanel(
      tint: _accentColor,
      radius: 30,
      padding: const EdgeInsets.all(28),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VeloPrimeSectionEyebrow(label: 'Publikacje', color: _accentColor),
              const SizedBox(height: 12),
              const Text(
                'Publikacja wersji DATA, ASSETS i APPLICATION',
                style: TextStyle(
                  color: VeloPrimePalette.ink,
                  fontSize: 34,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                pendingCount == 0
                  ? 'Lokalne wersje klienta są zgodne z opublikowanym manifestem. W tym miejscu zatwierdzasz zmiany katalogu i materiałów dla całego zespołu.'
                  : 'Lokalny klient jest już za opublikowanym manifestem. Przed dalszą pracą możesz ocenić różnice i świadomie opublikować kolejne paczki.',
                style: TextStyle(
                  color: VeloPrimePalette.muted.withValues(alpha: 0.96),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              const Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  VeloPrimeBadge(label: 'Lokalne DATA', value: ClientArtifactVersions.data),
                  VeloPrimeBadge(label: 'Lokalne ASSETS', value: ClientArtifactVersions.assets),
                  VeloPrimeBadge(label: 'Lokalna APP', value: ClientArtifactVersions.application),
                  VeloPrimeBadge(label: 'Release', value: ClientArtifactVersions.release),
                ],
              ),
            ],
          );

          final actions = Container(
            width: isWide ? 330 : double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.92),
                  Color.alphaBlend(_accentColor.withValues(alpha: 0.08), Colors.white),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: VeloPrimePalette.lineStrong),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aktualny manifest',
                  style: TextStyle(
                    color: VeloPrimePalette.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    VeloPrimeBadge(label: 'DATA', value: dataVersion),
                    VeloPrimeBadge(label: 'ASSETS', value: assetsVersion),
                    VeloPrimeBadge(label: 'APP', value: applicationVersion),
                    VeloPrimeBadge(
                      label: 'Stan klienta',
                      value: pendingCount == 0 ? 'Zgodny' : 'Wymaga uwagi',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _isPublishing ? null : () => _load(silent: false),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: const Text('Odśwież manifest'),
                ),
              ],
            ),
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: copy),
                const SizedBox(width: 20),
                actions,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              copy,
              const SizedBox(height: 18),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildArtifactCard(PublishedVersionInfo? version, VersionComparisonItem? comparisonItem) {
    final artifactType = version?.artifactType ?? comparisonItem?.artifactType ?? 'UNKNOWN';
    final snapshot = version?.snapshot ?? comparisonItem?.snapshot;
    final statsEntries = snapshot?.stats.entries.toList() ?? const [];
    final requiresUpdate = comparisonItem?.requiresUpdate ?? false;
    final statusColor = requiresUpdate ? VeloPrimePalette.rose : VeloPrimePalette.olive;

    return VeloPrimeWorkspacePanel(
      tint: statusColor,
      radius: 28,
      padding: const EdgeInsets.all(24),
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
                    VeloPrimeSectionEyebrow(
                      label: artifactType,
                      color: statusColor,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _artifactTitle(artifactType),
                      style: const TextStyle(
                        color: VeloPrimePalette.ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _artifactDescription(artifactType),
                      style: const TextStyle(
                        color: VeloPrimePalette.muted,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: _isPublishing ? null : () => _publishArtifact(artifactType),
                icon: _isPublishing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(Icons.publish_rounded),
                label: const Text('Publikuj'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              VeloPrimeBadge(label: 'Opublikowane', value: version?.version ?? 'v1'),
              VeloPrimeBadge(label: 'Lokalnie', value: comparisonItem?.currentVersion ?? _localVersionFor(artifactType)),
              VeloPrimeBadge(label: 'Priorytet', value: version?.priority ?? comparisonItem?.priority ?? 'STANDARD'),
              VeloPrimeBadge(label: 'Status klienta', value: requiresUpdate ? 'Nowsza wersja dostępna' : 'Zgodne'),
              if (snapshot != null) VeloPrimeBadge(label: 'Źródło snapshotu', value: snapshot.source),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Opublikowano: ${_formatDate(version?.publishedAt)}',
            style: const TextStyle(
              color: VeloPrimePalette.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          if ((version?.publishedBy ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Autor publikacji: ${version!.publishedBy}',
              style: const TextStyle(color: VeloPrimePalette.muted),
            ),
          ],
          if ((version?.summary ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: VeloPrimePalette.lineStrong),
              ),
              child: Text(
                version!.summary!,
                style: const TextStyle(color: VeloPrimePalette.ink, height: 1.5),
              ),
            ),
          ],
          const SizedBox(height: 18),
          if (statsEntries.isEmpty)
            const Text(
              'Ten artefakt nie ma jeszcze zapisanego snapshotu publikacji.',
              style: TextStyle(color: VeloPrimePalette.muted, height: 1.6),
            )
          else ...[
            const Text(
              'Snapshot publikacji',
              style: TextStyle(
                color: VeloPrimePalette.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: statsEntries
                  .map(
                    (entry) => VeloPrimeBadge(
                      label: entry.key,
                      value: entry.value.toString(),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (snapshot != null && snapshot.notes.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Notatki snapshotu',
              style: TextStyle(
                color: VeloPrimePalette.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ...snapshot.notes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 8, color: VeloPrimePalette.muted),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        note,
                        style: const TextStyle(color: VeloPrimePalette.muted, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manifest = _manifest;
    final comparison = _comparison;

    final content = _isLoading
        ? const VeloPrimeWorkspaceState(
            tint: _accentColor,
            eyebrow: 'Publikacje',
            title: 'Ładujemy manifest aktualizacji',
            message: 'Pobieramy opublikowane wersje, snapshoty i porównanie z lokalnym klientem.',
            isLoading: true,
          )
        : _error != null
            ? VeloPrimeWorkspaceState(
                tint: VeloPrimePalette.rose,
                eyebrow: 'Publikacje',
                title: 'Nie udało się pobrać manifestu',
                message: _error!,
                icon: Icons.warning_amber_rounded,
              )
            : manifest == null || comparison == null
                ? const VeloPrimeWorkspaceState(
                    tint: _accentColor,
                    eyebrow: 'Publikacje',
                    title: 'Brak danych manifestu',
                    message: 'Po pierwszej publikacji wersje DATA, ASSETS i APPLICATION pojawią się w tym miejscu.',
                    icon: Icons.publish_outlined,
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHero(manifest, comparison),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 1100;
                            final cards = _artifactOrder
                                .map(
                                  (artifactType) => _buildArtifactCard(
                                    manifest.findVersion(artifactType),
                                    _comparisonFor(artifactType),
                                  ),
                                )
                                .toList();

                            if (!isWide) {
                              return Column(
                                children: [
                                  for (final card in cards) ...[
                                    card,
                                    const SizedBox(height: 18),
                                  ],
                                ],
                              );
                            }

                            return Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: cards[0]),
                                    const SizedBox(width: 18),
                                    Expanded(child: cards[1]),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                cards[2],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  );

    if (widget.embeddedInShell) {
      return content;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: content,
        ),
      ),
    );
  }
}

class _PublishRequest {
  const _PublishRequest({
    required this.priority,
    required this.summary,
  });

  final String priority;
  final String? summary;
}

class _PublishArtifactDialog extends StatefulWidget {
  const _PublishArtifactDialog({
    required this.artifactType,
    required this.defaultPriority,
  });

  final String artifactType;
  final String defaultPriority;

  @override
  State<_PublishArtifactDialog> createState() => _PublishArtifactDialogState();
}

class _PublishArtifactDialogState extends State<_PublishArtifactDialog> {
  late final TextEditingController _summaryController = TextEditingController();
  late String _priority = widget.defaultPriority;

  @override
  void dispose() {
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Publikuj ${widget.artifactType}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ta akcja podniesie wersję ${widget.artifactType} w manifeście i zapisze nowy snapshot publikacji.',
              style: const TextStyle(color: VeloPrimePalette.muted, height: 1.5),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: veloPrimeInputDecoration('Priorytet'),
              items: const [
                DropdownMenuItem(value: 'STANDARD', child: Text('STANDARD')),
                DropdownMenuItem(value: 'CRITICAL', child: Text('CRITICAL')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _priority = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _summaryController,
              minLines: 3,
              maxLines: 4,
              decoration: veloPrimeInputDecoration(
                'Podsumowanie publikacji',
                hintText: 'Np. nowe modele, aktualizacja cen BYD, nowy pakiet zdjęć Seal U',
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop(
              _PublishRequest(
                priority: _priority,
                summary: _summaryController.text.trim().isEmpty ? null : _summaryController.text.trim(),
              ),
            );
          },
          icon: const Icon(Icons.publish_rounded),
          label: const Text('Publikuj'),
        ),
      ],
    );
  }
}
