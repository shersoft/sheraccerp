// @dart = 2.11
import 'package:sheraccerp/models/cart_item.dart';
import 'package:sheraccerp/models/customer_model.dart';

class Order {
  final String otherDiscount;
  final String otherCharges;
  final String cashReceived;
  final List<CartItem> lineItems;
  final List<CustomerModel> customerModel;
  final String loadingCharge;
  final String narration;
  final String balanceAmount;
  final String labourCharge;
  final String creditPeriod;
  final String takeUser; //1
  final String cashAC;
  final String dated;
  final String location; //1
  final String salesMan; //0
  final String roundOff; //0
  final String billType; //0
  final String sType; //0
  final String grossValue; //0
  final String discount; //0
  final String discountPer; //0
  final String rDiscount; //0
  final String net; //0
  final String cess; //0
  final String cGST; //0
  final String sGST; //0
  final String iGST; //0
  final String fCess; //0
  final String adCess; //0
  final String total; //0
  final String profit; //0
  final List<dynamic> otherAmountData;
  final String grandTotal;

  Order(
      {this.customerModel,
      this.lineItems,
      this.grossValue,
      this.discount,
      this.discountPer,
      this.rDiscount,
      this.net,
      this.cess,
      this.cGST,
      this.sGST,
      this.iGST,
      this.fCess,
      this.adCess,
      this.total,
      this.profit,
      this.otherDiscount,
      this.loadingCharge,
      this.otherCharges,
      this.cashReceived,
      this.narration,
      this.balanceAmount,
      this.labourCharge,
      this.creditPeriod,
      this.takeUser,
      this.cashAC,
      this.dated,
      this.location,
      this.salesMan,
      this.roundOff,
      this.billType,
      this.sType,
      this.otherAmountData,
      this.grandTotal});

  // Order.fromData(CustomerModel customerModel,CartItem){
  //   return()
  // }
}
