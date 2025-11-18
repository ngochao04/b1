import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference cho user cụ thể
  CollectionReference _userTransactions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions');
  }

  // Thêm giao dịch
  Future<void> addTransaction(TransactionModel transaction) async {
    await _userTransactions(transaction.userId).add(transaction.toMap());
  }

  // Cập nhật giao dịch
  Future<void> updateTransaction(TransactionModel transaction) async {
    if (transaction.id == null) return;
    await _userTransactions(transaction.userId)
        .doc(transaction.id)
        .update(transaction.toMap());
  }

  // Xóa giao dịch
  Future<void> deleteTransaction(String userId, String transactionId) async {
    await _userTransactions(userId).doc(transactionId).delete();
  }

  // Stream theo dõi giao dịch
  Stream<List<TransactionModel>> getTransactions(String userId) {
    return _userTransactions(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  // Lấy giao dịch theo khoảng thời gian
  Stream<List<TransactionModel>> getTransactionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _userTransactions(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }
}