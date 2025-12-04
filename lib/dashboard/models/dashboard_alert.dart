import 'package:flutter/material.dart';

/// Alert type for dashboard notifications
enum AlertType { warning, info, error }

/// Alert model for dashboard
class DashboardAlert {
  final AlertType type;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const DashboardAlert({
    required this.type,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
}

