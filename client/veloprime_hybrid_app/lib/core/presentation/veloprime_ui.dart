import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VeloPrimePalette {
  static const shellTop = Color(0xFFFBFBFA);
  static const shellBottom = Color(0xFFF3F0EA);
  static const sand = Color(0xFFFBFBFA);
  static const ivory = Color(0xFFFFFFFF);
  static const ivoryStrong = Color(0xFFF8F5F0);
  static const surface = Color(0xFFF7F4EE);
  static const overlay = Color(0xFFFEFCF9);
  static const ink = Color(0xFF111111);
  static const bronze = Color(0xFFD4A84F);
  static const bronzeDeep = Color(0xFFBE933E);
  static const champagne = Color(0xFFE9D3A0);
  static const olive = Color(0xFF1F8F6A);
  static const sea = Color(0xFF4A90E2);
  static const rose = Color(0xFFC05621);
  static const violet = Color(0xFF7C5CFF);
  static const line = Color(0x14000000);
  static const lineStrong = Color(0x14111111);
  static const muted = Color(0xFF666666);
}

class VeloPrimeBackgroundVisualData {
  const VeloPrimeBackgroundVisualData({
    required this.overlayTint,
    required this.primaryGlow,
    required this.secondaryGlow,
  });

  static const fallback = VeloPrimeBackgroundVisualData(
    overlayTint: Color(0x3DE7F3FF),
    primaryGlow: Color(0x304A90E2),
    secondaryGlow: Color(0x1ABCE4FF),
  );

  final Color overlayTint;
  final Color primaryGlow;
  final Color secondaryGlow;
}

const String veloPrimeBackgroundPreferenceKey = 'crm_shell_background_preset';

class _VeloPrimeScenicPreset {
  const _VeloPrimeScenicPreset({
    required this.key,
    required this.assetPath,
    required this.overlayGradient,
    required this.overlayColor,
    required this.primaryGlow,
    required this.secondaryGlow,
  });

  final String key;
  final String assetPath;
  final Gradient overlayGradient;
  final Color overlayColor;
  final Color primaryGlow;
  final Color secondaryGlow;
}

const List<_VeloPrimeScenicPreset> _veloPrimeScenicPresets = [
  _VeloPrimeScenicPreset(
    key: 'Biały',
    assetPath: 'assets/backgrounds/Biały.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xD9FFFDF8), Color(0xC7F5F1EA), Color(0xBAEEE8DF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x52FFFDF9),
    primaryGlow: Color(0x18EEDBB2),
    secondaryGlow: Color(0x12D7E7FF),
  ),
  _VeloPrimeScenicPreset(
    key: 'Błękitny',
    assetPath: 'assets/backgrounds/Błękitny.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xAAFCFEFF), Color(0x7AEAF4FF), Color(0x8FCFDBF3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x3DE7F3FF),
    primaryGlow: Color(0x304A90E2),
    secondaryGlow: Color(0x1ABCE4FF),
  ),
  _VeloPrimeScenicPreset(
    key: 'Dark',
    assetPath: 'assets/backgrounds/Dark.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xB30A1431), Color(0x95112654), Color(0x8A09101F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x6407111F),
    primaryGlow: Color(0x3B3FA9FF),
    secondaryGlow: Color(0x309A59FF),
  ),
  _VeloPrimeScenicPreset(
    key: 'Granatowy',
    assetPath: 'assets/backgrounds/Granatowy.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xB6081535), Color(0x940D214F), Color(0x8A0B1229)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x60081227),
    primaryGlow: Color(0x382675FF),
    secondaryGlow: Color(0x264ED7FF),
  ),
  _VeloPrimeScenicPreset(
    key: 'Indygo',
    assetPath: 'assets/backgrounds/Indygo.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xA60B1636), Color(0x84162758), Color(0x82111A40)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x540B1635),
    primaryGlow: Color(0x2E5866FF),
    secondaryGlow: Color(0x22D45CFF),
  ),
  _VeloPrimeScenicPreset(
    key: 'Lawendowy',
    assetPath: 'assets/backgrounds/Lawendowy.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xA9FFFDFE), Color(0x7FD9DDFD), Color(0x8EBBC8F2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x34EEF0FF),
    primaryGlow: Color(0x244F7CFF),
    secondaryGlow: Color(0x1ADDDCFF),
  ),
  _VeloPrimeScenicPreset(
    key: 'Niebieski',
    assetPath: 'assets/backgrounds/Niebieski.png',
    overlayGradient: LinearGradient(
      colors: [Color(0x9AFBFEFF), Color(0x5BD6E5FF), Color(0x78B2C7EA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x34DCEEFF),
    primaryGlow: Color(0x26549EEF),
    secondaryGlow: Color(0x1ABEE0FF),
  ),
  _VeloPrimeScenicPreset(
    key: 'Różowy',
    assetPath: 'assets/backgrounds/Różowy.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xACFFFDFE), Color(0x83F2DBEC), Color(0x85E2C9DC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x32FBE6EF),
    primaryGlow: Color(0x20C57D9A),
    secondaryGlow: Color(0x18FDBDD0),
  ),
  _VeloPrimeScenicPreset(
    key: 'Szary',
    assetPath: 'assets/backgrounds/Szary.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xB7FFFFFF), Color(0x8BECEEF3), Color(0x8FDEE4EC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x32F6F9FC),
    primaryGlow: Color(0x180E1B34),
    secondaryGlow: Color(0x149EBDE7),
  ),
  _VeloPrimeScenicPreset(
    key: 'Wiśniowy',
    assetPath: 'assets/backgrounds/Wiśniowy.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xB90D1732), Color(0x8F421433), Color(0x7F1A0D1E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x56210B19),
    primaryGlow: Color(0x28CF5E72),
    secondaryGlow: Color(0x18A85BFF),
  ),
  _VeloPrimeScenicPreset(
    key: 'Zielony',
    assetPath: 'assets/backgrounds/Zielony.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xAEFFFDF8), Color(0x82E0F4E9), Color(0x85CAE8D7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x36E4F5EA),
    primaryGlow: Color(0x221F8F6A),
    secondaryGlow: Color(0x18A3F0D0),
  ),
  _VeloPrimeScenicPreset(
    key: 'Złoty',
    assetPath: 'assets/backgrounds/Złoty.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xBCFFFDF8), Color(0x94F4E6C6), Color(0x8FE0CEAE)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x42FFF3D6),
    primaryGlow: Color(0x2AD4A84F),
    secondaryGlow: Color(0x18FFD998),
  ),
  _VeloPrimeScenicPreset(
    key: 'Żółty',
    assetPath: 'assets/backgrounds/Żółty.png',
    overlayGradient: LinearGradient(
      colors: [Color(0xC4FFFDF8), Color(0xA5FFF0BE), Color(0x96F3D89A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x48FFF0B5),
    primaryGlow: Color(0x2DEFCB58),
    secondaryGlow: Color(0x14FFD96A),
  ),
  _VeloPrimeScenicPreset(
    key: 'propozycja',
    assetPath: 'assets/backgrounds/propozycja.png',
    overlayGradient: LinearGradient(
      colors: [Color(0x8EFFFDFE), Color(0x66CFDCF5), Color(0x73B2C4E6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    overlayColor: Color(0x2FE1EEFF),
    primaryGlow: Color(0x225B89E7),
    secondaryGlow: Color(0x1AC8D8FF),
  ),
];

_VeloPrimeScenicPreset _resolveVeloPrimeScenicPreset(String? key) {
  return _veloPrimeScenicPresets.firstWhere(
    (preset) => preset.key == key,
    orElse: () => _veloPrimeScenicPresets.firstWhere(
      (preset) => preset.key == 'Błękitny',
      orElse: () => _veloPrimeScenicPresets.first,
    ),
  );
}

class VeloPrimeBackgroundVisualScope extends InheritedWidget {
  const VeloPrimeBackgroundVisualScope({
    super.key,
    required this.data,
    required super.child,
  });

  final VeloPrimeBackgroundVisualData data;

  static VeloPrimeBackgroundVisualData of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<VeloPrimeBackgroundVisualScope>();
    return scope?.data ?? VeloPrimeBackgroundVisualData.fallback;
  }

  @override
  bool updateShouldNotify(VeloPrimeBackgroundVisualScope oldWidget) {
    return data.overlayTint != oldWidget.data.overlayTint ||
        data.primaryGlow != oldWidget.data.primaryGlow ||
        data.secondaryGlow != oldWidget.data.secondaryGlow;
  }
}

BoxDecoration veloPrimeWorkspacePanelDecoration({
  required Color tint,
  double radius = 30,
  double surfaceOpacity = 0.75,
}) {
  return BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Colors.white.withValues(alpha: surfaceOpacity),
        Color.alphaBlend(tint.withValues(alpha: 0.08), const Color(0xBFF7F4FB)),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: tint.withValues(alpha: 0.14)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF101F3B).withValues(alpha: 0.08),
        blurRadius: 32,
        offset: const Offset(0, 18),
      ),
    ],
  );
}

class VeloPrimeWorkspacePanel extends StatelessWidget {
  const VeloPrimeWorkspacePanel({
    super.key,
    required this.child,
    required this.tint,
    this.radius = 30,
    this.padding = const EdgeInsets.all(24),
    this.surfaceOpacity = 0.75,
  });

  final Widget child;
  final Color tint;
  final double radius;
  final EdgeInsets padding;
  final double surfaceOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: veloPrimeWorkspacePanelDecoration(
        tint: tint,
        radius: radius,
        surfaceOpacity: surfaceOpacity,
      ),
      child: child,
    );
  }
}

class VeloPrimeHorizontalScrollAssist extends StatefulWidget {
  const VeloPrimeHorizontalScrollAssist({
    super.key,
    required this.controller,
    required this.child,
    this.scrollStep = 348,
    this.leftTooltip = 'Przewiń w lewo',
    this.rightTooltip = 'Przewiń w prawo',
  });

  final ScrollController controller;
  final Widget child;
  final double scrollStep;
  final String leftTooltip;
  final String rightTooltip;

  @override
  State<VeloPrimeHorizontalScrollAssist> createState() =>
      _VeloPrimeHorizontalScrollAssistState();
}

class _VeloPrimeHorizontalScrollAssistState
    extends State<VeloPrimeHorizontalScrollAssist> {
  bool _hasOverflow = false;
  bool _canScrollBackward = false;
  bool _canScrollForward = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refreshIndicators);
    _scheduleRefresh();
  }

  @override
  void didUpdateWidget(covariant VeloPrimeHorizontalScrollAssist oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      _scheduleRefresh();
      return;
    }

    oldWidget.controller.removeListener(_refreshIndicators);
    widget.controller.addListener(_refreshIndicators);
    _scheduleRefresh();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refreshIndicators);
    super.dispose();
  }

  void _scheduleRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _refreshIndicators();
    });
  }

  void _refreshIndicators() {
    final controller = widget.controller;
    final hasClients = controller.hasClients;
    final hasOverflow = hasClients && controller.position.maxScrollExtent > 12;
    final canScrollBackward = hasOverflow && controller.offset > 12;
    final canScrollForward =
        hasOverflow && controller.offset < controller.position.maxScrollExtent - 12;

    if (_hasOverflow == hasOverflow &&
        _canScrollBackward == canScrollBackward &&
        _canScrollForward == canScrollForward) {
      return;
    }

    setState(() {
      _hasOverflow = hasOverflow;
      _canScrollBackward = canScrollBackward;
      _canScrollForward = canScrollForward;
    });
  }

  Future<void> _animateBy(double delta) async {
    final controller = widget.controller;
    if (!controller.hasClients) {
      return;
    }

    final targetOffset = (controller.offset + delta)
        .clamp(0.0, controller.position.maxScrollExtent);

    if ((targetOffset - controller.offset).abs() < 1) {
      return;
    }

    await controller.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    _scheduleRefresh();

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        _scheduleRefresh();
        return false;
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_hasOverflow) ...[
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _HorizontalScrollAssistButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: widget.leftTooltip,
                  enabled: _canScrollBackward,
                  onTap: _canScrollBackward
                      ? () => _animateBy(-widget.scrollStep)
                      : null,
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _HorizontalScrollAssistButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: widget.rightTooltip,
                  enabled: _canScrollForward,
                  onTap: _canScrollForward
                      ? () => _animateBy(widget.scrollStep)
                      : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HorizontalScrollAssistButton extends StatelessWidget {
  const _HorizontalScrollAssistButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final button = AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 0.94 : 0.26,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Ink(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.88),
                    Color.alphaBlend(
                      VeloPrimePalette.sea.withValues(alpha: 0.08),
                      Colors.white,
                    ),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x1F3159B9)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A102040),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(icon, color: const Color(0xFF3159B9), size: 24),
            ),
          ),
        ),
      ),
    );

    return Tooltip(message: tooltip, child: button);
  }
}

class VeloPrimeSectionEyebrow extends StatelessWidget {
  const VeloPrimeSectionEyebrow({
    super.key,
    required this.label,
    this.color = VeloPrimePalette.bronzeDeep,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }
}

class VeloPrimeWorkspaceState extends StatelessWidget {
  const VeloPrimeWorkspaceState({
    super.key,
    required this.tint,
    required this.eyebrow,
    required this.title,
    this.message,
    this.icon,
    this.action,
    this.isLoading = false,
    this.maxWidth = 520,
  });

  final Color tint;
  final String eyebrow;
  final String title;
  final String? message;
  final IconData? icon;
  final Widget? action;
  final bool isLoading;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: VeloPrimeWorkspacePanel(
          tint: tint,
          radius: 30,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VeloPrimeSectionEyebrow(label: eyebrow, color: tint),
              const SizedBox(height: 16),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          valueColor: AlwaysStoppedAnimation<Color>(tint),
                        ),
                      )
                    : Icon(icon ?? Icons.info_outline_rounded, color: tint, size: 24),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  color: VeloPrimePalette.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 10),
                Text(
                  message!,
                  style: const TextStyle(
                    color: VeloPrimePalette.muted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 18),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VeloPrimeDecoratedBackground extends StatefulWidget {
  const _VeloPrimeDecoratedBackground({
    required this.padding,
    required this.child,
  });

  final EdgeInsets padding;
  final Widget child;

  @override
  State<_VeloPrimeDecoratedBackground> createState() => _VeloPrimeDecoratedBackgroundState();
}

class _VeloPrimeDecoratedBackgroundState extends State<_VeloPrimeDecoratedBackground> {
  String _backgroundPresetKey = 'Błękitny';

  @override
  void initState() {
    super.initState();
    _restoreBackgroundPreset();
  }

  Future<void> _restoreBackgroundPreset() async {
    final preferences = await SharedPreferences.getInstance();
    final savedKey = preferences.getString(veloPrimeBackgroundPreferenceKey);

    if (!mounted || savedKey == null) {
      return;
    }

    if (_veloPrimeScenicPresets.any((preset) => preset.key == savedKey)) {
      setState(() {
        _backgroundPresetKey = savedKey;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preset = _resolveVeloPrimeScenicPreset(_backgroundPresetKey);

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: preset.overlayColor),
            child: Image.asset(
              preset.assetPath,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: preset.overlayGradient),
          ),
        ),
        Positioned(
          top: -120,
          left: -40,
          child: Container(
            width: 360,
            height: 240,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [preset.primaryGlow, const Color(0x00000000)],
              ),
            ),
          ),
        ),
        Positioned(
          top: -70,
          right: -40,
          child: Container(
            width: 260,
            height: 180,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [preset.secondaryGlow, const Color(0x00000000)],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class VeloPrimeShell extends StatelessWidget {
  const VeloPrimeShell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.decorateBackground = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool decorateBackground;

  @override
  Widget build(BuildContext context) {
    if (!decorateBackground) {
      return SafeArea(
        child: Padding(
          padding: padding,
          child: child,
        ),
      );
    }

    return _VeloPrimeDecoratedBackground(
      padding: padding,
      child: child,
    );
  }
}

class VeloPrimeCard extends StatelessWidget {
  const VeloPrimeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.backgroundColor = VeloPrimePalette.ivory,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(backgroundColor, Colors.white, 0.3) ?? backgroundColor,
            Color.lerp(backgroundColor, VeloPrimePalette.ivoryStrong, 0.94) ?? backgroundColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: VeloPrimePalette.lineStrong),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E111111),
            blurRadius: 34,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class VeloPrimeHero extends StatelessWidget {
  const VeloPrimeHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return VeloPrimeCard(
      backgroundColor: VeloPrimePalette.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: const TextStyle(
                    color: VeloPrimePalette.bronzeDeep,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: VeloPrimePalette.ink,
                    fontSize: 36,
                    height: 1.08,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: VeloPrimePalette.muted,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 20),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class VeloPrimeMetricCard extends StatelessWidget {
  const VeloPrimeMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Color.lerp(accentColor, Colors.white, 0.92) ?? Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VeloPrimePalette.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D111111),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: VeloPrimePalette.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class VeloPrimeBadge extends StatelessWidget {
  const VeloPrimeBadge({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8F5F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VeloPrimePalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w700,
              color: VeloPrimePalette.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: VeloPrimePalette.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration veloPrimeInputDecoration(String label, {String? hintText}) {
  return InputDecoration(
    labelText: label,
    hintText: hintText,
    filled: true,
    fillColor: const Color(0xFFFEFCF8),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    hintStyle: const TextStyle(
      color: Color(0xFF9F916F),
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    labelStyle: const TextStyle(
      color: Color(0xFF8A7441),
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
    floatingLabelStyle: const TextStyle(
      color: Color(0xFFB2862F),
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Color(0x33D9C39A)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Color(0x33D9C39A)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Color(0x66D4A84F), width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Color(0xFFC97A70), width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Color(0xFFC97A70), width: 1.5),
    ),
  );
}