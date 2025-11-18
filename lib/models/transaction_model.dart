import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String? id;
  final double amount;
  final String description;
  final String category;
  final DateTime date;
  final String userId;

  TransactionModel({
    this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    required this.userId,
  });

  // Chuyển đổi sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'description': description,
      'category': category,
      'date': Timestamp.fromDate(date),
      'userId': userId,
    };
  }

  // Tạo từ Firestore Document
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      amount: data['amount']?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }
}