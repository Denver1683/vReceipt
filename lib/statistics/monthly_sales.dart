import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:vreceipt_merchant/models/statistics_model.dart';

class TimeStatsPage extends StatelessWidget {
  final List<charts.Series<ChartData, String>> seriesTimeData;
  final int totalIncome;
  final String selectedYear;
  final Map<String, int> monthlySpending; // Map to hold spending by month

  const TimeStatsPage({
    super.key,
    required this.seriesTimeData,
    required this.totalIncome,
    required this.selectedYear,
    required this.monthlySpending, // Initialize it in the constructor
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Text(
              'Monthly Sales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: seriesTimeData.isNotEmpty
                  ? charts.PieChart<String>(
                      seriesTimeData,
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
            Text('Total: RM $totalIncome ($selectedYear)'),
            const SizedBox(height: 10),
            Column(
              children: monthlySpending.entries.map((entry) {
                final month = entry.key;
                final spending = entry.value;
                return spending > 0
                    ? Text('$month Spending: RM $spending')
                    : const SizedBox.shrink();
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
