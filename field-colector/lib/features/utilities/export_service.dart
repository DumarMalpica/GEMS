import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/ports/bird_record_remote_port.dart';
import '../../domain/ports/rock_record_remote_port.dart';
import '../../domain/ports/soil_record_remote_port.dart';
import '../../domain/ports/vegetation_record_remote_port.dart';
import '../../domain/ports/water_record_remote_port.dart';
import '../../domain/ports/social_record_remote_port.dart';

import '../../domain/entities/bird_record.dart';
import '../../domain/entities/social_record.dart';
import '../../domain/entities/rock_record.dart';
import '../../domain/entities/soil_record.dart';
import '../../domain/entities/vegetation_record.dart';
import '../../domain/entities/water_record.dart';

class ExportService {
  final BirdRecordRemotePort birdPort;
  final RockRecordRemotePort rockPort;
  final SoilRecordRemotePort soilPort;
  final VegetationRecordRemotePort vegetationPort;
  final WaterRecordRemotePort waterPort;
  final SocialRecordRemotePort socialPort;

  ExportService({
    required this.birdPort,
    required this.rockPort,
    required this.soilPort,
    required this.vegetationPort,
    required this.waterPort,
    required this.socialPort,
  });

  /// Firestore needs composite index for equality + date range on same query.
  /// When [outingId] or [userId] is set, fetch without dates and filter in app.
  static bool _filterDatesOnClient({
    String? outingId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return (outingId != null || userId != null) &&
        (startDate != null || endDate != null);
  }

  static DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  static bool _inDateRange(
    DateTime recordedAt,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate != null && recordedAt.isBefore(_startOfDay(startDate))) {
      return false;
    }
    if (endDate != null && recordedAt.isAfter(_endOfDay(endDate))) {
      return false;
    }
    return true;
  }

  static List<T> _applyDateFilter<T>(
    List<T> records,
    DateTime Function(T) recordedAt,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    return records
        .where(
          (r) => _inDateRange(recordedAt(r), startDate, endDate),
        )
        .toList();
  }

  Future<String?> generateExcel({String? outingId, String? userId, DateTime? startDate, DateTime? endDate, required String fileNamePrefix}) async {
    final rangeStart =
        startDate != null ? _startOfDay(startDate) : null;
    final rangeEnd = endDate != null ? _endOfDay(endDate) : null;

    final clientDateFilter = _filterDatesOnClient(
      outingId: outingId,
      userId: userId,
      startDate: rangeStart,
      endDate: rangeEnd,
    );
    final queryStart = clientDateFilter ? null : rangeStart;
    final queryEnd = clientDateFilter ? null : rangeEnd;

    try {
      var excel = Excel.createExcel();

      String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';

      var birds = await birdPort.getBirdRecordsForExport(
        outingId: outingId,
        userId: userId,
        startDate: queryStart,
        endDate: queryEnd,
      );
      if (clientDateFilter) {
        birds = _applyDateFilter(birds, (b) => b.recordedAt, rangeStart, rangeEnd);
      }
      if (birds.isNotEmpty) {
        Sheet sheet = excel['Aves'];
        sheet.appendRow([
          TextCellValue('ID Registro'), TextCellValue('Fecha'), TextCellValue('Latitud'),
          TextCellValue('Longitud'), TextCellValue('Departamento'), TextCellValue('Municipio'),
          TextCellValue('Época'), TextCellValue('Lugar'), TextCellValue('ID Especie'),
          TextCellValue('Tipo Ave'), TextCellValue('Estatus'), TextCellValue('Cantidad'),
          TextCellValue('Comportamiento'), TextCellValue('Actividad'), TextCellValue('Hábitat'),
          TextCellValue('Forrajeo'), TextCellValue('Amenazas'), TextCellValue('Fotos/ID Cámara'), TextCellValue('Links Fotos')
        ]);

        for (BirdRecord b in birds) {
          String fotosResumen = b.photos.map((p) => p.filename).join(' | ');
          String linksResumen = b.photos.map((p) => p.storageUrl).where((url) => url.isNotEmpty).join(' | ');
          sheet.appendRow([
            TextCellValue(b.id), TextCellValue(b.recordedAt.toIso8601String()), DoubleCellValue(b.coordinates.latitude),
            DoubleCellValue(b.coordinates.longitude), TextCellValue(b.department), TextCellValue(b.municipality),
            TextCellValue(b.season), TextCellValue(b.place), TextCellValue(b.speciesId),
            TextCellValue(b.birdType), TextCellValue(b.migratorStatus), IntCellValue(b.individualCount),
            TextCellValue(b.behavior), TextCellValue(b.activity), TextCellValue(b.habitat.join(', ')),
            TextCellValue(b.foragingType.join(', ')), TextCellValue(b.observedThreats.join(', ')),
            TextCellValue(fotosResumen), TextCellValue(linksResumen)
          ]);
        }
      }

      var rocks = await rockPort.getRockRecordsForExport(
        outingId: outingId,
        userId: userId,
        startDate: queryStart,
        endDate: queryEnd,
      );
      if (clientDateFilter) {
        rocks = _applyDateFilter(rocks, (r) => r.recordedAt, rangeStart, rangeEnd);
      }
      if (rocks.isNotEmpty) {
        Sheet sheet = excel['Rocas'];
        sheet.appendRow([
          TextCellValue('ID Registro'), TextCellValue('Fecha'), TextCellValue('Latitud'), TextCellValue('Longitud'),
          TextCellValue('Tipo Roca'), TextCellValue('Color'), TextCellValue('Textura'),
          TextCellValue('Estructura'), TextCellValue('Dureza'), TextCellValue('Minerales'),
          TextCellValue('Tiene Muestra'), TextCellValue('ID Muestra'), TextCellValue('Profundidad (cm)'),
          TextCellValue('Observaciones'), TextCellValue('Fotos'), TextCellValue('Links Fotos')
        ]);

        for (RockRecord r in rocks) {
          String fotosResumen = r.photos.map((p) => p.filename).join(' | ');
          String linksResumen = r.photos.map((p) => p.storageUrl).where((url) => url.isNotEmpty).join(' | ');
          sheet.appendRow([
            TextCellValue(r.id), TextCellValue(r.recordedAt.toIso8601String()), DoubleCellValue(r.coordinates.latitude), DoubleCellValue(r.coordinates.longitude),
            TextCellValue(r.rockType), TextCellValue(r.dominantColor), TextCellValue(r.texture.join(', ')),
            TextCellValue(r.structure), TextCellValue(r.hardness), TextCellValue(r.minerals),
            TextCellValue(r.hasSample ? 'Sí' : 'No'), TextCellValue(r.sampleId ?? ''),
            r.sampleDepth != null ? DoubleCellValue(r.sampleDepth!) : TextCellValue(''),
            TextCellValue(r.observations), TextCellValue(fotosResumen), TextCellValue(linksResumen)
          ]);
        }
      }

      var soils = await soilPort.getSoilRecordsForExport(
        outingId: outingId,
        userId: userId,
        startDate: queryStart,
        endDate: queryEnd,
      );
      if (clientDateFilter) {
        soils = _applyDateFilter(soils, (s) => s.recordedAt, rangeStart, rangeEnd);
      }
      if (soils.isNotEmpty) {
        Sheet sheet = excel['Suelos'];
        sheet.appendRow([
          TextCellValue('ID Registro'), TextCellValue('Fecha'), TextCellValue('Latitud'), TextCellValue('Longitud'),
          TextCellValue('Tipos Suelo'), TextCellValue('Color'), TextCellValue('Variabilidad Color'),
          TextCellValue('Textura'), TextCellValue('Estructura'), TextCellValue('Perfil'),
          TextCellValue('Tiene Muestra'), TextCellValue('ID Muestra'), TextCellValue('Profundidad (cm)'),
          TextCellValue('Observaciones'), TextCellValue('Fotos'), TextCellValue('Links Fotos')
        ]);

        for (SoilRecord s in soils) {
          String fotosResumen = s.photos.map((p) => p.filename).join(' | ');
          String linksResumen = s.photos.map((p) => p.storageUrl).where((url) => url.isNotEmpty).join(' | ');
          sheet.appendRow([
            TextCellValue(s.id), TextCellValue(s.recordedAt.toIso8601String()), DoubleCellValue(s.coordinates.latitude), DoubleCellValue(s.coordinates.longitude),
            TextCellValue(s.soilTypes.join(', ')), TextCellValue(s.dominantColor), TextCellValue(s.colorVariability),
            TextCellValue(s.texture.join(', ')), TextCellValue(s.structure), TextCellValue(s.soilProfile),
            TextCellValue(s.hasSample ? 'Sí' : 'No'), TextCellValue(s.sampleId ?? ''),
            s.sampleDepth != null ? DoubleCellValue(s.sampleDepth!) : TextCellValue(''),
            TextCellValue(s.observations), TextCellValue(fotosResumen), TextCellValue(linksResumen)
          ]);
        }
      }

      var veg = await vegetationPort.getVegetationRecordsForExport(
        outingId: outingId,
        userId: userId,
        startDate: queryStart,
        endDate: queryEnd,
      );
      if (clientDateFilter) {
        veg = _applyDateFilter(veg, (v) => v.recordedAt, rangeStart, rangeEnd);
      }
      if (veg.isNotEmpty) {
        Sheet sheet = excel['Vegetación'];
        sheet.appendRow([
          TextCellValue('ID Registro'), TextCellValue('Fecha'), TextCellValue('Latitud'), TextCellValue('Longitud'),
          TextCellValue('ID Especie'), TextCellValue('Nombre Común'), TextCellValue('Origen'), TextCellValue('Tipo Vegetación'),
          TextCellValue('Altura (m)'), TextCellValue('Diámetro (m)'), TextCellValue('Fisionomía'), TextCellValue('Cobertura %'),
          TextCellValue('Condición'), TextCellValue('Pirogenia'), TextCellValue('Suelo/Hojarasca'), TextCellValue('Fotos'), TextCellValue('Links Fotos')
        ]);

        for (VegetationRecord v in veg) {
          String fotosResumen = v.photos.map((p) => p.filename).join(' | ');
          String linksResumen = v.photos.map((p) => p.storageUrl).where((url) => url.isNotEmpty).join(' | ');
          sheet.appendRow([
            TextCellValue(v.id), TextCellValue(v.recordedAt.toIso8601String()), DoubleCellValue(v.coordinates.latitude), DoubleCellValue(v.coordinates.longitude),
            TextCellValue(v.speciesId), TextCellValue(v.commonName), TextCellValue(v.origin), TextCellValue(v.vegetationType),
            v.height != null ? DoubleCellValue(v.height!) : TextCellValue(''),
            v.diameter != null ? DoubleCellValue(v.diameter!) : TextCellValue(''),
            TextCellValue(v.physiognomy), v.coveragePercent != null ? IntCellValue(v.coveragePercent!) : TextCellValue(''),
            TextCellValue(v.physicalCondition), TextCellValue(v.hasPyrogeny ? 'Sí' : 'No'), TextCellValue(v.groundCover),
            TextCellValue(fotosResumen), TextCellValue(linksResumen)
          ]);
        }
      }

      var water = await waterPort.getWaterRecordsForExport(
        outingId: outingId,
        userId: userId,
        startDate: queryStart,
        endDate: queryEnd,
      );
      if (clientDateFilter) {
        water = _applyDateFilter(water, (w) => w.recordedAt, rangeStart, rangeEnd);
      }
      if (water.isNotEmpty) {
        Sheet sheet = excel['Agua'];
        sheet.appendRow([
          TextCellValue('ID Registro'), TextCellValue('Fecha'), TextCellValue('Latitud'), TextCellValue('Longitud'),
          TextCellValue('Clima'), TextCellValue('Visibilidad'), TextCellValue('Acceso'), TextCellValue('Profundidad'),
          TextCellValue('pH'), TextCellValue('Temp (°C)'), TextCellValue('Conductividad'), TextCellValue('OD (mg/L)'),
          TextCellValue('Turbidez'), TextCellValue('Color Aparente'), TextCellValue('Olor'), TextCellValue('Tiene Muestra'),
          TextCellValue('ID Muestra'), TextCellValue('Objetivo Muestreo'), TextCellValue('Tipo Muestra'),
          TextCellValue('Recipiente'), TextCellValue('Fotos'), TextCellValue('Links Fotos')
        ]);

        for (WaterRecord w in water) {
          String fotosResumen = w.photos.map((p) => p.filename).join(' | ');
          String linksResumen = w.photos.map((p) => p.storageUrl).where((url) => url.isNotEmpty).join(' | ');
          sheet.appendRow([
            TextCellValue(w.id), TextCellValue(w.recordedAt.toIso8601String()), DoubleCellValue(w.coordinates.latitude), DoubleCellValue(w.coordinates.longitude),
            TextCellValue(w.weatherConditions), TextCellValue(w.visibility), TextCellValue(w.access), TextCellValue(w.samplingDepth),
            w.ph != null ? DoubleCellValue(w.ph!) : TextCellValue(''),
            w.temperature != null ? DoubleCellValue(w.temperature!) : TextCellValue(''),
            w.conductivity != null ? DoubleCellValue(w.conductivity!) : TextCellValue(''),
            w.dissolvedOxygen != null ? DoubleCellValue(w.dissolvedOxygen!) : TextCellValue(''),
            w.turbidity != null ? DoubleCellValue(w.turbidity!) : TextCellValue(''),
            TextCellValue(w.apparentColor), TextCellValue(w.odor), TextCellValue(w.hasSample ? 'Sí' : 'No'),
            TextCellValue(w.sampleId ?? ''), TextCellValue(w.samplingGoal ?? ''),
            TextCellValue(w.sampleType ?? ''), TextCellValue(w.container ?? ''), // <-- Corregido a w.container
            TextCellValue(fotosResumen), TextCellValue(linksResumen)
          ]);
        }
      }

      var socials = await socialPort.getSocialRecordsForExport(
        outingId: outingId,
        userId: userId,
        startDate: queryStart,
        endDate: queryEnd,
      );
      if (clientDateFilter) {
        socials = _applyDateFilter(
          socials,
          (s) => s.recordedAt,
          rangeStart,
          rangeEnd,
        );
      }
      if (socials.isNotEmpty) {
        Sheet sheet = excel['Social'];
        sheet.appendRow([
          TextCellValue('ID Registro'),
          TextCellValue('Fecha'),
          TextCellValue('Latitud'),
          TextCellValue('Longitud'),
          TextCellValue('ID Encuestado'),
          TextCellValue('Actor'),
          TextCellValue('Tipo Actor'),
          TextCellValue('Edad'),
          TextCellValue('Género'),
          TextCellValue('Nivel Educativo'),
          TextCellValue('Actividad Principal'),
          TextCellValue('Tiempo Territorio'),
          TextCellValue('Dependencia RN'),
          TextCellValue('Percepción Cambio'),
          TextCellValue('Impacto Paisaje'),
          TextCellValue('Observaciones'),
        ]);

        for (SocialRecord s in socials) {
          sheet.appendRow([
            TextCellValue(s.id),
            TextCellValue(s.recordedAt.toIso8601String()),
            DoubleCellValue(s.coordinates.latitude),
            DoubleCellValue(s.coordinates.longitude),
            TextCellValue(s.respondentId),
            TextCellValue(s.actorName),
            TextCellValue(s.actorType),
            DoubleCellValue(s.age),
            TextCellValue(s.gender),
            TextCellValue(s.educationLevel),
            TextCellValue(s.mainActivity),
            DoubleCellValue(s.timeInTerritory),
            TextCellValue(s.naturalResourceDependency),
            TextCellValue(s.coverageChangePerception),
            TextCellValue(s.perceivedLandscapeImpact),
            TextCellValue(s.observations ?? ''),
          ]);
        }
      }

      if (excel.tables.keys.length > 1) {
        excel.delete(defaultSheet);
      }

      var fileBytes = excel.save();
      if (fileBytes == null) return null;

      Directory tempDir = await getTemporaryDirectory();
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String filePath = '${tempDir.path}/${fileNamePrefix}_$timestamp.xlsx';

      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      print('Archivo Excel generado con éxito: $filePath');
      return filePath;

    } catch (e, stackTrace) {
      print('Error generando el archivo Excel: $e\n$stackTrace');
      rethrow;
    }
  }
}