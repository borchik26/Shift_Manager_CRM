import 'package:flutter/material.dart';

/// Employee avatar widget with fallback to initials
class EmployeeAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fullName;
  final double size;

  const EmployeeAvatar({
    super.key,
    this.imageUrl,
    required this.fullName,
    this.size = 40,
  });

  String _getInitials() {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _getColorFromName() {
    final hash = fullName.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl!),
        onBackgroundImageError: (_, __) {},
        child: Container(), // Fallback if image fails
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _getColorFromName(),
      child: Text(
        _getInitials(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size / 2.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}