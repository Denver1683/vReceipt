import 'package:flutter/material.dart';

class ReceiptWidget extends StatelessWidget {
  final String name;
  final String id;
  final List<String> products;
  final List<int> quantities;
  final List<double> prices;
  final String storeAddress;
  final String storeName;
  final String storeId;
  final double total;
  final String trDate;
  final List<String> warranties;
  final String trid;
  final List<String> categories;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final Future<Map<String, String>> Function(String) fetchStoreDetails;
  final double? subtotal;
  final double? tax;
  final double? serviceCharge;
  final double? taxPercentage;
  final double? serviceChargePercentage;
  final String payBy; // New property for payment method

  const ReceiptWidget({
    super.key,
    required this.name,
    required this.id,
    required this.products,
    required this.quantities,
    required this.prices,
    required this.storeAddress,
    required this.storeName,
    required this.storeId,
    required this.total,
    required this.trDate,
    required this.warranties,
    required this.trid,
    required this.categories,
    required this.onFavoriteToggle,
    required this.onDelete,
    required this.onShare,
    required this.fetchStoreDetails,
    this.subtotal,
    this.tax,
    this.serviceCharge,
    this.taxPercentage,
    this.serviceChargePercentage,
    required this.payBy,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty || prices.isEmpty || quantities.isEmpty) {
      return const Text('No data available');
    }

    return FutureBuilder<Map<String, String>>(
      future: fetchStoreDetails(storeId),
      builder: (context, snapshot) {
        String storeEmail = '';
        String storePhoneNumber = '';
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          storeEmail = snapshot.data!['email'] ?? '';
          storePhoneNumber = snapshot.data!['phoneNumber'] ?? '';
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (storeName.isNotEmpty)
                    Center(
                      child: Text(
                        storeName,
                        style: Theme.of(context).textTheme.headline6,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (storeAddress.isNotEmpty)
                    Center(
                      child: Text(
                        storeAddress,
                        style: Theme.of(context).textTheme.subtitle1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text('Product',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Price(Qty)',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Warranty',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(products[index]),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                                'RM ${prices[index]} x ${quantities[index]}'),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(warranties[index],
                                textAlign: TextAlign.right),
                          ),
                        ],
                      );
                    },
                  ),
                  if (tax! > 0 || serviceCharge! > 0)
                    Column(
                      children: [
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal',
                                style: Theme.of(context).textTheme.bodySmall),
                            Text('RM ${subtotal!.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  if (tax != null && tax! > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tax (${taxPercentage!.toStringAsFixed(2)}%)',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('RM ${tax!.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  if (serviceCharge != null && serviceCharge! > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            'Service Charge (${serviceChargePercentage!.toStringAsFixed(2)}%)',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('RM ${serviceCharge!.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total',
                          style: Theme.of(context).textTheme.subtitle1),
                      Text('RM $total',
                          style: Theme.of(context).textTheme.subtitle1),
                    ],
                  ),
                  Text(
                    'Transaction ID: $trid',
                    style: Theme.of(context).textTheme.caption,
                  ),
                  Text(
                    'Date: $trDate',
                    style: Theme.of(context).textTheme.caption,
                  ),
                  Text(
                    'Store ID: $storeId',
                    style: Theme.of(context).textTheme.caption,
                  ),
                  Text(
                    'Payment Method: $payBy', // Displaying the payment method
                    style: Theme.of(context).textTheme.caption,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
