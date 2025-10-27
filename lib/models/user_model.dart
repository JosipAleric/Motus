class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      email: map['email'] ?? '',
    );
  }
}
