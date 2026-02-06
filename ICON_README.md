# ÓOLALE - Icono de la Aplicación

## Icono Actual

El icono de la aplicación está ubicado en:
- `assets/images/logo.png` - Logo principal usado en la app
- `android/app/src/main/res/mipmap-*/ic_launcher.png` - Iconos de Android en diferentes resoluciones

## Diseño del Icono

El icono presenta:
- **Nota musical estilizada** combinada con símbolos de conexión/red
- **Color primario**: Amarillo-verde neón (#D4FF00)
- **Fondo**: Oscuro con gradiente sutil
- **Estilo**: Minimalista, moderno y premium
- **Elementos**: Ondas de sonido y formas geométricas abstractas

## Generar Iconos para Diferentes Plataformas

### Opción 1: Usar flutter_launcher_icons (Recomendado)

1. Agregar al `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.2

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/logo.png"
  adaptive_icon_background: "#0A0E27"
  adaptive_icon_foreground: "assets/images/logo.png"
```

2. Ejecutar:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

### Opción 2: Manual

Tamaños requeridos para Android:
- mipmap-mdpi: 48x48 px
- mipmap-hdpi: 72x72 px
- mipmap-xhdpi: 96x96 px
- mipmap-xxhdpi: 144x144 px
- mipmap-xxxhdpi: 192x192 px

Tamaños requeridos para iOS:
- 20x20, 29x29, 40x40, 60x60, 76x76, 83.5x83.5, 1024x1024

## Actualizar el Icono

Si necesitas actualizar el icono:

1. Reemplaza `assets/images/logo.png` con el nuevo diseño
2. Ejecuta `flutter pub run flutter_launcher_icons` (si usas la opción 1)
3. O copia manualmente a todas las carpetas mipmap

## Notas

- El icono debe tener fondo transparente o sólido según la plataforma
- Para Android, considera crear un adaptive icon
- Para iOS, asegúrate de que el icono no tenga esquinas redondeadas (iOS las agrega automáticamente)
