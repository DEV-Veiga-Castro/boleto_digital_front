import 'package:flutter/material.dart';

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.color,
    this.elevation = 0,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry borderRadius;
  final Color? color;
  final double elevation;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: Material(
      color: color ?? Theme.of(context).colorScheme.surface,
      borderRadius: borderRadius,
      elevation: elevation,
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    ),
  );
}
