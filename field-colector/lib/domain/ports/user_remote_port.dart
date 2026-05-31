import '../entities/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Puerto remoto para la gestión de Usuarios (User).
/// 
/// Define las operaciones relacionadas con la base de datos de usuarios (perfiles).
abstract class UserRemotePort {

  /// Guarda un nuevo perfil de [user] en Firestore.
  Future<void> saveUser(User user);

  /// Actualiza los atributos de un usuario ([id]) utilizando un mapa [data].
  Future<void> updateUser(String id, Map<String, dynamic> data);

  /// Elimina por completo el registro de un usuario mediante su [id].
  Future<void> deleteUser(String id);

  /// Obtiene los datos de un usuario usando su [id].
  Future<User?> getUserById(String id);

  /// Busca un usuario basándose en su correo electrónico ([email]).
  Future<User?> getUserByEmail(String email);

  /// Realiza una búsqueda paginada de usuarios cuyo nombre coincida con [name].
  Future<UserSearchResult> searchUsersByName(
      String name, {
        int limit = 10,
        DocumentSnapshot? lastDocument,
      });

  /// Busca usuarios que posean un rol específico ([roleString]) de forma paginada.
  Future<UserSearchResult> getUsersByRole(
      String roleString, {
        int limit = 10,
        DocumentSnapshot? lastDocument,
      });

  /// Obtiene todos los usuarios del sistema de forma paginada.
  Future<UserSearchResult> getAllUsers({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  });
}

/// Estructura de resultados para respuestas paginadas en consultas de usuarios.
class UserSearchResult {
  /// Lista de usuarios obtenidos en la página actual.
  final List<User> users;

  /// Documento en el que finalizó la lectura, necesario para la siguiente página.
  final DocumentSnapshot? lastDocument;

  UserSearchResult({required this.users, this.lastDocument});
}