import 'package:flutter/material.dart';
import 'package:vreceipt_merchant/models/statistics_model.dart';

class CustomerRankingPage extends StatelessWidget {
  final Future<List<CustomerSpending>> customerSpendingFuture;

  const CustomerRankingPage({super.key, required this.customerSpendingFuture});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Text(
              'Customer Spending Ranking',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<CustomerSpending>>(
                future: customerSpendingFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error fetching customer data'));
                  }

                  List<CustomerSpending> customerData = snapshot.data ?? [];

                  if (customerData.isEmpty) {
                    return const Center(child: Text('No data available'));
                  }

                  return ListView.builder(
                    itemCount: customerData.length,
                    itemBuilder: (context, index) {
                      final customer = customerData[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ListTile(
                            title: Text(
                              '${index + 1}. ${customer.name}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: Text(
                              'RM ${customer.spending}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
