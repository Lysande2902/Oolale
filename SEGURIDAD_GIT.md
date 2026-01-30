# 🔒 Seguridad en Git - Archivos Sensibles

## ⚠️ Problema Resuelto

GitHub bloqueó el push porque detectó credenciales de Firebase en el repositorio:
- **Archivo**: `oolale-firebase-adminsdk-fbsvc-9c0e0e533e.json`
- **Tipo**: Google Cloud Service Account Credentials
- **Riesgo**: Cualquiera con acceso al repo podría usar estas credenciales

## ✅ Solución Aplicada

### 1. Eliminado del Historial de Git
```bash
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch oolale-firebase-adminsdk-fbsvc-9c0e0e533e.json" \
  --prune-empty --tag-name-filter cat -- --all
```

### 2. Agregado al .gitignore
```
# Firebase Service Account Keys (NEVER commit these!)
*-firebase-adminsdk-*.json
oolale-firebase-adminsdk-*.json
google-services.json
GoogleService-Info.plist
```

### 3. Push Forzado
```bash
git push --force
```

---

## 🚫 Archivos que NUNCA Debes Subir a Git

### Credenciales de Firebase:
- ❌ `*-firebase-adminsdk-*.json` (Service Account Keys)
- ❌ `google-services.json` (Android)
- ❌ `GoogleService-Info.plist` (iOS)

### Variables de Entorno:
- ❌ `.env`
- ❌ `.env.local`
- ❌ `.env.production`

### Claves API:
- ❌ Cualquier archivo con API keys
- ❌ Archivos de configuración con passwords
- ❌ Tokens de acceso

### Otros:
- ❌ Certificados SSL privados
- ❌ Archivos de base de datos con datos reales
- ❌ Backups con información sensible

---

## ✅ Cómo Manejar Archivos Sensibles

### Opción 1: Variables de Entorno
```dart
// En lugar de:
final apiKey = "AIzaSyC..."; // ❌ Hardcoded

// Usa:
final apiKey = Platform.environment['FIREBASE_API_KEY']; // ✅
```

### Opción 2: Archivo .env (No Commiteado)
```
# .env (agregado a .gitignore)
FIREBASE_API_KEY=AIzaSyC...
SUPABASE_URL=https://...
SUPABASE_ANON_KEY=eyJ...
```

### Opción 3: Archivo de Ejemplo
```
# Commitea un archivo de ejemplo:
.env.example

# Con valores de placeholder:
FIREBASE_API_KEY=your_api_key_here
SUPABASE_URL=your_supabase_url_here
```

---

## 🔍 Cómo Verificar Antes de Commitear

### 1. Revisar qué vas a commitear:
```bash
git status
git diff
```

### 2. Buscar archivos sensibles:
```bash
# Buscar archivos JSON con "private_key"
git diff | grep -i "private_key"

# Buscar archivos con credenciales
git diff | grep -i "password\|secret\|key"
```

### 3. Usar herramientas de escaneo:
```bash
# Instalar git-secrets
git secrets --install
git secrets --register-aws
```

---

## 🛡️ Qué Hacer Si Ya Subiste Credenciales

### 1. **INMEDIATAMENTE**: Revocar las credenciales
- Ve a Firebase Console
- Elimina el Service Account comprometido
- Genera nuevas credenciales

### 2. Eliminar del historial de Git
```bash
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch ARCHIVO_SENSIBLE" \
  --prune-empty --tag-name-filter cat -- --all
```

### 3. Agregar al .gitignore
```bash
echo "ARCHIVO_SENSIBLE" >> .gitignore
git add .gitignore
git commit -m "Add sensitive file to gitignore"
```

### 4. Push forzado
```bash
git push --force
```

### 5. Notificar al equipo
- Avisar que se hizo un push forzado
- Pedir que hagan `git pull --rebase`

---

## 📋 Checklist de Seguridad

Antes de cada commit, verifica:

- [ ] No hay archivos `*-adminsdk-*.json`
- [ ] No hay archivos `.env` con valores reales
- [ ] No hay API keys hardcodeadas en el código
- [ ] No hay passwords en archivos de configuración
- [ ] El `.gitignore` está actualizado
- [ ] Revisaste `git diff` antes de commitear

---

## 🔗 Referencias

- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- [Firebase Security Best Practices](https://firebase.google.com/docs/projects/api-keys)
- [Git Filter-Branch](https://git-scm.com/docs/git-filter-branch)
- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/) (alternativa más rápida)

---

## ⚡ Resumen

**Lo que pasó:**
- Subiste credenciales de Firebase a GitHub
- GitHub lo detectó y bloqueó el push

**Lo que hicimos:**
- Eliminamos el archivo del historial de Git
- Lo agregamos al .gitignore
- Hicimos push forzado

**Lo que debes hacer:**
- **IMPORTANTE**: Ve a Firebase Console y regenera las credenciales
- Guarda el nuevo archivo localmente (NO lo subas a Git)
- Usa variables de entorno para valores sensibles

**Nunca más:**
- ❌ No subas archivos `*-adminsdk-*.json`
- ❌ No subas archivos `.env` con valores reales
- ❌ No hardcodees API keys en el código
- ✅ Siempre revisa `git diff` antes de commitear
