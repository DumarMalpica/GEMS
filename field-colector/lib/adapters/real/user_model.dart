import 'package:isar/isar.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/role.dart';

part 'user_model.g.dart';

/// Modelo de persistencia Isar para User.
///
/// Separa la entidad pura de dominio del modelo de base de datos.
/// Solo este archivo conoce Isar — el dominio permanece limpio.
@Collection()
class UserModel {
  Id id = Isar.autoIncrement;

  /// Firebase UID — clave de búsqueda principal.
  @Index(unique: true)
  late String firebaseId;

  late String email;
  late String fullName;
  String? fieldStudy;
  bool graduated = false;

  /// id del rol: 'admin' | 'user'
  late String roleId;

  /// JWT de Firebase guardado para validación offline.
  String? token;
  DateTime? tokenExpiry;

  bool isActive = true;
  bool profileComplete = true;
  DateTime? createdAt;

  /// Convierte el modelo Isar a la entidad pura de dominio.
  User toDomain() {
    return User(
      id: firebaseId,
      email: email,
      fullName: fullName,
      fieldStudy: fieldStudy,
      graduated: graduated,
      role: Role.fromId(roleId),
      token: token,
      tokenExpiry: tokenExpiry,
      isActive: isActive,
      profileComplete: profileComplete,
      createdAt: createdAt,
    );
  }

  /// Construye un UserModel desde la entidad pura de dominio.
  static UserModel fromDomain(User user) {
    return UserModel()
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
      ..createdAt = user.createdAt;
  }
}
