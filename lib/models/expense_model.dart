import 'package:equatable/equatable.dart';
import '../core/constants/app_constants.dart';
/// Represents a single expense entry, mirroring one row in the
/// "Expenses" Google Sheet.
class ExpenseModel extends Equatable {
  final String id;
  final String member;
  final String category;
  final String description;
  final double amount;
  final String paymentMode;
  final DateTime date;
  final String time;
  final String remarks;
  final DateTime createdAt;

  const ExpenseModel({
    required this.id,
    required this.member,
    required this.category,
    required this.description,
    required this.amount,
    required this.paymentMode,
    required this.date,
    required this.time,
    required this.remarks,
    required this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    // Backend GET returns PascalCase; POST body uses camelCase.
    // We handle both so fromJson works for both API responses and local cache.
    final id = (json['ExpenseID'] ?? json['id'] ?? '').toString();
    final rawMember = json['Paid By'] ?? json['PaidBy'] ?? json['paidBy'] ?? json['Member'] ?? json['MemberName'] ?? json['member'] ?? '';
    final memberStr = rawMember.toString().trim();
    
    String resolvedMember = memberStr;
    
    // Check if it's a numeric ID
    final memberId = int.tryParse(memberStr);
    if (memberId != null && memberId >= 0 && memberId < AppConstants.familyMembers.length) {
      resolvedMember = AppConstants.familyMembers[memberId];
    } else {
      // Case-insensitive match against known members
      for (final m in AppConstants.familyMembers) {
        if (m.toLowerCase() == memberStr.toLowerCase()) {
          resolvedMember = m;
          break;
        }
      }
    }
    
    final member = memberStr.isEmpty ? 'Unknown' : resolvedMember;
    final category = (json['Category'] ?? json['category'] ?? 'Others').toString();
    final description = (json['Description'] ?? json['description'] ?? '').toString();
    final amount = double.tryParse((json['Amount'] ?? json['amount'] ?? 0).toString()) ?? 0.0;
    final paymentMode = (json['PaymentMode'] ?? json['Payment Mode'] ?? json['paymentMode'] ?? 'Cash').toString();
    final dateStr = (json['Date'] ?? json['date'] ?? '').toString();
    final time = (json['Time'] ?? json['time'] ?? '').toString();
    final remarks = (json['Remarks'] ?? json['remarks'] ?? '').toString();
    final createdAtStr = (json['CreatedAt'] ?? json['createdAt'] ?? '').toString();

    return ExpenseModel(
      id: id,
      member: member,
      category: category,
      description: description,
      amount: amount,
      paymentMode: paymentMode,
      date: DateTime.tryParse(dateStr) ?? DateTime.now(),
      time: time,
      remarks: remarks,
      createdAt: DateTime.tryParse(createdAtStr) ?? DateTime.now(),
    );
  }

  /// toJson() sends PascalCase keys as required by the GAS backend.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'Member': member,
      'Category': category,
      'Description': description,
      'Amount': amount,
      'Payment Mode': paymentMode,
      'Date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'Time': time,
      'Remarks': remarks,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? member,
    String? category,
    String? description,
    double? amount,
    String? paymentMode,
    DateTime? date,
    String? time,
    String? remarks,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      member: member ?? this.member,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      date: date ?? this.date,
      time: time ?? this.time,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, member, category, description, amount, paymentMode, date, time, remarks];
}

