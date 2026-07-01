import 'package:logger/logger.dart';

/// Logger global de Harmonix.
///
/// También almacena los últimos N logs en memoria para la pantalla
/// DebugLogs. Se accede desde cualquier parte de la app vía
/// `HarmonixLogger.instance`.
class HarmonixLogger {
  HarmonixLogger._();
  static final HarmonixLogger instance = HarmonixLogger._();

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: Level.debug,
  );

  /// Buffer circular en memoria para la pantalla de debug.
  final List<HarmonixLogEntry> _buffer = [];
  static const int _maxBuffer = 1000;

  List<HarmonixLogEntry> get entries => List.unmodifiable(_buffer);

  void addEntry(HarmonixLogEntry entry) {
    _buffer.add(entry);
    if (_buffer.length > _maxBuffer) {
      _buffer.removeRange(0, _buffer.length - _maxBuffer);
    }
  }

  /// Limpia el buffer en memoria (no afecta a la salida estándar).
  void clearBuffer() {
    _buffer.clear();
  }

  void debug(String message, {String? tag}) {
    _logger.d('[$tag] $message');
    addEntry(HarmonixLogEntry(level: Level.debug, message: message, tag: tag));
  }

  void info(String message, {String? tag}) {
    _logger.i('[$tag] $message');
    addEntry(HarmonixLogEntry(level: Level.info, message: message, tag: tag));
  }

  void warning(String message, {String? tag, Object? error, StackTrace? stack}) {
    _logger.w('[$tag] $message', error: error, stackTrace: stack);
    addEntry(HarmonixLogEntry(
      level: Level.warning,
      message: message,
      tag: tag,
      error: error?.toString(),
      stack: stack?.toString(),
    ));
  }

  void error(String message, {String? tag, Object? error, StackTrace? stack}) {
    _logger.e('[$tag] $message', error: error, stackTrace: stack);
    addEntry(HarmonixLogEntry(
      level: Level.error,
      message: message,
      tag: tag,
      error: error?.toString(),
      stack: stack?.toString(),
    ));
  }
}

/// Representación simple de una entrada de log para la UI.
class HarmonixLogEntry {
  HarmonixLogEntry({
    required this.level,
    required this.message,
    this.tag,
    this.error,
    this.stack,
  }) : timestamp = DateTime.now();

  final Level level;
  final String message;
  final String? tag;
  final String? error;
  final String? stack;
  final DateTime timestamp;
}
