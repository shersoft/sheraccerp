// @dart = 2.11
class SalesManModel {
  int id;
  String name, empCode, employeeSection;
  double salary;
  bool active;

  SalesManModel(
      {this.id,
      this.name,
      this.empCode,
      this.employeeSection,
      this.salary,
      this.active});

  factory SalesManModel.fromJson(Map<String, dynamic> json) {
    return SalesManModel(
      id: json['Auto'],
      name: json['name'],
      empCode: json['emp_code'],
      employeeSection: json['EmployeeSection'],
      salary: json['Salary'],
      active: json['Active'] == 1 ? true : false,
    );
  }
}
