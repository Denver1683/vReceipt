import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:vreceipt_merchant/statistics/customer_ranking.dart';
import 'package:vreceipt_merchant/statistics/monthly_sales.dart';
import 'package:vreceipt_merchant/statistics/product_ranking.dart';
import 'package:vreceipt_merchant/models/statistics_model.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final PageController _pageController = PageController();
  List<charts.Series<ChartData, String>> _seriesTimeData = [];
  int totalIncome = 0;
  List<String> _years = [];
  String _selectedYear = DateTime.now().year.toString();
  Map<String, int> productIncome = {};
  Map<String, int> customerSpending = {};
  Map<String, int> monthlySpending =
      {}; // Add this map to store monthly spending

  @override
  void initState() {
    super.initState();
    _fetchYears();
  }

  _fetchYears() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Merchant')
          .doc(user.email)
          .collection('TrHistory')
          .where('void', isEqualTo: false)
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
          .collection('Merchant')
          .doc(user.email)
          .collection('TrHistory')
          .get();

      if (snapshot.docs.isNotEmpty) {
        List<ChartData> monthlyData = [];
        Map<String, int> monthlyIncome = {
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

        productIncome.clear();
        customerSpending.clear();
        monthlySpending.clear(); // Clear the map

        for (var doc in snapshot.docs) {
          if (doc.exists && doc.data() is Map) {
            Map<String, dynamic>? transactionData =
                doc.data() as Map<String, dynamic>?;
            if (transactionData != null &&
                transactionData.containsKey('trdate') &&
                transactionData.containsKey('total') &&
                transactionData.containsKey('prodname') &&
                transactionData.containsKey('uid') &&
                transactionData.containsKey('qty') &&
                transactionData.containsKey('prodprice') &&
                transactionData.containsKey('void')) {
              if (transactionData['void'] == false) {
                // Only process non-void transactions
                DateTime date = DateTime.parse(transactionData['trdate']);
                if (date.year.toString() == _selectedYear) {
                  double total = double.tryParse(transactionData['total']) ?? 0;
                  if (total > 0) {
                    // Ensure total is positive
                    totalIncome += total.toInt();
                    String month = _getMonthString(date.month);
                    if (monthlyIncome.containsKey(month)) {
                      monthlyIncome[month] =
                          monthlyIncome[month]! + total.toInt();
                      monthlySpending[month] = monthlyIncome[
                          month]!; // Update the monthlySpending map
                    }

                    // Handle product income
                    List products = transactionData['prodname'];
                    List quantities = transactionData['qty'];
                    List prices = transactionData['prodprice'];
                    for (int i = 0; i < products.length; i++) {
                      String product = products[i];
                      int quantity = quantities[i];
                      double price = double.tryParse(prices[i]) ?? 0;
                      int subtotal = (price * quantity).toInt();
                      if (productIncome.containsKey(product)) {
                        productIncome[product] =
                            productIncome[product]! + subtotal;
                      } else {
                        productIncome[product] = subtotal;
                      }
                    }

                    // Handle customer spending
                    String uid = transactionData['uid'].toString();
                    if (uid != '0') {
                      // Exclude customer with uid 0
                      if (customerSpending.containsKey(uid)) {
                        customerSpending[uid] =
                            customerSpending[uid]! + total.toInt();
                      } else {
                        customerSpending[uid] = total.toInt();
                      }
                    }
                  }
                }
              }
            }
          }
        }

        if (totalIncome == 0) {
          totalIncome = 1; // To avoid division by zero
        }

        monthlyIncome.forEach((month, income) {
          monthlyData.add(ChartData(month, income));
        });

        // Sort customer spending
        customerSpending = Map.fromEntries(
          customerSpending.entries.toList()
            ..sort((e1, e2) => e2.value.compareTo(e1.value)),
        );

        setState(() {
          _seriesTimeData = [
            charts.Series<ChartData, String>(
              id: 'Income',
              domainFn: (ChartData data, _) => data.month,
              measureFn: (ChartData data, _) => data.spending,
              data: monthlyData,
              labelAccessorFn: (ChartData row, _) =>
                  '${row.month}: RM${row.spending}',
            ),
          ];
        });
      } else {
        setState(() {
          _seriesTimeData = [];
          totalIncome = 0;
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

  Future<String> _fetchCustomerName(String uid) async {
    try {
      final DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('Customer')
          .where('uid', isEqualTo: int.parse(uid))
          .limit(1)
          .get()
          .then((snapshot) => snapshot.docs.first);

      return customerDoc['name'] ?? 'Unknown Customer';
    } catch (e) {
      return 'Unknown Customer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              children: [
                TimeStatsPage(
                  seriesTimeData: _seriesTimeData,
                  totalIncome: totalIncome,
                  selectedYear: _selectedYear,
                  monthlySpending: monthlySpending, // Pass the map here
                ),
                ProductStatsPage(
                  productIncomeFuture: _fetchProductIncome(),
                ),
                CustomerRankingPage(
                  customerSpendingFuture: _fetchCustomerSpending(),
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
                  child: DropdownButton<String>(
                    value: _selectedYear,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedYear = newValue!;
                        totalIncome = 0; // Reset total income
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

  Future<List<ProductIncome>> _fetchProductIncome() async {
    List<ProductIncome> productData = [];
    productIncome.forEach((product, income) {
      productData.add(ProductIncome(product, income));
    });
    productData.sort((a, b) => b.income.compareTo(a.income));
    return productData;
  }

  Future<List<CustomerSpending>> _fetchCustomerSpending() async {
    List<CustomerSpending> customerData = [];
    for (var entry in customerSpending.entries) {
      String name = await _fetchCustomerName(entry.key);
      customerData.add(CustomerSpending(entry.key, name, entry.value));
    }
    customerData.sort((a, b) => b.spending.compareTo(a.spending));
    return customerData;
  }
}
