import 'package:flutter/material.dart';
import '../utils/category_icons.dart';

/// A circular initials avatar for a family member, colored consistently
/// per-member using the same hashing approach as category colors.
class MemberAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const MemberAvatar({super.key, required this.name, this.radius = 22});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = CategoryIcons.colorFor(name);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withOpacity(0.15),
      child: Text(
        _initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.65,
        ),
      ),
    );
  }
}
