import 'dart:async';
import 'package:flutter/material.dart';
import 'package:harmonix/core/theme/colors.dart';
import 'package:harmonix/core/utils/logger.dart';
import 'package:logger/logger.dart' show Level;

/// Pantalla de logs en tiempo real (modo desarrollador).
///
/// Muestra todas las entradas del [HarmonixLogger] (requests a Piped, errores
/// de streaming, errores de caché, etc.). Stream periódico (10 fps) para no
/// saturar la UI.
class DebugLogsScreen extends StatefulWidget {
  const DebugLogsScreen({super.key});

  @override
  State<DebugLogsScreen> createState() => _DebugLogsScreenState();
}

class _DebugLogsScreenState extends State<DebugLogsScreen> {
  Timer? _timer;
  final ScrollController _scroll = ScrollController();
  /// Filtro actual. null = todos los niveles.
  Level? _filter;
  List<HarmonixLogEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _refresh());
  }

  void _refresh() {
    final all = HarmonixLogger.instance.entries;
    final filtered = _filter == null
        ? all
        : all.where((e) => e.level.index >= _filter!.index).toList();
    if (!mounted) return;
    setState(() => _entries = filtered);
    // Auto-scroll al final
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Color _colorFor(Level level) {
    switch (level) {
      case Level.debug:
        return HarmonixColors.textSecondary;
      case Level.info:
        return HarmonixColors.accentBright;
      case Level.warning:
        return HarmonixColors.recent;
      case Level.error:
        return HarmonixColors.error;
      default:
        return HarmonixColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HarmonixColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Logs'),
        backgroundColor: HarmonixColors.background,
        actions: [
          PopupMenuButton<Level?>(
            icon: const Icon(Icons.filter_list_rounded,
                color: HarmonixColors.textPrimary),
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: null, child: Text('Todos')),
              PopupMenuItem(value: Level.debug, child: Text('Debug+')),
              PopupMenuItem(value: Level.info, child: Text('Info+')),
              PopupMenuItem(value: Level.warning, child: Text('Warning+')),
              PopupMenuItem(value: Level.error, child: Text('Errores')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: HarmonixColors.textSecondary),
            tooltip: 'Limpiar',
            onPressed: () {
              HarmonixLogger.instance.clearBuffer();
              _refresh();
            },
          ),
        ],
      ),
      body: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(8),
        itemCount: _entries.length,
        itemBuilder: (_, i) {
          final e = _entries[i];
          final time =
              '${e.timestamp.hour.toString().padLeft(2, '0')}:${e.timestamp.minute.toString().padLeft(2, '0')}:${e.timestamp.second.toString().padLeft(2, '0')}.${e.timestamp.millisecond.toString().padLeft(3, '0')}';
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: HarmonixColors.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _colorFor(e.level).withValues(alpha: 0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(time,
                        style: TextStyle(
                            color: HarmonixColors.textDisabled,
                            fontSize: 10,
                            fontFamily: 'monospace')),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: _colorFor(e.level).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        e.level.name.toUpperCase(),
                        style: TextStyle(
                            color: _colorFor(e.level),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace'),
                      ),
                    ),
                    if (e.tag != null) ...[
                      const SizedBox(width: 8),
                      Text(e.tag!,
                          style: TextStyle(
                              color: HarmonixColors.accent.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontFamily: 'monospace')),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                SelectableText(
                  e.message,
                  style: const TextStyle(
                      color: HarmonixColors.textPrimary,
                      fontSize: 12,
                      fontFamily: 'monospace'),
                ),
                if (e.error != null) ...[
                  const SizedBox(height: 4),
                  SelectableText(
                    e.error!,
                    style: TextStyle(
                        color: HarmonixColors.error.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontFamily: 'monospace'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
