import 'package:flutter/material.dart';
import 'dart:math' as math;

class SpendingTrendChart extends StatelessWidget {
  final List<DailySpending> data;
  final Color lineColor;
  final Color gradientStartColor;
  final Color gradientEndColor;

  const SpendingTrendChart({
    super.key,
    required this.data,
    this.lineColor = Colors.blue,
    this.gradientStartColor = Colors.blue,
    this.gradientEndColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu'),
      );
    }

    return CustomPaint(
      painter: _SpendingTrendPainter(
        data: data,
        lineColor: lineColor,
        gradientStartColor: gradientStartColor,
        gradientEndColor: gradientEndColor,
      ),
      child: Container(),
    );
  }
}

class DailySpending {
  final DateTime date;
  final double amount;

  DailySpending({
    required this.date,
    required this.amount,
  });
}

class _SpendingTrendPainter extends CustomPainter {
  final List<DailySpending> data;
  final Color lineColor;
  final Color gradientStartColor;
  final Color gradientEndColor;

  _SpendingTrendPainter({
    required this.data,
    required this.lineColor,
    required this.gradientStartColor,
    required this.gradientEndColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxAmount = data.map((e) => e.amount).reduce(math.max);
    final minAmount = data.map((e) => e.amount).reduce(math.min);
    final amountRange = maxAmount - minAmount;

    const padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    _drawGrid(canvas, size, padding, chartWidth, chartHeight);
    _drawAxes(canvas, size, padding, chartWidth, chartHeight);
    _drawLabels(canvas, size, padding, chartWidth, chartHeight, maxAmount, minAmount);

    final linePath = Path();
    final gradientPath = Path();
    
    final firstX = padding;
    final firstY = padding + chartHeight - 
        ((data[0].amount - minAmount) / amountRange * chartHeight);
    
    linePath.moveTo(firstX, firstY);
    gradientPath.moveTo(firstX, size.height - padding);
    gradientPath.lineTo(firstX, firstY);

    for (int i = 0; i < data.length; i++) {
      final x = padding + (i / (data.length - 1)) * chartWidth;
      final y = padding + chartHeight - 
          ((data[i].amount - minAmount) / amountRange * chartHeight);
      
      linePath.lineTo(x, y);
      gradientPath.lineTo(x, y);
    }

    gradientPath.lineTo(padding + chartWidth, size.height - padding);
    gradientPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          gradientStartColor.withOpacity(0.3),
          gradientEndColor,
        ],
      ).createShader(
        Rect.fromLTWH(padding, padding, chartWidth, chartHeight),
      );
    canvas.drawPath(gradientPath, gradientPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    for (int i = 0; i < data.length; i++) {
      final x = padding + (i / (data.length - 1)) * chartWidth;
      final y = padding + chartHeight - 
          ((data[i].amount - minAmount) / amountRange * chartHeight);
      
      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
      
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawGrid(Canvas canvas, Size size, double padding, double chartWidth, double chartHeight) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = padding + (i / 4) * chartHeight;
      canvas.drawLine(
        Offset(padding, y),
        Offset(padding + chartWidth, y),
        gridPaint,
      );
    }

    for (int i = 0; i < data.length; i++) {
      final x = padding + (i / (data.length - 1)) * chartWidth;
      canvas.drawLine(
        Offset(x, padding),
        Offset(x, padding + chartHeight),
        gridPaint,
      );
    }
  }

  void _drawAxes(Canvas canvas, Size size, double padding, double chartWidth, double chartHeight) {
    final axesPaint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, padding + chartHeight),
      axesPaint,
    );

    canvas.drawLine(
      Offset(padding, padding + chartHeight),
      Offset(padding + chartWidth, padding + chartHeight),
      axesPaint,
    );
  }

  void _drawLabels(Canvas canvas, Size size, double padding, double chartWidth, 
      double chartHeight, double maxAmount, double minAmount) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    for (int i = 0; i <= 4; i++) {
      final amount = minAmount + (maxAmount - minAmount) * (4 - i) / 4;
      final y = padding + (i / 4) * chartHeight;

      textPainter.text = TextSpan(
        text: _formatAmount(amount),
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(padding - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    final displayIndices = _getDisplayIndices(data.length);
    for (final i in displayIndices) {
      final x = padding + (i / (data.length - 1)) * chartWidth;
      final date = data[i].date;

      textPainter.text = TextSpan(
        text: '${date.day}/${date.month}',
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 10,
        ),
      );
      textPainter.textAlign = TextAlign.center;
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, padding + chartHeight + 8),
      );
    }
  }

  List<int> _getDisplayIndices(int dataLength) {
    if (dataLength <= 7) {
      return List.generate(dataLength, (i) => i);
    } else {
      final step = (dataLength - 1) / 4;
      return [
        0,
        (step * 1).round(),
        (step * 2).round(),
        (step * 3).round(),
        dataLength - 1,
      ];
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(_SpendingTrendPainter oldDelegate) {
    return data != oldDelegate.data ||
        lineColor != oldDelegate.lineColor ||
        gradientStartColor != oldDelegate.gradientStartColor ||
        gradientEndColor != oldDelegate.gradientEndColor;
  }
}