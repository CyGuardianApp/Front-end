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
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: UserRole.values.firstWhere(
        (role) => role.toString() == json['role'],
      ),
      departmentId: json['departmentId'],
      departmentName: json['departmentName'],
      company: json['company'], // Add company field
    );
  }
}

enum UserRole {
  cto,
  cyberSecurityHead,
  subDepartmentHead,
}
