import 'package:flutter/material.dart';

/// Утилита для генерации стабильных цветов на основе текста
///
/// Генерирует цвет используя хеш строки, что гарантирует:
/// - Одна и та же строка всегда даёт один цвет
/// - Разные строки дают разные цвета
/// - Цвета визуально приятные (HSL с фиксированными saturation/lightness)
class ColorGenerator {
  ColorGenerator._();

  /// Генерирует стабильный цвет на основе строки
  ///
  /// Использует хеш строки для генерации hue (0-360),
  /// saturation и lightness фиксированы для приятных цветов.
  ///
  /// Примеры:
  /// ```dart
  /// ColorGenerator.generateColor('Кассир'); // Всегда один цвет
  /// ColorGenerator.generateColor('Повар'); // Другой цвет
  /// ```
  static Color generateColor(String text) {
    if (text.isEmpty) return Colors.grey;

    // Хеш строки (берём абсолютное значение для положительного числа)
    int hash = text.hashCode.abs();

    // Генерация hue (0-360) из хеша
    double hue = (hash % 360).toDouble();

    // Фиксированные saturation и lightness для приятных, насыщенных цветов
    const double saturation = 0.65;
    const double lightness = 0.50;

    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }

  /// Генерирует Map цветов для списка должностей
  ///
  /// Полезно для создания color mapping'а для легенды.
  ///
  /// Пример:
  /// ```dart
  /// final colors = ColorGenerator.generateColorMap(['Кассир', 'Повар']);
  /// // {'Кассир': Color(...), 'Повар': Color(...)}
  /// ```
  static Map<String, Color> generateColorMap(List<String> positions) {
    return {
      for (final position in positions) position: generateColor(position)
    };
  }
}
