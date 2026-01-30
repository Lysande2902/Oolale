# 📚 Guía de Scripts SQL

## ⚠️ Importante: Tipos de Scripts

### 🟢 Scripts EJECUTABLES (Puedes ejecutar directamente)

Estos scripts están listos para ejecutarse sin modificaciones:

1. **`FIX_REPORTES_REFERENCIAS.sql`** ✅
   - Agrega columna `estatus` a reportes
   - Hace columnas antiguas NULLABLE
   - Verifica estructura

2. **`FIX_REFERENCIAS_TABLE.sql`** ✅
   - Agrega columnas nuevas a referencias
   - Crea índices
   - Idempotente (se puede ejecutar múltiples veces)

3. **`VERIFICAR_ESTRUCTURA_REFERENCIAS.sql`** ✅ (NUEVO)
   - Muestra estructura de tablas
   - Verifica índices y políticas RLS
   - Cuenta registros
   - NO modifica nada, solo consulta

4. **`CHECK_PROFILES_STRUCTURE.sql`** ✅
   - Verifica estructura de tabla profiles

5. **`SETUP_*.sql`** ✅
   - Scripts de configuración inicial
   - Crean tablas, funciones, triggers

### 🔴 Scripts de EJEMPLO (NO ejecutar directamente)

Estos archivos contienen ejemplos con placeholders que debes reemplazar:

1. **`QUERIES_PRACTICAS.sql`** ❌
   - Conti