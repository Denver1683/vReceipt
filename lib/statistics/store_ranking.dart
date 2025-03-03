import 'package:flutter/material.dart';
import 'package:vreceipt_customer/models/statistics_model.dart';

class StoreRanking extends StatelessWidget {
  final Future<List<StoreSpending>> storeDataFuture;

  const StoreRanking({super.key, required this.storeDataFuture});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const Text(
            'Spending Ranking by Store',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<StoreSpending>>(
              future: storeDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error fetching store data'));
                }

                List<StoreSpending> storeData = snapshot.data ?? [];

                if (storeData.isEmpty) {
                  return const Center(child: Text('No data available'));
                }

                return ListView.builder(
                  itemCount: storeData.length,
                  itemBuilder: (context, index) {
                    final store = storeData[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: ListTile(
                        leading: Text(
                          '${index + 1}.',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        title: Text(
                          store.storeName,
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: Text(
                          'RM ${store.spending}',
                          style: const TextStyle(color: Colors.white),
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
    );
  }
}
