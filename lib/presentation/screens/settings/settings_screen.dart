import 'package:flutter/material.dart';
import 'package:harmonix/core/constants/app_constants.dart';
import 'package:harmonix/core/theme/colors.dart';
import 'package:harmonix/data/services/cache_service.dart';
import 'package:harmonix/data/services/settings_service.dart';
import 'package:harmonix/presentation/providers/settings_provider.dart';
import 'package:harmonix/presentation/screens/debug/debug_logs_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla de Ajustes con secciones (Tema, Preferencias, Sobre nosotros).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HarmonixColors.background,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Ajustes',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3)),
            floating: true,
          ),
          SliverList(
            delegate: SliverChildListDelegate.fixed([
              const _SectionHeader('Tema'),
              const _AccentColorSelector(),
              const _SectionHeader('Reproducción'),
              const _PipedInstanceTile(),
              const _CacheLimitTile(),
              const _SkipSilenceTile(),
              const _NormalizeTile(),
              const _BackgroundPlaybackTile(),
              const _SectionHeader('Preferencias'),
              const _LanguageTile(),
              const _NotificationsTile(),
              const _AllowedFoldersTile(),
              const _HiddenFilesTile(),
              const _FileFilterTile(),
              const _DiscordRpcTile(),
              const _SectionHeader('Desarrollador'),
              const _DebugModeTile(),
              const _DebugLogsTile(),
              const _SectionHeader('Sobre nosotros'),
              const _AboutTile(
                icon: Icons.rate_review_rounded,
                title: 'Danos tu opinión',
                url: 'https://github.com/SantiagortegaDev/harmonix/issues',
              ),
              const _AboutTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Política de privacidad',
                url: 'https://github.com/SantiagortegaDev/harmonix',
              ),
              const _AboutTile(
                icon: Icons.description_outlined,
                title: 'Términos y condiciones',
                url: 'https://github.com/SantiagortegaDev/harmonix',
              ),
              const _AboutTile(
                icon: Icons.mail_outline_rounded,
                title: 'Contacto',
                url: 'mailto:harmonix@example.com',
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Harmonix v1.0.0',
                  style: TextStyle(
                      color: HarmonixColors.textDisabled, fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: HarmonixColors.accentBright,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _AccentColorSelector extends StatelessWidget {
  const _AccentColorSelector();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final idx = settings.service.accentSeedIndex;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 56,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: HarmonixColors.accentSeeds.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final color = HarmonixColors.accentSeeds[i];
            final selected = i == idx;
            return GestureDetector(
              onTap: () => settings.setAccentSeedIndex(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? Colors.white
                        : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 22)
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PipedInstanceTile extends StatefulWidget {
  const _PipedInstanceTile();
  @override
  State<_PipedInstanceTile> createState() => _PipedInstanceTileState();
}

class _PipedInstanceTileState extends State<_PipedInstanceTile> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: SettingsService.instance.pipedInstance);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.dns_rounded, color: HarmonixColors.accent),
      title: const Text('Instancia Piped'),
      subtitle: Text(SettingsService.instance.pipedInstance),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: HarmonixColors.textSecondary),
      onTap: () => _showDialog(context),
    );
  }

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Instancia Piped'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                  hintText: 'https://piped.example.com',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            const Text(
              'Lista pública recomendada: pipedapi.kavin.rocks, '
              'piped.tokhmi.xyz, piped.moomoo.me',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              await SettingsService.instance.setPipedInstance(_ctrl.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _CacheLimitTile extends StatefulWidget {
  const _CacheLimitTile();
  @override
  State<_CacheLimitTile> createState() => _CacheLimitTileState();
}

class _CacheLimitTileState extends State<_CacheLimitTile> {
  @override
  Widget build(BuildContext context) {
    final current = SettingsService.instance.cacheLimitMB;
    return ListTile(
      leading: const Icon(Icons.cached_rounded, color: HarmonixColors.accent),
      title: const Text('Límite de caché de audio'),
      subtitle: Text('$current MB · Usado: ${CacheService.instance.currentSizeMB.toStringAsFixed(1)} MB'),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: HarmonixColors.textSecondary),
      onTap: () => _showSlider(context, current),
    );
  }

  void _showSlider(BuildContext context, int current) {
    int value = current;
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$value MB',
                    style: const TextStyle(
                        color: HarmonixColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                Slider(
                  value: value.toDouble(),
                  min: AppConstants.minCacheLimitMB.toDouble(),
                  max: AppConstants.maxCacheLimitMB.toDouble(),
                  divisions:
                      (AppConstants.maxCacheLimitMB - AppConstants.minCacheLimitMB) ~/
                          50,
                  onChanged: (v) => setState(() => value = v.toInt()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar')),
                    FilledButton(
                      onPressed: () async {
                        await SettingsService.instance.setCacheLimitMB(value);
                        CacheService.instance.setLimit(value);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Aplicar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkipSilenceTile extends StatelessWidget {
  const _SkipSilenceTile();
  @override
  Widget build(BuildContext context) {
    return _SwitchTile(
      icon: Icons.hearing_rounded,
      title: 'Saltar silencios',
      subtitle: 'Omite automáticamente los silencios largos',
      getter: () => SettingsService.instance.skipSilence,
      setter: (v) => SettingsService.instance.setSkipSilence(v),
    );
  }
}

class _NormalizeTile extends StatelessWidget {
  const _NormalizeTile();
  @override
  Widget build(BuildContext context) {
    return _SwitchTile(
      icon: Icons.equalizer_rounded,
      title: 'Normalización de audio',
      subtitle: 'Mantén volumen uniforme entre canciones',
      getter: () => SettingsService.instance.normalizeAudio,
      setter: (v) => SettingsService.instance.setNormalizeAudio(v),
    );
  }
}

class _BackgroundPlaybackTile extends StatelessWidget {
  const _BackgroundPlaybackTile();
  @override
  Widget build(BuildContext context) {
    return _SwitchTile(
      icon: Icons.play_circle_outline_rounded,
      title: 'Reproducción en segundo plano',
      subtitle: 'Continúa reproduciendo al salir de la app',
      getter: () => SettingsService.instance.backgroundPlayback,
      setter: (v) => SettingsService.instance.setBackgroundPlayback(v),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile();
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.language_rounded, color: HarmonixColors.accent),
      title: const Text('Idioma'),
      subtitle: const Text('Español'),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: HarmonixColors.textSecondary),
      onTap: () {},
    );
  }
}

class _NotificationsTile extends StatelessWidget {
  const _NotificationsTile();
  @override
  Widget build(BuildContext context) {
    return _SwitchTile(
      icon: Icons.notifications_outlined,
      title: 'Notificaciones',
      subtitle: 'Recibe novedades de Harmonix',
      getter: () => SettingsService.instance.notifications,
      setter: (v) => SettingsService.instance.setNotifications(v),
    );
  }
}

class _AllowedFoldersTile extends StatelessWidget {
  const _AllowedFoldersTile();
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.folder_rounded, color: HarmonixColors.accent),
      title: const Text('Carpetas permitidas'),
      subtitle: const Text('Carpetas locales accesibles'),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: HarmonixColors.textSecondary),
      onTap: () {},
    );
  }
}

class _HiddenFilesTile extends StatelessWidget {
  const _HiddenFilesTile();
  @override
  Widget build(BuildContext context) {
    return _SwitchTile(
      icon: Icons.visibility_off_outlined,
      title: 'Mostrar archivos ocultos',
      subtitle: 'Incluye archivos y carpetas que empiezan con "."',
      getter: () => SettingsService.instance.showHiddenFiles,
      setter: (v) => SettingsService.instance.setShowHiddenFiles(v),
    );
  }
}

class _FileFilterTile extends StatelessWidget {
  const _FileFilterTile();
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.filter_alt_outlined,
          color: HarmonixColors.accent),
      title: const Text('Filtro de archivos'),
      subtitle: Text(SettingsService.instance.fileFilter),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: HarmonixColors.textSecondary),
      onTap: () {},
    );
  }
}

class _DiscordRpcTile extends StatelessWidget {
  const _DiscordRpcTile();
  @override
  Widget build(BuildContext context) {
    return _SwitchTile(
      icon: Icons.discord_outlined,
      title: 'Discord Rich Presence',
      subtitle: 'Muestra lo que escuchas en Discord',
      getter: () => SettingsService.instance.discordRpc,
      setter: (v) => SettingsService.instance.setDiscordRpc(v),
    );
  }
}

class _DebugModeTile extends StatelessWidget {
  const _DebugModeTile();
  @override
  Widget build(BuildContext context) {
    return _SwitchTile(
      icon: Icons.bug_report_rounded,
      title: 'Modo desarrollador',
      subtitle: 'Habilita herramientas de depuración',
      getter: () => SettingsService.instance.debugMode,
      setter: (v) => SettingsService.instance.setDebugMode(v),
    );
  }
}

class _DebugLogsTile extends StatelessWidget {
  const _DebugLogsTile();
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.terminal_rounded, color: HarmonixColors.accent),
      title: const Text('Logs de depuración'),
      subtitle: const Text('Ver requests y errores en tiempo real'),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: HarmonixColors.textSecondary),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DebugLogsScreen()),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile({
    required this.icon,
    required this.title,
    required this.url,
  });
  final IconData icon;
  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: HarmonixColors.accent),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: HarmonixColors.textSecondary),
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.getter,
    required this.setter,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool Function() getter;
  final Future<void> Function(bool) setter;

  @override
  Widget build(BuildContext context) {
    bool value = getter();
    return StatefulBuilder(
      builder: (ctx, setState) => SwitchListTile(
        secondary: Icon(icon, color: HarmonixColors.accent),
        title: Text(title),
        subtitle: Text(subtitle,
            style: const TextStyle(
                color: HarmonixColors.textSecondary, fontSize: 12)),
        value: value,
        onChanged: (v) async {
          await setter(v);
          setState(() {});
        },
      ),
    );
  }
}
