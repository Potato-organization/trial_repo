import 'package:flutter/material.dart';

class ChaosColors {
  ChaosColors._();

  static const Color background = Color(0xFF101216);
  static const Color panel = Color(0xFF181B21);
  static const Color panelHigh = Color(0xFF20242C);
  static const Color panelPressed = Color(0xFF272C35);
  static const Color border = Color(0xFF303642);
  static const Color borderStrong = Color(0xFF46505E);
  static const Color text = Color(0xFFF4F1EA);
  static const Color muted = Color(0xFF9BA1AA);
  static const Color faint = Color(0xFF646B76);
  static const Color blue = Color(0xFF4D8DFF);
  static const Color green = Color(0xFF3BC981);
  static const Color coral = Color(0xFFFF6B5F);
}

class ChaosRadii {
  ChaosRadii._();

  static const double card = 24;
  static const double tile = 20;
  static const double button = 999;
}

class ChaosDecorations {
  ChaosDecorations._();

  static BoxDecoration panel({
    Color? color,
    Color? borderColor,
    double? radius,
  }) {
    return BoxDecoration(
      color: color ?? ChaosColors.panel,
      borderRadius: BorderRadius.circular(radius ?? ChaosRadii.card),
      border: Border.all(color: borderColor ?? ChaosColors.border),
    );
  }

  static BoxDecoration selectedPanel(Color accent, {double? radius}) {
    return BoxDecoration(
      color: Color.alphaBlend(
        accent.withValues(alpha: 0.12),
        ChaosColors.panel,
      ),
      borderRadius: BorderRadius.circular(radius ?? ChaosRadii.tile),
      border: Border.all(color: accent.withValues(alpha: 0.7)),
    );
  }
}
