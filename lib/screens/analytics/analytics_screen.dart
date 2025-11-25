import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../services/database_service.dart';
import '../../widgets/spending_trend_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  final String userId;

  const AnalyticsScreen({super.key, required this.userId});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _dbService = DatabaseService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  
  String _selectedPeriod = '30_days';
  int _touchedIndex = -1;
  bool _showCustomChart = false;

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case '7_days':
        return now.subtract(const Duration(days: 7));
      case '30_days':
        return now.subtract(const Duration(days: 30));
      case '90_days':
        return now.subtract(const Duration(days: 90));
      default:
        return now.subtract(const Duration(days: 30));
    }
  }

  Map<String, double> _calculateCategoryTotals(List<TransactionModel> transactions) {
    Map<String, double> totals = {};
    for (var transaction in transactions) {
      totals[transaction.category] = 
          (totals[transaction.category] ?? 0) + transaction.amount;
    }
    return totals;
  }

  List<DailySpending> _calculateDailySpending(List<TransactionModel> transactions) {
    Map<String, double> dailyTotals = {};
    
    for (var transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + transaction.amount;
    }

    final sortedDates = dailyTotals.keys.toList()..sort();
    
    return sortedDates.map((dateKey) {
      return DailySpending(
        date: DateTime.parse(dateKey),
        amount: dailyTotals[dateKey]!,
      );
    }).toList();
  }

  Color _getCategoryColor(String category, int index) {
    const colors = [
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.red,
      Colors.green,
      Colors.indigo,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  List<PieChartSectionData> _getPieChartSections(
    Map<String, double> categoryTotals,
    double totalAmount,
  ) {
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value.key;
      final amount = entry.value.value;
      final percentage = (amount / totalAmount * 100);
      final isTouched = index == _touchedIndex;
      final radius = isTouched ? 110.0 : 100.0;
      final fontSize = isTouched ? 18.0 : 14.0;

      return PieChartSectionData(
        color: _getCategoryColor(category, index),
        value: amount,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  List<Widget> _buildCategoryDetails(Map<String, double> categoryTotals, double totalAmount) {
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value.key;
      final amount = entry.value.value;
      final percentage = (amount / totalAmount * 100);
      final color = _getCategoryColor(category, index);

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 12,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          title: Text(
            category,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currencyFormat.format(amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân tích Chi tiêu'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: '7_days',
                  label: Text('7 ngày'),
                ),
                ButtonSegment(
                  value: '30_days',
                  label: Text('30 ngày'),
                ),
                ButtonSegment(
                  value: '90_days',
                  label: Text('90 ngày'),
                ),
              ],
              selected: {_selectedPeriod},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedPeriod = newSelection.first;
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _dbService.getTransactionsByDateRange(
                widget.userId,
                _getStartDate(),
                DateTime.now(),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final transactions = snapshot.data ?? [];

                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có dữ liệu',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final categoryTotals = _calculateCategoryTotals(transactions);
                final dailySpending = _calculateDailySpending(transactions);
                final totalAmount = transactions.fold<double>(
                  0,
                  (sum, transaction) => sum + transaction.amount,
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text(
                                'Tổng chi tiêu',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _currencyFormat.format(totalAmount),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${transactions.length} giao dịch',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Xu hướng chi tiêu',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showCustomChart = !_showCustomChart;
                              });
                            },
                            icon: Icon(_showCustomChart 
                              ? Icons.auto_graph 
                              : Icons.brush
                            ),
                            label: Text(_showCustomChart 
                              ? 'FL Chart' 
                              : 'Custom'
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: SizedBox(
                            height: 250,
                            child: _showCustomChart
                                ? SpendingTrendChart(
                                    data: dailySpending,
                                    lineColor: Colors.blue.shade700,
                                    gradientStartColor: Colors.blue.shade700,
                                  )
                                : LineChart(
                                    LineChartData(
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: true,
                                        getDrawingHorizontalLine: (value) {
                                          return FlLine(
                                            color: Colors.grey.shade300,
                                            strokeWidth: 1,
                                          );
                                        },
                                      ),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 30,
                                            getTitlesWidget: (value, meta) {
                                              final index = value.toInt();
                                              if (index < 0 || 
                                                  index >= dailySpending.length) {
                                                return const Text('');
                                              }
                                              final date = dailySpending[index].date;
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text(
                                                  '${date.day}/${date.month}',
                                                  style: const TextStyle(fontSize: 10),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 42,
                                            getTitlesWidget: (value, meta) {
                                              return Text(
                                                _formatAmount(value),
                                                style: const TextStyle(fontSize: 10),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(
                                        show: true,
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      minX: 0,
                                      maxX: (dailySpending.length - 1).toDouble(),
                                      minY: 0,
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: dailySpending
                                              .asMap()
                                              .entries
                                              .map((e) => FlSpot(
                                                    e.key.toDouble(),
                                                    e.value.amount,
                                                  ))
                                              .toList(),
                                          isCurved: true,
                                          color: Colors.blue.shade700,
                                          barWidth: 3,
                                          isStrokeCapRound: true,
                                          dotData: const FlDotData(show: true),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: Colors.blue.shade700.withOpacity(0.2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Chi tiêu theo danh mục',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: AspectRatio(
                            aspectRatio: 1.3,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        _touchedIndex = -1;
                                        return;
                                      }
                                      _touchedIndex = pieTouchResponse
                                          .touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: _getPieChartSections(
                                  categoryTotals,
                                  totalAmount,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Chi tiết theo danh mục',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      ..._buildCategoryDetails(categoryTotals, totalAmount),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}