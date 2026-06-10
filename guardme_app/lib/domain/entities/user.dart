class User {
  final int id;
  final String login;
  final String firstName;
  final String lastName;
  final String email;
  final List<String> authorities;
  final String? token;

  User({
    required this.id,
    required this.login,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.authorities,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      login: json['login'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      authorities: (json['authorities'] as List<dynamic>?)
              ?.map((e) => e is String ? e : (e as Map)['name'] as String? ?? e.toString())
              .toList() ??
          [],
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'login': login,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'authorities': authorities,
      'token': token,
    };
  }

  String get fullName => '$firstName $lastName';
}
