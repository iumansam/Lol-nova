import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de reproducción persistentes de "LOL Nova".
///
/// - Velocidad de reproducción (se aplica al reabrir cualquier video).
/// - Posición de reanudación por contenido (continuar donde se dejó).
///
/// La lógica pura (`normalizeSpeed`, `label`, `nextSpeed`) es testeable sin
/// el plugin de SharedPreferences.
class PlaybackPreferences {
  PlaybackPreferences._();

  static const String _kSpeed = 'player_playback_speed';
  static const String _kResumePrefix = 'player_resume_';

  /// Velocidades permitidas.
  static const List<double> speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  static const double defaultSpeed = 1.0;

  /// Segundos mínimos antes de considerar una posición "reanudable".
  static const int minResumeSeconds = 5;

  // ── Lógica pura ─────────────────────────────────────────────────────────

  /// Devuelve la velocidad permitida más cercana a [value].
  static double normalizeSpeed(double? value) {
    if (value == null) return defaultSpeed;
    var best = defaultSpeed;
    var bestDiff = double.infinity;
    for (final s in speeds) {
      final diff = (s - value).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = s;
      }
    }
    return best;
  }

  /// Etiqueta legible: `1x`, `1.25x`, `0.75x`…
  static String label(double speed) {
    final fixed = speed.toStringAsFixed(2);
    final trimmed = fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return '${trimmed.isEmpty ? '0' : trimmed}x';
  }

  /// Siguiente velocidad del ciclo (wraps).
  static double nextSpeed(double current) {
    final idx = speeds.indexOf(normalizeSpeed(current));
    return speeds[(idx + 1) % speeds.length];
  }

  // ── Persistencia ────────────────────────────────────────────────────────

  static Future<double> getSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getDouble(_kSpeed);
    return normalizeSpeed(raw);
  }

  static Future<void> setSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kSpeed, normalizeSpeed(speed));
  }

  /// Guarda la posición (segundos) de un contenido.
  static Future<void> saveResume(String key, int seconds) async {
    if (key.isEmpty || seconds < minResumeSeconds) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_kResumePrefix$key', seconds);
  }

  /// Posición guardada (segundos), o `null` si no hay nada reanudable.
  static Future<int?> getResume(String key) async {
    if (key.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt('$_kResumePrefix$key');
    if (v == null || v < minResumeSeconds) return null;
    return v;
  }

  static Future<void> clearResume(String key) async {
    if (key.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kResumePrefix$key');
  }
}
