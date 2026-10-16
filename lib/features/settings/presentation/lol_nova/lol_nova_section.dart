import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_constants.dart';
import '../../../library/data/library_backup_service.dart';
import '../diagnostics/diagnostics_page.dart';

/// Sección "LOL Nova": diagnóstico y copia de seguridad de la biblioteca local.
class LolNovaSectionPage extends StatefulWidget {
  const LolNovaSectionPage({super.key});

  @override
  State<LolNovaSectionPage> createState() => _LolNovaSectionPageState();
}

class _LolNovaSectionPageState extends State<LolNovaSectionPage> {
  static const _card = Color(0xFF1C1C1E);
  bool _busy = false;

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade800 : const Color(0xFF1C1C1E),
      ),
    );
  }

  Future<void> _openDiagnostics() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DiagnosticsPage()),
    );
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final json = await LibraryBackupService.export();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _card,
          title: const Text(
            'Copia exportada',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                json,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: json));
                if (ctx.mounted) Navigator.pop(ctx);
                _snack('Copia en el portapapeles.');
              },
              child: const Text('Copiar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      _snack('No se pudo exportar: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        title: const Text(
          'Importar biblioteca',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pega aquí una copia exportada previamente.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: '{"app":"LOL Nova","schema":1,...}',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Importar'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (raw == null || raw.trim().isEmpty) return;

    final replace = await _askReplace();
    if (replace == null) return;

    setState(() => _busy = true);
    try {
      final written = await LibraryBackupService.importFromJson(
        raw,
        replace: replace,
      );
      _snack(
        written == 0
            ? 'No había elementos nuevos para importar.'
            : 'Importados $written elemento(s).',
      );
    } catch (e) {
      _snack('Copia inválida: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _askReplace() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        title: const Text(
          'Modo de importación',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          '¿Reemplazar tu biblioteca actual o fusionarla con la copia?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Fusionar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Reemplazar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
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
          'LOL Nova',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _tile(
            icon: Icons.monitor_heart_outlined,
            title: 'Diagnóstico',
            subtitle: 'Versión, dispositivo y estado (sin datos sensibles)',
            onTap: _busy ? null : _openDiagnostics,
          ),
          _tile(
            icon: Icons.upload_file_rounded,
            title: 'Exportar biblioteca',
            subtitle: 'Favoritos, historial y "me gusta" a JSON',
            onTap: _busy ? null : _export,
          ),
          _tile(
            icon: Icons.download_for_offline_outlined,
            title: 'Importar biblioteca',
            subtitle: 'Restaurar desde una copia exportada',
            onTap: _busy ? null : _import,
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppConstants.accentColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppConstants.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppConstants.accentColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.35),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
