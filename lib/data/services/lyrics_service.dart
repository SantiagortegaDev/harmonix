import 'package:dio/dio.dart';
import 'package:harmonix/core/utils/logger.dart';

/// Línea de letra sincronizada (LRC).
class LyricLine {
  LyricLine(this.time, this.text);
  final Duration time;
  final String text;

  bool get isGap => text.trim().isEmpty;
}

/// Resultado con letra original + traducción opcional.
class LyricsResult {
  LyricsResult({this.original = const [], this.translated = const []});
  final List<LyricLine> original;
  final List<LyricLine> translated;
}

/// Servicio de letras sincronizadas.
///
/// Estrategia (orden):
///  1. Buscar letras sincronizadas en LRCLIB (https://lrclib.net/api).
///  2. Fallback a letras no sincronizadas si no hay LRC.
///  3. Traducción opcional vía MyMemory API o LibreTranslate.
class LyricsService {
  LyricsService._();
  static final LyricsService instance = LyricsService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );

  /// Obtiene letras para una canción.
  Future<LyricsResult> fetch({
    required String title,
    required String artist,
    String? album,
    int? durationMs,
  }) async {
    try {
      final res = await _dio.get('https://lrclib.net/api/get', queryParameters: {
        'artist_name': artist,
        'track_name': title,
        'album_name': album,
        'duration': durationMs != null ? (durationMs / 1000).round() : null,
      });
      final data = res.data as Map<String, dynamic>;
      final synced = data['syncedLyrics'] as String?;
      final plain = data['plainLyrics'] as String?;
      final lines = synced != null
          ? _parseLrc(synced)
          : (plain != null
              ? plain
                  .split('\n')
                  .where((l) => l.trim().isNotEmpty)
                  .map((l) => LyricLine(Duration.zero, l))
                  .toList()
              : <LyricLine>[]);
      return LyricsResult(original: lines);
    } catch (e, s) {
      HarmonixLogger.instance.warning('Letras no encontradas para "$title"',
          tag: 'Lyrics', error: e, stack: s);
      return LyricsResult();
    }
  }

  /// Traduce líneas vía MyMemory (gratis, no requiere auth).
  Future<List<LyricLine>> translate(List<LyricLine> lines, {String to = 'es'}) async {
    try {
      final out = <LyricLine>[];
      for (final l in lines) {
        if (l.isGap) {
          out.add(l);
          continue;
        }
        final res = await _dio.get('https://api.mymemory.translated.net/get',
            queryParameters: {'q': l.text, 'langpair': 'en|$to'});
        final translated =
            (res.data as Map<String, dynamic>)['responseData']?['translatedText']
                    ?.toString() ??
                l.text;
        out.add(LyricLine(l.time, translated));
      }
      return out;
    } catch (e, s) {
      HarmonixLogger.instance.warning('Traducción falló',
          tag: 'Lyrics', error: e, stack: s);
      return lines;
    }
  }

  /// Parser LRC estándar: [mm:ss.xx]texto
  List<LyricLine> _parseLrc(String lrc) {
    final regex = RegExp(r'\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]');
    final lines = <LyricLine>[];
    for (final raw in lrc.split('\n')) {
      final matches = regex.allMatches(raw);
      if (matches.isEmpty) continue;
      final text = raw.substring(matches.last.end);
      for (final m in matches) {
        final min = int.parse(m.group(1)!);
        final sec = int.parse(m.group(2)!);
        final msRaw = m.group(3) ?? '0';
        final ms = int.parse(msRaw.padRight(3, '0'));
        lines.add(LyricLine(
            Duration(minutes: min, seconds: sec, milliseconds: ms), text));
      }
    }
    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }
}
