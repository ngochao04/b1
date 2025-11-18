import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/transaction_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../transaction/add_transaction_screen.dart';
import '../analytics/analytics_screen.dart';

class HomeScreenSliver extends StatefulWidget {
  final UserModel user;

  const HomeScreenSliver({super.key, required this.user});

  @override
  State<HomeScreenSliver> createState() => _HomeScreenSliverState();
}

class _HomeScreenSliverState extends State<HomeScreenSliver> {
  final _authService = AuthService();
  final _dbService = DatabaseService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Ăn uống':
        return Icons.restaurant;
      case 'Di chuyển':
        return Icons.directions_car;
      case 'Mua sắm':
        return Icons.shopping_bag;
      case 'Giải trí':
        return Icons.movie;
      case 'Hóa đơn':
        return Icons.receipt;
      case 'Sức khỏe':
        return Icons.local_hospital;
      case 'Giáo dục':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Ăn uống':
        return Colors.orange;
      case 'Di chuyển':
        return Colors.blue;
      case 'Mua sắm':
        return Colors.purple;
      case 'Giải trí':
        return Colors.pink;
      case 'Hóa đơn':
        return Colors.red;
      case 'Sức khỏe':
        return Colors.green;
      case 'Giáo dục':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Future<void> _deleteTransaction(String transactionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa giao dịch này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dbService.deleteTransaction(widget.user.uid, transactionId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa giao dịch'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<TransactionModel>>(
        stream: _dbService.getTransactions(widget.user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${snapshot.error}'),
                ],
              ),
            );
          }

          final transactions = snapshot.data ?? [];
          final totalAmount = transactions.fold<double>(
            0,
            (sum, transaction) => sum + transaction.amount,
          );

          // Nhóm giao dịch theo ngày
          Map<String, List<TransactionModel>> groupedTransactions = {};
          for (var transaction in transactions) {
            final dateKey = DateFormat('dd/MM/yyyy').format(transaction.date);
            if (!groupedTransactions.containsKey(dateKey)) {
              groupedTransactions[dateKey] = [];
            }
            groupedTransactions[dateKey]!.add(transaction);
          }

          return CustomScrollView(
            slivers: [
              // App Bar với hiệu ứng mở rộng
              SliverAppBar(
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Quản lý Chi tiêu',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade600,
                          Colors.blue.shade800,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          const Text(
                            'Tổng chi tiêu',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currencyFormat.format(totalAmount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${transactions.length} giao dịch',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.bar_chart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnalyticsScreen(
                            userId: widget.user.uid,
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Xác nhận'),
                          content: const Text('Bạn có chắc muốn đăng xuất?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Đăng xuất'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _authService.signOut();
                      }
                    },
                  ),
                ],
              ),

              // Nội dung chính
              if (transactions.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 100,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có giao dịch nào',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nhấn nút + để thêm giao dịch đầu tiên',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...groupedTransactions.entries.map((entry) {
                  final dateKey = entry.key;
                  final dayTransactions = entry.value;
                  final dayTotal = dayTransactions.fold<double>(
                    0,
                    (sum, t) => sum + t.amount,
                  );

                  return SliverMainAxisGroup(
                    slivers: [
                      // Header ngày
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _DateHeaderDelegate(
                          date: dateKey,
                          total: _currencyFormat.format(dayTotal),
                          minHeight: 50,
                          maxHeight: 50,
                        ),
                      ),
                      // Danh sách giao dịch trong ngày
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final transaction = dayTransactions[index];
                              final color = _getCategoryColor(
                                transaction.category,
                              );

                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(transaction.category),
                                      color: color,
                                    ),
                                  ),
                                  title: Text(
                                    transaction.description,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    transaction.category,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 13,
                                    ),
                                  ),
                                  trailing: Text(
                                    _currencyFormat.format(transaction.amount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddTransactionScreen(
                                          userId: widget.user.uid,
                                          transaction: transaction,
                                        ),
                                      ),
                                    );
                                  },
                                  onLongPress: () {
                                    _deleteTransaction(transaction.id!);
                                  },
                                ),
                              );
                            },
                            childCount: dayTransactions.length,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),

              // Khoảng trống cuối
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 80),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(
                userId: widget.user.uid,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm'),
      ),
    );
  }
}

// Delegate cho header ngày
class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String date;
  final String total;
  final double minHeight;
  final double maxHeight;

  _DateHeaderDelegate({
    required this.date,
    required this.total,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            date,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            total,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_DateHeaderDelegate oldDelegate) {
    return date != oldDelegate.date || total != oldDelegate.total;
  }
}