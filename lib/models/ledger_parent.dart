class LedgerParent {
  final int id;
  final String name;

  LedgerParent({required this.id, required this.name});

  factory LedgerParent.fromJson(Map<String, dynamic> json) {
    return LedgerParent(id: json['lh_id'], name: json['lh_name']);
  }
}
