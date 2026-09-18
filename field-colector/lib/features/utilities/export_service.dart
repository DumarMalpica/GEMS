import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/ports/bird_record_remote_port.dart';
import '../../domain/ports/rock_record_remote_port.dart';
import '../../domain/ports/soil_record_remote_port.dart';
import '../../domain/ports/vegetation_record_remote_port.dart';
import '../../domain/ports/water_record_remote_port.dart';
import '../../domain/ports/social_record_remote_port.dart';

/// Servicio encargado de generar archivos Excel con los registros recolectados.
///
/// Utiliza los puertos remotos para obtener los documentos de Firestore
/// correspondientes a cada tipo de registro (aves, rocas, suelos, etc.)
/// y los vuelca a hojas separadas dentro de un único archivo de Excel (.xlsx).
///
/// Las columnas se generan dinámicamente a partir de las claves presentes en
/// los documentos, por lo que no hay columnas hardcodeadas y los cambios en
/// la estructura de la base de datos se reflejan automáticamente en el Excel.
class ExportService {
  final BirdRecordRemotePort birdPort;
  final RockRecordRemotePort rockPort;
  final SoilRecordRemotePort soilPort;
  final VegetationRecordRemotePort vegetationPort;
  final WaterRecordRemotePort waterPort;
  final SocialRecordRemotePort socialPort;

  /// Constructor de [ExportService].
  ExportService({
    required this.birdPort,
    required this.rockPort,
    required this.soilPort,
    required this.vegetationPort,
    required this.waterPort,
    required this.socialPort,
  });

  /// Determina si el filtrado por fechas debe realizarse en el cliente de la aplicación.
  ///
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

  /// Retorna el inicio del día (00:00:00) para una fecha dada.
  static DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Retorna el final del día (23:59:59.999) para una fecha dada.
  static DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  /// Verifica si una fecha de registro [recordedAt] se encuentra dentro del
  /// rango definido por [startDate] y [endDate].
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

  /// Aplica un filtro de fecha en memoria local (cliente) a una lista de [records].
  static List<Map<String, dynamic>> _applyDateFilterOnRaw(
    List<Map<String, dynamic>> records,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    return records.where((record) {
      final rawRecordedAt = record['recordedAt'];
      if (rawRecordedAt == null) return false;
      final recordedAt = rawRecordedAt is DateTime
          ? rawRecordedAt
          : DateTime.tryParse(rawRecordedAt.toString());
      if (recordedAt == null) return false;
      return _inDateRange(recordedAt, startDate, endDate);
    }).toList();
  }

  /// Aplana un mapa anidado para que las claves compuestas usen [separator].
  ///
  /// Las listas se expanden usando el índice como clave intermedia.
  static Map<String, dynamic> _flatten(
    Map<String, dynamic> data, {
    String separator = '.',
  }) {
    final result = <String, dynamic>{};

    void _flattenHelper(Map<String, dynamic> current, String prefix) {
      current.forEach((key, value) {
        final newKey = prefix.isEmpty ? key : '$prefix$separator$key';
        if (value is Map<String, dynamic>) {
          _flattenHelper(value, newKey);
        } else if (value is List) {
          for (var i = 0; i < value.length; i++) {
            final item = value[i];
            final indexedKey = '$newKey$separator$i';
            if (item is Map<String, dynamic>) {
              _flattenHelper(item, indexedKey);
            } else {
              result[indexedKey] = item;
            }
          }
        } else {
          result[newKey] = value;
        }
      });
    }

    _flattenHelper(data, '');
    return result;
  }

  /// Convierte un valor dinámico en una celda de Excel.
  static CellValue _toCellValue(dynamic value) {
    if (value == null) return TextCellValue('');
    if (value is bool) return TextCellValue(value ? 'Sí' : 'No');
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    if (value is DateTime) return TextCellValue(value.toIso8601String());
    if (value is List) return TextCellValue(value.join(', '));
    return TextCellValue(value.toString());
  }

  /// Escribe una hoja de Excel a partir de documentos en bruto.
  ///
  /// Las columnas se deducen de la unión de todas las claves aplanadas de los
  /// documentos. Si un documento no tiene una clave, la celda queda vacía.
  static void _writeRawSheet(Sheet sheet, List<Map<String, dynamic>> records) {
    if (records.isEmpty) return;

    final flattened = records.map(_flatten).toList();
    final keys = flattened.expand((record) => record.keys).toSet().toList()
      ..sort();

    sheet.appendRow(keys.map((key) => TextCellValue(key)).toList());

    for (final record in flattened) {
      sheet.appendRow(
        keys.map((key) => _toCellValue(record[key])).toList(),
      );
    }
  }

  /// Genera un archivo Excel agrupando todos los tipos de registros en diferentes hojas.
  ///
  /// Si se provee [outingId] o [userId], los datos consultados al backend pertenecerán
  /// exclusivamente a esa salida o a ese usuario.
  ///
  /// El filtro de fechas ([startDate] y [endDate]) puede resolverse localmente
  /// o en la base de datos remota dependiendo del comportamiento de los índices.
  /// El archivo resultante se guarda temporalmente con el prefijo [fileNamePrefix].
  ///
  /// Retorna la ruta (path) absoluto del archivo generado, o null en caso de error.
  Future<String?> generateExcel({
    String? outingId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    required String fileNamePrefix,
  }) async {
    final rangeStart = startDate != null ? _startOfDay(startDate) : null;
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
      final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';

      var birds = await birdPort.getRawBirdRecordsForExport(
        outingId: outingId,
        userId: userId,
        startDate: queryStart,
        endDate: queryEnd,
      );
      if (clientDateFilter) {
        birds = _applyDateFilterOnRaw(birds, rangeStart, rangeEnd);
      }
      if (birds.isNotEmpty) {
        _writeRawSheet(excel['Aves'], birds);
      }

      var rocks = await rockPort.getRawRockRecordsForExport(
        outingId: outingId,
        userId: userId,
        startDate: queryStart,
        endDate: queryEnd,
      );
      if (clientDateFilter) {
        rocks = _applyDateFilterOnRaw(rocks, rangeStart, rangeEnd);
      }
      if (rocks.isNotEmpty) {
        _writeRawSheet(excel['Rocas'], rocks);
      }

      var soils = await soilPort.getRawSoilRecordsForExport(
        outingId: outingId,
        userId: userId,
        startDate: queryStart,
        endDate: queryEnd,
      );
      if (clientDateFilter) {
        soils = _applyDateFilterOnRaw(soils, rangeStart, rangeEnd);
      }
      if (soils.isNotEmpty) {
        _writeRawSheet(excel['Suelos'], soils);
      }

      var veg = await vegetationPort.getRawVegetationRecordsForExport(
        outingId: outingId,
        userId: userId,
        startDate: queryStart,
        endDate: queryEnd,
      );
      if (clientDateFilter) {
        veg = _applyDateFilterOnRaw(veg, rangeStart, rangeEnd);
      }
      if (veg.isNotEmpty) {
        _writeRawSheet(excel['Vegetación'], veg);
      }

      var water = await waterPort.getRawWaterRecordsForExport(
        outingId: outingId,
        userId: userId,
        startDate: queryStart,
        endDate: queryEnd,
      );
      if (clientDateFilter) {
        water = _applyDateFilterOnRaw(water, rangeStart, rangeEnd);
      }
      if (water.isNotEmpty) {
        _writeRawSheet(excel['Agua'], water);
      }

      var socials = await socialPort.getRawSocialRecordsForExport(
        outingId: outingId,
        userId: userId,
        startDate: queryStart,
        endDate: queryEnd,
      );
      if (clientDateFilter) {
        socials = _applyDateFilterOnRaw(socials, rangeStart, rangeEnd);
      }
      if (socials.isNotEmpty) {
        _writeRawSheet(excel['Social'], socials);
      }

      if (excel.tables.keys.length > 1) {
        excel.delete(defaultSheet);
      }

      final fileBytes = excel.save();
      if (fileBytes == null) return null;

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final filePath = '${tempDir.path}/${fileNamePrefix}_$timestamp.xlsx';

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
