import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/presentation/veloprime_ui.dart';
import '../../bootstrap/models/bootstrap_payload.dart';
import '../data/pricing_repository.dart';
import '../models/pricing_models.dart';

class PricingHomePage extends StatefulWidget {
  const PricingHomePage({
    super.key,
    required this.session,
    required this.repository,
    this.embeddedInShell = false,
    this.onPricingCatalogChanged,
  });

  final SessionInfo session;
  final PricingRepository repository;
  final bool embeddedInShell;
  final Future<void> Function()? onPricingCatalogChanged;

  @override
  State<PricingHomePage> createState() => _PricingHomePageState();
}

class _PricingHomePageState extends State<PricingHomePage> {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy HH:mm');
  static const Color _accentColor = Color(0xFF8B5E34);

  final TextEditingController _importController = TextEditingController();

  PricingSheetData? _sheet;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isImporting = false;
  bool _isClearing = false;
  String? _error;
  String? _feedback;
  bool _isSuccessFeedback = true;
  List<int> _rowTokens = const [];
  List<int> _columnTokens = const [];
  int _nextToken = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sheet = await widget.repository.fetchSheet();

      if (!mounted) {
        return;
      }

      setState(() {
        _applySheet(sheet);
        _isLoading = false;
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

  void _applySheet(PricingSheetData source) {
    final normalized = _normalizeSheet(source);
    _sheet = normalized;
    _columnTokens = List<int>.generate(normalized.headers.length, (_) => _nextToken++);
    _rowTokens = List<int>.generate(normalized.rows.length, (_) => _nextToken++);
  }

  PricingSheetData _normalizeSheet(PricingSheetData source) {
    final headers = source.headers.isEmpty
        ? <String>['Kolumna 1', 'Kolumna 2']
        : source.headers.map((value) => value.trim().isEmpty ? 'Kolumna ${source.headers.indexOf(value) + 1}' : value).toList();
    final columnCount = math.max(headers.length, 2);
    final normalizedHeaders = headers.length >= 2
        ? headers
        : <String>[...headers, ...List<String>.generate(columnCount - headers.length, (index) => 'Kolumna ${headers.length + index + 1}')];
    final rows = source.rows
        .map((row) {
          final next = List<String>.from(row);
          while (next.length < normalizedHeaders.length) {
            next.add('');
          }
          return next.take(normalizedHeaders.length).toList();
        })
        .toList();

    if (rows.isEmpty) {
      rows.add(List<String>.filled(normalizedHeaders.length, ''));
    }

    return PricingSheetData(
      headers: normalizedHeaders,
      rows: rows,
      updatedAt: source.updatedAt,
      updatedBy: source.updatedBy,
    );
  }

  Future<void> _saveSheet() async {
    final sheet = _sheet;
    if (sheet == null) {
      return;
    }

    setState(() {
      _isSaving = true;
      _feedback = null;
      _error = null;
    });

    try {
      final saved = await widget.repository.saveSheet(
        headers: sheet.headers,
        rows: sheet.rows,
      );

      if (widget.onPricingCatalogChanged != null) {
        await widget.onPricingCatalogChanged!();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _applySheet(saved);
        _feedback = 'Baza samochodow zostala zapisana.';
        _isSuccessFeedback = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _feedback = error.toString();
        _isSuccessFeedback = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _importSheet() async {
    setState(() {
      _isImporting = true;
      _feedback = null;
      _error = null;
    });

    try {
      final imported = await widget.repository.importSheet(_importController.text);

      if (widget.onPricingCatalogChanged != null) {
        await widget.onPricingCatalogChanged!();
      }

      if (!mounted) {
        return;
      }

      _importController.clear();
      setState(() {
        _applySheet(imported);
        _feedback = 'Tabela zostala zaimportowana do arkusza CRM.';
        _isSuccessFeedback = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _feedback = error.toString();
        _isSuccessFeedback = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  Future<void> _clearSheet() async {
    setState(() {
      _isClearing = true;
      _feedback = null;
      _error = null;
    });

    try {
      final cleared = await widget.repository.clearSheet();

      if (widget.onPricingCatalogChanged != null) {
        await widget.onPricingCatalogChanged!();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _applySheet(cleared);
        _feedback = 'Baza cenowa zostala wyczyszczona.';
        _isSuccessFeedback = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _feedback = error.toString();
        _isSuccessFeedback = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isClearing = false;
        });
      }
    }
  }

  void _updateHeader(int columnIndex, String value) {
    final sheet = _sheet;
    if (sheet == null) {
      return;
    }

    final headers = List<String>.from(sheet.headers);
    headers[columnIndex] = value;

    setState(() {
      _sheet = sheet.copyWith(headers: headers);
    });
  }

  void _updateCell(int rowIndex, int columnIndex, String value) {
    final sheet = _sheet;
    if (sheet == null) {
      return;
    }

    final rows = sheet.rows.map((row) => List<String>.from(row)).toList();
    rows[rowIndex][columnIndex] = value;

    setState(() {
      _sheet = sheet.copyWith(rows: rows);
    });
  }

  void _addColumn() {
    final sheet = _sheet;
    if (sheet == null) {
      return;
    }

    final headers = List<String>.from(sheet.headers)..add('Kolumna ${sheet.headers.length + 1}');
    final rows = sheet.rows
        .map((row) => <String>[...row, ''])
        .toList();

    setState(() {
      _sheet = sheet.copyWith(headers: headers, rows: rows);
      _columnTokens = [..._columnTokens, _nextToken++];
    });
  }

  void _removeColumn(int columnIndex) {
    final sheet = _sheet;
    if (sheet == null) {
      return;
    }

    if (sheet.headers.length <= 2) {
      setState(() {
        _feedback = 'Arkusz musi miec przynajmniej dwie kolumny.';
        _isSuccessFeedback = false;
      });
      return;
    }

    final headers = List<String>.from(sheet.headers)..removeAt(columnIndex);
    final rows = sheet.rows
        .map((row) {
          final next = List<String>.from(row);
          next.removeAt(columnIndex);
          return next;
        })
        .toList();
    final columnTokens = List<int>.from(_columnTokens)..removeAt(columnIndex);

    setState(() {
      _sheet = sheet.copyWith(headers: headers, rows: rows);
      _columnTokens = columnTokens;
    });
  }

  void _addRow() {
    final sheet = _sheet;
    if (sheet == null) {
      return;
    }

    final rows = <List<String>>[
      ...sheet.rows.map((row) => List<String>.from(row)),
      List<String>.filled(sheet.headers.length, ''),
    ];

    setState(() {
      _sheet = sheet.copyWith(rows: rows);
      _rowTokens = [..._rowTokens, _nextToken++];
    });
  }

  void _removeRow(int rowIndex) {
    final sheet = _sheet;
    if (sheet == null) {
      return;
    }

    final rows = sheet.rows.map((row) => List<String>.from(row)).toList();
    final rowTokens = List<int>.from(_rowTokens);

    if (rows.length <= 1) {
      rows[0] = List<String>.filled(sheet.headers.length, '');
    } else {
      rows.removeAt(rowIndex);
      rowTokens.removeAt(rowIndex);
    }

    setState(() {
      _sheet = sheet.copyWith(rows: rows);
      _rowTokens = rowTokens;
    });
  }

  int get _filledRowCount {
    final sheet = _sheet;
    if (sheet == null) {
      return 0;
    }

    return sheet.rows.where((row) => row.any((cell) => cell.trim().isNotEmpty)).length;
  }

  double _columnWidth(int columnIndex) {
    final sheet = _sheet;
    if (sheet == null) {
      return 180;
    }

    final headerLength = sheet.headers[columnIndex].trim().length;
    var longest = headerLength;

    for (final row in sheet.rows) {
      longest = math.max(longest, row[columnIndex].trim().length);
    }

    return (56 + longest * 7).clamp(140, 280).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final sheet = _sheet;
    final content = _isLoading
        ? const VeloPrimeWorkspaceState(
            tint: _accentColor,
            eyebrow: 'Polityka cenowa',
            title: 'Ladujemy baze samochodow',
            message: 'Przygotowujemy arkusz cenowy do dalszej edycji i importu.',
            isLoading: true,
          )
        : _error != null
            ? VeloPrimeWorkspaceState(
                tint: VeloPrimePalette.rose,
                eyebrow: 'Polityka cenowa',
                title: 'Nie udalo sie pobrac arkusza',
                message: _error!,
                icon: Icons.warning_amber_rounded,
              )
            : sheet == null
                ? const VeloPrimeWorkspaceState(
                    tint: _accentColor,
                    eyebrow: 'Polityka cenowa',
                    title: 'Brak danych arkusza',
                    message: 'Baza cenowa pojawi sie tutaj po pierwszym imporcie lub zapisie.',
                    icon: Icons.table_chart_outlined,
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VeloPrimeWorkspacePanel(
                          tint: _accentColor,
                          radius: 30,
                          padding: const EdgeInsets.all(28),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 1020;
                              final copy = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const VeloPrimeSectionEyebrow(label: 'Polityka cenowa', color: _accentColor),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Wewnetrzna baza samochodow do ofert',
                                    style: TextStyle(
                                      color: VeloPrimePalette.ink,
                                      fontSize: 34,
                                      height: 1.05,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Edytujesz arkusz bezposrednio w CRM, importujesz dane z Excela i zapisujesz katalog, z ktorego korzysta generator ofert.',
                                    style: TextStyle(
                                      color: VeloPrimePalette.muted.withValues(alpha: 0.96),
                                      fontSize: 15,
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _StatPill(label: 'Rola', value: _roleLabel(widget.session.role), tint: _accentColor),
                                      _StatPill(label: 'Kolumny', value: '${sheet.headers.length}', tint: _accentColor),
                                      _StatPill(label: 'Wiersze', value: '$_filledRowCount', tint: _accentColor),
                                    ],
                                  ),
                                ],
                              );
                              final meta = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _InfoBlock(
                                    title: 'Ostatnia aktualizacja',
                                    value: _formatDate(sheet.updatedAt),
                                    subtitle: 'Autor: ${sheet.updatedBy ?? 'Seed systemowy'}',
                                    tint: _accentColor,
                                  ),
                                ],
                              );

                              if (!isWide) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    copy,
                                    const SizedBox(height: 20),
                                    meta,
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 3, child: copy),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 2, child: meta),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 1180;
                            final sidebar = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                VeloPrimeWorkspacePanel(
                                  tint: _accentColor,
                                  radius: 28,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.upload_file_outlined, color: _accentColor),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Import na start z Excela',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Wklej caly zakres z arkusza razem z naglowkami, a potem edytuj dalej recznie w tabeli.',
                                        style: TextStyle(color: VeloPrimePalette.muted, height: 1.55),
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        controller: _importController,
                                        minLines: 8,
                                        maxLines: 12,
                                        decoration: const InputDecoration(
                                          hintText: 'Stock\tMarka\tModel\tWersja\tCena brutto\nVP-001\tBYD\tSeal 6 DM-i\tComfort\t184900',
                                          alignLabelWithHint: true,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.icon(
                                          onPressed: _isImporting ? null : _importSheet,
                                          icon: _isImporting
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Icon(Icons.file_download_done_outlined),
                                          label: Text(_isImporting ? 'Importujemy...' : 'Importuj do arkusza'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                                VeloPrimeWorkspacePanel(
                                  tint: _accentColor,
                                  radius: 28,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.table_chart_outlined, color: _accentColor),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Edytuj baze w polach',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Mozesz pracowac jak na prostym Excelu: dodawac kolumny, wiersze, usuwac pozycje i recznie poprawiac konkretne komorki.',
                                        style: TextStyle(color: VeloPrimePalette.muted, height: 1.55),
                                      ),
                                      if (_feedback != null) ...[
                                        const SizedBox(height: 16),
                                        _FeedbackBox(
                                          message: _feedback!,
                                          isSuccess: _isSuccessFeedback,
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: [
                                          FilledButton.icon(
                                            onPressed: _isSaving ? null : _saveSheet,
                                            icon: _isSaving
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  )
                                                : const Icon(Icons.save_outlined),
                                            label: Text(_isSaving ? 'Zapisujemy...' : 'Zapisz baze'),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: _addRow,
                                            icon: const Icon(Icons.add_outlined),
                                            label: const Text('Dodaj wiersz'),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: _addColumn,
                                            icon: const Icon(Icons.view_column_outlined),
                                            label: const Text('Dodaj kolumne'),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: _isClearing ? null : _clearSheet,
                                            icon: _isClearing
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  )
                                                : const Icon(Icons.layers_clear_outlined),
                                            label: Text(_isClearing ? 'Czyscimy...' : 'Wyczysc tabele'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const VeloPrimeWorkspacePanel(
                                  tint: _accentColor,
                                  radius: 28,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      VeloPrimeSectionEyebrow(label: 'Co juz daje ten krok', color: _accentColor),
                                      SizedBox(height: 14),
                                      Text(
                                        'Budujemy baze wejsciowa pod ofertowanie bez zaleznosci od zewnetrznego arkusza.',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink),
                                      ),
                                      SizedBox(height: 12),
                                      Text('1. Mozesz recznie wklejac i poprawiac dane w konkretnych komorkach.', style: TextStyle(color: VeloPrimePalette.muted, height: 1.55)),
                                      SizedBox(height: 6),
                                      Text('2. Sam decydujesz o ukladzie kolumn i liczbie wierszy.', style: TextStyle(color: VeloPrimePalette.muted, height: 1.55)),
                                      SizedBox(height: 6),
                                      Text('3. Ten katalog od razu zasila generator oferty i dalsze kalkulacje.', style: TextStyle(color: VeloPrimePalette.muted, height: 1.55)),
                                    ],
                                  ),
                                ),
                              ],
                            );

                            final tablePanel = VeloPrimeWorkspacePanel(
                              tint: _accentColor,
                              radius: 28,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const VeloPrimeSectionEyebrow(label: 'Arkusz bazy', color: _accentColor),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Widok roboczy jak prosty Excel. Ostatnia aktualizacja: ${_formatDate(sheet.updatedAt)}',
                                    style: const TextStyle(color: VeloPrimePalette.muted),
                                  ),
                                  const SizedBox(height: 18),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.74),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(color: _accentColor.withValues(alpha: 0.14)),
                                    ),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildSheetLettersRow(sheet),
                                          _buildSheetHeadersRow(sheet),
                                          for (var rowIndex = 0; rowIndex < sheet.rows.length; rowIndex++)
                                            _buildSheetRow(sheet, rowIndex),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (!isWide) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [sidebar, const SizedBox(height: 18), tablePanel],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: 360, child: sidebar),
                                const SizedBox(width: 20),
                                Expanded(child: tablePanel),
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
      body: VeloPrimeShell(
        decorateBackground: false,
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
        child: content,
      ),
    );
  }

  Widget _buildSheetLettersRow(PricingSheetData sheet) {
    return Row(
      children: [
        _TableChromeCell(
          width: 72,
          height: 42,
          backgroundColor: const Color(0xFFF4EFE4),
          alignment: Alignment.center,
          child: const Text(
            'Sheet',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: VeloPrimePalette.muted,
            ),
          ),
        ),
        for (var columnIndex = 0; columnIndex < sheet.headers.length; columnIndex++)
          _TableChromeCell(
            width: _columnWidth(columnIndex),
            height: 42,
            backgroundColor: const Color(0xFFF4EFE4),
            alignment: Alignment.center,
            child: Text(
              _columnLabel(columnIndex),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: VeloPrimePalette.muted,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSheetHeadersRow(PricingSheetData sheet) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TableChromeCell(
          width: 72,
          height: 72,
          backgroundColor: const Color(0xFFF7F3EA),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: const Text(
            '#',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: VeloPrimePalette.muted,
            ),
          ),
        ),
        for (var columnIndex = 0; columnIndex < sheet.headers.length; columnIndex++)
          _TableChromeCell(
            width: _columnWidth(columnIndex),
            height: 72,
            backgroundColor: const Color(0xFFF7F3EA),
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: _InlineEditableField(
                    key: ValueKey('header-${_columnTokens[columnIndex]}'),
                    value: sheet.headers[columnIndex],
                    onChanged: (value) => _updateHeader(columnIndex, value),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: VeloPrimePalette.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _removeColumn(columnIndex),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: VeloPrimePalette.lineStrong),
                    ),
                    child: const Icon(Icons.delete_outline, size: 18, color: VeloPrimePalette.muted),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSheetRow(PricingSheetData sheet, int rowIndex) {
    final isEven = rowIndex.isEven;
    final background = isEven ? Colors.white.withValues(alpha: 0.92) : const Color(0xFFFDFCFA);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TableChromeCell(
          width: 72,
          height: 54,
          backgroundColor: background,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${rowIndex + 1}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: VeloPrimePalette.muted,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _removeRow(rowIndex),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: VeloPrimePalette.lineStrong),
                  ),
                  child: const Icon(Icons.remove, size: 16, color: VeloPrimePalette.muted),
                ),
              ),
            ],
          ),
        ),
        for (var columnIndex = 0; columnIndex < sheet.headers.length; columnIndex++)
          _TableChromeCell(
            width: _columnWidth(columnIndex),
            height: 54,
            backgroundColor: background,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: _InlineEditableField(
              key: ValueKey('cell-${_rowTokens[rowIndex]}-${_columnTokens[columnIndex]}'),
              value: sheet.rows[rowIndex][columnIndex],
              onChanged: (value) => _updateCell(rowIndex, columnIndex, value),
              style: const TextStyle(fontSize: 13, color: VeloPrimePalette.ink),
            ),
          ),
      ],
    );
  }
}

class _TableChromeCell extends StatelessWidget {
  const _TableChromeCell({
    required this.width,
    required this.height,
    required this.backgroundColor,
    required this.child,
    this.padding,
    this.alignment = Alignment.centerLeft,
  });

  final double width;
  final double height;
  final Color backgroundColor;
  final EdgeInsets? padding;
  final Alignment alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          right: BorderSide(color: VeloPrimePalette.lineStrong.withValues(alpha: 0.8)),
          bottom: BorderSide(color: VeloPrimePalette.lineStrong.withValues(alpha: 0.8)),
        ),
      ),
      child: child,
    );
  }
}

class _InlineEditableField extends StatefulWidget {
  const _InlineEditableField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.style,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final TextStyle style;

  @override
  State<_InlineEditableField> createState() => _InlineEditableFieldState();
}

class _InlineEditableFieldState extends State<_InlineEditableField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _InlineEditableField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      style: widget.style,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.tint,
  });

  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tint)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink)),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.tint,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.88),
            Color.alphaBlend(tint.withValues(alpha: 0.08), Colors.white),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tint.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tint)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: VeloPrimePalette.muted, height: 1.45)),
        ],
      ),
    );
  }
}

class _FeedbackBox extends StatelessWidget {
  const _FeedbackBox({
    required this.message,
    required this.isSuccess,
  });

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final background = isSuccess ? const Color(0xFFF4FBF8) : const Color(0xFFFFF5F4);
    final border = isSuccess ? const Color(0xFFD9ECE4) : const Color(0xFFF1D4D2);
    final foreground = isSuccess ? const Color(0xFF3F7D64) : const Color(0xFFA64B45);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Text(message, style: TextStyle(color: foreground, height: 1.45)),
    );
  }
}

String _roleLabel(String role) {
  switch (role) {
    case 'ADMIN':
      return 'Administrator';
    case 'DIRECTOR':
      return 'Dyrektor';
    case 'MANAGER':
      return 'Manager';
    default:
      return 'Handlowiec';
  }
}

String _formatDate(String? value) {
  if (value == null || value.isEmpty) {
    return 'Brak importu recznego';
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  return _PricingHomePageState._dateFormat.format(parsed);
}

String _columnLabel(int index) {
  var nextIndex = index;
  var label = '';

  while (nextIndex >= 0) {
    label = String.fromCharCode((nextIndex % 26) + 65) + label;
    nextIndex = (nextIndex ~/ 26) - 1;
  }

  return label;
}