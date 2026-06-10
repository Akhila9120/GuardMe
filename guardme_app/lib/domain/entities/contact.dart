class Contact {
  final int? id;
  final String name;
  final String phone;
  final String? email;
  final String? relationship;

  Contact({
    this.id,
    required this.name,
    required this.phone,
    this.email,
    this.relationship,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      relationship: json['relationship'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      if (email != null) 'email': email,
      if (relationship != null) 'relationship': relationship,
    };
  }
}
