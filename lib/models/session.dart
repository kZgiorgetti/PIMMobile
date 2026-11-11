class UserSession {
  const UserSession({required this.accessToken, required this.refreshToken, required this.user});
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;
  String get role => '${user['perfil'] ?? ''}';
  String get name => '${user['nome'] ?? ''}';
  int get id => (user['id'] as num?)?.toInt() ?? 0;
  factory UserSession.fromJson(Map<String, dynamic> j) => UserSession(
    accessToken: '${j['accessToken'] ?? ''}', refreshToken: '${j['refreshToken'] ?? ''}',
    user: Map<String, dynamic>.from(j['usuario'] as Map? ?? const {}),
  );
  Map<String, dynamic> toJson() => {'accessToken': accessToken, 'refreshToken': refreshToken, 'usuario': user};
}
