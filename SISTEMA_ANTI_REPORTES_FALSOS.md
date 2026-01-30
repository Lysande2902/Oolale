# 🛡️ Sistema Anti-Reportes Falsos - Documentación Completa

## 📋 Estado General

✅ **Sistema de Protección:** IMPLEMENTADO  
✅ **Límites Automáticos:** Activos  
✅ **Puntuación de Confiabilidad:** Funcional  
✅ **Suspensiones Automáticas:** Configuradas

---

## 🎯 Objetivo

Proteger la plataforma contra usuarios que abusan del sistema de reportes enviando reportes falsos o malintencionados.

---

## ✅ Funcionalidades Implementadas

### **1. Límites Automáticos por Tiempo** ✅

| Período | Límite | Descripción |
|---------|--------|-------------|
| **Día** | 5 reportes | Máximo 5 reportes en 24 horas |
| **Semana** | 15 reportes | Máximo 15 reportes en 7 días |
| **Mes** | 30 reportes | Máximo 30 reportes en 30 días |

**Comportamiento:**
- Si alcanzas el límite, no puedes reportar hasta que pase el período
- Los contadores se resetean automáticamente
- Mensaje claro al usuario: "Has alcanzado el límite de reportes por [período]"

### **2. Puntuación de Confiabilidad (0-100)** ✅

**Sistema de Puntos:**
- **Inicio:** Todos empiezan con 100 puntos
- **Reporte Válido:** +5 puntos (máx 100)
- **Reporte Falso:** -20 puntos (mín 0)
- **Umbral Mínimo:** 30 puntos para poder reportar

**Ejemplo:**
```
Usuario nuevo: 100 puntos ✅ Puede reportar
Envía 3 reportes falsos: 100 - (20×3) = 40 puntos ✅ Puede reportar
Envía 1 reporte falso más: 40 - 20 = 20 puntos ❌ NO puede reportar
```

### **3. Sistema de Suspensiones Automáticas** ✅

**Umbral:** 3 reportes falsos = suspensión automática

**Duración de Suspensiones:**
| Suspensión | Duración | Condición |
|------------|----------|-----------|
| **Primera** | 7 días | 3 reportes falsos |
| **Segunda** | 30 días | 6 reportes falsos |
| **Tercera** | 1 año | 9+ reportes falsos |

**Durante la Suspensión:**
- No puede enviar reportes
- Mensaje: "Tu cuenta está suspendida por reportes falsos hasta [fecha]"
- La suspensión expira automáticamente

### **4. Historial Completo por Usuario** ✅

**Tabla: `historial_reportes_usuario`**

Cada usuario tiene un registro con:
- Total de reportes enviados
- Reportes válidos
- Reportes falsos
- Reportes pendientes
- Puntuación de confiabilidad
- Estado de suspensión
- Contadores por período (día/semana/mes)
- Advertencias recibidas

### **5. Validación Antes de Reportar** ✅

**Función: `puede_reportar(usuario_id)`**

Verifica automáticamente:
1. ¿Está suspendido?
2. ¿Tiene puntuación suficiente?
3. ¿Ha alcanzado límite diario?
4. ¿Ha alcanzado límite semanal?
5. ¿Ha alcanzado límite mensual?

**Respuesta:**
```json
{
  "puede": true/false,
  "razon": "Mensaje explicativo",
  "reportes_disponibles_hoy": 3
}
```

---

## 🗄️ Estructura de Base de Datos

### **Tabla: `historial_reportes_usuario`**

```sql
CREATE TABLE historial_reportes_usuario (
    id SERIAL PRIMARY KEY,
    usuario_id UUID NOT NULL,
    
    -- Contadores
    total_reportes_enviados INTEGER DEFAULT 0,
    reportes_validos INTEGER DEFAULT 0,
    reportes_falsos INTEGER DEFAULT 0,
    reportes_pendientes INTEGER DEFAULT 0,
    
    -- Puntuación (0-100)
    puntuacion_confiabilidad INTEGER DEFAULT 100,
    
    -- Estado
    puede_reportar BOOLEAN DEFAULT TRUE,
    razon_suspension TEXT,
    fecha_suspension TIMESTAMP,
    fecha_fin_suspension TIMESTAMP,
    
    -- Límites temporales
    reportes_hoy INTEGER DEFAULT 0,
    reportes_esta_semana INTEGER DEFAULT 0,
    reportes_este_mes INTEGER DEFAULT 0,
    ultima_fecha_reporte TIMESTAMP,
    
    -- Advertencias
    advertencias_recibidas INTEGER DEFAULT 0,
    ultima_advertencia TIMESTAMP
);
```

### **Tabla: `reglas_reportes`**

```sql
CREATE TABLE reglas_reportes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    
    -- Límites
    max_reportes_por_dia INTEGER DEFAULT 5,
    max_reportes_por_semana INTEGER DEFAULT 15,
    max_reportes_por_mes INTEGER DEFAULT 30,
    
    -- Umbrales
    umbral_reportes_falsos INTEGER DEFAULT 3,
    dias_suspension_primera_vez INTEGER DEFAULT 7,
    dias_suspension_segunda_vez INTEGER DEFAULT 30,
    dias_suspension_tercera_vez INTEGER DEFAULT 365,
    
    -- Puntuación
    puntos_perdidos_por_falso INTEGER DEFAULT 20,
    puntos_ganados_por_valido INTEGER DEFAULT 5,
    puntuacion_minima_para_reportar INTEGER DEFAULT 30
);
```

### **Campos Agregados a `reportes`**

```sql
ALTER TABLE reportes ADD COLUMN:
- es_falso BOOLEAN DEFAULT FALSE
- verificado_por UUID (admin que verificó)
- fecha_verificacion TIMESTAMP
- notas_verificacion TEXT
```

---

## 🔧 Funciones SQL Implementadas

### **1. `puede_reportar(usuario_id)`**
Verifica si un usuario puede enviar reportes.

**Uso:**
```sql
SELECT * FROM puede_reportar('user-uuid-here');
```

**Retorna:**
```
puede | razon | reportes_disponibles_hoy
------|-------|-------------------------
true  | "Puedes reportar" | 3
```

### **2. `registrar_reporte(usuario_id)`**
Registra un nuevo reporte en el historial del usuario.

**Uso:**
```sql
SELECT registrar_reporte('user-uuid-here');
```

**Efecto:**
- Incrementa contadores
- Actualiza fecha del último reporte
- Crea historial si no existe

### **3. `marcar_reporte_falso(reporte_id, admin_id, notas)`**
Marca un reporte como falso (solo admins).

**Uso:**
```sql
SELECT marcar_reporte_falso(123, 'admin-uuid', 'Reporte sin fundamento');
```

**Efecto:**
- Marca reporte como falso
- Reduce puntuación del reportante (-20)
- Incrementa contador de reportes falsos
- Suspende si alcanza umbral (3 falsos)

### **4. `marcar_reporte_valido(reporte_id, admin_id, notas)`**
Marca un reporte como válido (solo admins).

**Uso:**
```sql
SELECT marcar_reporte_valido(123, 'admin-uuid', 'Reporte confirmado');
```

**Efecto:**
- Marca reporte como válido
- Aumenta puntuación del reportante (+5)
- Incrementa contador de reportes válidos

### **5. `resetear_contadores_semanales()`**
Resetea contadores semanales (ejecutar cada lunes).

### **6. `resetear_contadores_mensuales()`**
Resetea contadores mensuales (ejecutar el día 1).

---

## 🎯 Flujo Completo

### **Flujo del Usuario:**

```
1. Usuario presiona "Reportar"
   ↓
2. App llama: puede_reportar(user_id)
   ↓
3a. SI puede reportar:
    - Muestra pantalla de reporte
    - Usuario completa formulario
    - Envía reporte
    - App llama: registrar_reporte(user_id)
    - Muestra: "Reporte enviado. Reportes disponibles hoy: X"
   
3b. NO puede reportar:
    - Muestra diálogo con razón
    - Ejemplos:
      * "Has alcanzado el límite de reportes por hoy (5)"
      * "Tu cuenta está suspendida hasta 05/02/2026"
      * "Tu puntuación de confiabilidad es muy baja"
```

### **Flujo del Administrador:**

```
1. Admin revisa reporte en panel
   ↓
2. Investiga el caso
   ↓
3a. Reporte es VÁLIDO:
    - Llama: marcar_reporte_valido(reporte_id, admin_id, notas)
    - Usuario gana +5 puntos
    - Toma acción contra el reportado
   
3b. Reporte es FALSO:
    - Llama: marcar_reporte_falso(reporte_id, admin_id, notas)
    - Usuario pierde -20 puntos
    - Si tiene 3+ falsos: suspensión automática
    - Usuario recibe notificación (futuro)
```

---

## 📊 Ejemplos de Casos

### **Caso 1: Usuario Normal**
```
Estado inicial:
- Puntuación: 100
- Reportes hoy: 0/5
- Puede reportar: ✅

Envía 2 reportes válidos:
- Puntuación: 110 → 100 (máx)
- Reportes hoy: 2/5
- Puede reportar: ✅
```

### **Caso 2: Usuario Abusivo**
```
Estado inicial:
- Puntuación: 100
- Reportes falsos: 0

Envía 3 reportes falsos:
- Puntuación: 100 - 60 = 40
- Reportes falsos: 3
- Estado: SUSPENDIDO 7 días ❌

Después de 7 días:
- Suspensión expira automáticamente
- Puede reportar: ✅ (pero con puntuación baja)
```

### **Caso 3: Usuario Spam**
```
Intenta enviar 10 reportes en un día:

Reportes 1-5: ✅ Enviados
Reporte 6: ❌ "Has alcanzado el límite de reportes por hoy (5)"
Reportes 7-10: ❌ Bloqueados

Al día siguiente:
- Contador se resetea
- Puede enviar 5 más
```

---

## 🚀 Instalación

### **Paso 1: Ejecutar SQL**
```bash
1. Ve a Supabase SQL Editor
2. Copia el contenido de SETUP_ANTI_REPORTES_FALSOS.sql
3. Ejecuta el script
4. Verifica que las tablas se crearon
```

### **Paso 2: Configurar Cron Jobs (Opcional)**

**Resetear contadores semanales (cada lunes):**
```sql
-- Crear Edge Function o usar pg_cron
SELECT cron.schedule(
    'resetear-contadores-semanales',
    '0 0 * * 1', -- Cada lunes a medianoche
    $$ SELECT resetear_contadores_semanales(); $$
);
```

**Resetear contadores mensuales (día 1):**
```sql
SELECT cron.schedule(
    'resetear-contadores-mensuales',
    '0 0 1 * *', -- Día 1 de cada mes
    $$ SELECT resetear_contadores_mensuales(); $$
);
```

---

## ⚙️ Configuración de Reglas

Para cambiar los límites, edita la tabla `reglas_reportes`:

```sql
UPDATE reglas_reportes SET
    max_reportes_por_dia = 10,           -- Cambiar límite diario
    max_reportes_por_semana = 30,        -- Cambiar límite semanal
    umbral_reportes_falsos = 5,          -- Cambiar umbral de suspensión
    puntos_perdidos_por_falso = 30       -- Cambiar penalización
WHERE activo = TRUE;
```

---

## 🧪 Pruebas

### **Test 1: Límite Diario**
```
1. Envía 5 reportes en un día
✅ Todos se envían

2. Intenta enviar el 6to
❌ Mensaje: "Has alcanzado el límite de reportes por hoy (5)"

3. Espera al día siguiente
✅ Puede enviar 5 más
```

### **Test 2: Puntuación**
```
1. Usuario con 100 puntos
2. Admin marca 3 reportes como falsos
3. Puntuación: 100 - 60 = 40
✅ Puede reportar (> 30)

4. Admin marca 1 más como falso
5. Puntuación: 40 - 20 = 20
❌ No puede reportar (< 30)
```

### **Test 3: Suspensión**
```
1. Usuario envía 3 reportes falsos
2. Sistema detecta automáticamente
✅ Usuario suspendido 7 días

3. Intenta reportar
❌ "Tu cuenta está suspendida hasta [fecha]"

4. Después de 7 días
✅ Suspensión expira, puede reportar
```

---

## 📈 Métricas y Monitoreo

### **Consultas Útiles:**

**Usuarios con más reportes falsos:**
```sql
SELECT 
    p.nombre_artistico,
    h.reportes_falsos,
    h.puntuacion_confiabilidad,
    h.puede_reportar
FROM historial_reportes_usuario h
JOIN profiles p ON h.usuario_id = p.id
ORDER BY h.reportes_falsos DESC
LIMIT 10;
```

**Usuarios suspendidos:**
```sql
SELECT 
    p.nombre_artistico,
    h.razon_suspension,
    h.fecha_fin_suspension
FROM historial_reportes_usuario h
JOIN profiles p ON h.usuario_id = p.id
WHERE h.puede_reportar = FALSE
AND h.fecha_fin_suspension > CURRENT_TIMESTAMP;
```

**Estadísticas generales:**
```sql
SELECT 
    COUNT(*) as total_usuarios,
    AVG(puntuacion_confiabilidad) as puntuacion_promedio,
    SUM(reportes_falsos) as total_reportes_falsos,
    COUNT(CASE WHEN puede_reportar = FALSE THEN 1 END) as usuarios_suspendidos
FROM historial_reportes_usuario;
```

---

## ⚠️ Consideraciones Importantes

### **Privacidad:**
- El historial es privado para cada usuario
- Solo admins ven quién envió reportes falsos
- Los reportados NO saben quién los reportó

### **Apelaciones:**
- Usuario suspendido puede contactar soporte
- Admin puede revisar caso y levantar suspensión manualmente
- Futuro: Sistema de apelaciones automático

### **Falsos Positivos:**
- Admin debe verificar cuidadosamente antes de marcar como falso
- Un reporte "no procedente" ≠ reporte falso
- Solo marcar como falso si hay mala intención clara

---

## 🎉 Conclusión

El sistema anti-reportes falsos está **100% funcional** y protege la plataforma contra abusos.

**Características principales:**
- ✅ Límites automáticos por tiempo
- ✅ Puntuación de confiabilidad
- ✅ Suspensiones automáticas
- ✅ Historial completo
- ✅ Validación antes de reportar
- ✅ Fácil de configurar

**Recomendación:** Sistema listo para producción. Monitorear métricas regularmente.

---

**Fecha de Implementación:** 29 de Enero, 2026  
**Estado:** ✅ COMPLETADO  
**Listo para:** Producción

