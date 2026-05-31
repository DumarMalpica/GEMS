import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/role.dart';
import '../../domain/ports/user_remote_port.dart';

/// Adaptador concreto para operaciones de User en Firestore.
class FirebaseUserAdapter implements UserRemotePort {
  final FirebaseFirestore _firestore;
  final String _collection = 'users';

  FirebaseUserAdapter(this._firestore);

  /// Guarda un nuevo registro de User en Firestore y sincroniza sus datos.
  @override
  Future<void> saveUser(User user) async {
    await _firestore.collection(_collection).doc(user.id).set({
      'email': user.email,
      'fullName': user.fullName,
      'fieldStudy': user.fieldStudy,
      'role': user.role.id,
      'createdAt': user.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    });
  }

  /// Actualiza un registro existente de User en Firestore con los nuevos datos.
  @override
  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update(data);
  }

  /// Elimina un registro de User en Firestore mediante su id.
  @override
  Future<void> deleteUser(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Recupera un usuario ([User]) por su [id]. Retorna null si no existe.
  @override
  Future<User?> getUserById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return _mapSnapshotToUser(doc);
  }

  /// Recupera un usuario ([User]) por su [email]. Retorna null si no existe.
  @override
  Future<User?> getUserByEmail(String email) async {
    final snapshot = await _firestore.collection(_collection)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return _mapSnapshotToUser(snapshot.docs.first);
  }

  @override
  Future<UserSearchResult> searchUsersByName(
      String name, {
        int limit = 10,
        DocumentSnapshot? lastDocument,
      }) async {
    Query query = _firestore.collection(_collection)
        .where('fullName', isGreaterThanOrEqualTo: name)
        .where('fullName', isLessThanOrEqualTo: '$name\uf8ff')
        .orderBy('fullName')
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    return UserSearchResult(
      users: snapshot.docs.map((doc) => _mapSnapshotToUser(doc)).toList(),
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  /// Obtiene de forma paginada un listado de usuarios filtrados por [roleString].
  @override
  Future<UserSearchResult> getUsersByRole(
      String roleString, {
        int limit = 10,
        DocumentSnapshot? lastDocument,
      }) async {
    Query query = _firestore.collection(_collection)
        .where('role', isEqualTo: roleString)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    return UserSearchResult(
      users: snapshot.docs.map((doc) => _mapSnapshotToUser(doc)).toList(),
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  /// Obtiene de forma paginada un listado de todos los usuarios registrados.
  @override
  Future<UserSearchResult> getAllUsers({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore.collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    return UserSearchResult(
      users: snapshot.docs.map((doc) => _mapSnapshotToUser(doc)).toList(),
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }


  /// Mapea un documento de Firestore (`DocumentSnapshot`) a una entidad de dominio `User`.
  User _mapSnapshotToUser(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      fieldStudy: data['fieldStudy'],
      role: Role.fromId(data['role'] ?? 'user'),
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : null,
    );
  }
}