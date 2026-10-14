import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/feedbackkit_theme.dart';

/// Supplies what Material widgets need when the host app does not.
///
/// A `MaterialApp` host passes through untouched, apart from Material 3 being
/// switched on and an optional brand tint. A `CupertinoApp` host gets a
/// Material 3 theme seeded from its `CupertinoTheme` primary colour and
/// brightness, plus Material localizations. A bare widget tree also gets a
/// `MediaQuery` and an `Overlay`, so tooltips and the search field work.
class MaterialHostBridge extends StatefulWidget {
  /// The FeedbackKit theme. Its primary colour becomes the tint when the
  /// host changed it from the default.
  final FeedbackKitTheme kitTheme;

  /// The Material subtree.
  final Widget child;

  const MaterialHostBridge({
    super.key,
    required this.kitTheme,
    required this.child,
  });

  /// Whether a Material route can be pushed from [context]: a navigator
  /// exists and its routes see Material localizations.
  static bool canShowMaterialRoute(BuildContext context) {
    final navigator = Navigator.maybeOf(context);
    if (navigator == null) return false;
    return Localizations.of<MaterialLocalizations>(
          navigator.context,
          MaterialLocalizations,
        ) !=
        null;
  }

  /// The theme Showcase renders with under [context].
  static ThemeData resolveTheme(BuildContext context, FeedbackKitTheme kit) {
    final ThemeData base;
    if (context.findAncestorWidgetOfExactType<Theme>() != null) {
      final host = Theme.of(context);
      base = host.useMaterial3
          ? host
          : ThemeData.from(colorScheme: host.colorScheme, useMaterial3: true);
    } else {
      final brightness = CupertinoTheme.maybeBrightnessOf(context) ??
          MediaQuery.maybePlatformBrightnessOf(context) ??
          Brightness.light;
      final seed = CupertinoDynamicColor.resolve(
        CupertinoTheme.of(context).primaryColor,
        context,
      );
      base = ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: brightness,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ),
      );
    }
    final tint = _brandTint(kit);
    if (tint == null) return base;
    final seeded = ColorScheme.fromSeed(
      seedColor: tint,
      brightness: base.colorScheme.brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: seeded.primary,
        onPrimary: seeded.onPrimary,
        primaryContainer: seeded.primaryContainer,
        onPrimaryContainer: seeded.onPrimaryContainer,
        secondaryContainer: seeded.secondaryContainer,
        onSecondaryContainer: seeded.onSecondaryContainer,
        surfaceTint: seeded.primary,
      ),
    );
  }

  /// The host's brand colour, or null when [kit] keeps a default primary and
  /// the Material colour scheme (including dynamic colour) should lead.
  static Color? _brandTint(FeedbackKitTheme kit) {
    final primary = kit.primaryColor;
    if (primary == const FeedbackKitTheme().primaryColor ||
        primary == FeedbackKitTheme.dark.primaryColor) {
      return null;
    }
    return primary;
  }

  @override
  State<MaterialHostBridge> createState() => _MaterialHostBridgeState();
}

class _MaterialHostBridgeState extends State<MaterialHostBridge> {
  OverlayEntry? _entry;

  @override
  void didUpdateWidget(MaterialHostBridge oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry?.markNeedsBuild();
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget material;
    if (Overlay.maybeOf(context) == null) {
      _entry ??= OverlayEntry(
        builder: (_) => Material(
          type: MaterialType.transparency,
          child: widget.child,
        ),
      );
      material = Overlay(initialEntries: [_entry!]);
    } else {
      material = Material(type: MaterialType.transparency, child: widget.child);
    }

    // Resolved below the MediaQuery that a bare tree gets, so the platform
    // brightness is known.
    final themed = Builder(
      builder: (context) => Theme(
        data: MaterialHostBridge.resolveTheme(context, widget.kitTheme),
        child: material,
      ),
    );

    final hasMaterialStrings = Localizations.of<MaterialLocalizations>(
          context,
          MaterialLocalizations,
        ) !=
        null;
    final Widget localized;
    if (hasMaterialStrings) {
      localized = themed;
    } else if (Localizations.maybeLocaleOf(context) == null) {
      // Localizations installs its own left-to-right Directionality, so the
      // direction FeedbackKitDirection chose is restated beneath it.
      localized = Localizations(
        locale: const Locale('en'),
        delegates: const [
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        child: Directionality(
          textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
          child: themed,
        ),
      );
    } else {
      localized = Localizations.override(
        context: context,
        delegates: const [DefaultMaterialLocalizations.delegate],
        child: themed,
      );
    }

    if (MediaQuery.maybeOf(context) != null) return localized;
    return MediaQuery.fromView(view: View.of(context), child: localized);
  }
}
