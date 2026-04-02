import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
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
  static final NumberFormat _moneyFormat = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł', decimalDigits: 0);
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy HH:mm');
  static const Color _accentColor = Color(0xFF8B5E34);

  CatalogWorkspaceData? _workspace;
  bool _isLoading = true;
  bool _isMutating = false;
  String? _error;
  String? _selectedBrandId;
  String? _selectedModelId;
  String? _selectedVersionId;
  String? _selectedPricingId;

  @override
  void initState() {
    super.initState();
    _loadWorkspace();
  }

  Future<void> _loadWorkspace({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final workspace = await widget.repository.fetchWorkspace();

      if (!mounted) {
        return;
      }

      setState(() {
        _applyWorkspace(workspace);
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

  void _applyWorkspace(CatalogWorkspaceData workspace) {
    _workspace = workspace;

    final brands = _sortedBrands(workspace.brands);
    final selectedBrandId = brands.any((brand) => brand.id == _selectedBrandId)
        ? _selectedBrandId
        : null;

    final models = _sortedModels(
      workspace.models.where((model) => model.brandId == selectedBrandId).toList(),
    );
    final selectedModelId = models.any((model) => model.id == _selectedModelId)
        ? _selectedModelId
        : null;

    final versions = _sortedVersions(
      workspace.versions.where((version) => version.modelId == selectedModelId).toList(),
    );
    final selectedVersionId = versions.any((version) => version.id == _selectedVersionId)
        ? _selectedVersionId
        : null;

    final pricingRecords = _sortedPricing(
      workspace.pricingRecords.where((record) => record.versionId == selectedVersionId).toList(),
    );
    final selectedPricingId = pricingRecords.any((record) => record.id == _selectedPricingId)
        ? _selectedPricingId
        : null;

    _selectedBrandId = selectedBrandId;
    _selectedModelId = selectedModelId;
    _selectedVersionId = selectedVersionId;
    _selectedPricingId = selectedPricingId;
  }

  List<CatalogBrand> _sortedBrands(List<CatalogBrand> brands) {
    final list = List<CatalogBrand>.from(brands);
    list.sort((left, right) {
      final sortCompare = left.sortOrder.compareTo(right.sortOrder);
      if (sortCompare != 0) {
        return sortCompare;
      }
      return left.name.compareTo(right.name);
    });
    return list;
  }

  List<CatalogModel> _sortedModels(List<CatalogModel> models) {
    final list = List<CatalogModel>.from(models);
    list.sort((left, right) {
      if (left.isArchived != right.isArchived) {
        return left.isArchived ? 1 : -1;
      }
      final sortCompare = left.sortOrder.compareTo(right.sortOrder);
      if (sortCompare != 0) {
        return sortCompare;
      }
      return left.name.compareTo(right.name);
    });
    return list;
  }

  List<CatalogVersion> _sortedVersions(List<CatalogVersion> versions) {
    final list = List<CatalogVersion>.from(versions);
    list.sort((left, right) {
      final sortCompare = left.sortOrder.compareTo(right.sortOrder);
      if (sortCompare != 0) {
        return sortCompare;
      }
      return left.name.compareTo(right.name);
    });
    return list;
  }

  List<CatalogPricingRecord> _sortedPricing(List<CatalogPricingRecord> pricingRecords) {
    final list = List<CatalogPricingRecord>.from(pricingRecords);
    list.sort((left, right) {
      final rankLeft = left.pricingStatus == 'PUBLISHED' ? 0 : left.pricingStatus == 'DRAFT' ? 1 : 2;
      final rankRight = right.pricingStatus == 'PUBLISHED' ? 0 : right.pricingStatus == 'DRAFT' ? 1 : 2;
      final rankCompare = rankLeft.compareTo(rankRight);
      if (rankCompare != 0) {
        return rankCompare;
      }
      return right.updatedAt.compareTo(left.updatedAt);
    });
    return list;
  }

  List<CatalogColorRecord> _sortedColors(List<CatalogColorRecord> colors) {
    final list = List<CatalogColorRecord>.from(colors);
    list.sort((left, right) {
      if (left.isBaseColor != right.isBaseColor) {
        return left.isBaseColor ? -1 : 1;
      }
      final sortCompare = left.sortOrder.compareTo(right.sortOrder);
      if (sortCompare != 0) {
        return sortCompare;
      }
      return left.name.compareTo(right.name);
    });
    return list;
  }

  CatalogWorkspaceData? get _resolvedWorkspace => _workspace;

  bool get _isReadOnlyWorkspace => false;

  List<CatalogBrand> get _brands => _workspace == null ? const [] : _sortedBrands(_workspace!.brands);

  List<CatalogModel> get _allModels => _workspace == null ? const [] : _sortedModels(_workspace!.models);

  List<CatalogModel> get _models => _workspace == null || _selectedBrandId == null
      ? const []
      : _sortedModels(_workspace!.models.where((model) => model.brandId == _selectedBrandId).toList());

  List<CatalogVersion> get _versions => _workspace == null || _selectedModelId == null
      ? const []
      : _sortedVersions(_workspace!.versions.where((version) => version.modelId == _selectedModelId).toList());

  List<CatalogPricingRecord> get _pricingRecords => _workspace == null || _selectedVersionId == null
      ? const []
      : _sortedPricing(_workspace!.pricingRecords.where((record) => record.versionId == _selectedVersionId).toList());

  List<CatalogColorRecord> get _colors => _workspace == null || _selectedModelId == null
      ? const []
      : _sortedColors(_workspace!.colors.where((color) => color.modelId == _selectedModelId).toList());

  CatalogBrand? get _selectedBrand {
    for (final brand in _brands) {
      if (brand.id == _selectedBrandId) {
        return brand;
      }
    }
    return null;
  }

  CatalogModel? get _selectedModel {
    for (final model in _models) {
      if (model.id == _selectedModelId) {
        return model;
      }
    }
    return null;
  }

  CatalogVersion? get _selectedVersion {
    for (final version in _versions) {
      if (version.id == _selectedVersionId) {
        return version;
      }
    }
    return null;
  }

  CatalogAssetBundle? get _selectedAssetBundle {
    final workspace = _workspace;
    if (workspace == null || _selectedModelId == null) {
      return null;
    }

    for (final bundle in workspace.assetBundles) {
      if (bundle.modelId == _selectedModelId) {
        return bundle;
      }
    }

    return null;
  }

  Widget _buildTechnicalToolsPanel() => const SizedBox.shrink();

  int _versionCountForModel(String modelId) =>
      _workspace?.versions.where((version) => version.modelId == modelId).length ?? 0;

  int _colorCountForModel(String modelId) =>
      _workspace?.colors.where((color) => color.modelId == modelId).length ?? 0;

  int _assetFileCountForModel(String modelId) {
    final workspace = _workspace;
    if (workspace == null) {
      return 0;
    }

    for (final bundle in workspace.assetBundles) {
      if (bundle.modelId == modelId) {
        return bundle.files.length;
      }
    }

    return 0;
  }

  int _pricingCountForModel(String modelId) {
    final workspace = _workspace;
    if (workspace == null) {
      return 0;
    }

    final versionIds = workspace.versions.where((version) => version.modelId == modelId).map((version) => version.id).toSet();
    return workspace.pricingRecords.where((record) => versionIds.contains(record.versionId)).length;
  }

  void _selectBrand(String brandId) {
    setState(() {
      _selectedBrandId = brandId;
      _selectedModelId = null;
      _selectedVersionId = null;
      _selectedPricingId = null;
      _applyWorkspace(_workspace!);
    });
  }

  void _selectModel(String modelId) {
    final model = _findModelById(modelId);

    setState(() {
      _selectedBrandId = model?.brandId ?? _selectedBrandId;
      _selectedModelId = modelId;
      _selectedVersionId = null;
      _selectedPricingId = null;
      _applyWorkspace(_workspace!);
    });
  }

  void _selectVersion(String versionId) {
    setState(() {
      _selectedVersionId = versionId;
      _selectedPricingId = null;
      _applyWorkspace(_workspace!);
    });
  }

  Future<void> _performMutation<T>({
    required Future<T> Function() action,
    required String successMessage,
    void Function(T result)? applySelection,
  }) async {
    setState(() {
      _isMutating = true;
    });

    try {
      final result = await action();
      if (mounted && applySelection != null) {
        setState(() {
          applySelection(result);
        });
      }
      await _loadWorkspace(silent: true);
      if (widget.onPricingCatalogChanged != null) {
        await widget.onPricingCatalogChanged!();
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  Future<void> _handleCreateOrEditBrand({CatalogBrand? brand}) async {
    final result = await _showBrandDialog(brand: brand);
    if (result == null) {
      return;
    }

    await _performMutation(
      action: () {
        if (brand == null) {
          return widget.repository.createBrand(name: result.name, sortOrder: result.sortOrder);
        }
        return widget.repository.updateBrand(
          brandId: brand.id,
          name: result.name,
          sortOrder: result.sortOrder,
        );
      },
      successMessage: brand == null ? 'Marka została dodana.' : 'Marka została zaktualizowana.',
      applySelection: (CatalogBrand savedBrand) {
        _selectedBrandId = savedBrand.id;
        _selectedModelId = null;
        _selectedVersionId = null;
        _selectedPricingId = null;
      },
    );
  }

  Future<void> _handleCreateOrEditModel({CatalogModel? model}) async {
    final workspace = _resolvedWorkspace;
    if (workspace == null || workspace.brands.isEmpty) {
      return;
    }

    final result = await _showModelDialog(workspace: workspace, model: model);
    if (result == null) {
      return;
    }

    await _performMutation(
      action: () {
        if (model == null) {
          return widget.repository.createModel(
            brandId: result.brandId,
            name: result.name,
            marketingName: result.marketingName,
            sortOrder: result.sortOrder,
          );
        }
        return widget.repository.updateModel(
          modelId: model.id,
          brandId: result.brandId,
          name: result.name,
          marketingName: result.marketingName,
          sortOrder: result.sortOrder,
        );
      },
      successMessage: model == null ? 'Model został dodany.' : 'Model został zaktualizowany.',
      applySelection: (CatalogModel savedModel) {
        _selectedBrandId = savedModel.brandId;
        _selectedModelId = savedModel.id;
        _selectedVersionId = null;
        _selectedPricingId = null;
      },
    );
  }

  Future<void> _handleArchiveToggle(CatalogModel model) async {
    final shouldArchive = !model.isArchived;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(shouldArchive ? 'Archiwizować model?' : 'Przywrócić model?'),
            content: Text(
              shouldArchive
                  ? 'Model zniknie z nowych ofert, ale pozostanie dostępny w historii.'
                  : 'Model ponownie wróci do wyboru w nowych ofertach.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(shouldArchive ? 'Archiwizuj' : 'Przywróć'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await _performMutation(
      action: () => shouldArchive ? widget.repository.archiveModel(model.id) : widget.repository.restoreModel(model.id),
      successMessage: shouldArchive ? 'Model został zarchiwizowany.' : 'Model został przywrócony.',
    );
  }

  Future<void> _handleCreateOrEditVersion({CatalogVersion? version}) async {
    final workspace = _resolvedWorkspace;
    if (workspace == null || workspace.models.isEmpty) {
      return;
    }

    final result = await _showVersionDialog(workspace: workspace, version: version);
    if (result == null) {
      return;
    }

    await _performMutation(
      action: () {
        if (version == null) {
          return widget.repository.createVersion(
            modelId: result.modelId,
            name: result.name,
            powertrainType: result.powertrainType,
            year: result.year,
            sortOrder: result.sortOrder,
            driveType: result.driveType,
            systemPowerHp: result.systemPowerHp,
            batteryCapacityKwh: result.batteryCapacityKwh,
            combustionEnginePowerHp: result.combustionEnginePowerHp,
            engineDisplacementCc: result.engineDisplacementCc,
            rangeKm: result.rangeKm,
            notes: result.notes,
          );
        }
        return widget.repository.updateVersion(
          versionId: version.id,
          modelId: result.modelId,
          name: result.name,
          powertrainType: result.powertrainType,
          year: result.year,
          sortOrder: result.sortOrder,
          driveType: result.driveType,
          systemPowerHp: result.systemPowerHp,
          batteryCapacityKwh: result.batteryCapacityKwh,
          combustionEnginePowerHp: result.combustionEnginePowerHp,
          engineDisplacementCc: result.engineDisplacementCc,
          rangeKm: result.rangeKm,
          notes: result.notes,
        );
      },
      successMessage: version == null ? 'Wersja została dodana.' : 'Wersja została zaktualizowana.',
      applySelection: (CatalogVersion savedVersion) {
        _selectedModelId = savedVersion.modelId;
        _selectedVersionId = savedVersion.id;
        _selectedPricingId = null;
      },
    );
  }

  Future<void> _handleCreateOrEditPricing({CatalogPricingRecord? pricing}) async {
    final workspace = _resolvedWorkspace;
    if (workspace == null || workspace.versions.isEmpty) {
      return;
    }

    final result = await _showPricingDialog(workspace: workspace, pricing: pricing);
    if (result == null) {
      return;
    }

    await _performMutation(
      action: () {
        if (pricing == null) {
          return widget.repository.createPricing(
            versionId: result.versionId,
            listPriceNet: result.listPriceNet,
            basePriceNet: result.basePriceNet,
            vatRate: result.vatRate,
          );
        }
        return widget.repository.updatePricing(
          pricingId: pricing.id,
          listPriceNet: result.listPriceNet,
          basePriceNet: result.basePriceNet,
          vatRate: result.vatRate,
        );
      },
      successMessage: pricing == null ? 'Rekord cenowy został dodany.' : 'Rekord cenowy został zaktualizowany.',
      applySelection: (CatalogPricingRecord savedPricing) {
        _selectedVersionId = savedPricing.versionId;
        _selectedPricingId = savedPricing.id;
      },
    );
  }

  Future<void> _handlePublishPricing(CatalogPricingRecord pricing) async {
    await _performMutation(
      action: () => widget.repository.publishPricing(pricing.id),
      successMessage: 'Ceny zostały opublikowane.',
    );
  }

  Future<void> _handleArchivePricing(CatalogPricingRecord pricing) async {
    await _performMutation(
      action: () => widget.repository.archivePricing(pricing.id),
      successMessage: 'Rekord cenowy został zarchiwizowany.',
    );
  }

  Future<void> _handleCreateOrEditColor({CatalogColorRecord? color}) async {
    final model = _selectedModel;
    if (model == null) {
      return;
    }

    final result = await _showColorDialog(
      color: color,
      model: model,
      brand: _selectedBrand,
    );
    if (result == null) {
      return;
    }

    await _performMutation(
      action: () {
        if (color == null) {
          return widget.repository.createColor(
            modelId: model.id,
            name: result.name,
            finishType: result.finishType,
            isBaseColor: result.isBaseColor,
            hasSurcharge: result.hasSurcharge,
            surchargeNet: result.surchargeNet,
            sortOrder: result.sortOrder,
          );
        }

        return widget.repository.updateColor(
          colorId: color.id,
          name: result.name,
          finishType: result.finishType,
          isBaseColor: result.isBaseColor,
          hasSurcharge: result.hasSurcharge,
          surchargeNet: result.surchargeNet,
          sortOrder: result.sortOrder,
        );
      },
      successMessage: color == null ? 'Kolor został dodany.' : 'Kolor został zaktualizowany.',
      applySelection: (CatalogColorRecord savedColor) {
        _selectedModelId = savedColor.modelId;
      },
    );
  }

  Future<void> _handleDeleteColor(CatalogColorRecord color) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Usunąć kolor?'),
            content: Text('Kolor ${color.name} zostanie usunięty z modelu.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Usuń'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await _performMutation(
      action: () => widget.repository.deleteColor(color.id),
      successMessage: 'Kolor został usunięty.',
    );
  }

  Future<void> _handleEditAssetBundle() async {
    final bundle = _selectedAssetBundle;
    final model = _selectedModel;
    if (model == null) {
      return;
    }

    final result = await _showAssetBundleDialog(bundle: bundle);
    if (result == null) {
      return;
    }

    await _performMutation(
      action: () => widget.repository.updateModelAssets(
        modelId: model.id,
        assetsVersionTag: result.assetsVersionTag,
        isActive: result.isActive,
      ),
      successMessage: 'Pakiet materiałów został zapisany.',
    );
  }

  Future<void> _handleCreateAssetFile() async {
    final workspace = _resolvedWorkspace;
    final model = _selectedModel;
    if (workspace == null || model == null) {
      return;
    }

    final result = await _showAssetFileDialog(
      workspace: workspace,
      model: model,
      brand: _selectedBrand,
    );
    if (result == null) {
      return;
    }

    await _performMutation(
      action: () => widget.repository.createAssetFile(
        modelId: model.id,
        category: result.category,
        powertrainType: result.powertrainType,
        fileName: result.fileName,
        sourceFilePath: result.sourceFilePath,
        mimeType: result.mimeType,
        sortOrder: result.sortOrder,
      ),
      successMessage: 'Plik materiałów został dodany.',
      applySelection: (_) {
        _selectedModelId = model.id;
      },
    );
  }

  Future<void> _handleDeleteAssetFile(CatalogAssetFile file) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Usunąć plik?'),
            content: Text('Plik ${file.fileName} zostanie usunięty z pakietu materiałów.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Usuń'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await _performMutation(
      action: () => widget.repository.deleteAssetFile(file.id),
      successMessage: 'Plik został usunięty.',
    );
  }

  String _formatMoney(num? value) {
    if (value == null) {
      return '—';
    }
    return _moneyFormat.format(value);
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return '—';
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }

    return _dateFormat.format(parsed.toLocal());
  }

  String _powertrainLabel(String? value) {
    switch (value) {
      case 'ELECTRIC':
        return 'Elektryk';
      case 'HYBRID':
        return 'Hybryda';
      case 'ICE':
        return 'Spalinowy';
      default:
        return value ?? '—';
    }
  }

  String _driveTypeLabel(String? value) {
    switch (value) {
      case 'FWD':
        return 'Przedni napęd';
      case 'RWD':
        return 'Tylny napęd';
      case 'AWD':
        return '4x4';
      default:
        return '—';
    }
  }

  String _pricingStatusLabel(String value) {
    switch (value) {
      case 'PUBLISHED':
        return 'Opublikowane';
      case 'ARCHIVED':
        return 'Archiwalne';
      default:
        return 'Robocze';
    }
  }

  String _assetCategoryLabel(String value) {
    switch (value) {
      case 'PRIMARY':
        return 'Grafika główna';
      case 'EXTERIOR':
        return 'Z zewnątrz';
      case 'INTERIOR':
        return 'Wnętrze';
      case 'DETAILS':
        return 'Detale';
      case 'PREMIUM':
        return 'Premium';
      case 'SPEC_PDF':
        return 'PDF specyfikacji';
      case 'LOGO':
        return 'Logo';
      default:
        return 'Inne';
    }
  }

  String _selectionHint() {
    if (_selectedBrand == null) {
      return 'Zacznij od wyboru marki. Dopiero po świadomym wyborze pokażemy Ci modele i dalsze sekcje.';
    }
    if (_selectedModel == null) {
      return 'Marka jest już aktywna. Teraz wybierz konkretny model samochodu, dla którego będziesz konfigurować wersje, kolory i materiały.';
    }
    if (_selectedVersion == null) {
      return 'Pracujesz już na konkretnym samochodzie. Możesz dodawać kolory i materiały modelu, a wybór wersji odblokuje sekcję cen.';
    }
    return 'Masz pełny ciąg wyboru: marka, model i wersja. Teraz pracujesz na jednym samochodzie i jednej wersji cenowej.';
  }

  CatalogBrand? _findBrandById(String? brandId) {
    final workspace = _workspace;
    if (workspace == null || brandId == null) {
      return null;
    }

    for (final brand in workspace.brands) {
      if (brand.id == brandId) {
        return brand;
      }
    }

    return null;
  }

  CatalogModel? _findModelById(String? modelId) {
    final workspace = _workspace;
    if (workspace == null || modelId == null) {
      return null;
    }

    for (final model in workspace.models) {
      if (model.id == modelId) {
        return model;
      }
    }

    return null;
  }

  CatalogVersion? _findVersionById(String? versionId) {
    final workspace = _workspace;
    if (workspace == null || versionId == null) {
      return null;
    }

    for (final version in workspace.versions) {
      if (version.id == versionId) {
        return version;
      }
    }

    return null;
  }

  String _buildVersionContextLabel(CatalogVersion version) {
    final model = _findModelById(version.modelId);
    final brand = _findBrandById(model?.brandId);
    final parts = <String>[
      if (brand != null) brand.name,
      if (model != null) model.name,
      version.name,
      _powertrainLabel(version.powertrainType),
      if (version.year != null) '${version.year}',
    ];
    return parts.join(' / ');
  }

  String _buildModelContextLabel(CatalogModel model) {
    final brand = _findBrandById(model.brandId);
    return [if (brand != null) brand.name, model.name].join(' / ');
  }

  bool _isSpecPdfCategory(String category) => category == 'SPEC_PDF';

  bool _isSupportedAssetPath(String fileName, String category) {
    final normalized = fileName.toLowerCase();
    if (_isSpecPdfCategory(category)) {
      return normalized.endsWith('.pdf');
    }

    return normalized.endsWith('.png') ||
        normalized.endsWith('.jpg') ||
        normalized.endsWith('.jpeg') ||
        normalized.endsWith('.webp');
  }

  String _guessAssetMimeType(String fileName, String category) {
    final normalized = fileName.toLowerCase();
    if (_isSpecPdfCategory(category) || normalized.endsWith('.pdf')) {
      return 'application/pdf';
    }
    if (normalized.endsWith('.png')) {
      return 'image/png';
    }
    if (normalized.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session.role != 'ADMIN') {
      return const VeloPrimeWorkspaceState(
        tint: VeloPrimePalette.rose,
        eyebrow: 'Polityka cenowa',
        title: 'Dostęp tylko dla administratora',
        message: 'Zarządzanie katalogiem samochodów i cenami jest dostępne wyłącznie w trybie administratora.',
        icon: Icons.lock_outline,
      );
    }

    final workspace = _resolvedWorkspace;

    final content = _isLoading
        ? const VeloPrimeWorkspaceState(
            tint: _accentColor,
            eyebrow: 'Polityka cenowa',
            title: 'Ładujemy katalog sprzedażowy',
            message: 'Przygotowujemy marki, modele, wersje i aktywne ceny dla administratora.',
            isLoading: true,
          )
        : _error != null
            ? VeloPrimeWorkspaceState(
                tint: VeloPrimePalette.rose,
                eyebrow: 'Polityka cenowa',
                title: 'Nie udało się pobrać katalogu',
                message: _error!,
                icon: Icons.warning_amber_rounded,
              )
            : workspace == null
                ? const VeloPrimeWorkspaceState(
                    tint: _accentColor,
                    eyebrow: 'Polityka cenowa',
                    title: 'Brak danych katalogu',
                    message: 'Gdy tylko katalog będzie gotowy, pojawi się w tej zakładce.',
                    icon: Icons.car_rental_outlined,
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isMutating)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: LinearProgressIndicator(minHeight: 3),
                          ),
                        _buildHeroPanel(workspace),
                        const SizedBox(height: 14),
                        _buildCatalogOverviewPanel(),
                        const SizedBox(height: 14),
                        _buildSelectionSummaryPanel(),
                        const SizedBox(height: 14),
                        _buildBrandsPanel(),
                        const SizedBox(height: 14),
                        _buildModelsPanel(),
                        const SizedBox(height: 14),
                        _buildActiveVehicleWorkspace(),
                        const SizedBox(height: 14),
                        _buildTechnicalToolsPanel(),
                      ],
                    ),
                  );

    if (widget.embeddedInShell) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Polityka cenowa')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }

  Widget _buildHeroPanel(CatalogWorkspaceData workspace) {
    return VeloPrimeWorkspacePanel(
      tint: _accentColor,
      radius: 26,
      padding: const EdgeInsets.all(20),
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
                    const VeloPrimeSectionEyebrow(label: 'Polityka cenowa', color: _accentColor),
                    const SizedBox(height: 12),
                    const Text(
                      'Katalog samochodów i cen w aplikacji administratora.',
                      style: TextStyle(
                        color: VeloPrimePalette.ink,
                        fontSize: 28,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tutaj jednocześnie widzisz istniejące samochody w katalogu i konfigurujesz wybrany model. Marki i modele budują katalog, a karta aktywnego samochodu pozwala uzupełniać wersje, kolory, materiały i ceny.',
                      style: TextStyle(
                        color: VeloPrimePalette.muted.withValues(alpha: 0.92),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatCard(label: 'Marki', value: workspace.stats.brands.toString()),
              _StatCard(label: 'Modele', value: workspace.stats.models.toString()),
              _StatCard(label: 'Wersje', value: workspace.stats.versions.toString()),
              _StatCard(label: 'Rekordy cenowe', value: workspace.stats.pricingRecords.toString()),
              _StatCard(label: 'Kolory', value: workspace.stats.colors.toString()),
              _StatCard(label: 'Pliki assetów', value: workspace.stats.assetFiles.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogOverviewPanel() {
    final workspace = _workspace;
    if (workspace == null) {
      return const SizedBox.shrink();
    }

    return _AdminSectionPanel(
      tint: const Color(0xFF355C7D),
      title: 'Samochody w katalogu',
      subtitle:
          'To jest lista istniejących modeli. Najpierw wybierasz samochód z katalogu, a potem niżej uzupełniasz jego wersje, kolory, materiały i ceny.',
      actions: [
        FilledButton.icon(
          onPressed: _isMutating || _isReadOnlyWorkspace ? null : () => _handleCreateOrEditBrand(),
          icon: const Icon(Icons.add_business_outlined),
          label: const Text('Nowa marka'),
        ),
        FilledButton.icon(
          onPressed: _isMutating || _isReadOnlyWorkspace || _selectedBrand == null ? null : () => _handleCreateOrEditModel(),
          icon: const Icon(Icons.add_road_outlined),
          label: const Text('Nowy model'),
        ),
      ],
      child: _allModels.isEmpty
          ? const _EmptySectionState(
              message:
                  'Katalog nie ma jeszcze żadnych modeli. Zacznij od dodania marki, a potem dodaj pierwszy model samochodu do tej marki.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _brands.map((brand) {
                final brandModels = _allModels.where((model) => model.brandId == brand.id).toList();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: VeloPrimePalette.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    brand.name,
                                    style: const TextStyle(
                                      color: VeloPrimePalette.ink,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    brandModels.isEmpty
                                        ? 'Ta marka nie ma jeszcze żadnych modeli w katalogu.'
                                        : 'Modele tej marki: ${brandModels.length}. Kliknij model, aby pracować na jego karcie konfiguracji.',
                                    style: const TextStyle(color: VeloPrimePalette.muted, height: 1.35, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _isMutating || _isReadOnlyWorkspace ? null : () => _selectBrand(brand.id),
                              icon: const Icon(Icons.checklist_rtl_outlined),
                              label: const Text('Ustaw aktywną markę'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (brandModels.isEmpty)
                          const _EmptySectionState(message: 'Brak modeli dla tej marki.')
                        else
                          Column(
                            children: brandModels.map((model) {
                              final selected = model.id == _selectedModelId;
                              final footerChips = <Widget>[
                                _InfoChip(label: 'Wersje: ${_versionCountForModel(model.id)}'),
                                _InfoChip(label: 'Kolory: ${_colorCountForModel(model.id)}'),
                                _InfoChip(label: 'Materiały: ${_assetFileCountForModel(model.id)}'),
                                _InfoChip(label: 'Ceny: ${_pricingCountForModel(model.id)}'),
                                _InfoChip(label: model.isArchived ? 'Status: zarchiwizowany' : 'Status: aktywny'),
                              ];

                              return _SelectableRecordCard(
                                title: model.name,
                                subtitle: [
                                  brand.name,
                                  if (model.marketingName != null && model.marketingName!.isNotEmpty) model.marketingName!,
                                  model.availablePowertrains.isEmpty
                                      ? 'Brak wersji napędowych'
                                      : model.availablePowertrains.map(_powertrainLabel).join(', '),
                                ].join(' • '),
                                selected: selected,
                                leading: Icon(
                                  model.isArchived ? Icons.inventory_2_outlined : Icons.directions_car_filled_outlined,
                                  color: model.isArchived ? VeloPrimePalette.muted : const Color(0xFF355C7D),
                                ),
                                onTap: () => _selectModel(model.id),
                                footer: Wrap(spacing: 8, runSpacing: 8, children: footerChips),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edytuj model',
                                      onPressed: _isMutating || _isReadOnlyWorkspace ? null : () => _handleCreateOrEditModel(model: model),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: model.isArchived ? 'Przywróć model' : 'Archiwizuj model',
                                      onPressed: _isMutating || _isReadOnlyWorkspace ? null : () => _handleArchiveToggle(model),
                                      icon: Icon(model.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSelectionSummaryPanel() {
    final brand = _selectedBrand;
    final model = _selectedModel;
    final version = _selectedVersion;
    final colors = _colors;
    final bundle = _selectedAssetBundle;

    return VeloPrimeWorkspacePanel(
      tint: const Color(0xFF52606D),
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VeloPrimeSectionEyebrow(label: 'Aktywny ciąg wyboru', color: Color(0xFF52606D)),
          const SizedBox(height: 8),
          const Text(
            'Najpierw świadomie wybierasz samochód, dopiero potem edytujesz jego dane.',
            style: TextStyle(
              color: VeloPrimePalette.ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectionHint(),
            style: const TextStyle(color: VeloPrimePalette.muted, height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3EC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: VeloPrimePalette.line),
            ),
            child: const Text(
              'Nie ma tutaj jednego przycisku „Zapisz konfigurację samochodu”. Każda sekcja zapisuje się osobno: model, wersje, kolory, materiały i ceny. Najpierw wybierasz samochód z katalogu, potem uzupełniasz jego kartę poniżej.',
              style: TextStyle(color: VeloPrimePalette.muted, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: 'Marka: ${brand?.name ?? '—'}'),
              _InfoChip(label: 'Model: ${model?.name ?? '—'}'),
              _InfoChip(label: 'Wersja: ${version?.name ?? '—'}'),
              _InfoChip(label: 'Kolory modelu: ${colors.length}'),
              _InfoChip(label: 'Pliki materiałów: ${bundle?.files.length ?? 0}'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            model == null
                ? 'Dopóki nie wybierzesz modelu, nie dodasz przypadkowo koloru ani materiałów do niewłaściwego samochodu.'
                : version == null
                    ? 'Kolory i materiały zapisują się teraz dla modelu ${model.name}. Wybierz jeszcze wersję, jeśli chcesz dopisać ceny.'
                    : 'Ceny zapiszą się wyłącznie dla wersji ${version.name}, a kolory i materiały pozostają wspólne dla modelu ${model.name}.',
            style: const TextStyle(color: VeloPrimePalette.muted, height: 1.4, fontSize: 13),
          ),
          if (model != null) ...[
            const SizedBox(height: 12),
            _buildCurrentVehicleInventoryPanel(),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentVehicleInventoryPanel() {
    final model = _selectedModel;
    if (model == null) {
      return const SizedBox.shrink();
    }

    final versions = _versions;
    final colors = _colors;
    final files = _selectedAssetBundle?.files ?? const <CatalogAssetFile>[];
    final pricingRecords = _pricingRecords;

    List<Widget> buildChips(List<String> labels, {String emptyLabel = 'Brak danych'}) {
      if (labels.isEmpty) {
        return [
          _InfoChip(label: emptyLabel),
        ];
      }

      return labels.take(6).map((label) => _InfoChip(label: label)).toList();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: VeloPrimePalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Co już dodano do tego samochodu',
            style: TextStyle(
              color: VeloPrimePalette.ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Model ${model.name} ma już poniższe wersje, kolory, materiały i ceny. Po zapisie nowy rekord zostaje tu od razu widoczny.',
            style: const TextStyle(color: VeloPrimePalette.muted, height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatCard(label: 'Wersje modelu', value: versions.length.toString()),
              _StatCard(label: 'Kolory modelu', value: colors.length.toString()),
              _StatCard(label: 'Pliki materiałów', value: files.length.toString()),
              _StatCard(label: 'Ceny wybranej wersji', value: pricingRecords.length.toString()),
            ],
          ),
          const SizedBox(height: 12),
          _InventorySubsection(
            title: 'Wersje',
            children: buildChips(versions.map(_buildVersionContextLabel).toList(), emptyLabel: 'Brak wersji'),
          ),
          const SizedBox(height: 10),
          _InventorySubsection(
            title: 'Kolory',
            children: buildChips(
              colors.map((color) => color.hasSurcharge ? '${color.name} (+${_formatMoney(color.surchargeNet)} netto)' : color.name).toList(),
              emptyLabel: 'Brak kolorów',
            ),
          ),
          const SizedBox(height: 10),
          _InventorySubsection(
            title: 'Materiały',
            children: buildChips(
              files.map((file) => '${_assetCategoryLabel(file.category)}: ${file.fileName}').toList(),
              emptyLabel: 'Brak plików',
            ),
          ),
          const SizedBox(height: 10),
          _InventorySubsection(
            title: 'Ceny aktywnej wersji',
            children: buildChips(
              pricingRecords
                  .map((pricing) => '${_pricingStatusLabel(pricing.pricingStatus)} • ${_formatMoney(pricing.listPriceNet)} netto')
                  .toList(),
              emptyLabel: 'Brak cen dla wybranej wersji',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveVehicleWorkspace() {
    final model = _selectedModel;
    final version = _selectedVersion;
    final brand = _selectedBrand;

    return VeloPrimeWorkspacePanel(
      tint: const Color(0xFF3D405B),
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VeloPrimeSectionEyebrow(label: 'Aktywny samochód', color: Color(0xFF3D405B)),
          const SizedBox(height: 8),
          Text(
            model == null
                ? 'Wybierz model samochodu, aby przejść do jego konfiguracji.'
                : [if (brand != null) brand.name, model.name].join(' / '),
            style: const TextStyle(
              color: VeloPrimePalette.ink,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            model == null
                ? 'Sekcje wersji, kolorów, materiałów i cen staną się aktywne dopiero po wyborze konkretnego modelu. Dzięki temu każda operacja ma jasny kontekst.'
                : version == null
                    ? 'Pracujesz na jednym modelu. Najpierw ustaw wersje, kolory i materiały tego samochodu. Ceny odblokują się po wskazaniu konkretnej wersji.'
                    : 'Pracujesz na jednym modelu i jednej wersji. Kolory i materiały dotyczą modelu, a ceny dokładnie wybranej wersji.',
            style: const TextStyle(color: VeloPrimePalette.muted, height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: 'Krok 1: wybierz markę'),
              _InfoChip(label: 'Krok 2: wybierz model'),
              _InfoChip(label: 'Krok 3: dodaj wersje i kolory'),
              _InfoChip(label: 'Krok 4: dodaj materiały'),
              _InfoChip(label: 'Krok 5: ustaw ceny wersji'),
            ],
          ),
          const SizedBox(height: 14),
          _buildVersionsPanel(),
          const SizedBox(height: 14),
          _buildColorsPanel(),
          const SizedBox(height: 14),
          _buildAssetsPanel(),
          const SizedBox(height: 14),
          _buildPricingPanel(),
        ],
      ),
    );
  }

  Widget _buildBrandsPanel() {
    final brands = _brands;

    return _AdminSectionPanel(
      tint: _accentColor,
      title: 'Marki',
      subtitle: 'Grupy główne katalogu. Handlowiec zaczyna konfigurację od wyboru marki.',
      actions: [
        FilledButton.icon(
          onPressed: _isMutating || _isReadOnlyWorkspace ? null : () => _handleCreateOrEditBrand(),
          icon: const Icon(Icons.add),
          label: const Text('Dodaj markę'),
        ),
      ],
      child: brands.isEmpty
          ? const _EmptySectionState(message: 'Dodaj pierwszą markę, aby budować dalszy katalog modeli i wersji.')
          : Column(
              children: brands.map((brand) {
                final selected = brand.id == _selectedBrandId;
                return _SelectableRecordCard(
                  title: brand.name,
                  subtitle: 'Kod ${brand.code} • kolejność ${brand.sortOrder}',
                  selected: selected,
                  onTap: () {
                    _selectBrand(brand.id);
                  },
                  trailing: IconButton(
                    tooltip: 'Edytuj markę',
                    onPressed: _isMutating || _isReadOnlyWorkspace ? null : () => _handleCreateOrEditBrand(brand: brand),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildModelsPanel() {
    final brands = _brands;
    final models = _models;
    final selectedBrand = _selectedBrand;

    return _AdminSectionPanel(
      tint: const Color(0xFF4A6FA5),
      title: 'Modele',
      subtitle: selectedBrand == null
          ? 'Najpierw wybierz markę, aby dodać lub przeglądać modele.'
          : 'Modele dla marki ${selectedBrand.name}. Tutaj zarządzasz aktywnością przez archiwizację modelu.',
      actions: [
        FilledButton.icon(
          onPressed: _isMutating || _isReadOnlyWorkspace || brands.isEmpty ? null : () => _handleCreateOrEditModel(),
          icon: const Icon(Icons.directions_car_outlined),
          label: const Text('Dodaj model'),
        ),
      ],
      child: selectedBrand == null
          ? const _EmptySectionState(message: 'Brak wybranej marki.')
          : models.isEmpty
              ? const _EmptySectionState(message: 'Ta marka nie ma jeszcze żadnych modeli.')
              : Column(
                  children: models.map((model) {
                    final selected = model.id == _selectedModelId;
                    final powertrains = model.availablePowertrains.map(_powertrainLabel).join(', ');
                    return _SelectableRecordCard(
                      title: model.name,
                      subtitle: [
                        if (model.marketingName != null && model.marketingName!.isNotEmpty) model.marketingName!,
                        powertrains.isEmpty ? 'Brak wersji napędowych' : powertrains,
                        model.isArchived ? 'Zarchiwizowany' : 'Aktywny',
                      ].join(' • '),
                      selected: selected,
                      leading: model.isArchived
                          ? const Icon(Icons.inventory_2_outlined, color: VeloPrimePalette.muted)
                          : const Icon(Icons.electric_car_outlined, color: Color(0xFF4A6FA5)),
                      onTap: () => _selectModel(model.id),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Edytuj model',
                            onPressed: _isMutating || _isReadOnlyWorkspace ? null : () => _handleCreateOrEditModel(model: model),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: model.isArchived ? 'Przywróć model' : 'Archiwizuj model',
                            onPressed: _isMutating || _isReadOnlyWorkspace ? null : () => _handleArchiveToggle(model),
                            icon: Icon(model.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
    );
  }

  Widget _buildVersionsPanel() {
    final models = _models;
    final versions = _versions;
    final selectedModel = _selectedModel;

    return _AdminSectionPanel(
      tint: VeloPrimePalette.olive,
      title: 'Wersje',
      subtitle: selectedModel == null
          ? 'Najpierw wybierz model, aby dodać lub przeglądać wersje.'
          : 'Wersje wyposażenia i napędu dla modelu ${selectedModel.name}.',
      actions: [
        FilledButton.icon(
          onPressed: _isMutating || _isReadOnlyWorkspace || models.isEmpty ? null : () => _handleCreateOrEditVersion(),
          icon: const Icon(Icons.tune_outlined),
          label: const Text('Dodaj wersję'),
        ),
      ],
      child: selectedModel == null
          ? const _EmptySectionState(message: 'Brak wybranego modelu.')
          : versions.isEmpty
              ? const _EmptySectionState(message: 'Ten model nie ma jeszcze żadnej wersji.')
              : Column(
                  children: versions.map((version) {
                    final selected = version.id == _selectedVersionId;
                    final chips = <String>[
                      _powertrainLabel(version.powertrainType),
                      if (version.year != null) 'Rocznik ${version.year}',
                      if (version.systemPowerHp != null) '${version.systemPowerHp!.toStringAsFixed(0)} KM',
                      if (version.batteryCapacityKwh != null) '${version.batteryCapacityKwh} kWh',
                    ];
                    return _SelectableRecordCard(
                      title: version.name,
                      subtitle: chips.join(' • '),
                      selected: selected,
                      leading: const Icon(Icons.settings_input_component_outlined, color: VeloPrimePalette.olive),
                      onTap: () => _selectVersion(version.id),
                      trailing: IconButton(
                        tooltip: 'Edytuj wersję',
                        onPressed: _isMutating || _isReadOnlyWorkspace ? null : () => _handleCreateOrEditVersion(version: version),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    );
                  }).toList(),
                ),
    );
  }

  Widget _buildColorsPanel() {
    final model = _selectedModel;
    final colors = _colors;

    return _AdminSectionPanel(
      tint: const Color(0xFF5A7D52),
      title: 'Kolory modelu',
      subtitle: model == null
          ? 'Najpierw wybierz model, aby zarządzać kolorami bazowymi i dopłatami.'
          : 'Kolory są wspólne dla modelu ${model.name}. Dopłata za kolor nie wchodzi do puli rabatowo-prowizyjnej.',
      actions: [
        FilledButton.icon(
          onPressed: _isMutating || _isReadOnlyWorkspace || model == null ? null : () => _handleCreateOrEditColor(),
          icon: const Icon(Icons.palette_outlined),
          label: const Text('Dodaj kolor'),
        ),
      ],
      child: model == null
          ? const _EmptySectionState(message: 'Brak wybranego modelu.')
          : colors.isEmpty
              ? const _EmptySectionState(message: 'Ten model nie ma jeszcze skonfigurowanych kolorów.')
              : Column(
                  children: colors.map((color) {
                    final subtitle = [
                      if (color.finishType != null && color.finishType!.isNotEmpty) color.finishType!,
                      color.isBaseColor ? 'Kolor bazowy' : 'Kolor dodatkowy',
                      color.hasSurcharge ? 'Dopłata ${_formatMoney(color.surchargeNet)} netto' : 'Bez dopłaty',
                    ].join(' • ');

                    return _SelectableRecordCard(
                      title: color.name,
                      subtitle: subtitle,
                      selected: false,
                      leading: Icon(
                        color.isBaseColor ? Icons.check_circle_outline : Icons.color_lens_outlined,
                        color: color.isBaseColor ? VeloPrimePalette.olive : const Color(0xFF5A7D52),
                      ),
                      onTap: () {},
                      footer: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(label: _buildModelContextLabel(model)),
                          _InfoChip(label: 'Kod ${color.code}'),
                          _InfoChip(label: 'Kolejność ${color.sortOrder}'),
                          if (color.hasSurcharge) _InfoChip(label: 'Brutto ${_formatMoney(color.surchargeGross)}'),
                        ],
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Edytuj kolor',
                            onPressed: _isMutating || _isReadOnlyWorkspace ? null : () => _handleCreateOrEditColor(color: color),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Usuń kolor',
                            onPressed: _isMutating || _isReadOnlyWorkspace ? null : () => _handleDeleteColor(color),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
    );
  }

  Widget _buildAssetsPanel() {
    final model = _selectedModel;
    final bundle = _selectedAssetBundle;
    final files = bundle?.files ?? const <CatalogAssetFile>[];

    return _AdminSectionPanel(
      tint: const Color(0xFF6D597A),
      title: 'Materiały modelu',
      subtitle: model == null
          ? 'Najpierw wybierz model, aby zarządzać grafikami i PDF specyfikacji.'
          : 'Zdjęcia są wspólne dla modelu ${model.name}. Specyfikacje PDF rozróżniamy po typie napędu. Pliki wybierasz z dysku, a system zapisuje je do katalogu materiałów.',
      actions: [
        OutlinedButton.icon(
          onPressed: _isMutating || _isReadOnlyWorkspace || model == null ? null : _handleEditAssetBundle,
          icon: const Icon(Icons.settings_outlined),
          label: const Text('Ustaw pakiet'),
        ),
        FilledButton.icon(
          onPressed: _isMutating || _isReadOnlyWorkspace || model == null ? null : _handleCreateAssetFile,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Dodaj plik'),
        ),
      ],
      child: model == null
          ? const _EmptySectionState(message: 'Brak wybranego modelu.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: VeloPrimePalette.line),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(label: 'Pakiet ${bundle == null ? 'nieutworzony' : 'aktywny'}'),
                      _InfoChip(label: 'Tag wersji ${bundle?.assetsVersionTag ?? '—'}'),
                      _InfoChip(label: 'Liczba plików ${files.length}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (files.isEmpty)
                  const _EmptySectionState(message: 'Ten model nie ma jeszcze żadnych plików materiałów.')
                else
                  Column(
                    children: files.map((file) {
                      final subtitle = [
                        _assetCategoryLabel(file.category),
                        if (file.powertrainType != null) _powertrainLabel(file.powertrainType),
                        file.filePath,
                      ].join(' • ');

                      return _SelectableRecordCard(
                        title: file.fileName,
                        subtitle: subtitle,
                        selected: false,
                        leading: Icon(
                          file.isSpecPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                          color: file.isSpecPdf ? const Color(0xFF9C6644) : const Color(0xFF6D597A),
                        ),
                        onTap: () {},
                        footer: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(label: 'Kategoria ${_assetCategoryLabel(file.category)}'),
                            _InfoChip(label: 'Kolejność ${file.sortOrder}'),
                            if (file.mimeType != null && file.mimeType!.isNotEmpty) _InfoChip(label: file.mimeType!),
                          ],
                        ),
                        trailing: IconButton(
                          tooltip: 'Usuń plik',
                          onPressed: _isMutating || _isReadOnlyWorkspace ? null : () => _handleDeleteAssetFile(file),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
    );
  }

  Widget _buildPricingPanel() {
    final versions = _versions;
    final pricingRecords = _pricingRecords;
    final selectedVersion = _selectedVersion;

    return _AdminSectionPanel(
      tint: const Color(0xFF9C6644),
      title: 'Ceny',
      subtitle: selectedVersion == null
          ? 'Najpierw wybierz wersję, aby zarządzać rekordami cenowymi.'
          : 'Pracujesz na wersji ${_buildVersionContextLabel(selectedVersion)}. Ceny netto są źródłem prawdy, a system automatycznie liczy brutto i pulę marżową.',
      actions: [
        FilledButton.icon(
          onPressed: _isMutating || _isReadOnlyWorkspace || versions.isEmpty ? null : () => _handleCreateOrEditPricing(),
          icon: const Icon(Icons.price_change_outlined),
          label: const Text('Dodaj ceny'),
        ),
      ],
      child: selectedVersion == null
          ? const _EmptySectionState(message: 'Brak wybranej wersji.')
          : pricingRecords.isEmpty
              ? const _EmptySectionState(message: 'Ta wersja nie ma jeszcze żadnego rekordu cenowego.')
              : Column(
                  children: pricingRecords.map((pricing) {
                    final selected = pricing.id == _selectedPricingId;
                    return _SelectableRecordCard(
                      title: '${_pricingStatusLabel(pricing.pricingStatus)} • ${_formatMoney(pricing.listPriceNet)} netto',
                      subtitle: 'Bazowa ${_formatMoney(pricing.basePriceNet)} • Pula ${_formatMoney(pricing.marginPoolNet)} • VAT ${pricing.vatRate}%',
                      selected: selected,
                      leading: Icon(
                        pricing.isPublished ? Icons.verified_outlined : Icons.request_quote_outlined,
                        color: pricing.isPublished ? VeloPrimePalette.olive : const Color(0xFF9C6644),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedPricingId = pricing.id;
                        });
                      },
                      footer: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(label: 'Zaktualizowano ${_formatDate(pricing.updatedAt)}'),
                          if (pricing.effectiveFrom != null) _InfoChip(label: 'Od ${_formatDate(pricing.effectiveFrom)}'),
                          if (pricing.effectiveTo != null) _InfoChip(label: 'Do ${_formatDate(pricing.effectiveTo)}'),
                          _InfoChip(label: 'Brutto ${_formatMoney(pricing.listPriceGross)}'),
                        ],
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Edytuj rekord cenowy',
                            onPressed: _isMutating || _isReadOnlyWorkspace ? null : () => _handleCreateOrEditPricing(pricing: pricing),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Publikuj ceny',
                            onPressed: _isMutating || _isReadOnlyWorkspace || pricing.isPublished ? null : () => _handlePublishPricing(pricing),
                            icon: const Icon(Icons.publish_outlined),
                          ),
                          IconButton(
                            tooltip: 'Archiwizuj ceny',
                            onPressed: _isMutating || _isReadOnlyWorkspace || pricing.isArchived ? null : () => _handleArchivePricing(pricing),
                            icon: const Icon(Icons.archive_outlined),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
    );
  }

  Future<_BrandFormData?> _showBrandDialog({CatalogBrand? brand}) async {
    final nameController = TextEditingController(text: brand?.name ?? '');
    final sortOrderController = TextEditingController(text: brand?.sortOrder.toString() ?? _brands.length.toString());
    final formKey = GlobalKey<FormState>();

    try {
      return await showDialog<_BrandFormData>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(brand == null ? 'Dodaj markę' : 'Edytuj markę'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nazwa marki'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Podaj nazwę marki.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: sortOrderController,
                    decoration: const InputDecoration(labelText: 'Kolejność na liście'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                Navigator.of(context).pop(
                  _BrandFormData(
                    name: nameController.text.trim(),
                    sortOrder: int.tryParse(sortOrderController.text.trim()),
                  ),
                );
              },
              child: Text(brand == null ? 'Dodaj' : 'Zapisz'),
            ),
          ],
        ),
      );
    } finally {
      nameController.dispose();
      sortOrderController.dispose();
    }
  }

  Future<_ModelFormData?> _showModelDialog({required CatalogWorkspaceData workspace, CatalogModel? model}) async {
    final nameController = TextEditingController(text: model?.name ?? '');
    final marketingController = TextEditingController(text: model?.marketingName ?? '');
    final sortOrderController = TextEditingController(text: model?.sortOrder.toString() ?? _models.length.toString());
    String selectedBrandId = model?.brandId ?? _selectedBrandId ?? workspace.brands.first.id;
    final formKey = GlobalKey<FormState>();

    try {
      return await showDialog<_ModelFormData>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(model == null ? 'Dodaj model' : 'Edytuj model'),
            content: SizedBox(
              width: 460,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedBrandId,
                      decoration: const InputDecoration(labelText: 'Marka'),
                      items: _sortedBrands(workspace.brands)
                          .map((brand) => DropdownMenuItem(value: brand.id, child: Text(brand.name)))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedBrandId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nazwa modelu'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Podaj nazwę modelu.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: marketingController,
                      decoration: const InputDecoration(labelText: 'Nazwa marketingowa (opcjonalnie)'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: sortOrderController,
                      decoration: const InputDecoration(labelText: 'Kolejność na liście'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }
                  Navigator.of(context).pop(
                    _ModelFormData(
                      brandId: selectedBrandId,
                      name: nameController.text.trim(),
                      marketingName: marketingController.text.trim(),
                      sortOrder: int.tryParse(sortOrderController.text.trim()),
                    ),
                  );
                },
                child: Text(model == null ? 'Dodaj' : 'Zapisz'),
              ),
            ],
          ),
        ),
      );
    } finally {
      nameController.dispose();
      marketingController.dispose();
      sortOrderController.dispose();
    }
  }

  Future<_VersionFormData?> _showVersionDialog({required CatalogWorkspaceData workspace, CatalogVersion? version}) async {
    final nameController = TextEditingController(text: version?.name ?? '');
    final yearController = TextEditingController(text: version?.year?.toString() ?? '');
    final sortOrderController = TextEditingController(text: version?.sortOrder.toString() ?? _versions.length.toString());
    final systemPowerController = TextEditingController(text: version?.systemPowerHp?.toString() ?? '');
    final batteryController = TextEditingController(text: version?.batteryCapacityKwh?.toString() ?? '');
    final combustionPowerController = TextEditingController(text: version?.combustionEnginePowerHp?.toString() ?? '');
    final engineController = TextEditingController(text: version?.engineDisplacementCc?.toString() ?? '');
    final rangeController = TextEditingController(text: version?.rangeKm?.toString() ?? '');
    final notesController = TextEditingController(text: version?.notes ?? '');
    final availableModels = _sortedModels(workspace.models);
    String selectedModelId = version?.modelId ?? _selectedModelId ?? availableModels.first.id;
    String selectedPowertrain = version?.powertrainType ?? workspace.dictionaries.powertrainTypes.first;
    String? selectedDriveType = version?.driveType;
    final formKey = GlobalKey<FormState>();

    String? validatePowertrainRequirements() {
      final systemPower = num.tryParse(systemPowerController.text.trim().replaceAll(',', '.'));
      final battery = num.tryParse(batteryController.text.trim().replaceAll(',', '.'));
      final engineCapacity = num.tryParse(engineController.text.trim().replaceAll(',', '.'));

      if ((selectedPowertrain == 'ELECTRIC' || selectedPowertrain == 'HYBRID') && systemPower == null) {
        return 'Podaj moc układu.';
      }

      if ((selectedPowertrain == 'ELECTRIC' || selectedPowertrain == 'HYBRID') && battery == null) {
        return 'Podaj pojemność baterii.';
      }

      if (selectedPowertrain == 'HYBRID' && engineCapacity == null) {
        return 'Podaj pojemność silnika spalinowego dla hybrydy.';
      }

      return null;
    }

    try {
      return await showDialog<_VersionFormData>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(version == null ? 'Dodaj wersję' : 'Edytuj wersję'),
            content: SizedBox(
              width: 520,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedModelId,
                        decoration: const InputDecoration(labelText: 'Model'),
                        items: availableModels
                            .map((item) => DropdownMenuItem(value: item.id, child: Text(_buildModelContextLabel(item))))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setDialogState(() {
                            selectedModelId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nazwa wersji'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Podaj nazwę wersji.' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: yearController,
                              decoration: const InputDecoration(labelText: 'Rocznik'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: sortOrderController,
                              decoration: const InputDecoration(labelText: 'Kolejność'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPowertrain,
                        decoration: const InputDecoration(labelText: 'Typ napędu'),
                        items: workspace.dictionaries.powertrainTypes
                            .map((type) => DropdownMenuItem(value: type, child: Text(_powertrainLabel(type))))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setDialogState(() {
                            selectedPowertrain = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        initialValue: selectedDriveType,
                        decoration: const InputDecoration(labelText: 'Napęd osi'),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('Brak danych')),
                          ...workspace.dictionaries.driveTypes
                              .map((type) => DropdownMenuItem<String?>(value: type, child: Text(_driveTypeLabel(type))))
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedDriveType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: systemPowerController,
                        decoration: const InputDecoration(labelText: 'Moc układu [KM]'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: batteryController,
                        decoration: const InputDecoration(labelText: 'Pojemność baterii [kWh]'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: combustionPowerController,
                        decoration: const InputDecoration(labelText: 'Moc silnika spalinowego [KM]'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: engineController,
                        decoration: const InputDecoration(labelText: 'Pojemność silnika spalinowego [cm3]'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: rangeController,
                        decoration: const InputDecoration(labelText: 'Zasięg [km]'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesController,
                        decoration: const InputDecoration(labelText: 'Notatki (opcjonalnie)'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: VeloPrimePalette.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: VeloPrimePalette.line),
                        ),
                        child: Text(
                          selectedPowertrain == 'HYBRID'
                              ? 'Dla hybrydy wymagane są: moc układu, bateria i pojemność silnika spalinowego.'
                              : selectedPowertrain == 'ELECTRIC'
                                  ? 'Dla elektryka uzupełnij przynajmniej moc układu i pojemność baterii.'
                                  : 'Dla wersji spalinowej możesz zostawić pola baterii puste.',
                          style: const TextStyle(color: VeloPrimePalette.muted, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }
                  final powertrainError = validatePowertrainRequirements();
                  if (powertrainError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(powertrainError)));
                    return;
                  }
                  Navigator.of(context).pop(
                    _VersionFormData(
                      modelId: selectedModelId,
                      name: nameController.text.trim(),
                      powertrainType: selectedPowertrain,
                      year: int.tryParse(yearController.text.trim()),
                      sortOrder: int.tryParse(sortOrderController.text.trim()),
                      driveType: selectedDriveType,
                      systemPowerHp: num.tryParse(systemPowerController.text.trim().replaceAll(',', '.')),
                      batteryCapacityKwh: num.tryParse(batteryController.text.trim().replaceAll(',', '.')),
                      combustionEnginePowerHp: num.tryParse(combustionPowerController.text.trim().replaceAll(',', '.')),
                      engineDisplacementCc: num.tryParse(engineController.text.trim().replaceAll(',', '.')),
                      rangeKm: num.tryParse(rangeController.text.trim().replaceAll(',', '.')),
                      notes: notesController.text.trim(),
                    ),
                  );
                },
                child: Text(version == null ? 'Dodaj' : 'Zapisz'),
              ),
            ],
          ),
        ),
      );
    } finally {
      nameController.dispose();
      yearController.dispose();
      sortOrderController.dispose();
      systemPowerController.dispose();
      batteryController.dispose();
      combustionPowerController.dispose();
      engineController.dispose();
      rangeController.dispose();
      notesController.dispose();
    }
  }

  Future<_PricingFormData?> _showPricingDialog({required CatalogWorkspaceData workspace, CatalogPricingRecord? pricing}) async {
    final listPriceController = TextEditingController(text: pricing?.listPriceNet.toString() ?? '');
    final basePriceController = TextEditingController(text: pricing?.basePriceNet.toString() ?? '');
    final vatController = TextEditingController(text: pricing?.vatRate.toString() ?? workspace.dictionaries.defaultVatRate.toString());
    final selectedVersion = pricing != null ? _findVersionById(pricing.versionId) : _selectedVersion;
    final selectedVersionId = pricing?.versionId ?? selectedVersion?.id;

    if (selectedVersionId == null) {
      return null;
    }

    final versionContext = _buildVersionContextLabel(selectedVersion ?? _findVersionById(selectedVersionId)!);
    final formKey = GlobalKey<FormState>();

    try {
      return await showDialog<_PricingFormData>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(pricing == null ? 'Dodaj rekord cenowy' : 'Edytuj rekord cenowy'),
            content: SizedBox(
              width: 460,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: VeloPrimePalette.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: VeloPrimePalette.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rekord cenowy dla wersji',
                            style: TextStyle(
                              color: VeloPrimePalette.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            versionContext,
                            style: const TextStyle(
                              color: VeloPrimePalette.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: listPriceController,
                      decoration: const InputDecoration(labelText: 'Cena katalogowa netto'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final number = num.tryParse((value ?? '').trim().replaceAll(',', '.'));
                        if (number == null || number <= 0) {
                          return 'Podaj poprawną cenę katalogową netto.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: basePriceController,
                      decoration: const InputDecoration(labelText: 'Cena bazowa netto'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final number = num.tryParse((value ?? '').trim().replaceAll(',', '.'));
                        if (number == null || number <= 0) {
                          return 'Podaj poprawną cenę bazową netto.';
                        }
                        final listNumber = num.tryParse(listPriceController.text.trim().replaceAll(',', '.'));
                        if (listNumber != null && number > listNumber) {
                          return 'Cena bazowa nie może być wyższa niż katalogowa.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: vatController,
                      decoration: const InputDecoration(labelText: 'VAT [%]'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }
                  Navigator.of(context).pop(
                    _PricingFormData(
                      versionId: selectedVersionId,
                      listPriceNet: num.parse(listPriceController.text.trim().replaceAll(',', '.')),
                      basePriceNet: num.parse(basePriceController.text.trim().replaceAll(',', '.')),
                      vatRate: num.tryParse(vatController.text.trim().replaceAll(',', '.')) ?? workspace.dictionaries.defaultVatRate,
                    ),
                  );
                },
                child: Text(pricing == null ? 'Dodaj' : 'Zapisz'),
              ),
            ],
          ),
        ),
      );
    } finally {
      listPriceController.dispose();
      basePriceController.dispose();
      vatController.dispose();
    }
  }

  Future<_ColorFormData?> _showColorDialog({
    CatalogColorRecord? color,
    required CatalogModel model,
    CatalogBrand? brand,
  }) async {
    final nameController = TextEditingController(text: color?.name ?? '');
    final finishTypeController = TextEditingController(text: color?.finishType ?? '');
    final surchargeController = TextEditingController(text: color?.surchargeNet?.toString() ?? '');
    final sortOrderController = TextEditingController(text: color?.sortOrder.toString() ?? _colors.length.toString());
    bool isBaseColor = color?.isBaseColor ?? _colors.every((item) => !item.isBaseColor);
    bool hasSurcharge = color?.hasSurcharge ?? false;
    final formKey = GlobalKey<FormState>();

    try {
      return await showDialog<_ColorFormData>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(color == null ? 'Dodaj kolor' : 'Edytuj kolor'),
            content: SizedBox(
              width: 460,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: VeloPrimePalette.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: VeloPrimePalette.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kolor zostanie przypisany do modelu',
                            style: TextStyle(
                              color: VeloPrimePalette.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            [if (brand != null) brand.name, model.name].join(' / '),
                            style: const TextStyle(
                              color: VeloPrimePalette.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nazwa koloru'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Podaj nazwę koloru.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: finishTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Wykończenie lakieru (opcjonalnie)',
                        helperText: 'Np. metaliczny, perłowy albo matowy. Możesz zostawić puste.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      value: isBaseColor,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Kolor bazowy'),
                      subtitle: const Text('Kolor bazowy jest dostępny bez dopłaty w standardzie modelu.'),
                      onChanged: (value) {
                        setDialogState(() {
                          isBaseColor = value;
                          if (value) {
                            hasSurcharge = false;
                            surchargeController.text = '';
                          }
                        });
                      },
                    ),
                    SwitchListTile.adaptive(
                      value: hasSurcharge,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Kolor za dopłatą'),
                      subtitle: const Text('Dopłata jest doliczana osobno i nie wchodzi do puli rabatowo-prowizyjnej.'),
                      onChanged: isBaseColor
                          ? null
                          : (value) {
                              setDialogState(() {
                                hasSurcharge = value;
                                if (!value) {
                                  surchargeController.text = '';
                                }
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: surchargeController,
                      enabled: hasSurcharge && !isBaseColor,
                      decoration: const InputDecoration(labelText: 'Dopłata netto'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (!hasSurcharge || isBaseColor) {
                          return null;
                        }
                        final number = num.tryParse((value ?? '').trim().replaceAll(',', '.'));
                        if (number == null || number <= 0) {
                          return 'Podaj poprawną dopłatę netto.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: sortOrderController,
                      decoration: const InputDecoration(labelText: 'Kolejność na liście'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }
                  Navigator.of(context).pop(
                    _ColorFormData(
                      name: nameController.text.trim(),
                      finishType: finishTypeController.text.trim(),
                      isBaseColor: isBaseColor,
                      hasSurcharge: hasSurcharge && !isBaseColor,
                      surchargeNet: hasSurcharge && !isBaseColor
                          ? num.tryParse(surchargeController.text.trim().replaceAll(',', '.'))
                          : null,
                      sortOrder: int.tryParse(sortOrderController.text.trim()),
                    ),
                  );
                },
                child: Text(color == null ? 'Dodaj' : 'Zapisz'),
              ),
            ],
          ),
        ),
      );
    } finally {
      nameController.dispose();
      finishTypeController.dispose();
      surchargeController.dispose();
      sortOrderController.dispose();
    }
  }

  Future<_AssetBundleFormData?> _showAssetBundleDialog({CatalogAssetBundle? bundle}) async {
    final versionTagController = TextEditingController(text: bundle?.assetsVersionTag ?? '');
    bool isActive = bundle?.isActive ?? true;

    try {
      return await showDialog<_AssetBundleFormData>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Ustaw pakiet materiałów'),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: versionTagController,
                    decoration: const InputDecoration(labelText: 'Tag wersji assetów (opcjonalnie)'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    value: isActive,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pakiet aktywny'),
                    subtitle: const Text('Aktywny pakiet może zostać opublikowany w ASSETS i wykorzystany przez ofertę.'),
                    onChanged: (value) {
                      setDialogState(() {
                        isActive = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  _AssetBundleFormData(
                    assetsVersionTag: versionTagController.text.trim(),
                    isActive: isActive,
                  ),
                ),
                child: const Text('Zapisz'),
              ),
            ],
          ),
        ),
      );
    } finally {
      versionTagController.dispose();
    }
  }

  Future<_AssetFileFormData?> _showAssetFileDialog({
    required CatalogWorkspaceData workspace,
    required CatalogModel model,
    CatalogBrand? brand,
  }) async {
    final fileNameController = TextEditingController();
    final mimeTypeController = TextEditingController();
    final sortOrderController = TextEditingController(text: (_selectedAssetBundle?.files.length ?? 0).toString());
    String selectedCategory = workspace.dictionaries.assetCategories.first;
    String? selectedPowertrainType;
    String? selectedLocalPath;
    bool isDragging = false;
    final formKey = GlobalKey<FormState>();

    try {
      return await showDialog<_AssetFileFormData>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Dodaj plik materiałów'),
            content: SizedBox(
              width: 520,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: VeloPrimePalette.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: VeloPrimePalette.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Plik zostanie przypisany do modelu',
                              style: TextStyle(
                                color: VeloPrimePalette.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              [if (brand != null) brand.name, model.name].join(' / '),
                              style: const TextStyle(
                                color: VeloPrimePalette.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Możesz wybrać plik z dysku albo przeciągnąć go do strefy poniżej. System zapisze go do katalogu materiałów tego modelu.',
                              style: TextStyle(color: VeloPrimePalette.muted, height: 1.45),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(labelText: 'Kategoria pliku'),
                        items: workspace.dictionaries.assetCategories
                            .map((category) => DropdownMenuItem(value: category, child: Text(_assetCategoryLabel(category))))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setDialogState(() {
                            selectedCategory = value;
                            if (selectedCategory != 'SPEC_PDF') {
                              selectedPowertrainType = null;
                            }
                          });
                        },
                      ),
                      if (selectedCategory == 'SPEC_PDF') ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          initialValue: selectedPowertrainType,
                          decoration: const InputDecoration(labelText: 'Typ napędu dla specyfikacji'),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('Ogólny PDF fallback')),
                            ...workspace.dictionaries.powertrainTypes.map(
                              (type) => DropdownMenuItem<String?>(value: type, child: Text(_powertrainLabel(type))),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              selectedPowertrainType = value;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: () async {
                            final typeGroup = _isSpecPdfCategory(selectedCategory)
                                ? const XTypeGroup(label: 'PDF', extensions: ['pdf'])
                                : const XTypeGroup(label: 'Obrazy', extensions: ['png', 'jpg', 'jpeg', 'webp']);
                            final file = await openFile(acceptedTypeGroups: [typeGroup]);
                            if (file == null) {
                              return;
                            }

                            if (!_isSupportedAssetPath(file.name, selectedCategory)) {
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _isSpecPdfCategory(selectedCategory)
                                        ? 'Dla tej kategorii wybierz plik PDF.'
                                        : 'Dla tej kategorii wybierz plik PNG, JPG albo WEBP.',
                                  ),
                                ),
                              );
                              return;
                            }

                            setDialogState(() {
                              selectedLocalPath = file.path;
                              fileNameController.text = file.name;
                              mimeTypeController.text = _guessAssetMimeType(file.name, selectedCategory);
                            });
                          },
                          icon: const Icon(Icons.upload_file_outlined),
                          label: const Text('Wybierz plik z dysku'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropTarget(
                        onDragEntered: (_) {
                          setDialogState(() {
                            isDragging = true;
                          });
                        },
                        onDragExited: (_) {
                          setDialogState(() {
                            isDragging = false;
                          });
                        },
                        onDragDone: (details) {
                          setDialogState(() {
                            isDragging = false;
                          });

                          if (details.files.isEmpty) {
                            return;
                          }

                          final file = details.files.first;
                          if (!_isSupportedAssetPath(file.name, selectedCategory)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _isSpecPdfCategory(selectedCategory)
                                      ? 'Dla tej kategorii przeciągnij plik PDF.'
                                      : 'Dla tej kategorii przeciągnij obraz PNG, JPG albo WEBP.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            selectedLocalPath = file.path;
                            fileNameController.text = file.name;
                            mimeTypeController.text = _guessAssetMimeType(file.name, selectedCategory);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDragging ? const Color(0x146D597A) : VeloPrimePalette.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDragging ? const Color(0xFF6D597A) : VeloPrimePalette.line,
                              width: isDragging ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _isSpecPdfCategory(selectedCategory)
                                    ? Icons.picture_as_pdf_outlined
                                    : Icons.add_photo_alternate_outlined,
                                color: const Color(0xFF6D597A),
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isSpecPdfCategory(selectedCategory)
                                    ? 'Przeciągnij tutaj PDF specyfikacji'
                                    : 'Przeciągnij tutaj zdjęcie modelu',
                                style: const TextStyle(
                                  color: VeloPrimePalette.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isSpecPdfCategory(selectedCategory)
                                    ? 'Obsługiwane pliki: PDF'
                                    : 'Obsługiwane pliki: PNG, JPG, JPEG, WEBP',
                                style: const TextStyle(color: VeloPrimePalette.muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: VeloPrimePalette.line),
                        ),
                        child: Text(
                          selectedLocalPath ?? 'Nie wybrano jeszcze pliku.',
                          style: const TextStyle(color: VeloPrimePalette.muted, height: 1.45),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: fileNameController,
                        decoration: const InputDecoration(labelText: 'Nazwa pliku w katalogu'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Podaj nazwę pliku.' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: mimeTypeController,
                        decoration: const InputDecoration(labelText: 'Mime type (opcjonalnie)'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: sortOrderController,
                        decoration: const InputDecoration(labelText: 'Kolejność'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }
                  if (selectedLocalPath == null || selectedLocalPath!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Najpierw wybierz plik z dysku.')),
                    );
                    return;
                  }
                  Navigator.of(context).pop(
                    _AssetFileFormData(
                      category: selectedCategory,
                      powertrainType: selectedPowertrainType,
                      fileName: fileNameController.text.trim(),
                      sourceFilePath: selectedLocalPath!,
                      mimeType: mimeTypeController.text.trim(),
                      sortOrder: int.tryParse(sortOrderController.text.trim()),
                    ),
                  );
                },
                child: const Text('Dodaj'),
              ),
            ],
          ),
        ),
      );
    } finally {
      fileNameController.dispose();
      mimeTypeController.dispose();
      sortOrderController.dispose();
    }
  }
}

class _AdminSectionPanel extends StatelessWidget {
  const _AdminSectionPanel({
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.actions,
  });

  final Color tint;
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return VeloPrimeWorkspacePanel(
      tint: tint,
      radius: 22,
      padding: const EdgeInsets.all(18),
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
                    VeloPrimeSectionEyebrow(label: title, color: tint),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        color: VeloPrimePalette.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: VeloPrimePalette.muted,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SelectableRecordCard extends StatelessWidget {
  const _SelectableRecordCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.leading,
    this.trailing,
    this.footer,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0x14BE933E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? const Color(0xFFBE933E) : VeloPrimePalette.line,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: VeloPrimePalette.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: VeloPrimePalette.muted,
                              height: 1.3,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
                if (footer != null) ...[
                  const SizedBox(height: 8),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptySectionState extends StatelessWidget {
  const _EmptySectionState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VeloPrimePalette.line),
      ),
      child: Text(
        message,
        style: const TextStyle(color: VeloPrimePalette.muted, height: 1.4, fontSize: 13),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VeloPrimePalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: VeloPrimePalette.muted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: VeloPrimePalette.ink,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: VeloPrimePalette.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VeloPrimePalette.line),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: VeloPrimePalette.muted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InventorySubsection extends StatelessWidget {
  const _InventorySubsection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: VeloPrimePalette.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        ),
      ],
    );
  }
}

class _BrandFormData {
  const _BrandFormData({
    required this.name,
    required this.sortOrder,
  });

  final String name;
  final int? sortOrder;
}

class _ModelFormData {
  const _ModelFormData({
    required this.brandId,
    required this.name,
    required this.marketingName,
    required this.sortOrder,
  });

  final String brandId;
  final String name;
  final String marketingName;
  final int? sortOrder;
}

class _VersionFormData {
  const _VersionFormData({
    required this.modelId,
    required this.name,
    required this.powertrainType,
    required this.year,
    required this.sortOrder,
    required this.driveType,
    required this.systemPowerHp,
    required this.batteryCapacityKwh,
    required this.combustionEnginePowerHp,
    required this.engineDisplacementCc,
    required this.rangeKm,
    required this.notes,
  });

  final String modelId;
  final String name;
  final String powertrainType;
  final int? year;
  final int? sortOrder;
  final String? driveType;
  final num? systemPowerHp;
  final num? batteryCapacityKwh;
  final num? combustionEnginePowerHp;
  final num? engineDisplacementCc;
  final num? rangeKm;
  final String notes;
}

class _PricingFormData {
  const _PricingFormData({
    required this.versionId,
    required this.listPriceNet,
    required this.basePriceNet,
    required this.vatRate,
  });

  final String versionId;
  final num listPriceNet;
  final num basePriceNet;
  final num vatRate;
}

class _ColorFormData {
  const _ColorFormData({
    required this.name,
    required this.finishType,
    required this.isBaseColor,
    required this.hasSurcharge,
    required this.surchargeNet,
    required this.sortOrder,
  });

  final String name;
  final String finishType;
  final bool isBaseColor;
  final bool hasSurcharge;
  final num? surchargeNet;
  final int? sortOrder;
}

class _AssetBundleFormData {
  const _AssetBundleFormData({
    required this.assetsVersionTag,
    required this.isActive,
  });

  final String assetsVersionTag;
  final bool isActive;
}

class _AssetFileFormData {
  const _AssetFileFormData({
    required this.category,
    required this.powertrainType,
    required this.fileName,
    required this.sourceFilePath,
    required this.mimeType,
    required this.sortOrder,
  });

  final String category;
  final String? powertrainType;
  final String fileName;
  final String sourceFilePath;
  final String mimeType;
  final int? sortOrder;
}
