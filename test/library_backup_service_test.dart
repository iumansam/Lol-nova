import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lol_nova/features/library/data/library_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibraryBackupService.encode / decode', () {
    test('round-trip conserva los datos y la versión', () {
      final data = {
        LibraryBackupService.guardadosKey: [
          {'tmdb_id': 550, 'tipo': 'movie', 'titulo': 'Fight Club'},
        ],
        LibraryBackupService.historialKey: [
          {'tmdb_id': 1399, 'tipo': 'tv', 'segundo': 1200},
        ],
        LibraryBackupService.likesKey: <Map<String, dynamic>>[],
      };

      final json = LibraryBackupService.encode(
        data,
        exportedAt: DateTime.utc(2026, 1, 1),
      );
      final backup = LibraryBackupService.decode(json);

      expect(backup.schema, LibraryBackupService.schemaVersion);
      expect(backup.exportedAt.toUtc(), DateTime.utc(2026, 1, 1));
      expect(backup.countOf(LibraryBackupService.guardadosKey), 1);
      expect(backup.countOf(LibraryBackupService.historialKey), 1);
      expect(backup.totalItems, 2);
    });

    test('rechaza texto vacío', () {
      expect(
        () => LibraryBackupService.decode('   '),
        throwsA(isA<FormatException>()),
      );
    });

    test('rechaza JSON inválido', () {
      expect(
        () => LibraryBackupService.decode('no-json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rechaza esquema más nuevo', () {
      final json = jsonEncode({
        'schema': LibraryBackupService.schemaVersion + 1,
        'data': {},
      });
      expect(
        () => LibraryBackupService.decode(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('rechaza lista con forma incorrecta', () {
      final json = jsonEncode({
        'schema': LibraryBackupService.schemaVersion,
        'data': {LibraryBackupService.guardadosKey: 'no-es-lista'},
      });
      expect(
        () => LibraryBackupService.decode(json),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('LibraryBackupService.importFromJson', () {
    test('reemplaza la biblioteca existente', () async {
      SharedPreferences.setMockInitialValues({
        LibraryBackupService.guardadosKey: jsonEncode([
          {'tmdb_id': 1, 'tipo': 'movie'},
        ]),
      });

      final json = LibraryBackupService.encode({
        LibraryBackupService.guardadosKey: [
          {'tmdb_id': 2, 'tipo': 'movie'},
        ],
      });

      final written = await LibraryBackupService.importFromJson(json, replace: true);
      expect(written, 1);

      final prefs = await SharedPreferences.getInstance();
      final stored =
          jsonDecode(prefs.getString(LibraryBackupService.guardadosKey)!)
              as List;
      expect(stored.length, 1);
      expect((stored.first as Map)['tmdb_id'], 2);
    });

    test('fusiona sin duplicar elementos idénticos', () async {
      SharedPreferences.setMockInitialValues({
        LibraryBackupService.guardadosKey: jsonEncode([
          {'tmdb_id': 1, 'tipo': 'movie'},
        ]),
      });

      final json = LibraryBackupService.encode({
        LibraryBackupService.guardadosKey: [
          {'tmdb_id': 1, 'tipo': 'movie'},
          {'tmdb_id': 2, 'tipo': 'movie'},
        ],
      });

      final written = await LibraryBackupService.importFromJson(json, replace: false);
      expect(written, 1, reason: 'solo el elemento nuevo debe añadirse');

      final prefs = await SharedPreferences.getInstance();
      final stored =
          jsonDecode(prefs.getString(LibraryBackupService.guardadosKey)!)
              as List;
      expect(stored.length, 2);
    });
  });
}
