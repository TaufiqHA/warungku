import 'package:flutter/material.dart';

/// Versi sliver dari [AppCard].
///
/// Dipakai bila isi kartu adalah daftar panjang: dengan `DecoratedSliver` +
/// `SliverList` hanya baris yang terlihat yang dibangun, berbeda dari
/// `ListView(shrinkWrap: true, physics: NeverScrollableScrollPhysics())` yang
/// membangun seluruh baris sekaligus.
class AppSliverCard extends StatelessWidget {
  /// Isi kartu berupa sliver, biasanya `SliverList` / `SliverList.separated`.
  final Widget sliver;

  /// Padding di dalam bingkai kartu (mis. `EdgeInsets.symmetric(vertical: 4)`).
  final EdgeInsetsGeometry innerPadding;

  /// Jarak kartu terhadap tepi layar.
  final EdgeInsetsGeometry outerPadding;

  final Color? backgroundColor;
  final double borderRadius;

  const AppSliverCard({
    super.key,
    required this.sliver,
    this.innerPadding = EdgeInsets.zero,
    this.outerPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.backgroundColor,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = sliver;
    if (innerPadding != EdgeInsets.zero) {
      content = SliverPadding(padding: innerPadding, sliver: content);
    }

    return SliverPadding(
      padding: outerPadding,
      sliver: DecoratedSliver(
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        sliver: content,
      ),
    );
  }
}
