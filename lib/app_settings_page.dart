// @dart = 2.11
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheraccerp/screens/settings/add_logo.dart';
import 'package:sheraccerp/shared/constants.dart';
import 'package:sheraccerp/util/res_color.dart';

class AppSettings extends StatelessWidget {
  const AppSettings({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SettingsScreen(
      title: 'App Settings',
      children: [
        //General
        SingleChildScrollView(
          child: SimpleSettingsTile(
            title: 'General',
            subtitle: 'General Settings',
            child: SettingsScreen(
              title: 'General Settings',
              children: [
                DropDownSettingsTile<int>(
                  title: 'App Language',
                  settingKey: 'key-dropdown-language-view',
                  values: const <int, String>{
                    2: 'English',
                    3: 'Arabic',
                    4: 'Chinese',
                    5: 'German',
                    6: 'Hindi',
                    7: 'Japanese',
                    8: 'Korean',
                    9: 'Malayalam',
                    10: 'Malay',
                    11: 'Russian',
                    12: 'Portuguese',
                    13: 'Spanish',
                    14: 'Thai',
                    15: 'Turkish',
                    16: 'Italian',
                    17: 'French',
                  },
                  selected: 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-language-view: $value');
                  },
                ),
                DropDownSettingsTile<int>(
                  title: 'Currency Symbol',
                  settingKey: 'key-dropdown-currency-symbol-view',
                  values: const <int, String>{
                    2: "\$",
                    3: '€',
                    4: '¥',
                    5: '£',
                    6: '₽',
                    7: '৳',
                    8: '₹',
                    9: 'د.إ',
                    10: '₪',
                    11: '£',
                    12: '₩',
                    13: 'د.ك',
                    14: 'RM',
                    15: 'रू',
                    16: '₨',
                    17: 'ر.ق',
                    18: '฿',
                    19: '₺',
                    20: 'Rp',
                  },
                  selected: 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-currency-symbol-view: $value');
                  },
                ),
                DropDownSettingsTile<int>(
                  title: 'Decimal Places',
                  settingKey: 'key-dropdown-decimal-place-view',
                  values: const <int, String>{
                    2: "1",
                    3: '2',
                    4: '3',
                    5: '4',
                  },
                  selected: 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-decimal-place-view: $value');
                  },
                ),
                DropDownSettingsTile<int>(
                  title: 'Date Format',
                  settingKey: 'key-dropdown-date-format-view',
                  values: const <int, String>{
                    2: "dd-mm-yyyy",
                    3: 'dd/mm/yyyy',
                    4: 'dd/MM/yyy',
                    5: 'dd-MM-yyyy',
                    6: 'yyyy/MM/dd',
                    7: 'yyyy-MM-dd',
                    8: 'yyyy-mm-dd',
                    9: 'yyyy/mm/dd',
                    10: 'mm-dd-yyyy',
                    11: 'MM-dd-yyyy',
                    12: 'mm/dd/yyyy',
                    13: 'MM/dd/yyyy',
                  },
                  selected: 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-date-format-view: $value');
                  },
                ),
                DropDownSettingsTile<int>(
                  title: 'Theme',
                  settingKey: 'key-dropdown-them-view',
                  values: const <int, String>{
                    2: "Light",
                    3: 'Dark',
                  },
                  selected: 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-them-view: $value');
                  },
                ),
                DropDownSettingsTileNew<int>(
                  enabled: defaultSalesMan,
                  title: 'Default SalesMan',
                  settingKey: 'key-dropdown-default-salesman-view',
                  values: salesmanList.isNotEmpty
                      ? {for (var e in salesmanList) e.key + 1: e.value}
                      : {
                          2: '',
                        },
                  selected:
                      salesmanList.isNotEmpty ? salesmanList[0].key + 1 : 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-default-salesman-view: $value');
                    var val = salesmanList
                        .firstWhere((element) => element.key == value - 1);
                    savePref('default-salesman', '${val.key}-${val.value}');
                  },
                ),
                DropDownSettingsTileNew<int>(
                  enabled: defaultBranch,
                  title: 'Default Branch',
                  settingKey: 'key-dropdown-default-location-view',
                  values: locationList.isNotEmpty
                      ? {for (var e in locationList) e.key + 1: e.value}
                      : {
                          2: '',
                        },
                  selected:
                      locationList.isNotEmpty ? locationList[0].key + 1 : 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-default-location-view: $value');
                    var val = salesmanList
                        .firstWhere((element) => element.key == value - 1);
                    savePref('default-location', '${val.e}-${val.value}');
                  },
                ),
                DropDownSettingsTileNew<int>(
                  enabled: defaultCashAc,
                  title: 'Default CASH AC',
                  settingKey: 'key-dropdown-default-cash-ac',
                  values: cashAccount.isNotEmpty
                      ? {for (var e in cashAccount) e.key + 1: e.value}
                      : {
                          2: '',
                        },
                  selected: cashAccount.isNotEmpty ? cashAccount[0].key + 1 : 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-default-cash-ac: $value');
                    var val = salesmanList
                        .firstWhere((element) => element.key == value - 1);
                    savePref('default-cash-ac', '${val.e}-${val.value}');
                  },
                ),
                DropDownSettingsTileNew<int>(
                  enabled: defaultArea,
                  title: 'Default Area',
                  settingKey: 'key-dropdown-default-area-view',
                  values: areaList.isNotEmpty
                      ? {for (var e in areaList) e.key + 1: e.value}
                      : {
                          2: '',
                        },
                  selected: areaList.isNotEmpty ? areaList[0].key + 1 : 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-default-area-view: $value');
                    var val = salesmanList
                        .firstWhere((element) => element.key == value - 1);
                    savePref('default-area', '${val.e}-${val.value}');
                  },
                ),
                DropDownSettingsTileNew<int>(
                  enabled: defaultGroup,
                  title: 'Default Group',
                  settingKey: 'key-dropdown-default-group-view',
                  values: groupList.isNotEmpty
                      ? {for (var e in groupList) e.key + 1: e.value}
                      : {
                          2: '',
                        },
                  selected: groupList.isNotEmpty ? groupList[0].key + 1 : 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-default-group-view: $value');
                    var val = salesmanList
                        .firstWhere((element) => element.key == value - 1);
                    savePref('default-group', '${val.e}-${val.value}');
                  },
                ),
                DropDownSettingsTileNew<int>(
                  enabled: defaultRoute,
                  title: 'Default Route',
                  settingKey: 'key-dropdown-default-route-view',
                  values: routeList.isNotEmpty
                      ? {for (var e in routeList) e.key + 1: e.value}
                      : {
                          2: '',
                        },
                  selected: routeList.isNotEmpty ? routeList[0].key + 1 : 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-default-route-view: $value');
                    var val = salesmanList
                        .firstWhere((element) => element.key == value - 1);
                    savePref('default-route', '${val.e}-${val.value}');
                  },
                ),
              ],
            ),
          ),
        ),
        //Company
        SimpleSettingsTile(
            title: 'Company',
            subtitle: 'Company Settings',
            child: SettingsScreen(
              title: 'Company Settings',
              children: [
                TextInputSettingsTile(
                  title: 'Company(Firm) Name',
                  settingKey: 'key-company-name',
                  initialValue: 'unknown',
                  validator: (String username) {
                    if (username != null && username.length > 3) {
                      return null;
                    }
                    return "can't be smaller than 4 letters";
                  },
                  borderColor: Colors.blueAccent,
                  errorColor: Colors.deepOrangeAccent,
                ),
                TextInputSettingsTile(
                  title: 'Address 1',
                  settingKey: 'key-company-address1',
                  initialValue: 'unknown',
                  validator: (String username) {
                    if (username != null && username.length > 3) {
                      return null;
                    }
                    return "can't be smaller than 4 letters";
                  },
                  borderColor: Colors.blueAccent,
                  errorColor: Colors.deepOrangeAccent,
                ),
                TextInputSettingsTile(
                  title: 'Address 2',
                  settingKey: 'key-company-address2',
                  initialValue: 'unknown',
                  validator: (String username) {
                    if (username != null && username.length > 3) {
                      return null;
                    }
                    return "can't be smaller than 4 letters";
                  },
                  borderColor: Colors.blueAccent,
                  errorColor: Colors.deepOrangeAccent,
                ),
                TextInputSettingsTile(
                  title: 'Tax Number',
                  settingKey: 'key-company-taxno',
                  initialValue: 'unknown',
                  validator: (String username) {
                    if (username != null && username.length > 3) {
                      return null;
                    }
                    return "can't be smaller than 4 letters";
                  },
                  borderColor: Colors.blueAccent,
                  errorColor: Colors.deepOrangeAccent,
                ),
                TextInputSettingsTile(
                  title: 'Phone',
                  settingKey: 'key-company-phone',
                  initialValue: 'unknown',
                  validator: (String username) {
                    if (username != null && username.length > 3) {
                      return null;
                    }
                    return "can't be smaller than 4 letters";
                  },
                  borderColor: Colors.blueAccent,
                  errorColor: Colors.deepOrangeAccent,
                ),
                TextInputSettingsTile(
                  title: 'Mail ID',
                  settingKey: 'key-company-mail',
                  initialValue: 'unknown',
                  validator: (String username) {
                    if (username != null && username.length > 3) {
                      return null;
                    }
                    return "can't be smaller than 4 letters";
                  },
                  borderColor: Colors.blueAccent,
                  errorColor: Colors.deepOrangeAccent,
                ),
              ],
            )),
        // //Transaction
        SingleChildScrollView(
          child: SimpleSettingsTile(
              title: 'Transaction',
              subtitle: 'Transaction Settings',
              child: SettingsScreen(
                title: 'Transaction Settings',
                children: [
                  SwitchSettingsTile(
                    settingKey: 'key-invoice-preview',
                    title: 'Enable Invoice Preview',
                    subtitle:
                        'Invoice Preview. Let’s you see the preview of your invoice during its action.',
                    enabledLabel: 'Enabled',
                    disabledLabel: 'Disabled',
                    leading: const Icon(Icons.receipt_long),
                    onChange: (value) {
                      debugPrint('key-invoice-preview: $value');
                    },
                  ),
                  SwitchSettingsTile(
                    settingKey: 'key-direct-print',
                    title: 'Enable Direct Printing',
                    subtitle:
                        'Direct Printing. Save and Print during its action.',
                    enabledLabel: 'Enabled',
                    disabledLabel: 'Disabled',
                    leading: const Icon(Icons.print),
                    onChange: (value) {
                      debugPrint('key-direct-print: $value');
                    },
                  ),
                  SwitchSettingsTile(
                    settingKey: 'key-print-balance',
                    title: 'Disable Balance Printing',
                    subtitle: 'Balance Printing. Hide print balance on invoice',
                    enabledLabel: 'Enabled',
                    disabledLabel: 'Disabled',
                    // leading: Icon(Icons.receipt_long),
                    onChange: (value) {
                      debugPrint('key-print-balance: $value');
                    },
                  ),
                  SwitchSettingsTile(
                    settingKey: 'key-print-bank-details',
                    title: 'Enable Bank Details Printing',
                    subtitle:
                        'Bank Details Printing. Print bank details on invoice',
                    enabledLabel: 'Enabled',
                    disabledLabel: 'Disabled',
                    // leading: Icon(Icons.receipt_long),
                    onChange: (value) {
                      debugPrint('key-print-bank-details: $value');
                    },
                  ),
                  SwitchSettingsTile(
                    settingKey: 'key-customer-scan',
                    title: 'Show Customer Scanner',
                    subtitle: 'Show Customer QrCode Scanner',
                    enabledLabel: 'Enabled',
                    disabledLabel: 'Disabled',
                    // leading: Icon(Icons.receipt_long),
                    onChange: (value) {
                      debugPrint('key-customer-scan: $value');
                    },
                  ),
                  SwitchSettingsTile(
                    settingKey: 'key-single-product',
                    title: 'Single Product only',
                    subtitle: 'Single Product or Service Only',
                    enabledLabel: 'Enabled',
                    disabledLabel: 'Disabled',
                    // leading: Icon(Icons.receipt_long),
                    onChange: (value) {
                      debugPrint('key-single-product: $value');
                    },
                  ),
                  SwitchSettingsTile(
                    settingKey: 'key-customer-reusable-product',
                    title: 'Customer Reusable Product',
                    subtitle: 'Customer Reusable Product or Service Only',
                    enabledLabel: 'Enabled',
                    disabledLabel: 'Disabled',
                    // leading: Icon(Icons.receipt_long),
                    onChange: (value) {
                      debugPrint('key-customer-reusable-product: $value');
                    },
                  ),
                  SwitchSettingsTile(
                    settingKey: 'key-show-qty',
                    title: 'Hide Stock Qty',
                    subtitle: 'Stock Quantity. Hide stock quantity with item',
                    enabledLabel: 'Enabled',
                    disabledLabel: 'Disabled',
                    // leading: Icon(Icons.receipt_long),
                    onChange: (value) {
                      debugPrint('key-show-qty: $value');
                    },
                  ),
                  SwitchSettingsTile(
                    settingKey: 'key-area-is-sales',
                    title: 'Enabled Area In Sales',
                    subtitle: 'Area In Sales. Area based sales',
                    enabledLabel: 'Enabled',
                    disabledLabel: 'Disabled',
                    // leading: Icon(Icons.receipt_long),
                    onChange: (value) {
                      debugPrint('key-area-is-sales: $value');
                    },
                  ),
                  SwitchSettingsTile(
                    settingKey: 'key-default-sales',
                    title: 'Enabled Default Sales',
                    subtitle: 'Default Sales. Invoice type default always',
                    enabledLabel: 'Enabled',
                    disabledLabel: 'Disabled',
                    // leading: Icon(Icons.receipt_long),
                    onChange: (value) {
                      debugPrint('key-default-sales: $value');
                    },
                  ),
                  SwitchSettingsTile(
                    settingKey: 'key-lock-sales-tax',
                    title: 'Lock Tax No In Sales',
                    subtitle:
                        'Lock Tax No. can\'t make sales(B2B) without tax no',
                    enabledLabel: 'Enabled',
                    disabledLabel: 'Disabled',
                    // leading: Icon(Icons.receipt_long),
                    onChange: (value) {
                      debugPrint('key-lock-sales-tax: $value');
                    },
                  ),
                  SwitchSettingsTile(
                    settingKey: 'key-sms-customer',
                    title: 'SMS To Customer',
                    subtitle: 'Auto Sent SMS(using SIM sms) to Customer',
                    enabledLabel: 'Enabled',
                    disabledLabel: 'Disabled',
                    // leading: Icon(Icons.receipt_long),
                    onChange: (value) {
                      debugPrint('key-sms-customer: $value');
                    },
                  ),
                  SwitchSettingsTile(
                    settingKey: 'key-sms-company',
                    title: 'SMS To Company',
                    subtitle: 'Auto Sent SMS(using SIM sms) to Company',
                    enabledLabel: 'Enabled',
                    disabledLabel: 'Disabled',
                    // leading: Icon(Icons.receipt_long),
                    onChange: (value) {
                      debugPrint('key-sms-company: $value');
                    },
                  ),
                  SwitchSettingsTile(
                    settingKey: 'key-regional-company-info',
                    title: 'Regional Company Details',
                    subtitle:
                        'Use Regional Company Details (with local language)',
                    enabledLabel: 'Enabled',
                    disabledLabel: 'Disabled',
                    // leading: Icon(Icons.receipt_long),
                    onChange: (value) {
                      debugPrint('key-regional-company-info: $value');
                    },
                  ),
                  SwitchSettingsTile(
                    settingKey: 'key-round-off-amount',
                    title: 'Disable Round Off Amount',
                    subtitle: 'Disable Round Off Amount (Total Figure)',
                    enabledLabel: 'Enabled',
                    disabledLabel: 'Disabled',
                    // leading: Icon(Icons.receipt_long),
                    onChange: (value) {
                      debugPrint('key-round-off-amount: $value');
                    },
                  ),
                  SwitchSettingsTile(
                    settingKey: 'key-simple-sales',
                    title: 'Enable Simple Sale',
                    subtitle: 'Enable Simple Sales Mode',
                    enabledLabel: 'Enabled',
                    disabledLabel: 'Disabled',
                    onChange: (value) {
                      debugPrint('key-simple-sales: $value');
                    },
                  ),
                  ExpandableSettingsTile(
                      title: 'Sales Forms',
                      subtitle: 'show sale forms',
                      children: [
                        SwitchSettingsTile(
                          title: 'Sales Forms hide and show',
                          settingKey: 'key-switch-sales-form-set',
                          onChange: (value) {
                            debugPrint('key-switch-sales-form-set: $value');
                          },
                          childrenIfEnabled: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: salesTypeList.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: CheckboxSettingsTile(
                                    settingKey: 'key-item-sale-form-' +
                                        salesTypeList[index].id.toString(),
                                    title: 'Show ' + salesTypeList[index].name,
                                    enabledLabel: 'Enabled',
                                    disabledLabel: 'Disabled',
                                    // leading: Icon(Icons.timelapse),
                                    onChange: (value) {
                                      debugPrint('key-item-sale-form-' +
                                          salesTypeList[index].id.toString() +
                                          ': $value');
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ]),
                ],
              )),
        ),
        SimpleSettingsTile(
            title: 'Item',
            subtitle: 'Item Settings',
            child: SettingsScreen(
              title: 'Item Settings',
              children: [
                // SwitchSettingsTile(
                //   settingKey: 'key-lock-sales-rate',
                //   title: 'Lock Sales Rate',
                //   subtitle:
                //       'Lock Sales Rate. can\'t edit rate it is default always',
                //   enabledLabel: 'Enabled',
                //   disabledLabel: 'Disabled',
                //   // leading: Icon(Icons.receipt_long),
                //   onChange: (value) {
                //     debugPrint('key-lock-sales-rate: $value');
                //   },
                // ),
                // SwitchSettingsTile(
                //   settingKey: 'key-lock-sales-discount',
                //   title: 'Lock Sales Discount',
                //   subtitle:
                //       'Lock Sales Rate. can\'t edit discount it is default always',
                //   enabledLabel: 'Enabled',
                //   disabledLabel: 'Disabled',
                //   // leading: Icon(Icons.receipt_long),
                //   onChange: (value) {
                //     debugPrint('key-lock-sales-rate: $value');
                //   },
                // ),
                // SwitchSettingsTile(
                //   settingKey: 'key-free-item',
                //   title: 'Enable Free Item',
                //   subtitle: 'Free Item (offer)',
                //   enabledLabel: 'Enabled',
                //   disabledLabel: 'Disabled',
                //   // leading: Icon(Icons.receipt_long),
                //   onChange: (value) {
                //     debugPrint('key-free-item: $value');
                //   },
                // ),
                SwitchSettingsTile(
                  settingKey: 'key-print-item-regional',
                  title: 'Print Item In Regional',
                  subtitle: 'Print Item Name In Regional',
                  enabledLabel: 'Enabled',
                  disabledLabel: 'Disabled',
                  // leading: Icon(Icons.receipt_long),
                  onChange: (value) {
                    debugPrint('key-print-item-regional: $value');
                  },
                ),
                SwitchSettingsTile(
                  settingKey: 'key-item-by-code',
                  title: 'Enabled Item Code Vice',
                  subtitle: 'Code vice select item',
                  enabledLabel: 'Enabled',
                  disabledLabel: 'Disabled',
                  // leading: Icon(Icons.receipt_long),
                  onChange: (value) {
                    debugPrint('key-item-by-code: $value');
                  },
                ),
                SwitchSettingsTile(
                  settingKey: 'key-item-serial-no',
                  title: 'Enabled Item Serial No',
                  subtitle: 'Add serial number to item',
                  enabledLabel: 'Enabled',
                  disabledLabel: 'Disabled',
                  // leading: Icon(Icons.receipt_long),
                  onChange: (value) {
                    debugPrint('key-item-serial-no: $value');
                  },
                ),
                SwitchSettingsTile(
                  settingKey: 'key-item-stock-all',
                  title: 'Limited Item On Stock',
                  subtitle: 'Show Limited Stock Items',
                  enabledLabel: 'Enabled',
                  disabledLabel: 'Disabled',
                  onChange: (value) {
                    debugPrint('key-item-stock-all: $value');
                  },
                ),
                DropDownSettingsTile<int>(
                  title: 'Item Default Unit',
                  settingKey: 'key-dropdown-item-default-sku-view',
                  values: unitListSettings.isNotEmpty
                      ? {for (var e in unitListSettings) e.key + 1: e.value}
                      : {
                          2: '',
                        },
                  selected: 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-item-default-sku-view: $value');
                  },
                ),
                SwitchSettingsTile(
                  settingKey: 'key-items-prate-sale',
                  title: 'Show PRate On Sales',
                  subtitle: 'Show Product Purchase Rate On Sales',
                  enabledLabel: 'Enabled',
                  disabledLabel: 'Disabled',
                  // leading: Icon(Icons.receipt_long),
                  onChange: (value) {
                    debugPrint('key-items-prate-sale: $value');
                  },
                ),
                SwitchSettingsTile(
                  settingKey: 'key-items-variant-stock',
                  title: 'Stock Variant Items',
                  subtitle:
                      'Product Stock Batch Vice grater Quantity default always',
                  enabledLabel: 'Enabled',
                  disabledLabel: 'Disabled',
                  // leading: Icon(Icons.receipt_long),
                  onChange: (value) {
                    debugPrint('key-items-variant-stock: $value');
                  },
                ),
                ExpandableSettingsTile(
                    title: 'Item Rate Type',
                    subtitle: 'show columns for rate slot of item',
                    children: [
                      SwitchSettingsTile(
                        title: 'Select item rate type option',
                        settingKey: 'key-switch-sales-rate-type-set',
                        onChange: (value) {
                          debugPrint('key-switch-sales-rate-type-set: $value');
                        },
                        childrenIfEnabled: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: optionRateTypeList.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: CheckboxSettingsTile(
                                  settingKey: 'key-item-rate-type-control-' +
                                      optionRateTypeList[index].id.toString(),
                                  title:
                                      'Show ' + optionRateTypeList[index].name,
                                  enabledLabel: 'Enabled',
                                  disabledLabel: 'Disabled',
                                  onChange: (value) {
                                    debugPrint('key-item-rate-type-control-' +
                                        optionRateTypeList[index]
                                            .id
                                            .toString() +
                                        ': $value');
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ]),
                ExpandableSettingsTile(
                  title: 'Item Batch Details',
                  subtitle: 'show columns for batch of item',
                  children: [
                    CheckboxSettingsTile(
                      settingKey: 'key-item-sale-qty',
                      title: 'Show Qty',
                      enabledLabel: 'Enabled',
                      disabledLabel: 'Disabled',
                      // leading: Icon(Icons.timelapse),
                      defaultValue: true,
                      onChange: (value) {
                        debugPrint('key-item-sale-qty: $value');
                      },
                    ),
                    CheckboxSettingsTile(
                      settingKey: 'key-item-sale-mrp',
                      title: 'Show MRP',
                      enabledLabel: 'Enabled',
                      disabledLabel: 'Disabled',
                      // leading: Icon(Icons.timelapse),
                      onChange: (value) {
                        debugPrint('key-item-sale-mrp: $value');
                      },
                    ),
                    CheckboxSettingsTile(
                      settingKey: 'key-item-sale-retail',
                      title: 'Show Retail',
                      enabledLabel: 'Enabled',
                      disabledLabel: 'Disabled',
                      // leading: Icon(Icons.timelapse),
                      onChange: (value) {
                        debugPrint('key-item-sale-retail: $value');
                      },
                    ),
                    CheckboxSettingsTile(
                      settingKey: 'key-item-sale-wholesale',
                      title: 'Show WholeSale',
                      enabledLabel: 'Enabled',
                      disabledLabel: 'Disabled',
                      // leading: Icon(Icons.timelapse),
                      onChange: (value) {
                        debugPrint('key-item-sale-wholesale: $value');
                      },
                    ),
                    CheckboxSettingsTile(
                      settingKey: 'key-item-sale-rate',
                      title: 'Show S Rate',
                      enabledLabel: 'Enabled',
                      disabledLabel: 'Disabled',
                      // leading: Icon(Icons.timelapse),
                      onChange: (value) {
                        debugPrint('key-item-sale-rate: $value');
                      },
                    ),
                    CheckboxSettingsTile(
                      settingKey: 'key-item-sale-spretail',
                      title: 'Show SP Retail',
                      enabledLabel: 'Enabled',
                      disabledLabel: 'Disabled',
                      // leading: Icon(Icons.timelapse),
                      onChange: (value) {
                        debugPrint('key-item-sale-spretail: $value');
                      },
                    ),
                    CheckboxSettingsTile(
                      settingKey: 'key-item-sale-branch',
                      title: 'Show Branch',
                      enabledLabel: 'Enabled',
                      disabledLabel: 'Disabled',
                      // leading: Icon(Icons.timelapse),
                      onChange: (value) {
                        debugPrint('key-item-sale-branch: $value');
                      },
                    ),
                    CheckboxSettingsTile(
                      settingKey: 'key-item-sale-prate',
                      title: 'Show P Rate',
                      enabledLabel: 'Enabled',
                      disabledLabel: 'Disabled',
                      // leading: Icon(Icons.timelapse),
                      onChange: (value) {
                        debugPrint('key-item-sale-prate: $value');
                      },
                    ),
                    CheckboxSettingsTile(
                      settingKey: 'key-item-sale-supplier',
                      title: 'Show Supplier',
                      enabledLabel: 'Enabled',
                      disabledLabel: 'Disabled',
                      // leading: Icon(Icons.timelapse),
                      onChange: (value) {
                        debugPrint('key-item-sale-supplier: $value');
                      },
                    ),
                  ],
                )
              ],
            )),
        SimpleSettingsTile(
            title: 'Pinter',
            subtitle: 'Pinter Settings',
            child: SettingsScreen(
              title: 'Pinter Settings',
              children: [
                SwitchSettingsTile(
                  settingKey: 'key-print-logo',
                  title: 'Show Logo On Print',
                  subtitle: 'Set Logo First On Settings',
                  enabledLabel: 'Enabled',
                  disabledLabel: 'Disabled',
                  // leading: Icon(Icons.receipt_long),
                  onChange: (value) {
                    debugPrint('key-print-logo: $value');
                  },
                ),
                DropDownSettingsTile<int>(
                  title: 'Printer Type',
                  settingKey: 'key-dropdown-printer-type-view',
                  values: const <int, String>{
                    2: 'Bluetooth',
                    3: 'Cloud',
                    4: 'Document',
                    5: 'POS',
                    6: 'TCP Network',
                    7: 'WiFi',
                    8: 'USB',
                    9: 'Invoice Designer',
                  },
                  selected: 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-printer-type-view: $value');
                  },
                ),
                DropDownSettingsTile<int>(
                  title: 'Printer Device',
                  settingKey: 'key-dropdown-printer-device-view',
                  values: const <int, String>{
                    2: 'Default',
                    3: 'Line',
                    4: 'Local',
                    5: 'ESC/POS',
                    6: 'Thermal',
                    7: 'RP_80',
                    8: 'SEWOO',
                    9: 'ESYPOS',
                    10: 'CIONTEK',
                    11: 'SUNMI_V1',
                    12: 'SUNMI_V2',
                    13: 'UROVO'
                  },
                  selected: 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-printer-device-view: $value');
                  },
                ),
                DropDownSettingsTile<int>(
                  title: 'Paper Size',
                  settingKey: 'key-dropdown-printer-paper-size',
                  values: const <int, String>{
                    2: '1',
                    3: '2',
                    4: '3',
                    5: '4',
                    6: '5',
                  },
                  selected: 4,
                  onChange: (value) {
                    debugPrint('key-dropdown-printer-paper-size: $value');
                  },
                ),
                // DropDownSettingsTile<int>(
                //   title: 'Print Copy',
                //   settingKey: 'key-dropdown-print-copy-view',
                //   values: const <int, String>{
                //     2: '1',
                //     3: '2',
                //     4: '3',
                //     5: '4',
                //     6: '5',
                //   },
                //   selected: 2,
                //   onChange: (value) {
                //     debugPrint('key-dropdown-print-copy-view: $value');
                //   },
                // ),
                DropDownSettingsTile<int>(
                  title: 'Printer Model',
                  settingKey: 'key-dropdown-printer-model-view',
                  values: const <int, String>{
                    2: 'Default',
                    3: 'VAT',
                    4: 'GST',
                    5: 'VAT1',
                    6: 'Other',
                    7: 'VAT2',
                    8: 'VAT3',
                  },
                  selected: 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-printer-model-view: $value');
                  },
                ),
                TextInputSettingsTile(
                  title: 'Footer Message',
                  settingKey: 'key-footer-message',
                  initialValue: 'Thank you for business wth us.',
                  validator: (String username) {
                    if (username != null && username.length > 3) {
                      return null;
                    }
                    return "can't be smaller than 4 letters";
                  },
                  borderColor: Colors.blueAccent,
                  errorColor: Colors.deepOrangeAccent,
                ),
                SwitchSettingsTile(
                  settingKey: 'key-print-header-es',
                  title: 'Show Header On Estimate',
                  subtitle: 'Show Header On Estimate Print',
                  enabledLabel: 'Enabled',
                  disabledLabel: 'Disabled',
                  // leading: Icon(Icons.receipt_long),
                  onChange: (value) {
                    debugPrint('key-print-header-es: $value');
                  },
                ),
                DropDownSettingsTile<int>(
                  title: 'Print Space',
                  settingKey: 'key-dropdown-print-line',
                  values: const <int, String>{
                    2: '1',
                    3: '2',
                    4: '3',
                    5: '4',
                    6: '5',
                    7: '6',
                    8: '7',
                    9: '8',
                    10: '9',
                    11: '10',
                    12: '11',
                    13: '12',
                    14: '13',
                    15: '14',
                    16: '15',
                    17: '16',
                    18: '17',
                    19: '18',
                    20: '19',
                    21: '20',
                    22: '21',
                    23: '22',
                    24: '23',
                    25: '24',
                    26: '25',
                    27: '26',
                    28: '27',
                    29: '28',
                    30: '29',
                    31: '30',
                  },
                  selected: 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-print-line: $value');
                  },
                ),
                SettingsGroup(
                  title: 'Print Head',
                  children: [
                    ExpandableSettingsTile(title: 'Sales Head', children: [
                      TextInputSettingsTile(
                        title: 'Sales Invoice',
                        settingKey: 'key-sales-invoice-head',
                        initialValue: 'Invoice',
                        validator: (String username) {
                          if (username != null && username.length > 3) {
                            return null;
                          }
                          return "can't be smaller than 4 letters";
                        },
                        borderColor: Colors.blueAccent,
                        errorColor: Colors.deepOrangeAccent,
                      ),
                      TextInputSettingsTile(
                        title: 'Sales Estimate',
                        settingKey: 'key-sales-estimate-head',
                        initialValue: 'Estimate',
                        validator: (String username) {
                          if (username != null && username.length > 3) {
                            return null;
                          }
                          return "can't be smaller than 4 letters";
                        },
                        borderColor: Colors.blueAccent,
                        errorColor: Colors.deepOrangeAccent,
                      ),
                      TextInputSettingsTile(
                        title: 'Sales Order',
                        settingKey: 'key-sales-order-head',
                        initialValue: 'Sales Order',
                        validator: (String username) {
                          if (username != null && username.length > 3) {
                            return null;
                          }
                          return "can't be smaller than 4 letters";
                        },
                        borderColor: Colors.blueAccent,
                        errorColor: Colors.deepOrangeAccent,
                      ),
                      TextInputSettingsTile(
                        title: 'Sales Quotation',
                        settingKey: 'key-sales-quotation-head',
                        initialValue: 'Quotation',
                        validator: (String username) {
                          if (username != null && username.length > 3) {
                            return null;
                          }
                          return "can't be smaller than 4 letters";
                        },
                        borderColor: Colors.blueAccent,
                        errorColor: Colors.deepOrangeAccent,
                      ),
                      TextInputSettingsTile(
                        title: 'Sales Return',
                        settingKey: 'key-sales-return-head',
                        initialValue: 'Sales Return',
                        validator: (String username) {
                          if (username != null && username.length > 3) {
                            return null;
                          }
                          return "can't be smaller than 4 letters";
                        },
                        borderColor: Colors.blueAccent,
                        errorColor: Colors.deepOrangeAccent,
                      ),
                    ]),
                    ExpandableSettingsTile(
                      title: 'Purchase Head',
                      children: [
                        TextInputSettingsTile(
                          title: 'Purchase',
                          settingKey: 'key-purchase-invoice-head',
                          initialValue: 'Purchase',
                          validator: (String username) {
                            if (username != null && username.length > 3) {
                              return null;
                            }
                            return "can't be smaller than 4 letters";
                          },
                          borderColor: Colors.blueAccent,
                          errorColor: Colors.deepOrangeAccent,
                        ),
                        TextInputSettingsTile(
                          title: 'Purchase Order',
                          settingKey: 'key-purchase-order-head',
                          initialValue: 'Purchase Order',
                          validator: (String username) {
                            if (username != null && username.length > 3) {
                              return null;
                            }
                            return "can't be smaller than 4 letters";
                          },
                          borderColor: Colors.blueAccent,
                          errorColor: Colors.deepOrangeAccent,
                        ),
                        TextInputSettingsTile(
                          title: 'Purchase Return',
                          settingKey: 'key-purchase-return-head',
                          initialValue: 'Purchase Return',
                          validator: (String username) {
                            if (username != null && username.length > 3) {
                              return null;
                            }
                            return "can't be smaller than 4 letters";
                          },
                          borderColor: Colors.blueAccent,
                          errorColor: Colors.deepOrangeAccent,
                        ),
                      ],
                    ),
                    ExpandableSettingsTile(
                      title: 'Other Head',
                      children: [
                        TextInputSettingsTile(
                          title: 'Payment voucher',
                          settingKey: 'key-payment-voucher-head',
                          initialValue: 'Payment Voucher',
                          validator: (String username) {
                            if (username != null && username.length > 3) {
                              return null;
                            }
                            return "can't be smaller than 4 letters";
                          },
                          borderColor: Colors.blueAccent,
                          errorColor: Colors.deepOrangeAccent,
                        ),
                        TextInputSettingsTile(
                          title: 'Receipt Voucher',
                          settingKey: 'key-receipt-voucher-head',
                          initialValue: 'Receipt Voucher',
                          validator: (String username) {
                            if (username != null && username.length > 3) {
                              return null;
                            }
                            return "can't be smaller than 4 letters";
                          },
                          borderColor: Colors.blueAccent,
                          errorColor: Colors.deepOrangeAccent,
                        ),
                        TextInputSettingsTile(
                          title: 'Journal Voucher',
                          settingKey: 'key-journal-voucher-head',
                          initialValue: 'Journal Voucher',
                          validator: (String username) {
                            if (username != null && username.length > 3) {
                              return null;
                            }
                            return "can't be smaller than 4 letters";
                          },
                          borderColor: Colors.blueAccent,
                          errorColor: Colors.deepOrangeAccent,
                        ),
                        TextInputSettingsTile(
                          title: 'Credit Note',
                          settingKey: 'key-credit-note-head',
                          initialValue: 'Credit Note',
                          validator: (String username) {
                            if (username != null && username.length > 3) {
                              return null;
                            }
                            return "can't be smaller than 4 letters";
                          },
                          borderColor: Colors.blueAccent,
                          errorColor: Colors.deepOrangeAccent,
                        ),
                        TextInputSettingsTile(
                          title: 'Debit Note',
                          settingKey: 'key-debit-note-head',
                          initialValue: 'Debit Note',
                          validator: (String username) {
                            if (username != null && username.length > 3) {
                              return null;
                            }
                            return "can't be smaller than 4 letters";
                          },
                          borderColor: Colors.blueAccent,
                          errorColor: Colors.deepOrangeAccent,
                        ),
                        TextInputSettingsTile(
                          title: 'Delivery Challan',
                          settingKey: 'key-journal-delivery-challan-head',
                          initialValue: 'Delivery Challan',
                          validator: (String username) {
                            if (username != null && username.length > 3) {
                              return null;
                            }
                            return "can't be smaller than 4 letters";
                          },
                          borderColor: Colors.blueAccent,
                          errorColor: Colors.deepOrangeAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            )),
        SimpleSettingsTile(
            title: 'PDF',
            subtitle: 'Pdf Settings',
            child: SettingsScreen(
              title: 'Pdf Settings',
              children: [
                SwitchSettingsTile(
                  settingKey: 'key-pdf-logo',
                  title: 'Show Logo On Pdf',
                  subtitle: 'Set Logo First On Settings',
                  enabledLabel: 'Enabled',
                  disabledLabel: 'Disabled',
                  // leading: Icon(Icons.receipt_long),
                  onChange: (value) {
                    debugPrint('key-pdf-logo: $value');
                  },
                ),
                DropDownSettingsTile<int>(
                  title: 'Pdf Type',
                  settingKey: 'key-dropdown-pdf-type-view',
                  values: const <int, String>{
                    2: 'Document',
                    3: 'Invoice Designer',
                  },
                  selected: 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-pdf-type-view: $value');
                  },
                ),
                DropDownSettingsTile<int>(
                  title: 'Paper Size',
                  settingKey: 'key-dropdown-pdf-size-view',
                  values: const <int, String>{
                    2: 'A4',
                    3: 'A3',
                    4: 'A5',
                    5: 'A6',
                    6: 'LETTER',
                    7: 'LEGAL',
                    8: 'ROLL57',
                    9: 'ROLL80',
                    10: 'STANDARD',
                    11: 'UNDEFINED',
                    12: 'POINT',
                    13: 'INCH',
                    14: 'CM',
                    15: 'MM'
                  },
                  selected: 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-pdf-size-view: $value');
                  },
                ),
                DropDownSettingsTile<int>(
                  title: 'Pdf Copy',
                  settingKey: 'key-dropdown-pdf-copy-view',
                  values: const <int, String>{
                    2: '1',
                    3: '2',
                    4: '3',
                    5: '4',
                    6: '5',
                  },
                  selected: 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-pdf-copy-view: $value');
                  },
                ),
                DropDownSettingsTile<int>(
                  title: 'Pdf Model',
                  settingKey: 'key-dropdown-pdf-model-view',
                  values: const <int, String>{
                    2: 'Default',
                    3: 'VAT',
                    4: 'GST',
                    5: 'VAT1',
                    6: 'Other',
                    7: 'VAT2',
                    8: 'VAT3',
                    9: 'A4Half',
                    10: 'VatA4Half',
                    11: 'GstA4Half',
                  },
                  selected: 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-pdf-model-view: $value');
                  },
                ),
                DropDownSettingsTile<int>(
                  title: 'Pdf Space',
                  settingKey: 'key-dropdown-pdf-line',
                  values: const <int, String>{
                    2: '1',
                    3: '2',
                    4: '3',
                    5: '4',
                    6: '5',
                    7: '6',
                    8: '7',
                    9: '8',
                    10: '9',
                    11: '10',
                    12: '11',
                    13: '12',
                    14: '13',
                    15: '14',
                    16: '15',
                    17: '16',
                    18: '17',
                    19: '18',
                    20: '19',
                    21: '20',
                    22: '21',
                    23: '22',
                    24: '23',
                    25: '24',
                    26: '25',
                    27: '26',
                    28: '27',
                    29: '28',
                    30: '29',
                    31: '30',
                    32: '31',
                    33: '32',
                    34: '33',
                    35: '34',
                    36: '35',
                    37: '36',
                    38: '37',
                    39: '38',
                    40: '39',
                    41: '40',
                    42: '41',
                    43: '42',
                    44: '43',
                    45: '44',
                    46: '45',
                    47: '46',
                    48: '47',
                    49: '48',
                    50: '49',
                    51: '50',
                    52: '51',
                    53: '52',
                    54: '53',
                    55: '54',
                    56: '55',
                    57: '56',
                    58: '57',
                    59: '58',
                    60: '59',
                  },
                  selected: 2,
                  onChange: (value) {
                    debugPrint('key-dropdown-pdf-line: $value');
                  },
                ),
              ],
            )),
        OutlinedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/InvoiceModels');
            },
            child: const Text('Invoice preview model')),
        //User
        SwitchSettingsTile(
          leading: const Icon(Icons.screen_lock_portrait),
          settingKey: 'key-switch-user-mode',
          title: 'User Settings',
          onChange: (value) {
            debugPrint('key-switch-user-mod: $value');
          },
          childrenIfEnabled: [
            TextButton.icon(
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(kPrimaryColor),
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Colors.white),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/passCode_Auth');
                },
                icon: const Icon(Icons.lock),
                label: const Text('Secure App'))
            // TextInputSettingsTile(
            //   title: 'User Name',
            //   settingKey: 'key-user-name',
            //   initialValue: 'admin',
            //   validator: (String username) {
            //     if (username != null && username.length > 3) {
            //       return null;
            //     }
            //     return "User Name can't be smaller than 4 letters";
            //   },
            //   borderColor: Colors.blueAccent,
            //   errorColor: Colors.deepOrangeAccent,
            // ),
            // TextInputSettingsTile(
            //   title: 'password',
            //   settingKey: 'key-user-password',
            //   initialValue: 'admin',
            //   obscureText: true,
            //   validator: (String password) {
            //     if (password != null && password.length > 6) {
            //       return null;
            //     }
            //     return "Password can't be smaller than 7 letters";
            //   },
            //   borderColor: Colors.blueAccent,
            //   errorColor: Colors.deepOrangeAccent,
            // ),
          ],
        ),
        //   ModalSettingsTile(
        //     title: 'Quick setting dialog',
        //     subtitle: 'Settings on a dialog',
        //     children: [
        //       CheckboxSettingsTile(
        //         settingKey: 'key-day-light-savings',
        //         title: 'Daylight Time Saving',
        //         enabledLabel: 'Enabled',
        //         disabledLabel: 'Disabled',
        //         leading: Icon(Icons.timelapse),
        //         onChange: (value) {
        //           debugPrint('key-day-light-saving: $value');
        //         },
        //       ),
        //       SwitchSettingsTile(
        //         settingKey: 'key-dark-mode',
        //         title: 'Dark Mode',
        //         enabledLabel: 'Enabled',
        //         disabledLabel: 'Disabled',
        //         leading: Icon(Icons.palette),
        //         onChange: (value) {
        //           debugPrint('jey-dark-mode: $value');
        //         },
        //       ),
        //     ],
        //   ),
        //   ExpandableSettingsTile(
        //     title: 'Quick setting 2',
        //     subtitle: 'Expandable Settings',
        //     children: [
        //       CheckboxSettingsTile(
        //         settingKey: 'key-day-light-savings-2',
        //         title: 'Daylight Time Saving',
        //         enabledLabel: 'Enabled',
        //         disabledLabel: 'Disabled',
        //         leading: Icon(Icons.timelapse),
        //         onChange: (value) {
        //           debugPrint('key-day-light-savings-2: $value');
        //         },
        //       ),
        //       SwitchSettingsTile(
        //         settingKey: 'key-dark-mode-2',
        //         title: 'Dark Mode',
        //         enabledLabel: 'Enabled',
        //         disabledLabel: 'Disabled',
        //         leading: Icon(Icons.palette),
        //         onChange: (value) {
        //           debugPrint('key-dark-mode-2: $value');
        //         },
        //       ),
        //     ],
        //   ),
        // ],
        // ),
        // SettingsGroup(
        //   title: 'Multiple choice settings',
        //   children: [
        //     RadioSettingsTile<int>(
        //       title: 'Preferred Sync Period',
        //       settingKey: 'key-radio-sync-period',
        //       values: <int, String>{
        //         0: 'Never',
        //         1: 'Daily',
        //         7: 'Weekly',
        //         15: 'Fortnight',
        //         30: 'Monthly',
        //       },
        //       selected: 0,
        //       onChange: (value) {
        //         debugPrint('key-radio-sync-period: $value');
        //       },
        //     ),
        //     DropDownSettingsTile<int>(
        //       title: 'E-Mail View',
        //       settingKey: 'key-dropdown-email-view',
        //       values: <int, String>{
        //         2: 'Simple',
        //         3: 'Adjusted',
        //         4: 'Normal',
        //         5: 'Compact',
        //         6: 'Squizzed',
        //       },
        //       selected: 2,
        //       onChange: (value) {
        //         debugPrint('key-dropdown-email-view: $value');
        //       },
        //     ),
        //   ],
        // ),
        // ModalSettingsTile(
        //   title: 'Group Settings',
        //   subtitle: 'Same group settings but in a dialog',
        //   children: [
        //     SimpleRadioSettingsTile(
        //       title: 'Sync Settings',
        //       settingKey: 'key-radio-sync-settings',
        //       values: <String>[
        //         'Never',
        //         'Daily',
        //         'Weekly',
        //         'Fortnight',
        //         'Monthly',
        //       ],
        //       selected: 'Daily',
        //       onChange: (value) {
        //         debugPrint('key-radio-sync-settins: $value');
        //       },
        //     ),
        //     SimpleDropDownSettingsTile(
        //       title: 'Beauty Filter',
        //       settingKey: 'key-dropdown-beauty-filter',
        //       values: <String>[
        //         'Simple',
        //         'Normal',
        //         'Little Special',
        //         'Special',
        //         'Extra Special',
        //         'Bizzar',
        //         'Horrific',
        //       ],
        //       selected: 'Special',
        //       onChange: (value) {
        //         debugPrint('key-dropdown-beauty-filter: $value');
        //       },
        //     )
        //   ],
        // ),
        // ExpandableSettingsTile(
        //   title: 'Expandable Group Settings',
        //   subtitle: 'Group of settings (expandable)',
        //   children: [
        //     RadioSettingsTile<double>(
        //       title: 'Beauty Filter',
        //       settingKey: 'key-radio-beauty-filter-exapndable',
        //       values: <double, String>{
        //         1.0: 'Simple',
        //         1.5: 'Normal',
        //         2.0: 'Little Special',
        //         2.5: 'Special',
        //         3.0: 'Extra Special',
        //         3.5: 'Bizzar',
        //         4.0: 'Horrific',
        //       },
        //       selected: 2.5,
        //       onChange: (value) {
        //         debugPrint('key-radio-beauty-filter-expandable: $value');
        //       },
        //     ),
        //     DropDownSettingsTile<int>(
        //       title: 'Preferred Sync Period',
        //       settingKey: 'key-dropdown-sync-period-2',
        //       values: <int, String>{
        //         0: 'Never',
        //         1: 'Daily',
        //         7: 'Weekly',
        //         15: 'Fortnight',
        //         30: 'Monthly',
        //       },
        //       selected: 0,
        //       onChange: (value) {
        //         debugPrint('key-dropdown-sync-period-2: $value');
        //       },
        //     )
        //   ],
        // ),
        // SettingsGroup(
        //   title: 'Other settings',
        //   children: [
        //     SliderSettingsTile(
        //       title: 'Volume',
        //       settingKey: 'key-slider-volume',
        //       defaultValue: 20,
        //       min: 0,
        //       max: 100,
        //       step: 5,
        //       leading: Icon(Icons.volume_up),
        //       onChangeEnd: (value) {
        //         debugPrint('\n===== on change end =====\n'
        //             'key-slider-volume: $value'
        //             '\n==========\n');
        //       },
        //     ),
        //     ColorPickerSettingsTile(
        //       settingKey: 'key-color-picker',
        //       title: 'Accent Color',
        //       defaultValue: Colors.blue,
        //       onChange: (value) {
        //         debugPrint('key-color-picker: $value');
        //       },
        //     )
        //   ],
        // ),
        // ModalSettingsTile(
        //   title: 'Other settings',
        //   subtitle: 'Other Settings in a Dialog',
        //   children: [
        //     SliderSettingsTile(
        //       title: 'Custom Ratio',
        //       settingKey: 'key-custom-ratio-slider-2',
        //       defaultValue: 2.5,
        //       min: 1,
        //       max: 5,
        //       step: 0.1,
        //       leading: Icon(Icons.aspect_ratio),
        //       onChange: (value) {
        //         debugPrint('\n===== on change =====\n'
        //             'key-custom-ratio-slider-2: $value'
        //             '\n==========\n');
        //       },
        //       onChangeStart: (value) {
        //         debugPrint('\n===== on change start =====\n'
        //             'key-custom-ratio-slider-2: $value'
        //             '\n==========\n');
        //       },
        //       onChangeEnd: (value) {
        //         debugPrint('\n===== on change end =====\n'
        //             'key-custom-ratio-slider-2: $value'
        //             '\n==========\n');
        //       },
        //     ),
        //     ColorPickerSettingsTile(
        //       settingKey: 'key-color-picker-2',
        //       title: 'Accent Picker',
        //       defaultValue: Colors.blue,
        //       onChange: (value) {
        //         debugPrint('key-color-picker-2: $value');
        //       },
        //     )
        //   ],
        // ),
        Center(
          child: Card(
            child: TextButton(
                onPressed: () {
                  Settings.clearCache();
                  Fluttertoast.showToast(msg: 'Reset Ok');
                },
                child: Text(
                  'Reset',
                  style: Theme.of(context).textTheme.headline6,
                )),
          ),
        ),
        Center(
          child: Card(
            child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => const AddLogo()));
                },
                child: Text(
                  'Add Logo',
                  style: Theme.of(context).textTheme.headline6,
                )),
          ),
        )
      ],
    );
  }

  savePref(String key, String value) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString(key, value);
  }
}

class AppSettingsMap {
  int key;
  String value;
  AppSettingsMap({this.key, this.value});

  @override
  String toString() {
    return '{ $key, $value }';
  }
}

class DropDownSettingsTileNew<T> extends StatefulWidget {
  /// Settings Key string for storing the state of Radio buttons in cache (assumed to be unique)
  final String settingKey;

  /// Selected value in the radio button group otherwise known as group value
  final T selected;

  /// A map containing unique values along with the display name
  final Map<T, String> values;

  /// title for the settings tile
  final String title;

  /// subtitle for the settings tile, default = ''
  final String subtitle;

  /// flag which represents the state of the settings, if false the the tile will
  /// ignore all the user inputs, default = true
  final bool enabled;

  /// on change callback for handling the value change
  final OnChanged<T> onChange;

  const DropDownSettingsTileNew({
    Key key,
    @required this.title,
    @required this.settingKey,
    @required this.selected,
    @required this.values,
    this.enabled = true,
    this.onChange,
    this.subtitle = '',
  }) : super(key: key);

  @override
  _DropDownSettingsTileNewState<T> createState() =>
      _DropDownSettingsTileNewState<T>();
}

class _DropDownSettingsTileNewState<T>
    extends State<DropDownSettingsTileNew<T>> {
  T selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return ValueChangeObserver<T>(
      cacheKey: widget.settingKey,
      defaultValue: selectedValue,
      builder: (BuildContext context, T value, OnChanged<T> onChanged) {
        return SettingsContainer(
          children: [
            _SettingsTile(
              title: widget.title,
              subtitle: widget.subtitle,
              enabled: widget.enabled,
              showChildBelow: true,
              child: _SettingsDropDown<T>(
                selected: value,
                values: widget.values.keys.toList().cast<T>(),
                onChanged: (T newValue) {
                  _handleDropDownChange(newValue, onChanged);
                },
                enabled: widget.enabled,
                itemBuilder: (T value) {
                  return Text(
                    widget.values[value],
                    // style: TextStyle(fontSize: 10),
                  );
                },
              ),
            )
          ],
        );
      },
    );
  }

  Future<void> _handleDropDownChange(T value, OnChanged<T> onChanged) async {
    selectedValue = value;
    onChanged(value);
    widget.onChange?.call(value);
  }
}

class _SettingsTile extends StatefulWidget {
  /// title string for the tile
  final String title;

  /// widget to be placed at first in the tile
  final Widget leading;

  /// subtitle string for the tile
  final String subtitle;

  /// flag to represent if the tile is accessible or not, if false user input is ignored
  final bool enabled;

  /// widget which is placed as the main element of the tile as settings UI
  final Widget child;

  /// call back for handling the tap event on tile
  final GestureTapCallback onTap;

  /// flag to show the child below the main tile elements
  final bool showChildBelow;

  const _SettingsTile({
    @required this.title,
    @required this.child,
    this.subtitle = '',
    this.onTap,
    this.enabled = true,
    this.showChildBelow = false,
    this.leading,
  });

  @override
  __SettingsTileState createState() => __SettingsTileState();
}

class __SettingsTileState extends State<_SettingsTile> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: widget.leading,
            title: Text(
              widget.title,
              style: headerTextStyle(context),
            ),
            subtitle: widget.subtitle.isEmpty
                ? null
                : Text(
                    widget.subtitle,
                    style: subtitleTextStyle(context),
                  ),
            enabled: widget.enabled,
            onTap: widget.onTap,
            trailing: Visibility(
              visible: !widget.showChildBelow,
              child: widget.child,
            ),
            dense: true,
            // wrap only if the subtitle is longer than 70 characters
            isThreeLine: (widget.subtitle?.isNotEmpty ?? false) &&
                widget.subtitle.length > 70,
          ),
          Visibility(
            visible: widget.showChildBelow,
            child: widget.child,
          ),
          const Divider(),
        ],
      ),
    );
  }
}

class _SettingsDropDown<T> extends StatelessWidget {
  /// value of the selected in this dropdown
  final T selected;

  /// List of values for this dropdown
  final List<T> values;

  /// on change call back to handle selected value change
  final OnChanged<T> onChanged;

  /// single item builder for creating a [DropdownMenuItem]
  final ItemBuilder<T> itemBuilder;

  /// flag which represents the state of the settings, if false the the tile will
  /// ignore all the user inputs
  final bool enabled;

  const _SettingsDropDown({
    @required this.selected,
    @required this.values,
    @required this.onChanged,
    this.itemBuilder,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      children: [
        DropdownButton<T>(
          isDense: true,
          value: selected,
          onChanged: enabled ? onChanged : null,
          underline: Container(),
          items: values.map<DropdownMenuItem<T>>(
            (T val) {
              return DropdownMenuItem<T>(
                value: val,
                child: itemBuilder(val),
              );
            },
          ).toList(),
        ),
      ],
    );
  }
}

TextStyle headerTextStyle(BuildContext context) =>
    Theme.of(context).textTheme.headline6.copyWith(fontSize: 16.0);

TextStyle subtitleTextStyle(BuildContext context) => Theme.of(context)
    .textTheme
    .subtitle2
    .copyWith(fontSize: 13.0, fontWeight: FontWeight.normal);
