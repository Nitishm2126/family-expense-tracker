import 'package:equatable/equatable.dart';

/// Represents a single income entry, mirroring one row in the
/// "Income" Google Sheet.
class IncomeModel extends Equatable {
  final String id;
  final String? familyId;
  final String? memberId;
  final String receivedBy;
  final String source;
  final String description;
  final double amount;
  final DateTime date;
  final DateTime createdAt;

  const IncomeModel({
    required this.id,
    this.familyId,
    this.memberId,
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
      familyId: json['family_id']?.toString(),
      memberId: json['member_id']?.toString(),
      receivedBy: json['members'] != null && json['members']['name'] != null 
          ? json['members']['name'].toString() 
          : receivedBy,
      source: source,
      description: description,
      amount: amount,
      date: DateTime.tryParse(dateStr) ?? DateTime.now(),
      createdAt: DateTime.tryParse(createdAtStr) ?? DateTime.now(),
    );
  }

  /// toJson for Supabase
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (familyId != null) 'family_id': familyId,
      if (memberId != null) 'member_id': memberId,
      'source': source,
      'description': description,
      'amount': amount,
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    };
  }

  IncomeModel copyWith({
    String? id,
    String? familyId,
    String? memberId,
    String? receivedBy,
    String? source,
    String? description,
    double? amount,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return IncomeModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      memberId: memberId ?? this.memberId,
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
      [id, familyId, memberId, receivedBy, source, description, amount, date];
}

