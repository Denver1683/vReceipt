import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:vreceipt_customer/models/statistics_model.dart';

class MonthlyStats extends StatelessWidget {
  final List<charts.Series<ChartData, String>> seriesPieData;
  final double totalSpending;
  final String selectedYear;
  final Map<String, double> monthlySpending;

  const MonthlyStats({
    super.key,
    required this.seriesPieData,
    required this.totalSpending,
    required this.selectedYear,
    required this.monthlySpending, // Add this
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const Text(
            'Spending by Month',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: seriesPieData.isNotEmpty
                ? charts.PieChart<String>(
                    seriesPieData,
                    animate: true,
                    animationDuration: const Duration(seconds: 1),
                    behaviors: [
                      charts.DatumLegend(
                        outsideJustification:
                            charts.OutsideJustification.endDrawArea,
                        horizontalFirst: false,
                        desiredMaxRows: 2,
                        cellPadding:
                            const EdgeInsets.only(right: 4.0, bottom: 4.0),
                        entryTextStyle: charts.TextStyleSpec(
                          color: charts.MaterialPalette.purple.shadeDefault,
                          fontFamily: 'Georgia',
                          fontSize: 11,
                        ),
                      )
                    ],
                    defaultRenderer: charts.ArcRendererConfig<String>(
                      arcWidth: 100,
                      arcRendererDecorators: [
                        charts.ArcLabelDecorator<String>(
                          labelPosition: charts.ArcLabelPosition.inside,
                        )
                      ],
                    ),
                  )
                : const Center(child: Text('No data available')),
          ),
          const SizedBox(height: 20),
          Column(
            children: monthlySpending.entries
                .where((entry) =>
                    entry.value > 0) // Only display months with spending
                .map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                          '${entry.key}: RM ${entry.value.toStringAsFixed(2)}'),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          Text('Total: RM $totalSpending ($selectedYear)'),
        ],
      ),
    );
  }
}
