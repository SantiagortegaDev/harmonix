# Harmonix

Reproductor de música para Android construido en Flutter/Dart, inspirado en InnerTune, con Material Design 3 estricto (Material You dynamic theming, NavigationBar, Cards, FilledButton, Slider MD3), animaciones fluidas (hero animations entre mini-player y reproductor completo, fade/slide entre pantallas, staggered animations en listas, wavy slider animado) y música extraída de YouTube Music vía la API de Piped.

> Sin inicio de sesión. Sin cuenta de Google/YouTube. Toda la app funciona de forma anónima.

## Características principales

- **Búsqueda** de canciones, videos, álbumes y playlists (vía Piped → YouTube Music).
- **Reproducción sin anuncios** y **en segundo plano** (notificación multimedia) con `just_audio` + `audio_service`.
- **Quick picks / recomendaciones** personalizadas en la pantalla de inicio.
- **Caché inteligente** de audio en disco (Hive) — igual que Spotify, las últimas canciones reproducidas no se vuelven a descargar; límite configurable.
- **Descargas** para escuchar sin conexión, con sección dedicada.
- **Letras sincronizadas** con opción de traducción.
- **Skip silence**, **normalización de audio** y **ajuste de tempo/pitch** en tiempo real.
- **Soporte Android Auto**.
- **Discord Rich Presence** (opcional).
- **Modo debug/desarrollador** con pantalla de logs en tiempo real (paquete `logger`): requests a Piped, errores de streaming, errores de caché, etc.

## Stack

| Capa | Tecnología |
|------|-----------|
| UI / Estado | Flutter 3.19+, Material 3, `provider` |
| Audio | `just_audio`, `audio_service`, `audio_session` |
| API | `dio` + `retrofit` → Piped API |
| Caché local | `hive` + `path_provider` |
| Descargas | `flutter_downloader` + `permission_handler` |
| Letras | scraping HTML + sincronización LRC |
| Logs | `logger` |
| Animaciones | `shimmer`, hero animations, `AnimatedList`, `CustomPainter` (wavy slider) |

## Configuración de instancia Piped

Por defecto: `https://piped.private.coffee`.

Configurable desde **Ajustes → Reproducción → Instancia Piped**. Si tu región bloquea Piped, puedes indicar otra instancia pública o propia.

## Compilar

```bash
flutter pub get
flutter run            # debug
flutter build apk --release
```

El repositorio incluye un workflow de GitHub Actions (`.github/workflows/build-release.yml`) que compila el APK release y lo publica como **Release Beta** en cada push a `main` (o manualmente vía `workflow_dispatch`).

## Estructura del proyecto

```
lib/
├── core/                 # Tema, constantes, router, logger, utils
│   ├── constants/
│   ├── theme/
│   ├── router/
│   └── utils/
├── data/                 # Capa de datos
│   ├── models/
│   ├── repositories/
│   └── services/         # Piped, AudioPlayer, Cache, Downloads, Lyrics, Settings
├── presentation/         # UI
│   ├── providers/
│   ├── screens/          # home, library, downloads, files, player, search, settings, debug
│   └── widgets/          # mini_player, wavy_slider, song_card, loading_skeleton, ...
└── main.dart
```

## Paleta de colores

| Token | Hex | Uso |
|-------|-----|-----|
| `harmonixBackground` | `#0A1A3A` | Fondo principal |
| `harmonixSurface` | `#0F2451` | Tarjetas |
| `harmonixAccent` | `#4A9EFF` | Texto destacado, iconos interactivos |
| `harmonixPrimaryContainer` | `#13316B` | Contenedores |
| `harmonixFavorite` | `#FF6B9D` | Icono favoritos (rosa) |
| `harmonixRecent` | `#FFA94D` | Icono "recién añadidas" (naranja) |

## Licencia

MIT.
