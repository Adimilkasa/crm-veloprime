import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/api_config.dart';
import '../../../core/presentation/veloprime_ui.dart';
import '../models/update_models.dart';

class UpdateGatePage extends StatefulWidget {
  const UpdateGatePage({
    super.key,
    required this.comparison,
    this.onSynchronizeSystemData,
  });

  final VersionComparisonResult comparison;
  final Future<bool> Function()? onSynchronizeSystemData;

  @override
  State<UpdateGatePage> createState() => _UpdateGatePageState();
}

class _UpdateGatePageState extends State<UpdateGatePage> {
  bool _isLaunching = false;
  bool _isSynchronizing = false;

  Uri get _appInstallerUri {
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    return Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: '/download/VeloPrime-CRM-Test.appinstaller',
    );
  }

  Future<void> _synchronizeSystemData() async {
    final callback = widget.onSynchronizeSystemData;

    if (callback == null || _isSynchronizing) {
      return;
    }

    setState(() {
      _isSynchronizing = true;
    });

    try {
      final synchronized = await callback();

      if (!mounted) {
        return;
      }

      if (synchronized) {
        Navigator.of(context).pop();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Synchronizacja nie została jeszcze zakończona.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udalo sie zsynchronizowac danych.\n$error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSynchronizing = false;
        });
      }
    }
  }

  Uri get _downloadPageUri {
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    return Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: '/download',
    );
  }

  Uri get _msAppInstallerUri {
    return Uri.parse('ms-appinstaller:?source=${Uri.encodeComponent(_appInstallerUri.toString())}');
  }

  Future<void> _openUpdate() async {
    if (_isLaunching) {
      return;
    }

    setState(() {
      _isLaunching = true;
    });

    try {
      final openedInInstaller = await launchUrl(
        _msAppInstallerUri,
        mode: LaunchMode.externalApplication,
      );

      if (openedInInstaller) {
        return;
      }

      final openedDownload = await launchUrl(
        _appInstallerUri,
        mode: LaunchMode.externalApplication,
      );

      if (openedDownload) {
        return;
      }

      final openedPage = await launchUrl(
        _downloadPageUri,
        mode: LaunchMode.externalApplication,
      );

      if (!openedPage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udalo sie uruchomic instalatora aktualizacji.')),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udalo sie uruchomic aktualizacji.\n$error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLaunching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingItems = widget.comparison.items.where((item) => item.requiresUpdate).toList();
    final requiresApplicationUpdate = pendingItems.any((item) => item.artifactType == 'APPLICATION');

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
                        Text(
                          requiresApplicationUpdate ? 'Aktualizacja jest gotowa' : 'Wymagana synchronizacja systemu',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          requiresApplicationUpdate
                              ? 'Wykryto nowszą wersję aplikacji. Zainstaluj aktualizację, aby kontynuować pracę.'
                              : 'Wykryto nowszą publikację danych systemowych. Aplikacja musi zsynchronizować się przed dalszą pracą.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: VeloPrimePalette.muted, height: 1.6),
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
                              const VeloPrimeSectionEyebrow(label: 'Elementy do aktualizacji', color: VeloPrimePalette.sea),
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
                                                'Lokalnie: ${item.currentVersion ?? 'brak'} • Dostępna wersja: ${item.publishedVersion}',
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
                        if (requiresApplicationUpdate) ...[
                          Text(
                            'Aktualizacja otworzy Windows App Installer dla adresu ${_appInstallerUri.toString()}. Jesli system nie obsluzy schematu automatycznie, otworzymy bezposredni plik instalatora albo strone pobierania.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: VeloPrimePalette.muted, height: 1.6),
                          ),
                        ] else ...[
                          Text(
                            widget.onSynchronizeSystemData == null
                                ? 'Ta publikacja nie wymaga nowej paczki instalacyjnej, ale wymaga zsynchronizowania danych i zasobow z centrala.'
                                : 'Ta publikacja nie wymaga nowej paczki instalacyjnej. Mozesz zsynchronizowac dane i materialy bez ponownego logowania.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: VeloPrimePalette.muted, height: 1.6),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            if (requiresApplicationUpdate)
                              FilledButton.icon(
                                onPressed: _isLaunching ? null : _openUpdate,
                                icon: _isLaunching
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2.2),
                                      )
                                    : const Icon(Icons.system_update_alt_rounded),
                                label: Text(_isLaunching ? 'Uruchamiamy instalator...' : 'Aktualizuj teraz'),
                              ),
                            if (!requiresApplicationUpdate && widget.onSynchronizeSystemData != null)
                              FilledButton.icon(
                                onPressed: _isSynchronizing ? null : _synchronizeSystemData,
                                icon: _isSynchronizing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2.2),
                                      )
                                    : const Icon(Icons.sync_rounded),
                                label: Text(_isSynchronizing ? 'Synchronizujemy...' : 'Synchronizuj teraz'),
                              ),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Wroc do aplikacji'),
                            ),
                          ],
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