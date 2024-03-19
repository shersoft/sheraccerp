class VoucherType {
  int id;
  String name;
  String voucher;
  String abbr;
  int location;
  int active;
  int tax;
  int sentry;
  VoucherType({
    required this.id,
    required this.name,
    required this.voucher,
    required this.abbr,
    required this.location,
    required this.active,
    required this.tax,
    required this.sentry,
  });

  Map<String, dynamic> toMap() {
    return {
      'entry': id,
      'name': name,
      'voucher': voucher,
      'abbr': abbr,
      'location': location,
      'active': active,
      'tax': tax,
      'sentry': sentry,
    };
  }

  factory VoucherType.fromMap(Map<String, dynamic> map) {
    return VoucherType(
      id: map['entry']?.toInt() ?? 0,
      name: map['name'] ?? '',
      voucher: map['voucher'] ?? '',
      abbr: map['abbr'] ?? '',
      location: map['location']?.toInt() ?? 0,
      active: map['active']?.toInt() ?? 0,
      tax: map['tax']?.toInt() ?? 0,
      sentry: map['sentry']?.toInt() ?? 0,
    );
  }

  static VoucherType emptyData() {
    return VoucherType(
        id: 0,
        name: '',
        voucher: '',
        abbr: '',
        location: 0,
        active: 0,
        tax: 0,
        sentry: 0);
  }
}
