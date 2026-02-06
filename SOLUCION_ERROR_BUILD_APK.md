# 🔧 SOLUCIÓN: Error al Compilar APK Release

**Fecha:** 6 de Febrero, 2026  
**Error:** Android resource compilation failed - ic_launcher.png files corrupted

---

## 🐛 PROBLEMA

Al ejecutar `flutter build apk --release`, aparece el siguiente error:

```
ERROR: C:\Users\acer\3Warner\oolale_mobile\android\app\src\main\res\mipmap-hdpi\ic_launcher.png: AAPT: error: file failed to compile.
ERROR: C:\Users\acer\3Warner\oolale_mobile\android\app\src\main\res\mipmap-mdpi\ic_launcher.png: AAPT: error: file failed to compile.
ERROR: C:\Users\acer\3Warner\oolale_mobile\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png: AAPT: error: file failed to compile.
ERROR: C:\Users\acer\3Warner\oolale_mobile\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png: AAPT: error: file failed to compile.
ERROR: C:\Users\acer\3Warner\oolale_mobile\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png: AAPT: error: file failed to compile.
```

**Causa:** Los archivos de iconos de la aplicación están corruptos o tienen un formato inválido.

---

## ✅ SOLUCIÓN 1: Eliminar Iconos Corruptos (Rápida)

Esta solución elimina los iconos corruptos y deja que Flutter use los iconos por defecto.

### **Pasos:**

1. **Eliminar los archivos corruptos:**

```cmd
cd android\app\src\main\res
del mipmap-hdpi\ic_launcher.png
del mipmap-mdpi\ic_launcher.png
del mipmap-xhdpi\ic_launcher.png
del mipmap-xxhdpi\ic_launcher.png
del mipmap-xxxhdpi\ic_launcher.png
```

2. **Limpiar el build:**

```cmd
cd ..\..\..\..
flutter clean
```

3. **Volver a compilar:**

```cmd
flutter build apk --release
```

---

## ✅ SOLUCIÓN 2: Usar flutter_launcher_icons (Recomendada)

Esta solución genera iconos válidos automáticamente desde una imagen.

### **Pasos:**

1. **Agregar dependencia en `pubspec.yaml`:**

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  flutter_launcher_icons: ^0.13.1  # Agregar esta línea
```

2. **Configurar los iconos en `pubspec.yaml`:**

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/logo.png"  # Tu logo existente
  adaptive_icon_background: "#009688"   # Color teal de Óolale
  adaptive_icon_foreground: "assets/images/logo.png"
```

3. **Instalar dependencias:**

```cmd
flutter pub get
```

4. **Generar los iconos:**

```cmd
flutter pub run flutter_launcher_icons
```

5. **Compilar:**

```cmd
flutter build apk --release
```

---

## ✅ SOLUCIÓN 3: Copiar Iconos por Defecto de Flutter

Si no tienes un logo personalizado, puedes copiar los iconos por defecto de Flutter.

### **Pasos:**

1. **Crear un nuevo proyecto temporal:**

```cmd
cd ..
flutter create temp_project
```

2. **Copiar los iconos del proyecto temporal:**

```cmd
xcopy temp_project\android\app\src\main\res\mipmap-* oolale_mobile\android\app\src\main\res\ /E /Y
```

3. **Eliminar el proyecto temporal:**

```cmd
rmdir /s /q temp_project
```

4. **Volver a compilar:**

```cmd
cd oolale_mobile
flutter clean
flutter build apk --release
```

---

## 🎯 SOLUCIÓN RECOMENDADA

**Para desarrollo rápido:** Usa **Solución 1** (eliminar iconos corruptos)

**Para producción:** Usa **Solución 2** (flutter_launcher_icons) con tu logo personalizado

---

## 📝 NOTAS ADICIONALES

### **Warnings de Java 8:**

Los warnings sobre Java 8 son normales y no afectan la compilación:

```
warning: [options] source value 8 is obsolete and will be removed in a future release
```

Estos se pueden ignorar por ahora. Para eliminarlos, actualiza el `build.gradle` a Java 11+.

### **Dependencias Desactualizadas:**

El mensaje "33 packages have newer versions" es informativo. Puedes actualizar después:

```cmd
flutter pub upgrade
```

---

## ✅ VERIFICACIÓN

Después de aplicar la solución, verifica que el APK se compile correctamente:

```cmd
flutter build apk --release
```

**Resultado esperado:**
```
✓ Built build\app\outputs\flutter-apk\app-release.apk (XX.X MB).
```

El APK estará en: `build\app\outputs\flutter-apk\app-release.apk`

---

## 🚀 SIGUIENTE PASO

Una vez compilado el APK, puedes:

1. **Instalarlo en un dispositivo físico:**
   ```cmd
   adb install build\app\outputs\flutter-apk\app-release.apk
   ```

2. **Compartirlo para testing:**
   - El archivo está en `build\app\outputs\flutter-apk\app-release.apk`
   - Puedes enviarlo por email, Drive, etc.

3. **Subirlo a Google Play Console** (cuando esté listo para producción)

---

**Última actualización:** 6 de Febrero, 2026
