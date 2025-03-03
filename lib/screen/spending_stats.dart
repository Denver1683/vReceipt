// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:vreceipt_customer/statistics/category_stats.dart';
import 'package:vreceipt_customer/statistics/monthly_stats.dart';
import 'package:vreceipt_customer/statistics/store_ranking.dart';
import 'package:vreceipt_customer/models/statistics_model.dart'; // Ensure the correct path

class SpendingStatsScreen extends StatefulWidget {
  const SpendingStatsScreen({super.key});

  @override
  _SpendingStatsScreenState createState() => _SpendingStatsScreenState();
}

class _SpendingStatsScreenState extends State<SpendingStatsScreen> {
  final PageController _pageController = PageController();
  List<charts.Series<ChartData, String>> _seriesPieData = [];
  List<charts.Series<CategoryData, String>> _seriesCategoryData = [];
  double totalSpending = 0.00;
  List<String> _years = [];
  String _selectedYear = DateTime.now().year.toString();
  Map<String, double> storeSpending = {};
  Map<String, double> monthlySpending = {}; // To store monthly spending
  Map<String, double> categorySpending = {}; // To store category spending

  @override
  void initState() {
    super.initState();
    _fetchYears();
  }

  _fetchYears() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.email)
          .collection('Transactions')
          .get();

      Set<String> years = {};

      for (var doc in snapshot.docs) {
        if (doc.exists && doc.data() is Map) {
          Map<String, dynamic>? transactionData =
              doc.data() as Map<String, dynamic>?;
          if (transactionData != null &&
              transactionData.containsKey('trdate')) {
            DateTime date = DateTime.parse(transactionData['trdate']);
            years.add(date.year.toString());
          }
        }
      }

      setState(() {
        _years = years.toList()..sort((a, b) => b.compareTo(a));
        _selectedYear =
            _years.isNotEmpty ? _years.first : DateTime.now().year.toString();
        _generateData();
      });
    }
  }

  _generateData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.email)
          .collection('Transactions')
          .get();

      if (snapshot.docs.isNotEmpty) {
        List<ChartData> monthlyData = [];
        List<CategoryData> categoryData = [];
        monthlySpending = {
          'Jan': 0,
          'Feb': 0,
          'Mar': 0,
          'Apr': 0,
          'May': 0,
          'Jun': 0,
          'Jul': 0,
          'Aug': 0,
          'Sep': 0,
          'Oct': 0,
          'Nov': 0,
          'Dec': 0,
        };

        categorySpending.clear();
        storeSpending.clear();

        for (var doc in snapshot.docs) {
          if (doc.exists && doc.data() is Map) {
            Map<String, dynamic>? transactionData =
                doc.data() as Map<String, dynamic>?;
            if (transactionData != null &&
                transactionData.containsKey('trdate') &&
                transactionData.containsKey('total') &&
                transactionData.containsKey('category')) {
              DateTime date = DateTime.parse(transactionData['trdate']);
              if (date.year.toString() == _selectedYear) {
                double total =
                    double.tryParse(transactionData['total'].toString()) ?? 0.0;
                if (total > 0) {
                  // Ensure total is positive
                  totalSpending += total;
                  String month = _getMonthString(date.month);
                  if (monthlySpending.containsKey(month)) {
                    monthlySpending[month] = monthlySpending[month]! + total;
                  }

                  // Handle category spending
                  List categories = transactionData['category'];
                  for (String category in categories) {
                    if (categorySpending.containsKey(category)) {
                      categorySpending[category] =
                          categorySpending[category]! + total;
                    } else {
                      categorySpending[category] = total;
                    }
                  }

                  // Handle store spending
                  String storeId = transactionData['storeid'].toString();
                  if (storeSpending.containsKey(storeId)) {
                    storeSpending[storeId] = storeSpending[storeId]! + total;
                  } else {
                    storeSpending[storeId] = total;
                  }
                }
              }
            }
          }
        }

        if (totalSpending == 0.00) {
          totalSpending = 0.01; // To avoid division by zero
        }

        monthlySpending.forEach((month, spending) {
          monthlyData.add(ChartData(month, spending));
        });

        categorySpending.forEach((category, spending) {
          categoryData.add(CategoryData(category, spending));
        });

        // Sort store spending
        storeSpending = Map.fromEntries(
          storeSpending.entries.toList()
            ..sort((e1, e2) => e2.value.compareTo(e1.value)),
        );

        setState(() {
          _seriesPieData = [
            charts.Series<ChartData, String>(
              id: 'Spending',
              domainFn: (ChartData data, _) => data.month,
              measureFn: (ChartData data, _) => data.spending,
              data: monthlyData,
              labelAccessorFn: (ChartData row, _) =>
                  '${row.month}: RM${row.spending}',
            ),
          ];

          _seriesCategoryData = [
            charts.Series<CategoryData, String>(
              id: 'CategorySpending',
              domainFn: (CategoryData data, _) => data.category,
              measureFn: (CategoryData data, _) => data.spending,
              data: categoryData,
              labelAccessorFn: (CategoryData row, _) =>
                  '${row.category}: RM${row.spending}',
            ),
          ];
        });
      } else {
        setState(() {
          _seriesPieData = [];
          _seriesCategoryData = [];
          totalSpending = 0.00;
        });
      }
    }
  }

  String _getMonthString(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }

  Future<List<StoreSpending>> _fetchStoreSpending() async {
    List<StoreSpending> storeData = [];
    for (var entry in storeSpending.entries) {
      String storeName = await _fetchStoreName(entry.key);
      storeData.add(StoreSpending(storeName, entry.value));
    }
    storeData.sort((a, b) => b.spending.compareTo(a.spending));
    return storeData;
  }

  Future<String> _fetchStoreName(String storeId) async {
    final DocumentSnapshot storeDoc = await FirebaseFirestore.instance
        .collection('Merchant')
        .where('storeid', isEqualTo: storeId)
        .limit(1)
        .get()
        .then((snapshot) => snapshot.docs.first);

    return storeDoc['storename'] ?? 'Unknown Store';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Stats'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              children: [
                MonthlyStats(
                  seriesPieData: _seriesPieData,
                  totalSpending: totalSpending,
                  selectedYear: _selectedYear,
                  monthlySpending: monthlySpending, // Pass the map here
                ),
                CategoryStats(
                  seriesCategoryData: _seriesCategoryData,
                  totalSpending: totalSpending,
                  selectedYear: _selectedYear,
                  categorySpending: categorySpending, // Pass the map here
                ),
                StoreRanking(
                  storeDataFuture: _fetchStoreSpending(),
                ),
              ],
            ),
          ),
          SmoothPageIndicator(
            controller: _pageController,
            count: 3, // Number of pages
            effect: const WormEffect(
              spacing: 8.0,
              radius: 8.0,
              dotWidth: 8.0,
              dotHeight: 8.0,
              activeDotColor: Colors.blue,
              dotColor: Colors.grey,
            ), // Customizable effect
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Year:'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100, // Adjust the width as needed
                  child: DropdownButton<String>(
                    value: _selectedYear,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedYear = newValue!;
                        totalSpending = 0; // Reset total spending
                        _generateData();
                      });
                    },
                    items: _years.map<DropdownMenuItem<String>>((String year) {
                      return DropdownMenuItem<String>(
                        value: year,
                        child: Text(year),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
