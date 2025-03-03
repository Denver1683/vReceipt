import 'package:vreceipt_merchant/models/category.dart';
import 'package:flutter/material.dart';

class SortFilterMenu extends StatefulWidget {
  final double totalPriceMin;
  final double totalPriceMax;
  final double productPriceMin;
  final double productPriceMax;
  final String category;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sortBy;
  final bool ascending;
  final Function(
    double,
    double,
    double,
    double,
    String,
    DateTime?,
    DateTime?,
    String,
    bool,
  ) onApply;

  const SortFilterMenu({
    super.key,
    required this.totalPriceMin,
    required this.totalPriceMax,
    required this.productPriceMin,
    required this.productPriceMax,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.sortBy,
    required this.ascending,
    required this.onApply,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SortFilterMenuState createState() => _SortFilterMenuState();
}

class _SortFilterMenuState extends State<SortFilterMenu> {
  late double totalPriceMin;
  late double totalPriceMax;
  late double productPriceMin;
  late double productPriceMax;
  late String category;
  DateTime? startDate;
  DateTime? endDate;
  late String sortBy;
  late bool ascending;

  final TextEditingController _totalPriceMinController =
      TextEditingController();
  final TextEditingController _totalPriceMaxController =
      TextEditingController();
  final TextEditingController _productPriceMinController =
      TextEditingController();
  final TextEditingController _productPriceMaxController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    totalPriceMin = widget.totalPriceMin;
    totalPriceMax = widget.totalPriceMax;
    productPriceMin = widget.productPriceMin;
    productPriceMax = widget.productPriceMax;
    category = widget.category;
    startDate = widget.startDate;
    endDate = widget.endDate;
    sortBy = widget.sortBy;
    ascending = widget.ascending;

    _totalPriceMinController.text =
        totalPriceMin != 0 ? totalPriceMin.toString() : '';
    _totalPriceMaxController.text =
        totalPriceMax != 99999999999 ? totalPriceMax.toString() : '';
    _productPriceMinController.text =
        productPriceMin != 0 ? productPriceMin.toString() : '';
    _productPriceMaxController.text =
        productPriceMax != 999999999999 ? productPriceMax.toString() : '';
  }

  @override
  void dispose() {
    _totalPriceMinController.dispose();
    _totalPriceMaxController.dispose();
    _productPriceMinController.dispose();
    _productPriceMaxController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (startDate ?? DateTime.now())
          : (endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  void _resetFilters() {
    setState(() {
      totalPriceMin = 0;
      totalPriceMax = 99999999999;
      productPriceMin = 0;
      productPriceMax = 999999999999;
      category = '';
      startDate = null;
      endDate = null;
      sortBy = 'Date of purchase';
      ascending = true;

      _totalPriceMinController.clear();
      _totalPriceMaxController.clear();
      _productPriceMinController.clear();
      _productPriceMaxController.clear();
    });

    // Apply the reset filters and close the menu
    widget.onApply(
      totalPriceMin,
      totalPriceMax,
      productPriceMin,
      productPriceMax,
      category,
      startDate,
      endDate,
      sortBy,
      ascending,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
          const Padding(padding: EdgeInsets.all(10)),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _resetFilters,
                          child: const Text('Reset Filter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildRangeField(
                      'Total Price:',
                      'Min',
                      'Max',
                      (min, max) {
                        setState(() {
                          totalPriceMin = min;
                          totalPriceMax = max;
                        });
                      },
                      _totalPriceMinController,
                      _totalPriceMaxController,
                    ),
                    const SizedBox(height: 10),
                    _buildRangeField(
                      'Product Price:',
                      'Min',
                      'Max',
                      (min, max) {
                        setState(() {
                          productPriceMin = min;
                          productPriceMax = max;
                        });
                      },
                      _productPriceMinController,
                      _productPriceMaxController,
                    ),
                    const SizedBox(height: 10),
                    const Text('Category:', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: category.isEmpty ? null : category,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          category = newValue ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text('Date of Purchase:',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            readOnly: true,
                            decoration: const InputDecoration(
                              hintText: 'Start Date',
                              border: OutlineInputBorder(),
                            ),
                            onTap: () => _selectDate(context, true),
                            controller: TextEditingController(
                              text: startDate != null
                                  ? '${startDate!.toLocal()}'.split(' ')[0]
                                  : '',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text('-'),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            readOnly: true,
                            decoration: const InputDecoration(
                              hintText: 'End Date',
                              border: OutlineInputBorder(),
                            ),
                            onTap: () => _selectDate(context, false),
                            controller: TextEditingController(
                              text: endDate != null
                                  ? '${endDate!.toLocal()}'.split(' ')[0]
                                  : '',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Sort:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                sortBy = 'Date of purchase';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: sortBy == 'Date of purchase'
                                  ? Colors.lightBlue
                                  : (isDarkMode ? Colors.white : Colors.black),
                              backgroundColor: sortBy == 'Date of purchase'
                                  ? Colors.lightBlue[100]
                                  : (isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.white),
                            ),
                            child: const Text('Date of purchase'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                sortBy = 'Name of Customer';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: sortBy == 'Name of Customer'
                                  ? Colors.lightBlue
                                  : (isDarkMode ? Colors.white : Colors.black),
                              backgroundColor: sortBy == 'Name of Customer'
                                  ? Colors.lightBlue[100]
                                  : (isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.white),
                            ),
                            child: const Text('Name of Customer'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                sortBy = 'Name of product';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: sortBy == 'Name of product'
                                  ? Colors.lightBlue
                                  : (isDarkMode ? Colors.white : Colors.black),
                              backgroundColor: sortBy == 'Name of product'
                                  ? Colors.lightBlue[100]
                                  : (isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.white),
                            ),
                            child: const Text('Name of product'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Ascending'),
                        Switch(
                          value: ascending,
                          onChanged: (value) {
                            setState(() {
                              ascending = value;
                            });
                          },
                        ),
                        const Text('Descending'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onApply(
                            totalPriceMin,
                            totalPriceMax,
                            productPriceMin,
                            productPriceMax,
                            category,
                            startDate,
                            endDate,
                            sortBy,
                            ascending,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                          foregroundColor: Colors.white, // Ensure white text
                        ),
                        child: const Text('Apply Sort/Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeField(
    String label,
    String hintMin,
    String hintMax,
    void Function(double min, double max) onChanged,
    TextEditingController minController,
    TextEditingController maxController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: hintMin,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                controller: minController,
                onChanged: (value) {
                  final min = double.tryParse(value) ?? 0.00;
                  onChanged(min,
                      double.tryParse(maxController.text) ?? 99999999999.00);
                },
              ),
            ),
            const SizedBox(width: 10),
            const Text('-'),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: hintMax,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                controller: maxController,
                onChanged: (value) {
                  final max = double.tryParse(value) ?? 99999999999.00;
                  onChanged(double.tryParse(minController.text) ?? 0.00, max);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
