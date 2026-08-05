import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Maps a category/source name to a representative icon and accent color.
/// Falls back to a neutral tag icon for anything unrecognized (e.g. a
/// custom category typed by a family member).
class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> _expenseIcons = {
    'Grocery': Icons.shopping_basket_rounded,
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_car_filled_rounded,
    'Medical': Icons.local_hospital_rounded,
    'Utilities': Icons.bolt_rounded,
    'Education': Icons.school_rounded,
    'Entertainment': Icons.movie_filter_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Rent': Icons.home_rounded,
    'Others': Icons.category_rounded,
  };

  static const Map<String, IconData> _incomeIcons = {
    'Salary': Icons.account_balance_wallet_rounded,
    'Business': Icons.storefront_rounded,
    'Freelance': Icons.laptop_mac_rounded,
    'Rental': Icons.apartment_rounded,
    'Interest': Icons.percent_rounded,
    'Gift': Icons.card_giftcard_rounded,
    'Others': Icons.category_rounded,
  };

  static IconData expenseIcon(String category) =>
      _expenseIcons[category] ?? Icons.receipt_long_rounded;

  static IconData incomeIcon(String source) =>
      _incomeIcons[source] ?? Icons.attach_money_rounded;

  static Color colorFor(String key) {
    final index = key.hashCode.abs() % AppColors.categoryPalette.length;
    return AppColors.categoryPalette[index];
  }
}
