import 'package:equatable/equatable.dart';

/// A per-category budget for a given month, plus an overall monthly cap.
class BudgetModel extends Equatable {
  final String category;
  final String? categoryId;
  final double limit;
  final double spent;
  final String month; // format: yyyy-MM

  const BudgetModel({
    required this.category,
    this.categoryId,
    required this.limit,
    required this.spent,
    required this.month,
  });

  double get remaining => (limit - spent).clamp(0, double.infinity);

  double get progress => limit <= 0 ? 0 : (spent / limit).clamp(0.0, 1.5);

  bool get isOverBudget => spent > limit;

  bool isNearLimit(double warnThreshold) => progress >= warnThreshold && !isOverBudget;

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      categoryId: json['category_id']?.toString(),
      category: json['categories'] != null && json['categories']['name'] != null
          ? json['categories']['name'].toString()
          : (json['category']?.toString() ?? 'Others'),
      limit: double.tryParse(json['limit'].toString()) ?? 0.0,
      spent: double.tryParse(json['spent'].toString()) ?? 0.0,
      month: json['month']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (categoryId != null) 'category_id': categoryId,
      'limit': limit,
      'spent': spent,
      'month': month,
    };
  }

  BudgetModel copyWith({
    String? category,
    String? categoryId,
    double? limit,
    double? spent,
    String? month,
  }) {
    return BudgetModel(
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      limit: limit ?? this.limit,
      spent: spent ?? this.spent,
      month: month ?? this.month,
    );
  }

  @override
  List<Object?> get props => [category, categoryId, limit, spent, month];
}

