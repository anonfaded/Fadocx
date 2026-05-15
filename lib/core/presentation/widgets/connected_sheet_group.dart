import 'package:flutter/material.dart';

class ConnectedSheetGroup extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double dividerIndent;

  const ConnectedSheetGroup({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.padding,
    this.radius = 12,
    this.dividerIndent = 56,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shellColor = colorScheme.surfaceContainerLow.withValues(alpha: 0.96);
    final shellBorderColor = colorScheme.outlineVariant.withValues(alpha: 0.42);

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          Divider(
            height: 1,
            indent: dividerIndent,
            color: colorScheme.outlineVariant.withValues(alpha: 0.48),
          ),
        );
      }
      rows.add(children[i]);
    }

    return Padding(
      padding: margin,
      child: Container(
        decoration: BoxDecoration(
          color: shellColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: shellBorderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: rows,
            ),
          ),
        ),
      ),
    );
  }
}

class ConnectedSheetRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final Widget? detail;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? titleColor;
  final Color? detailColor;
  final TextStyle? titleStyle;
  final TextStyle? detailStyle;
  final bool centerContent;

  const ConnectedSheetRow({
    super.key,
    required this.leading,
    required this.title,
    this.detail,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.titleColor,
    this.detailColor,
    this.titleStyle,
    this.detailStyle,
    this.centerContent = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget content = Padding(
      padding: padding,
      child: Row(
        children: [
          leading,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: centerContent
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: centerContent ? TextAlign.center : TextAlign.start,
                  style: titleStyle ??
                      textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  DefaultTextStyle.merge(
                    style: detailStyle ??
                        textTheme.bodySmall?.copyWith(
                          color: detailColor ??
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    child: detail!,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class SheetIconChip extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final Color color;
  final Color backgroundColor;
  final double size;

  const SheetIconChip.icon({
    super.key,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.size = 36,
  }) : emoji = null;

  const SheetIconChip.emoji({
    super.key,
    required this.emoji,
    required this.backgroundColor,
    this.size = 36,
  })  : icon = null,
        color = Colors.transparent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, size: size * 0.5, color: color)
          : Text(emoji!, style: TextStyle(fontSize: size * 0.55)),
    );
  }
}
