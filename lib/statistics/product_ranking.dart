import 'package:flutter/material.dart';
import 'package:vreceipt_merchant/models/statistics_model.dart';

class ProductStatsPage extends StatelessWidget {
  final Future<List<ProductIncome>> productIncomeFuture;

  const ProductStatsPage({super.key, required this.productIncomeFuture});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Text(
              'Product Sales Ranking',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<ProductIncome>>(
                future: productIncomeFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error fetching product data'));
                  }

                  List<ProductIncome> productData = snapshot.data ?? [];

                  if (productData.isEmpty) {
                    return const Center(child: Text('No data available'));
                  }

                  return ListView.builder(
                    itemCount: productData.length,
                    itemBuilder: (context, index) {
                      final product = productData[index];
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
                              '${index + 1}. ${product.productName}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: Text(
                              'RM ${product.income}',
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
