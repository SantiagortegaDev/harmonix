# Harmonix

Reproductor de música para Android construido en Flutter/Dart, inspirado en InnerTune, con Material Design 3 estricto (Material You dynamic theming, NavigationBar, Cards, FilledButton, Slider MD3), animaciones fluidas (hero animations entre mini-player y reproductor completo, fade/slide entre pantallas, staggered animations en listas, wavy slider animado) y música extraída de YouTube Music vía **yt-dlp** (a través de `youtube_explode_dart`, un port en Dart de la lógica de extracción de YouTube).

> Sin inicio de sesión. Sin cuenta de Google/YouTube. Toda la app funciona de forma anónima.

## Características principales

- **Búsqueda** de canciones, videos, álbumes y playlists (vía yt-dlp → YouTube Music).
- **Reproducción sin anuncios** y **en segundo plano** (notificación multimedia) con `just_audio` + `audio_service`.
- **Inicio de playback ultra-rápido**: la URL directa de audio se resuelve on-demand en el dispositivo (sin instancia externa) y se cachea 5 min en memoria. La siguiente pista se precarga en background para skips cuasi-instantáneos.
- **Quick picks / recomendaciones** personalizadas en la pantalla de inicio.
- **Caché inteligente** de audio en disco (Hive) — igual que Spotify, las últimas canciones reproducidas no se vuelven a descargar; límite configurable.
- **Descargas** para escuchar sin conexión, con sección dedicada.
- **Letras sincronizadas** con opción de traducción.
- **Skip silence**, **normalización de audio** y **ajuste de tempo/pitch** en tiempo real.
- **Soporte Android Auto**.
- **Discord Rich Presence** (opcional).
- **Modo debug/desarrollador** con pantalla de logs en tiempo real (paquete `logger`): requests a YouTube, errores de streaming, errores de caché, etc.

## Stack

| Capa | Tecnología |
|------|-----------|
| UI / Estado | Flutter 3.19+, Material 3, `provider` |
| Audio | `just_audio`, `audio_service`, `audio_session` |
| API | `youtube_explode_dart` (port Dart de yt-dlp) + `dio` |
| Caché local | `hive` + `path_provider` |
| Descargas | `flutter_downloader` + `permission_handler` |
| Letras | scraping HTML + sincronización LRC |
| Logs | `logger` |
| Animaciones | `shimmer`, hero animations, `AnimatedList`, `CustomPainter` (wavy slider) |

## Motor de audio

Harmonix usa **yt-dlp** (vía `youtube_explode_dart`) para resolver la URL directa de audio de YouTube **en el dispositivo**, sin depender de instancias externas inestables como Piped.

Estrategia de velocidad:

1. **Resolución on-demand**: la URL se resuelve solo cuando el usuario le da play (no se pre-resuelven todas las pistas de la cola).
2. **Caché en memoria (5 min)**: replay de la misma canción es instantáneo.
3. **Prefetch de la siguiente pista**: mientras suena la actual, se resuelve en background la URL de la siguiente → skip cuasi-inmediato.
4. **Caché en disco (LRU, configurable)**: las últimas canciones reproducidas se guardan localmente para offline parcial.

Sin configuración: el motor funciona out-of-the-box desde que se instala la app.

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
│   └── services/         # YtDlp, AudioPlayer, Cache, Downloads, Lyrics, Settings
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
