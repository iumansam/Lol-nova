import 'package:flutter_test/flutter_test.dart';
import 'package:lol_nova/features/player/data/playback_preferences.dart';

void main() {
  group('PlaybackPreferences.normalizeSpeed', () {
    test('devuelve 1.0 cuando el valor es null', () {
      expect(PlaybackPreferences.normalizeSpeed(null), 1.0);
    });

    test('ajusta al preset permitido más cercano', () {
      expect(PlaybackPreferences.normalizeSpeed(1.1), 1.0);
      expect(PlaybackPreferences.normalizeSpeed(1.3), 1.25);
      expect(PlaybackPreferences.normalizeSpeed(1.9), 2.0);
      expect(PlaybackPreferences.normalizeSpeed(0.4), 0.5);
      expect(PlaybackPreferences.normalizeSpeed(99), 2.0);
    });

    test('respeta los valores exactos de la lista', () {
      for (final s in PlaybackPreferences.speeds) {
        expect(PlaybackPreferences.normalizeSpeed(s), s);
      }
    });
  });

  group('PlaybackPreferences.label', () {
    test('formatea sin ceros innecesarios', () {
      expect(PlaybackPreferences.label(1.0), '1x');
      expect(PlaybackPreferences.label(1.25), '1.25x');
      expect(PlaybackPreferences.label(0.75), '0.75x');
      expect(PlaybackPreferences.label(2.0), '2x');
    });
  });

  group('PlaybackPreferences.nextSpeed', () {
    test('avanza en el ciclo de velocidades', () {
      expect(PlaybackPreferences.nextSpeed(1.0), 1.25);
      expect(PlaybackPreferences.nextSpeed(2.0), 0.5);
      expect(PlaybackPreferences.nextSpeed(0.5), 0.75);
    });

    test('normaliza antes de avanzar', () {
      expect(PlaybackPreferences.nextSpeed(1.1), 1.25);
    });
  });
}
