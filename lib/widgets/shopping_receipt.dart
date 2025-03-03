import 'package:flutter/material.dart';

class ShoppingReceipt extends StatelessWidget {
  final String title;
  final List<String> products;
  final List<int> quantities;
  final List<double> prices;
  final String storeAddress;
  final String storeName;
  final double total;
  final String trDate;
  final List<String> warranties;
  final String id;
  final String custName;
  final String custId;
  final List<String> categories;
  final bool isVoid;
  final double? subtotal;
  final double? tax;
  final double? serviceCharge;
  final double? taxPercentage;
  final double? serviceChargePercentage;
  final String payBy; // Add this field

  const ShoppingReceipt({
    super.key,
    required this.title,
    required this.products,
    required this.quantities,
    required this.prices,
    required this.storeAddress,
    required this.storeName,
    required this.total,
    required this.trDate,
    required this.warranties,
    required this.id,
    required this.custName,
    required this.custId,
    required this.categories,
    required this.isVoid,
    this.subtotal,
    this.tax,
    this.serviceCharge,
    this.taxPercentage,
    this.serviceChargePercentage,
    required this.payBy, // Initialize it in the constructor
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                      child: Text('Warranty',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
                            'RM ${prices[index].toStringAsFixed(2)} x ${quantities[index]}'),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          warranties[index],
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Show subtotal, tax, and service charge only if they are greater than 0
              if (tax! > 0 || serviceCharge! > 0) ...[
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
              if (tax != null && tax! > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tax (${taxPercentage!.toStringAsFixed(2)}%)',
                        style: Theme.of(context).textTheme.bodySmall),
                    Text('RM ${tax!.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
              if (serviceCharge != null && serviceCharge! > 0) ...[
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
              ],
              const Divider(), // Line before total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: Theme.of(context).textTheme.subtitle1),
                  Text('RM ${total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.subtitle1),
                ],
              ),
              Text(
                'Transaction ID: $id',
                style: Theme.of(context).textTheme.caption,
              ),
              Text(
                'Date: $trDate',
                style: Theme.of(context).textTheme.caption,
              ),
              Text(
                'Customer: $custName (ID: $custId)',
                style: Theme.of(context).textTheme.caption,
              ),
              Text(
                'Payment Method: $payBy', // Add Payment Method line
                style: Theme.of(context).textTheme.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
