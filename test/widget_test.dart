import 'dart:async';

import 'package:agile_knowledge/app/agile_knowledge_app.dart';
import 'package:agile_knowledge/app/app_routes.dart';
import 'package:agile_knowledge/features/auth/domain/app_user.dart';
import 'package:agile_knowledge/features/auth/domain/auth_repository.dart';
import 'package:agile_knowledge/features/auth/presentation/pages/sign_in_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('usuário sem sessão visualiza a página de entrada', (tester) async {
    await tester.pumpWidget(
      AgileKnowledgeApp(authRepository: FakeAuthRepository()),
    );

    expect(find.text('Entrar'), findsWidgets);
    expect(find.byKey(const Key('signInEmail')), findsOneWidget);
    expect(find.text('Olá, Gustavo'), findsNothing);
  });

  testWidgets('rota privada mantém usuário sem sessão na página de entrada',
      (tester) async {
    await tester.pumpWidget(
      AgileKnowledgeApp(authRepository: FakeAuthRepository()),
    );

    final context = tester.element(find.byType(SignInPage));
    Navigator.of(context).pushNamed(AppRoutes.occurrences);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('signInEmail')), findsOneWidget);
    expect(find.text('Ocorrências'), findsNothing);
  });

  testWidgets('login válido abre a página inicial com o nome do usuário',
      (tester) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(AgileKnowledgeApp(authRepository: repository));

    await tester.enterText(
      find.byKey(const Key('signInEmail')),
      'gustavo@exemplo.com',
    );
    await tester.enterText(
      find.byKey(const Key('signInPassword')),
      'Senha123',
    );
    await tester.tap(find.byKey(const Key('signInSubmit')));
    await tester.pumpAndSettle();

    expect(find.text('Olá, Gustavo'), findsOneWidget);
    expect(find.text('Registrar atraso'), findsOneWidget);
  });

  testWidgets('login sem e-mail confirmado permanece na pagina de entrada',
      (tester) async {
    final repository = FakeAuthRepository(
      signInError: StateError('Email not confirmed'),
    );
    await tester.pumpWidget(AgileKnowledgeApp(authRepository: repository));

    await tester.enterText(
      find.byKey(const Key('signInEmail')),
      'pendente@exemplo.com',
    );
    await tester.enterText(
      find.byKey(const Key('signInPassword')),
      'Senha123',
    );
    await tester.tap(find.byKey(const Key('signInSubmit')));
    await tester.pumpAndSettle();

    expect(find.text('Confirme seu e-mail antes de entrar.'), findsOneWidget);
    expect(find.text('Registrar atraso'), findsNothing);
  });

  testWidgets('logout remove a sessão e volta para a página de entrada',
      (tester) async {
    final repository = FakeAuthRepository(
      initialUser: const AppUser(
        id: 'user-1',
        name: 'Gustavo',
        email: 'gustavo@exemplo.com',
      ),
    );

    await tester.pumpWidget(AgileKnowledgeApp(authRepository: repository));
    expect(find.text('Olá, Gustavo'), findsOneWidget);

    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('signInEmail')), findsOneWidget);
    expect(find.text('Olá, Gustavo'), findsNothing);
  });

  testWidgets('cadastro exige nome, e-mail e senha válidos', (tester) async {
    await tester.pumpWidget(
      AgileKnowledgeApp(authRepository: FakeAuthRepository()),
    );

    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('signUpSubmit')));
    await tester.tap(find.byKey(const Key('signUpSubmit')));
    await tester.pump();

    expect(find.text('Informe seu nome.'), findsOneWidget);
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('Use pelo menos 8 caracteres.'), findsOneWidget);
  });

  testWidgets('cadastro válido cria a sessão e exibe o nome informado',
      (tester) async {
    await tester.pumpWidget(
      AgileKnowledgeApp(authRepository: FakeAuthRepository()),
    );

    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('signUpName')),
      'Ana Silva',
    );
    await tester.enterText(
      find.byKey(const Key('signUpEmail')),
      'ana@exemplo.com',
    );
    await tester.enterText(
      find.byKey(const Key('signUpPassword')),
      'Senha123',
    );
    await tester.enterText(
      find.byKey(const Key('signUpPasswordConfirmation')),
      'Senha123',
    );
    await tester.ensureVisible(find.byKey(const Key('signUpSubmit')));
    await tester.tap(find.byKey(const Key('signUpSubmit')));
    await tester.pumpAndSettle();

    expect(find.text('Olá, Ana Silva'), findsOneWidget);
  });
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? initialUser, this.signInError})
      : _currentUser = initialUser;

  final _controller = StreamController<AppUser?>.broadcast();
  final Object? signInError;
  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (signInError case final error?) throw error;
    _currentUser = AppUser(id: 'user-1', name: 'Gustavo', email: email);
    _controller.add(_currentUser);
  }

  @override
  Future<SignUpResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _currentUser = AppUser(id: 'user-1', name: name, email: email);
    _controller.add(_currentUser);
    return const SignUpResult(requiresEmailConfirmation: false);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }
}
