import 'package:flutter/material.dart';
import 'package:my_app/core/ui/app_theme.dart';

/// Adaptive card widget that adjusts its width based on screen size
class AdaptiveCard extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const AdaptiveCard({
    super.key,
    required this.child,
    this.maxWidth = 600,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        margin: margin ?? EdgeInsets.all(context.spacing.md),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: padding ?? EdgeInsets.all(context.spacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}