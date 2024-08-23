class CartItem {
  String itemName, serialNo, expDate;
  double quantity,
      stock,
      rate,
      rRate,
      gross,
      fCess,
      discount,
      discountPercent,
      rDiscount,
      tax,
      taxP,
      pRate,
      rPRate,
      unitValue,
      free,
      cdPer,
      cDisc,
      net,
      cess,
      total,
      profitPer,
      fUnitValue,
      adCess,
      iGST,
      cGST,
      sGST,
      minimumRate,
      cessPer,
      adCessPer;
  int id, itemId, fUnitId, unitId, barcode, uniqueCode;
  CartItem(
      {required this.id,
      required this.itemId,
      required this.itemName,
      required this.serialNo,
      required this.uniqueCode,
      required this.fCess,
      required this.unitId,
      required this.quantity,
      required this.rate,
      required this.rRate,
      required this.gross,
      required this.discount,
      required this.discountPercent,
      required this.rDiscount,
      required this.tax,
      required this.taxP,
      required this.unitValue,
      required this.pRate,
      required this.rPRate,
      required this.barcode,
      required this.expDate,
      required this.free,
      required this.fUnitId,
      required this.cdPer,
      required this.cDisc,
      required this.net,
      required this.cess,
      required this.total,
      required this.profitPer,
      required this.fUnitValue,
      required this.adCess,
      required this.iGST,
      required this.cGST,
      required this.sGST,
      required this.stock,
      required this.minimumRate,
      required this.cessPer,
      required this.adCessPer});

  Map<String, dynamic> toCartJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'serialNo': serialNo,
      'uniqueCode': uniqueCode,
      'fCess': fCess,
      'unit': unitId,
      'quantity': quantity,
      'rate': rate,
      'rRate': rRate,
      'gross': gross,
      'discount': discount,
      'discountPercent': discountPercent,
      'rDiscount': rDiscount,
      'tax': tax,
      'taxP': taxP,
      'unitValue': unitValue,
      'pRate': pRate,
      'rPRate': rPRate,
      'barcode': barcode,
      'expDate': expDate,
      'free': free,
      'fUnitId': fUnitId,
      'cdPer': cdPer,
      'cDisc': cDisc,
      'net': net,
      'cess': cess,
      'total': total,
      'profitPer': profitPer,
      'fUnitValue': fUnitValue,
      'adCess': adCess,
      'iGST': iGST,
      'cGST': cGST,
      'sGST': sGST,
      'stock': stock,
      'minimumRate': minimumRate,
      'cessPer': cessPer,
      'adCessPer': adCessPer
    };
  }

  static List encodeCartToJson(List<CartItem> list) {
    List jsonList = [];
    list.map((item) => jsonList.add(item.toCartJson())).toList();
    return jsonList;
  }

  Map toCartMap() {
    var map = {};
    map["id"] = id;
    map['itemId'] = itemId;
    map["itemName"] = itemName;
    map["serialNo"] = serialNo;
    map["uniqueCode"] = uniqueCode;
    map["fCess"] = fCess;
    map["unit"] = unitId;
    map["quantity"] = quantity;
    map["rate"] = rate;
    map['rRate'] = rRate;
    map["gross"] = gross;
    map["discount"] = discount;
    map["discountPercent"] = discountPercent;
    map["rDiscount"] = rDiscount;
    map["tax"] = tax;
    map["taxP"] = taxP;
    map["unitValue"] = unitValue;
    map["pRate"] = pRate;
    map['rPRate'] = rPRate;
    map['barcode'] = barcode;
    map['expDate'] = expDate;
    map['free'] = free;
    map['fUnitId'] = fUnitId;
    map['cdPer'] = cdPer;
    map['cDisc'] = cDisc;
    map['net'] = net;
    map['cess'] = cess;
    map['total'] = total;
    map['profitPer'] = profitPer;
    map['fUnitValue'] = fUnitValue;
    map['adCess'] = adCess;
    map['iGST'] = iGST;
    map['cGST'] = cGST;
    map['sGST'] = sGST;
    map['stock'] = stock;
    map['minimumRate'] = minimumRate;
    map['cessPer'] = cessPer;
    map['adCessPer'] = adCessPer;
    return map;
  }
}

class CartItemP {
  String itemName, serialNo, expDate, unitName;
  double quantity,
      rate,
      rRate,
      gross,
      fCess,
      discount,
      discountPercent,
      mrp,
      tax,
      taxP,
      retail,
      spRetail,
      unitValue,
      free,
      cdPer,
      cDisc,
      net,
      cess,
      total,
      wholesale,
      fUnitValue,
      adCess,
      iGST,
      cGST,
      sGST,
      branch,
      profitPer,
      expense,
      mrpPer,
      wholesalePer,
      retailPer,
      spRetailPer,
      branchPer;
  int id,
      itemId,
      unitId,
      fUnitId,
      barcode,
      uniqueCode,
      location,
      estUniqueCode,
      brand,
      company,
      size,
      color,
      expenseQty;
  CartItemP(
      {required this.id,
      required this.itemId,
      required this.itemName,
      required this.serialNo,
      required this.uniqueCode,
      required this.fCess,
      required this.unitId,
      required this.quantity,
      required this.rate,
      required this.rRate,
      required this.gross,
      required this.discount,
      required this.discountPercent,
      required this.mrp,
      required this.tax,
      required this.taxP,
      required this.unitValue,
      required this.retail,
      required this.spRetail,
      required this.barcode,
      required this.expDate,
      required this.free,
      required this.fUnitId,
      required this.cdPer,
      required this.cDisc,
      required this.net,
      required this.cess,
      required this.total,
      required this.wholesale,
      required this.fUnitValue,
      required this.adCess,
      required this.iGST,
      required this.cGST,
      required this.sGST,
      required this.branch,
      required this.profitPer,
      required this.location,
      required this.expense,
      required this.mrpPer,
      required this.wholesalePer,
      required this.retailPer,
      required this.spRetailPer,
      required this.branchPer,
      required this.unitName,
      required this.estUniqueCode,
      required this.brand,
      required this.company,
      required this.size,
      required this.color,
      required this.expenseQty});

  Map<String, dynamic> toCartJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'serialNo': serialNo,
      'uniqueCode': uniqueCode,
      'fCess': fCess,
      'unit': unitId,
      'quantity': quantity,
      'rate': rate,
      'rRate': rRate,
      'gross': gross,
      'discount': discount,
      'discountPercent': discountPercent,
      'mrp': mrp,
      'tax': tax,
      'taxP': taxP,
      'unitValue': unitValue,
      'retail': retail,
      'spRetail': spRetail,
      'barcode': barcode,
      'expDate': expDate,
      'free': free,
      'fUnitId': fUnitId,
      'cdPer': cdPer,
      'cDisc': cDisc,
      'net': net,
      'cess': cess,
      'total': total,
      'wholesale': wholesale,
      'fUnitValue': fUnitValue,
      'adCess': adCess,
      'iGST': iGST,
      'cGST': cGST,
      'sGST': sGST,
      'branch': branch,
      'profitPer': profitPer,
      'location': location,
      'expense': expense,
      'mrpPer': mrpPer,
      'wholesalePer': wholesalePer,
      'retailPer': retailPer,
      'spRetailPer': spRetailPer,
      'branchPer': branchPer,
      'unitName': unitName,
      'estUniqueCode': estUniqueCode,
      'brand': brand,
      'company': company,
      'size': size,
      'color': color,
      'expenseQty': expenseQty
    };
  }

  static List encodeCartToJson(List<CartItemP> list) {
    List jsonList = [];
    list.map((item) => jsonList.add(item.toCartJson())).toList();
    return jsonList;
  }

  Map toCartMap() {
    var map = {};
    map["id"] = id;
    map['itemId'] = itemId;
    map["itemName"] = itemName;
    map["serialNo"] = serialNo;
    map["uniqueCode"] = uniqueCode;
    map["fCess"] = fCess;
    map["unit"] = unitId;
    map["quantity"] = quantity;
    map["rate"] = rate;
    map['rRate'] = rRate;
    map["gross"] = gross;
    map["discount"] = discount;
    map["discountPercent"] = discountPercent;
    map["mrp"] = mrp;
    map["tax"] = tax;
    map["taxP"] = taxP;
    map["unitValue"] = unitValue;
    map["retail"] = retail;
    map['spRetail'] = spRetail;
    map['barcode'] = barcode;
    map['expDate'] = expDate;
    map['free'] = free;
    map['fUnitId'] = fUnitId;
    map['cdPer'] = cdPer;
    map['cDisc'] = cDisc;
    map['net'] = net;
    map['cess'] = cess;
    map['total'] = total;
    map['wholesale'] = wholesale;
    map['fUnitValue'] = fUnitValue;
    map['adCess'] = adCess;
    map['iGST'] = iGST;
    map['cGST'] = cGST;
    map['sGST'] = sGST;
    map['branch'] = branch;
    map['profitPer'] = profitPer;
    map['location'] = location;
    map['expense'] = expense;
    map['mrpPer'] = mrpPer;
    map['wholesalePer'] = wholesalePer;
    map['retailPer'] = retailPer;
    map['spRetailPer'] = spRetailPer;
    map['branchPer'] = branchPer;
    map['unitName'] = unitName;
    map['estUniqueCode'] = estUniqueCode;
    map['brand'] = brand;
    map['company'] = company;
    map['size'] = size;
    map['color'] = color;
    map['expenseQty'] = expenseQty;
    return map;
  }
}

class CartItemOP {
  String itemName, serialNo, expDate, unitName, supplier;
  double quantity,
      rate,
      rRate,
      gross,
      fCess,
      discount,
      discountPercent,
      mrp,
      tax,
      taxP,
      retail,
      spRetail,
      unitValue,
      free,
      cdPer,
      cDisc,
      net,
      cess,
      total,
      wholesale,
      fUnitValue,
      adCess,
      iGST,
      cGST,
      sGST,
      branch,
      profitPer,
      expense,
      mrpPer,
      wholesalePer,
      retailPer,
      spRetailPer,
      branchPer;
  int id, itemId, unitId, fUnitId, barcode, uniqueCode, location, supplierId;
  CartItemOP(
      {required this.id,
      required this.itemId,
      required this.itemName,
      required this.serialNo,
      required this.uniqueCode,
      required this.fCess,
      required this.unitId,
      required this.quantity,
      required this.rate,
      required this.rRate,
      required this.gross,
      required this.discount,
      required this.discountPercent,
      required this.mrp,
      required this.tax,
      required this.taxP,
      required this.unitValue,
      required this.retail,
      required this.spRetail,
      required this.barcode,
      required this.expDate,
      required this.free,
      required this.fUnitId,
      required this.cdPer,
      required this.cDisc,
      required this.net,
      required this.cess,
      required this.total,
      required this.wholesale,
      required this.fUnitValue,
      required this.adCess,
      required this.iGST,
      required this.cGST,
      required this.sGST,
      required this.branch,
      required this.profitPer,
      required this.location,
      required this.expense,
      required this.mrpPer,
      required this.wholesalePer,
      required this.retailPer,
      required this.spRetailPer,
      required this.branchPer,
      required this.unitName,
      required this.supplierId,
      required this.supplier});

  Map<String, dynamic> toCartJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'serialNo': serialNo,
      'uniqueCode': uniqueCode,
      'fCess': fCess,
      'unit': unitId,
      'quantity': quantity,
      'rate': rate,
      'rRate': rRate,
      'gross': gross,
      'discount': discount,
      'discountPercent': discountPercent,
      'mrp': mrp,
      'tax': tax,
      'taxP': taxP,
      'unitValue': unitValue,
      'retail': retail,
      'spRetail': spRetail,
      'barcode': barcode,
      'expDate': expDate,
      'free': free,
      'fUnitId': fUnitId,
      'cdPer': cdPer,
      'cDisc': cDisc,
      'net': net,
      'cess': cess,
      'total': total,
      'wholesale': wholesale,
      'fUnitValue': fUnitValue,
      'adCess': adCess,
      'iGST': iGST,
      'cGST': cGST,
      'sGST': sGST,
      'branch': branch,
      'profitPer': profitPer,
      'location': location,
      'expense': expense,
      'mrpPer': mrpPer,
      'wholesalePer': wholesalePer,
      'retailPer': retailPer,
      'spRetailPer': spRetailPer,
      'branchPer': branchPer,
      'unitName': unitName,
      'supplierId': supplierId,
      'supplier': supplier
    };
  }

  static List encodeCartToJson(List<CartItemOP> list) {
    List jsonList = [];
    list.map((item) => jsonList.add(item.toCartJson())).toList();
    return jsonList;
  }

  Map toCartMap() {
    var map = {};
    map["id"] = id;
    map['itemId'] = itemId;
    map["itemName"] = itemName;
    map["serialNo"] = serialNo;
    map["uniqueCode"] = uniqueCode;
    map["fCess"] = fCess;
    map["unit"] = unitId;
    map["quantity"] = quantity;
    map["rate"] = rate;
    map['rRate'] = rRate;
    map["gross"] = gross;
    map["discount"] = discount;
    map["discountPercent"] = discountPercent;
    map["mrp"] = mrp;
    map["tax"] = tax;
    map["taxP"] = taxP;
    map["unitValue"] = unitValue;
    map["retail"] = retail;
    map['spRetail'] = spRetail;
    map['barcode'] = barcode;
    map['expDate'] = expDate;
    map['free'] = free;
    map['fUnitId'] = fUnitId;
    map['cdPer'] = cdPer;
    map['cDisc'] = cDisc;
    map['net'] = net;
    map['cess'] = cess;
    map['total'] = total;
    map['wholesale'] = wholesale;
    map['fUnitValue'] = fUnitValue;
    map['adCess'] = adCess;
    map['iGST'] = iGST;
    map['cGST'] = cGST;
    map['sGST'] = sGST;
    map['branch'] = branch;
    map['profitPer'] = profitPer;
    map['location'] = location;
    map['expense'] = expense;
    map['mrpPer'] = mrpPer;
    map['wholesalePer'] = wholesalePer;
    map['retailPer'] = retailPer;
    map['spRetailPer'] = spRetailPer;
    map['branchPer'] = branchPer;
    map['unitName'] = unitName;
    map['supplierId'] = supplierId;
    map['supplier'] = supplier;
    return map;
  }
}

class CartItemST {
  String itemName, serialNo, unitName;
  double quantity,
      rate,
      rRate,
      gross,
      mrp,
      retail,
      spRetail,
      unitValue,
      wholesale,
      branch,
      stock;
  int id, itemId, unitId, barcode, uniqueCode, stUniqueCode;
  CartItemST(
      {required this.id,
      required this.itemId,
      required this.itemName,
      required this.serialNo,
      required this.uniqueCode,
      required this.unitId,
      required this.quantity,
      required this.rate,
      required this.rRate,
      required this.gross,
      required this.mrp,
      required this.unitValue,
      required this.retail,
      required this.spRetail,
      required this.barcode,
      required this.wholesale,
      required this.branch,
      required this.unitName,
      required this.stUniqueCode,
      required this.stock});

  Map<String, dynamic> toCartJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'serialNo': serialNo,
      'uniqueCode': uniqueCode,
      'unit': unitId,
      'quantity': quantity,
      'rate': rate,
      'rRate': rRate,
      'gross': gross,
      'mrp': mrp,
      'unitValue': unitValue,
      'retail': retail,
      'spRetail': spRetail,
      'barcode': barcode,
      'wholesale': wholesale,
      'branch': branch,
      'unitName': unitName,
      'stUniqueCode': stUniqueCode,
      'stock': stock
    };
  }

  static List encodeCartToJson(List<CartItemST> list) {
    List jsonList = [];
    list.map((item) => jsonList.add(item.toCartJson())).toList();
    return jsonList;
  }

  Map toCartMap() {
    var map = {};
    map["id"] = id;
    map['itemId'] = itemId;
    map["itemName"] = itemName;
    map["serialNo"] = serialNo;
    map["uniqueCode"] = uniqueCode;
    map["unit"] = unitId;
    map["quantity"] = quantity;
    map["rate"] = rate;
    map['rRate'] = rRate;
    map["gross"] = gross;
    map["mrp"] = mrp;
    map["unitValue"] = unitValue;
    map["retail"] = retail;
    map['spRetail'] = spRetail;
    map['barcode'] = barcode;
    map['wholesale'] = wholesale;
    map['branch'] = branch;
    map['unitName'] = unitName;
    map['stock'] = unitName;
    map['stUniqueCode'] = stUniqueCode;
    return map;
  }
}
