import 'package:equatable/equatable.dart';

/// Represents a single income entry, mirroring one row in the
/// "Income" Google Sheet.
class IncomeModel extends Equatable {
  final String id;
  final String receivedBy;
  final String source;
  final String description;
  final double amount;
  final DateTime date;
  final DateTime createdAt;

  const IncomeModel({
    required this.id,
    required this.receivedBy,
    required this.source,
    required this.description,
    required this.amount,
    required this.date,
    required this.createdAt,
  });

  factory IncomeModel.fromJson(Map<String, dynamic> json) {
    // Backend GET returns PascalCase; supports both for local cache compat.
    final id = (json['IncomeID'] ?? json['id'] ?? '').toString();
    final receivedBy = (json['MemberName'] ?? json['receivedBy'] ?? json['ReceivedBy'] ?? '').toString();
    final source = (json['Source'] ?? json['source'] ?? 'Others').toString();
    final description = (json['Description'] ?? json['description'] ?? '').toString();
    final amount = double.tryParse((json['Amount'] ?? json['amount'] ?? 0).toString()) ?? 0.0;
    final dateStr = (json['Date'] ?? json['date'] ?? '').toString();
    final createdAtStr = (json['CreatedAt'] ?? json['createdAt'] ?? '').toString();

    return IncomeModel(
      id: id,
      receivedBy: receivedBy,
      source: source,
      description: description,
      amount: amount,
      date: DateTime.tryParse(dateStr) ?? DateTime.now(),
      createdAt: DateTime.tryParse(createdAtStr) ?? DateTime.now(),
    );
  }

  /// toJson sends PascalCase keys as required by the GAS backend.
  /// Income also needs 'Member' and 'Payment Mode' per backend validation.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'Member': receivedBy,
      'Source': source,
      'Description': description,
      'Amount': amount,
      'Date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'Payment Mode': 'N/A',
    };
  }

  IncomeModel copyWith({
    String? id,
    String? receivedBy,
    String? source,
    String? description,
    double? amount,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return IncomeModel(
      id: id ?? this.id,
      receivedBy: receivedBy ?? this.receivedBy,
      source: source ?? this.source,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, receivedBy, source, description, amount, date];
}

