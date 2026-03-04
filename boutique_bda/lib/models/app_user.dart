class AppUser {
  final String id;
  final String? email;
  final String? displayName;

  AppUser({required this.id, this.email, this.displayName});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName;

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ displayName.hashCode;
}
