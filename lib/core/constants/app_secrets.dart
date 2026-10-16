/// Secretos de compilación inyectados con `--dart-define`.
///
/// NUNCA escribas claves reales en el repositorio. En GitHub Actions se pasan
/// a build/analyze/test, por ejemplo:
///
///   flutter build apk --debug --dart-define=TMDB_API_KEY=$TMDB_API_KEY
///
/// donde `TMDB_API_KEY` es un secret del repositorio.
class AppSecrets {
  AppSecrets._();

  /// Clave de la API de TMDB. Cadena vacía si no se inyectó en compilación.
  static const String tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');

  /// `true` cuando el build recibió una clave TMDB por `--dart-define`.
  static bool get hasTmdbApiKey => tmdbApiKey.trim().isNotEmpty;
}
