class AppUser {
  final String id;
  final String? email;
  final String? displayName;
  final bool mustChangePassword;

  AppUser({
    required this.id, 
    this.email, 
    this.displayName, 
    this.mustChangePassword = false
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName &&
          mustChangePassword == other.mustChangePassword;

  @override
  int get hashCode => 
    id.hashCode ^ 
    email.hashCode ^ 
    displayName.hashCode ^ 
    mustChangePassword.hashCode;
}
