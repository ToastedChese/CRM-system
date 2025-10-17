class AppUser {
  final String userId;
  final String email;
  final String userType;

  AppUser({
    required this.userId,
    required this.email,
    required this.userType,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'userType': userType,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      userId: map['user_id'],
      email: map['email'],
      userType: map['user_type'],
    );
  }
}