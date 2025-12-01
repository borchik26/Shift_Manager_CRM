import 'package:flutter/material.dart';

@immutable
class CustomDurations extends ThemeExtension<CustomDurations> {
  final Duration duration75;
  final Duration duration100;
  final Duration duration150;
  final Duration duration200;
  final Duration duration300;
  final Duration duration500;
  final Duration duration700;
  final Duration duration1000;

  const CustomDurations({
    this.duration75 = const Duration(milliseconds: 75),
    this.duration100 = const Duration(milliseconds: 100),
    this.duration150 = const Duration(milliseconds: 150),
    this.duration200 = const Duration(milliseconds: 200),
    this.duration300 = const Duration(milliseconds: 300),
    this.duration500 = const Duration(milliseconds: 500),
    this.duration700 = const Duration(milliseconds: 700),
    this.duration1000 = const Duration(milliseconds: 1000),
  });

  @override
  CustomDurations copyWith({
    Duration? duration75,
    Duration? duration100,
    Duration? duration150,
    Duration? duration200,
    Duration? duration300,
    Duration? duration500,
    Duration? duration700,
    Duration? duration1000,
  }) {
    return CustomDurations(
      duration75: duration75 ?? this.duration75,
      duration100: duration100 ?? this.duration100,
      duration150: duration150 ?? this.duration150,
      duration200: duration200 ?? this.duration200,
      duration300: duration300 ?? this.duration300,
      duration500: duration500 ?? this.duration500,
      duration700: duration700 ?? this.duration700,
      duration1000: duration1000 ?? this.duration1000,
    );
  }

  @override
  CustomDurations lerp(ThemeExtension<CustomDurations>? other, double t) {
    if (other is! CustomDurations) return this;
    return CustomDurations(
      duration75: other.duration75,
      duration100: other.duration100,
      duration150: other.duration150,
      duration200: other.duration200,
      duration300: other.duration300,
      duration500: other.duration500,
      duration700: other.duration700,
      duration1000: other.duration1000,
    );
  }
}
