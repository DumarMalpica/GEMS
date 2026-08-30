import 'package:field_colector/domain/entities/outing.dart';
import 'package:field_colector/domain/entities/role.dart';
import 'package:field_colector/domain/entities/user.dart';

/// ID del usuario simulado como "logueado".
/// fake-uid-002 = Ana Investigadora (no es propietaria de la mayoría).
const String kCurrentUserId = 'fake-uid-002';

/// Mapa de usuarios falsos para resolver IDs → nombres.
final Map<String, User> kFakeUsers = {
  'fake-uid-001': const User(
    id: 'fake-uid-001',
    email: 'admin@citesa.co',
    fullName: 'Carlos Administrador',
    role: Role.admin,
    fieldStudy: 'Administración',
    graduated: true,
  ),
  'fake-uid-002': const User(
    id: 'fake-uid-002',
    email: 'usuario@citesa.co',
    fullName: 'Ana Investigadora',
    role: Role.user,
    fieldStudy: 'Ecología',
    graduated: false,
  ),
  'fake-uid-003': const User(
    id: 'fake-uid-003',
    email: 'pedro@citesa.co',
    fullName: 'Pedro Botánico',
    role: Role.user,
    fieldStudy: 'Botánica',
    graduated: true,
  ),
  'fake-uid-004': const User(
    id: 'fake-uid-004',
    email: 'maria@citesa.co',
    fullName: 'María Geóloga',
    role: Role.user,
    fieldStudy: 'Geología',
    graduated: false,
  ),
  'fake-uid-005': const User(
    id: 'fake-uid-005',
    email: 'luis@citesa.co',
    fullName: 'Luis Hidrólogo',
    role: Role.user,
    fieldStudy: 'Hidrología',
    graduated: true,
  ),
};

List<OutingMember> _membersFromIds(List<String> ids) => ids
    .map((id) {
      final u = kFakeUsers[id];
      return OutingMember(
        id: id,
        name: u?.fullName ?? '',
        email: u?.email ?? '',
      );
    })
    .toList();

/// Lista de expediciones hardcodeadas para pruebas de UI.
final List<Outing> kFakeOutings = [
  Outing(
    id: 'outing-001',
    prefix: 'EXP-BYC',
    name: 'Expedición Boyacá Centro',
    location: 'Tunja, Boyacá',
    zone: 'Altiplano Cundiboyacense',
    reason: 'Inventario de flora nativa en páramos cercanos a Tunja',
    places: const [OutingPlace(id: 'place-001', name: 'Tunja', latitude: 5.5353, longitude: -73.3678, altitude: 2820)],
    startDate: DateTime(2026, 5, 1),
    endDate: DateTime(2026, 5, 15),
    createdById: 'fake-uid-001',
    participantIds: ['fake-uid-001', 'fake-uid-002', 'fake-uid-003'],
    participants: _membersFromIds(['fake-uid-001', 'fake-uid-002', 'fake-uid-003']),
    status: 'active',
    syncStatus: 'synced',
    pendingUsers: [
      PendingUser(
        id: 'fake-uid-004',
        name: 'María Geóloga',
        email: 'maria@citesa.co',
      ),
    ],
  ),
  Outing(
    id: 'outing-002',
    prefix: 'EXP-SND',
    name: 'Exploración Santander Norte',
    location: 'Bucaramanga, Santander',
    zone: 'Serranía de los Yariguíes',
    reason: 'Estudio de suelos volcánicos y vegetación asociada',
    places: const [OutingPlace(id: 'place-002', name: 'Bucaramanga', latitude: 7.1193, longitude: -73.1227, altitude: 959)],
    startDate: DateTime(2026, 6, 10),
    endDate: DateTime(2026, 6, 25),
    createdById: 'fake-uid-002',
    participantIds: ['fake-uid-002', 'fake-uid-005'],
    participants: _membersFromIds(['fake-uid-002', 'fake-uid-005']),
    status: 'active',
    syncStatus: 'pending',
    pendingUsers: [],
  ),
  Outing(
    id: 'outing-003',
    prefix: 'EXP-AMZ',
    name: 'Biodiversidad Amazonas',
    location: 'Leticia, Amazonas',
    zone: 'Selva Amazónica Colombiana',
    reason: 'Registro de aves migratorias y endémicas',
    places: const [OutingPlace(id: 'place-003', name: 'Leticia', latitude: -4.2153, longitude: -69.9406, altitude: 96)],
    startDate: DateTime(2026, 3, 1),
    endDate: DateTime(2026, 3, 20),
    createdById: 'fake-uid-001',
    participantIds: ['fake-uid-001', 'fake-uid-004'],
    participants: _membersFromIds(['fake-uid-001', 'fake-uid-004']),
    status: 'closed',
    syncStatus: 'synced',
    pendingUsers: [],
  ),
  Outing(
    id: 'outing-004',
    prefix: 'EXP-NRN',
    name: 'Hidrología Nariño',
    location: 'Pasto, Nariño',
    zone: 'Laguna de la Cocha',
    reason: 'Muestreo de calidad de agua en afluentes de la laguna',
    places: const [OutingPlace(id: 'place-004', name: 'Laguna de la Cocha', latitude: 1.2136, longitude: -77.2811, altitude: 2527)],
    startDate: DateTime(2026, 7, 5),
    endDate: DateTime(2026, 7, 18),
    createdById: 'fake-uid-003',
    participantIds: ['fake-uid-003'],
    participants: _membersFromIds(['fake-uid-003']),
    status: 'active',
    syncStatus: 'pending',
    pendingUsers: [
      PendingUser(
        id: 'fake-uid-002',
        name: 'Ana Investigadora',
        email: 'usuario@citesa.co',
      ),
      PendingUser(
        id: 'fake-uid-005',
        name: 'Luis Hidrólogo',
        email: 'luis@citesa.co',
      ),
    ],
  ),
  Outing(
    id: 'outing-005',
    prefix: 'EXP-CST',
    name: 'Costa Caribe Rocas',
    location: 'Santa Marta, Magdalena',
    zone: 'Sierra Nevada de Santa Marta',
    reason: 'Caracterización geológica de formaciones costeras',
    places: const [OutingPlace(id: 'place-005', name: 'Santa Marta', latitude: 11.2408, longitude: -74.1990, altitude: 6)],
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2026, 8, 12),
    createdById: 'fake-uid-004',
    participantIds: ['fake-uid-004', 'fake-uid-001'],
    participants: _membersFromIds(['fake-uid-004', 'fake-uid-001']),
    status: 'active',
    syncStatus: 'synced',
    pendingUsers: [],
  ),
];
