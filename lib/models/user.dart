class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String departmentId;
  final String? departmentName;
  final String? company; // Add company field

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.departmentId,
    this.departmentName,
    this.company, // Add company field
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => UserRole.subDepartmentHead,
      ),
      departmentId: json['department_id'] ?? json['departmentId'] ?? '',
      departmentName: json['department_name'] ?? json['departmentName'],
      company: json['company'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'department_id': departmentId,
      'department_name': departmentName,
      'company': company,
    };
  }
}

enum UserRole {
  cto,
  cyberSecurityHead,
  subDepartmentHead,
}
