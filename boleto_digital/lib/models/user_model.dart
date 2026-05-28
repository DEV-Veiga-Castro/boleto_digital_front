import 'dart:convert';

class User {
  int? id;
  String? username;
  String? name;
  String? surname;
  String? email;
  String? dataNascimento;
  String? cpf;
  bool? isActive;
  bool? isValidated;
  bool? isAdmin;
  Map<String, dynamic> role;
  List<Map<String, dynamic>> branch;
  List<String> permissions;

  User(
      {required this.id,
      required this.username,
      required this.name,
      required this.surname,
      required this.email,
      required this.dataNascimento,
      required this.cpf,
      required this.isActive,
      required this.isValidated,
      required this.isAdmin,
      required this.role,
      required this.branch,
      required this.permissions}
  );

  factory User.fromJson(Map<String, dynamic> json) => User(
      id: json['id'] as int?,
      username: json['username'] as String?,
      name: json['name'] as String?,
      surname: json['surname'] as String?,
      email: json['email'] as String?,
      dataNascimento: json['data_nascimento'] as String?,
      cpf: json['cpf'] as String?,
      isActive: json['is_active'] as bool?,
      isValidated: json['is_validated'] as bool?,
      isAdmin: json['is_admin'] as bool?,
      role: json['role'] ?? {},
      branch: List<Map<String, dynamic>>.from(json['branch'] ?? []),
      permissions: List<String>.from(json['permissions'] ?? [])
    );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'name': name,
    'surname': surname,
    'email': email,
    'data_nascimento': dataNascimento,
    'cpf': cpf,
    'is_active': isActive,
    'is_validated': isValidated,
    'is_admin': isAdmin,
    'role': role,
    'branch': branch,
    'permissions': permissions,
  };
}


// class User {
//   String name;
//   String age;
//   String location;

//   User();

//   User.fromJson(Map<String, dynamic> json)
//       : name = json['name'],
//         age = json['age'],
//         location = json['location'];

//   Map<String, dynamic> toJson() => {
//         'name': name,
//         'age': age,
//         'location': location,
//       };
// }