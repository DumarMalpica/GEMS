// ignore_for_file: experimental_member_use
import 'package:isar/isar.dart';
import '../../domain/entities/user.dart';
import '../../domain/ports/user_local_port.dart';
import '../../core/database/isar_service.dart';
import 'user_model.dart';

class IsarUserAdapter implements UserLocalPort {
  /// guardado del token despues del login
  @override
  Future<void> saveUser(User user) async {
    final isar = await IsarService.getInstance();

    final query = isar.userModels.buildQuery<UserModel>(
      filter: FilterCondition.equalTo(property: 'firebaseId', value: user.id),
      limit: 1,
    );
    final results = await query.findAll();
    final existing = results.isEmpty ? null : results.first;
    final model = existing ?? UserModel();

    model
      ..firebaseId = user.id
      ..email = user.email
      ..fullName = user.fullName
      ..fieldStudy = user.fieldStudy
      ..graduated = user.graduated
      ..roleId = user.role.id
      ..token = user.token
      ..tokenExpiry = user.tokenExpiry
      ..isActive = user.isActive
      ..profileComplete = user.profileComplete
      ..createdAt = user.createdAt ?? DateTime.now();

    await isar.writeTxn(() async {
      await isar.userModels.putByFirebaseId(model);
    });
  }

  /// lee el token para validar la sesion offline
  @override
  Future<User?> getLocalUser() async {
    final isar = await IsarService.getInstance();

    final query = isar.userModels.buildQuery<UserModel>(
      filter: FilterCondition.equalTo(property: 'isActive', value: true),
      limit: 1,
    );
    final results = await query.findAll();
    if (results.isEmpty) return null;

    final user = results.first.toDomain();
    if (!user.hasValidToken) return null;

    return user;
  }

  @override
  Future<User?> getRawLocalUser() async {
    final isar = await IsarService.getInstance();

    final query = isar.userModels.buildQuery<UserModel>(
      filter: FilterCondition.equalTo(property: 'isActive', value: true),
      limit: 1,
    );
    final results = await query.findAll();
    if (results.isEmpty) return null;

    return results.first.toDomain();
  }

  /// limpieza despues de logout
  @override
  Future<void> clearLocalUser() async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.userModels.clear();
    });
  }
}
