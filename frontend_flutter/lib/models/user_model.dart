class User {
  final String? id;
  final String? email;
  final String? password;
  final String? fullName;
  final String? role;
  final String? telefono;
  final String? bio;
  final String? fotoPerfil;

  User({this.id, this.email, this.password, this.fullName, this.role, this.telefono, this.bio, this.fotoPerfil});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id']?.toString() ?? json['Id']?.toString() ?? json['_id']?.toString(),
        email: json['email'] ?? json['Email'],
        password: json['password'] ?? json['Password'],
        role: json['role'] ?? json['Role'],
        fullName: json['fullName'] ?? json['FullName'],
        telefono: json['telefono'] ?? json['Telefono'],
        bio: json['bio'] ?? json['Bio'],
        fotoPerfil: json['fotoPerfil'] ?? json['FotoPerfil'] ?? json['foto_perfil'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'password': password,
        'role': role,
        'fullName': fullName,
        'telefono': telefono,
        'bio': bio,
        'fotoPerfil': fotoPerfil,
      };
}
