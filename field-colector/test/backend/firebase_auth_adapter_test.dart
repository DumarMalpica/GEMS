import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart' as google;

import 'package:field_colector/adapters/real/firebase_auth_adapter.dart';
import 'package:field_colector/domain/ports/user_local_port.dart';
import 'package:field_colector/domain/ports/auth_port.dart';
import 'package:field_colector/domain/entities/user.dart';
import 'package:field_colector/domain/entities/role.dart';

class MockFirebaseAuth extends Mock implements fb.FirebaseAuth {}

class MockGoogleSignIn extends Mock implements google.GoogleSignIn {}

class MockUserCredential extends Mock implements fb.UserCredential {}

class MockFirebaseUser extends Mock implements fb.User {}

class MockIdTokenResult extends Mock implements fb.IdTokenResult {}

class MockUserMetadata extends Mock implements fb.UserMetadata {}

class MockUserLocalPort extends Mock implements UserLocalPort {}

class MockGoogleAccount extends Mock implements google.GoogleSignInAccount {}

class MockGoogleAuthentication extends Mock
    implements google.GoogleSignInAuthentication {}

class FakeUser extends Fake implements User {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUser());
  });

  group('FirebaseAuthAdapter', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockUserLocalPort mockUserLocalPort;
    late FirebaseAuthAdapter adapter;

    late MockFirebaseUser mockFbUser;
    late MockUserCredential mockCredential;
    late MockIdTokenResult mockTokenResult;
    late MockUserMetadata mockMetadata;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockGoogleSignIn = MockGoogleSignIn();
      mockUserLocalPort = MockUserLocalPort();
      mockFbUser = MockFirebaseUser();
      mockCredential = MockUserCredential();
      mockTokenResult = MockIdTokenResult();
      mockMetadata = MockUserMetadata();

      adapter = FirebaseAuthAdapter(
        mockFirebaseAuth,
        mockUserLocalPort,
        googleSignIn: mockGoogleSignIn,
      );
      when(
        () => mockUserLocalPort.getRawLocalUser(),
      ).thenAnswer((_) async => null);
    });

    test('cancelar Google retorna null y permite volver a intentar', () async {
      when(() => mockGoogleSignIn.authenticate()).thenThrow(
        const google.GoogleSignInException(
          code: google.GoogleSignInExceptionCode.canceled,
        ),
      );

      expect(await adapter.loginWithExternalProvider(), isNull);
      expect(await adapter.loginWithExternalProvider(), isNull);
      verify(() => mockGoogleSignIn.authenticate()).called(2);
    });

    test('login exitoso: Autentica en Firebase y guarda en Isar', () async {
      final expiracion = DateTime.now().add(const Duration(hours: 1));

      when(() => mockTokenResult.token).thenReturn('token_secreto_123');
      when(() => mockTokenResult.expirationTime).thenReturn(expiracion);

      when(() => mockMetadata.creationTime).thenReturn(DateTime.now());

      when(() => mockFbUser.uid).thenReturn('user_firebase_001');
      when(() => mockFbUser.email).thenReturn('nicolas@citesa.co');
      when(() => mockFbUser.displayName).thenReturn('Nicolas Tinjaca');
      when(() => mockFbUser.metadata).thenReturn(mockMetadata);
      when(
        () => mockFbUser.getIdTokenResult(),
      ).thenAnswer((_) async => mockTokenResult);

      when(() => mockCredential.user).thenReturn(mockFbUser);

      when(
        () => mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'nicolas@citesa.co',
          password: 'Password123!',
        ),
      ).thenAnswer((_) async => mockCredential);

      when(() => mockUserLocalPort.saveUser(any())).thenAnswer((_) async => {});

      final user = await adapter.login('nicolas@citesa.co', 'Password123!');

      expect(user.id, 'user_firebase_001');
      expect(user.email, 'nicolas@citesa.co');
      expect(user.token, 'token_secreto_123');

      verify(() => mockUserLocalPort.saveUser(any())).called(1);
    });

    test('getCurrentUser: obtiene token, persiste y retorna usuario', () async {
      final expiracion = DateTime.now().add(const Duration(hours: 1));
      when(() => mockTokenResult.token).thenReturn('fresh');
      when(() => mockTokenResult.expirationTime).thenReturn(expiracion);
      when(() => mockMetadata.creationTime).thenReturn(DateTime(2024));
      when(() => mockFbUser.uid).thenReturn('uid');
      when(() => mockFbUser.email).thenReturn('e@e.co');
      when(() => mockFbUser.displayName).thenReturn('Name');
      when(() => mockFbUser.metadata).thenReturn(mockMetadata);
      when(
        () => mockFbUser.getIdTokenResult(),
      ).thenAnswer((_) async => mockTokenResult);
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockFbUser);
      when(() => mockUserLocalPort.saveUser(any())).thenAnswer((_) async => {});

      final u = await adapter.getCurrentUser();

      expect(u, isNotNull);
      expect(u!.token, 'fresh');
      verify(() => mockUserLocalPort.saveUser(any())).called(1);
    });

    test('getCurrentUser: null si no hay currentUser', () async {
      when(() => mockFirebaseAuth.currentUser).thenReturn(null);

      expect(await adapter.getCurrentUser(), isNull);
      verifyNever(() => mockUserLocalPort.saveUser(any()));
    });

    test(
      'login fallido: Lanza AuthException si las credenciales son incorrectas',
      () async {
        when(
          () => mockFirebaseAuth.signInWithEmailAndPassword(
            email: 'nicolas@citesa.co',
            password: 'clave_mala',
          ),
        ).thenThrow(fb.FirebaseAuthException(code: 'wrong-password'));

        expect(
          () => adapter.login('nicolas@citesa.co', 'clave_mala'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.type,
              'tipo de error',
              AuthErrorType.invalidCredentials,
            ),
          ),
        );

        verifyNever(() => mockUserLocalPort.saveUser(any()));
      },
    );

    group('register', () {
      test('weak-password → AuthException weakPassword', () async {
        when(
          () => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'a@b.co',
            password: '123',
          ),
        ).thenThrow(fb.FirebaseAuthException(code: 'weak-password'));

        expect(
          () => adapter.register(
            email: 'a@b.co',
            password: '123',
            fullName: 'Test User',
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.type,
              'type',
              AuthErrorType.weakPassword,
            ),
          ),
        );

        verifyNever(() => mockUserLocalPort.saveUser(any()));
      });

      test('invalid-email → AuthException invalidEmail', () async {
        when(
          () => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'bad',
            password: 'Password123!',
          ),
        ).thenThrow(fb.FirebaseAuthException(code: 'invalid-email'));

        expect(
          () => adapter.register(
            email: 'bad',
            password: 'Password123!',
            fullName: 'Test User',
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.type,
              'type',
              AuthErrorType.invalidEmail,
            ),
          ),
        );

        verifyNever(() => mockUserLocalPort.saveUser(any()));
      });

      test('too-many-requests → AuthException tooManyRequests', () async {
        when(
          () => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'a@b.co',
            password: 'Password123!',
          ),
        ).thenThrow(fb.FirebaseAuthException(code: 'too-many-requests'));

        expect(
          () => adapter.register(
            email: 'a@b.co',
            password: 'Password123!',
            fullName: 'Test User',
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.type,
              'type',
              AuthErrorType.tooManyRequests,
            ),
          ),
        );

        verifyNever(() => mockUserLocalPort.saveUser(any()));
      });

      test('operation-not-allowed → AuthException unknown', () async {
        when(
          () => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'a@b.co',
            password: 'Password123!',
          ),
        ).thenThrow(fb.FirebaseAuthException(code: 'operation-not-allowed'));

        expect(
          () => adapter.register(
            email: 'a@b.co',
            password: 'Password123!',
            fullName: 'Test User',
          ),
          throwsA(
            isA<AuthException>()
                .having((e) => e.type, 'type', AuthErrorType.unknown)
                .having((e) => e.message, 'message', contains('administrador')),
          ),
        );

        verifyNever(() => mockUserLocalPort.saveUser(any()));
      });

      test('email-already-in-use → AuthException emailAlreadyInUse', () async {
        when(
          () => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'taken@b.co',
            password: 'Password123!',
          ),
        ).thenThrow(fb.FirebaseAuthException(code: 'email-already-in-use'));

        expect(
          () => adapter.register(
            email: 'taken@b.co',
            password: 'Password123!',
            fullName: 'Test User',
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.type,
              'type',
              AuthErrorType.emailAlreadyInUse,
            ),
          ),
        );

        verifyNever(() => mockUserLocalPort.saveUser(any()));
      });
    });

    test(
      'validateOfflineSession: Retorna usuario si hay token local válido',
      () async {
        final localUser = User(
          id: '1',
          email: 'test@test.com',
          fullName: 'Test',
          role: Role.user,
          token: 'token_viejo',
          tokenExpiry: DateTime.now().add(const Duration(days: 1)), // Válido
        );

        when(
          () => mockUserLocalPort.getLocalUser(),
        ).thenAnswer((_) async => localUser);

        final session = await adapter.validateOfflineSession();

        expect(session, isNotNull);
        expect(session!.hasValidToken, isTrue);
      },
    );

    test(
      'validateOfflineSession: Retorna null si el token expiró o no existe',
      () async {
        when(
          () => mockUserLocalPort.getLocalUser(),
        ).thenAnswer((_) async => null);

        final session = await adapter.validateOfflineSession();

        expect(session, isNull);
      },
    );
  });
}
