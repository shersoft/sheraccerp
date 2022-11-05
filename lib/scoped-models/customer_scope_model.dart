import 'package:scoped_model/scoped_model.dart';
import 'package:sheraccerp/models/customer_model.dart';

mixin CustomerScopeModel on Model {
  List<CustomerModel> customer = [];
  double totalCustomerValue = 0;

  int get totalCustomer => customer.length;

  void addCustomer(data) {
    // int index = customer.indexWhere((i) => i.id == data.id);
    // print(index);
    if (customer.isNotEmpty) {
      updateCustomer(data);
    } else {
      customer.add(data);
      notifyListeners();
    }
  }

  void removeCustomer(data) {
    customer.removeLast();
    // customer.remove((item) => item.id == data.id);
    notifyListeners();
  }

  void updateCustomer(data) {
    // int index = customer.indexWhere((i) => i.id == data.id);
    if (customer.isNotEmpty) {
      removeCustomer(data);
      addCustomer(data);
    }
    notifyListeners();
  }

  void clearCustomer() {
    customer = [];
    notifyListeners();
  }

  void calculateCustomerTotal() {
    totalCustomerValue = 0;
    // customer.forEach((f) {
    //   totalCartValue += f.rate * f.quantity;
    // });
  }
}
