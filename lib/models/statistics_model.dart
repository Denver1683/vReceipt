class ChartData {
  final String month;
  final int spending;

  ChartData(this.month, this.spending);
}

class ProductIncome {
  final String productName;
  final int income;

  ProductIncome(this.productName, this.income);
}

class CustomerSpending {
  final String uid;
  final String name;
  final int spending;

  CustomerSpending(this.uid, this.name, this.spending);
}
