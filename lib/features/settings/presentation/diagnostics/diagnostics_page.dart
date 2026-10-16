import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/app_constants.dart';
import '../../../../core/constants/app_secrets.dart';
import '../../../../presentation/shared/widgets/async_state_views.dart';
import '../../../library/data/library_backup_service.dart';

/// Pantalla de diagnóstico de "LOL Nova".
///
/// Muestra únicamente información técnica no sensible: versión de la app,
/// datos del dispositivo, presencia (sí/no) de la clave TMDB y contadores de la
/// biblioteca local. Nunca muestra claves, tokens ni el contenido de los datos.
class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  Map<String, List<_DiagnosticEntry>>? _data;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _collect();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<Map<String, List<_DiagnosticEntry>>> _collect() async {
    final sections = <String, List<_DiagnosticEntry>>{};

    // ── Aplicación ────────────────────────────────────────────────────────
    try {
      final info = await PackageInfo.fromPlatform();
      sections['Aplicación'] = [
        _DiagnosticEntry('Nombre', info.appName.isEmpty ? 'LOL Nova' : info.appName),
        _DiagnosticEntry('Versión', info.version),
        _DiagnosticEntry('Build', info.buildNumber),
        _DiagnosticEntry('Paquete', info.packageName),
      ];
    } catch (_) {
      sections['Aplicación'] = [
        const _DiagnosticEntry('Nombre', 'LOL Nova'),
        const _DiagnosticEntry('Paquete', 'no disponible'),
      ];
    }

    // ── Entorno ───────────────────────────────────────────────────────────
    sections['Entorno'] = [
      _DiagnosticEntry('Plataforma', _platformName()),
      _DiagnosticEntry('Dart runtime', _dartVersion()),
      _DiagnosticEntry('Clave TMDB inyectada', AppSecrets.hasTmdbApiKey ? 'Sí' : 'No'),
    ];

    // ── Dispositivo ───────────────────────────────────────────────────────
    sections['Dispositivo'] = await _deviceInfo();

    // ── Biblioteca local (solo contadores) ────────────────────────────────
    sections['Biblioteca local'] = await _libraryCounts();

    return sections;
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    try {
      return Platform.operatingSystem;
    } catch (_) {
      return 'desconocida';
    }
  }

  String _dartVersion() {
    try {
      // Platform.version incluye el runtime Dart y el SO.
      final v = Platform.version;
      return v.length > 60 ? '${v.substring(0, 60)}…' : v;
    } catch (_) {
      return 'no disponible';
    }
  }

  Future<List<_DiagnosticEntry>> _deviceInfo() async {
    if (kIsWeb) return const [];
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await plugin.androidInfo;
        final isTv = a.systemFeatures
            .any((f) => f.contains('android.software.leanback'));
        return [
          _DiagnosticEntry('Fabricante', a.manufacturer),
          _DiagnosticEntry('Modelo', a.model),
          _DiagnosticEntry(
            'Android',
            '${a.version.release} (SDK ${a.version.sdkInt})',
          ),
          _DiagnosticEntry('Android TV', isTv ? 'Sí' : 'No'),
          _DiagnosticEntry(
            'Físico',
            a.isPhysicalDevice ? 'Sí' : 'No (emulador)',
          ),
        ];
      }
      return [
        _DiagnosticEntry('Plataforma', Platform.operatingSystem),
        _DiagnosticEntry('Versión', Platform.operatingSystemVersion),
      ];
    } catch (_) {
      return const [_DiagnosticEntry('Dispositivo', 'no disponible')];
    }
  }

  Future<List<_DiagnosticEntry>> _libraryCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return [
        _DiagnosticEntry(
          'Guardados',
          '${LibraryBackupService.countOf(prefs, LibraryBackupService.guardadosKey)}',
        ),
        _DiagnosticEntry(
          'Historial',
          '${LibraryBackupService.countOf(prefs, LibraryBackupService.historialKey)}',
        ),
        _DiagnosticEntry(
          'Me gusta',
          '${LibraryBackupService.countOf(prefs, LibraryBackupService.likesKey)}',
        ),
        _DiagnosticEntry(
          'API TMDB propia',
          (prefs.getBool('tmdb_use_custom_api') ?? false) ? 'Activada' : 'No',
        ),
      ];
    } catch (_) {
      return const [_DiagnosticEntry('Biblioteca', 'no disponible')];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Diagnóstico',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppLoadingView(message: 'Recopilando diagnóstico…');
    }
    if (_error != null) {
      return AppErrorView(
        title: 'No se pudo recopilar el diagnóstico',
        error: _error,
        message: 'Intenta de nuevo.',
        onRetry: _load,
      );
    }
    final data = _data ?? const {};
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        for (final section in data.entries) ...[
          _SectionCard(title: section.key, entries: section.value),
          const SizedBox(height: 14),
        ],
        Text(
          'Esta pantalla no muestra claves, tokens ni el contenido de tu '
          'biblioteca: solo su cantidad y datos técnicos del equipo.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.entries});

  final String title;
  final List<_DiagnosticEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      e.label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DiagnosticEntry {
  const _DiagnosticEntry(this.label, this.value);

  final String label;
  final String value;
}
