import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Copia de seguridad de favoritos / historial / "me gusta" locales.
///
/// Exporta e importa las listas que la app guarda en `SharedPreferences`
/// (modo invitado o caché local). El formato es JSON versionado y no contiene
/// secretos ni credenciales.
///
/// La codificación/decodificación es pura y testeable; la lectura/escritura de
/// `SharedPreferences` se aísla en [export] / [importFromJson].
class LibraryBackupService {
  LibraryBackupService._();

  static const int schemaVersion = 1;

  /// Claves de `SharedPreferences` que forman la biblioteca local.
  static const String guardadosKey = 'local_guardados';
  static const String historialKey = 'local_historial';
  static const String likesKey = 'local_likes';

  static const List<String> localKeys = [
    guardadosKey,
    historialKey,
    likesKey,
  ];

  // ── Lógica pura ─────────────────────────────────────────────────────────

  /// Serializa las listas a un JSON versionado.
  static String encode(
    Map<String, List<Map<String, dynamic>>> data, {
    DateTime? exportedAt,
  }) {
    final payload = <String, dynamic>{
      'app': 'LOL Nova',
      'schema': schemaVersion,
      'exported_at': (exportedAt ?? DateTime.now()).toIso8601String(),
      'data': {for (final k in localKeys) k: data[k] ?? const []},
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Decodifica y valida una copia. Lanza [FormatException] si es inválida.
  static LibraryBackup decode(String raw) {
    if (raw.trim().isEmpty) {
      throw const FormatException('La copia está vacía.');
    }
    final dynamic parsed;
    try {
      parsed = jsonDecode(raw);
    } on FormatException {
      throw const FormatException('El texto no es JSON válido.');
    }
    if (parsed is! Map) {
      throw const FormatException('Formato de copia desconocido.');
    }
    final schema = parsed['schema'];
    if (schema is! int) {
      throw const FormatException('Falta la versión del esquema.');
    }
    if (schema > schemaVersion) {
      throw FormatException(
        'La copia es más nueva (schema $schema) que esta app ($schemaVersion).',
      );
    }
    final data = parsed['data'];
    if (data is! Map) {
      throw const FormatException('La copia no contiene datos.');
    }
    final lists = <String, List<Map<String, dynamic>>>{};
    for (final key in localKeys) {
      final value = data[key];
      if (value == null) continue;
      if (value is! List) {
        throw FormatException('El campo "$key" no es una lista.');
      }
      lists[key] = value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return LibraryBackup(
      schema: schema,
      exportedAt:
          DateTime.tryParse(parsed['exported_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
      lists: lists,
    );
  }

  // ── Persistencia ────────────────────────────────────────────────────────

  static Future<Map<String, List<Map<String, dynamic>>>> _readLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, List<Map<String, dynamic>>>{};
    for (final key in localKeys) {
      result[key] = _decodeList(prefs.getString(key));
    }
    return result;
  }

  static List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Cuenta los elementos guardados bajo [key]. Útil para diagnóstico.
  static int countOf(SharedPreferences prefs, String key) =>
      _decodeList(prefs.getString(key)).length;

  /// Exporta la biblioteca local a JSON.
  static Future<String> export() async {
    final data = await _readLocal();
    return encode(data);
  }

  /// Importa una copia. Si [replace] es `true` reemplaza las listas afectadas;
  /// si es `false` fusiona evitando duplicados (comparando JSON del elemento).
  ///
  /// Devuelve cuántos elementos se escribieron.
  static Future<int> importFromJson(String raw, {bool replace = true}) async {
    final backup = decode(raw);
    final prefs = await SharedPreferences.getInstance();
    var written = 0;

    for (final entry in backup.lists.entries) {
      final incoming = entry.value;
      if (incoming.isEmpty) continue;

      final target = replace
          ? <Map<String, dynamic>>[]
          : _decodeList(prefs.getString(entry.key));

      final seen = target
          .map((e) => jsonEncode(e))
          .toSet();

      for (final item in incoming) {
        final signature = jsonEncode(item);
        if (seen.add(signature)) {
          target.add(item);
          written++;
        }
      }

      await prefs.setString(entry.key, jsonEncode(target));
    }

    return written;
  }
}

/// Copia decodificada.
class LibraryBackup {
  const LibraryBackup({
    required this.schema,
    required this.exportedAt,
    required this.lists,
  });

  final int schema;
  final DateTime exportedAt;
  final Map<String, List<Map<String, dynamic>>> lists;

  int get totalItems =>
      lists.values.fold(0, (sum, list) => sum + list.length);

  int countOf(String key) => lists[key]?.length ?? 0;
}
