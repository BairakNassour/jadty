class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
  });
}