import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(
    this._client, {
    required this.emailRedirectTo,
  });

  final SupabaseClient _client;
  final String emailRedirectTo;

  @override
  AppUser? get currentUser => _mapUser(_client.auth.currentUser);

  @override
  Stream<AppUser?> get authStateChanges => _client.auth.onAuthStateChange
      .map((state) => _mapUser(state.session?.user));

  @override
  Future<void> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    if (response.user?.emailConfirmedAt == null) {
      await _client.auth.signOut();
      throw AuthException('Email not confirmed');
    }
  }

  @override
  Future<SignUpResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {'name': name.trim()},
      emailRedirectTo: emailRedirectTo,
    );

    final requiresEmailConfirmation =
        response.session == null || response.user?.emailConfirmedAt == null;

    if (requiresEmailConfirmation && response.session != null) {
      await _client.auth.signOut();
    }

    return SignUpResult(
      requiresEmailConfirmation: requiresEmailConfirmation,
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  AppUser? _mapUser(User? user) {
    if (user == null || user.emailConfirmedAt == null) return null;

    final name = (user.userMetadata?['name'] as String?)?.trim();
    final email = user.email ?? '';

    return AppUser(
      id: user.id,
      name: name?.isNotEmpty == true ? name! : _nameFromEmail(email),
      email: email,
    );
  }

  String _nameFromEmail(String email) {
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) return 'Usuário';

    return localPart[0].toUpperCase() + localPart.substring(1);
  }
}
