import 'package:flutter/material.dart';

import '../../../app/app_constants.dart';

/// Estados reutilizables de carga y error para "LOL Nova".
///
/// Tema oscuro consistente con el resto de la app y un botón de reintento
/// explícito para que cualquier pantalla pueda ofrecer recuperación sin
/// duplicar UI.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message, this.color});

  final String? message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppConstants.accentColor;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(color: accent, strokeWidth: 3),
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Vista de error con botón "Reintentar".
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.onRetry,
    this.title = 'Algo salió mal',
    this.message,
    this.error,
    this.retryLabel = 'Reintentar',
    this.accent,
  });

  final VoidCallback onRetry;
  final String title;
  final String? message;

  /// Objeto de error original (solo se muestra un texto corto, sin stack).
  final Object? error;
  final String retryLabel;
  final Color? accent;

  String get _detail {
    if (message != null && message!.isNotEmpty) return message!;
    if (error != null) return error.toString();
    return 'No se pudo completar la operación.';
  }

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppConstants.accentColor;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: color, size: 54),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _detail,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(retryLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista de estado vacío, también en tema oscuro.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
