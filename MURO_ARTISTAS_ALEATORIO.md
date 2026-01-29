# 🎲 Muro de Artistas - Sistema Aleatorio

## 📋 Resumen

El Muro de Artistas ahora muestra **20 posts aleatorios** en lugar de un timeline cronológico. Esto permite a los usuarios descubrir contenido variado cada vez que actualizan.

---

## 🎯 Características

### ✅ Lo Nuevo:
- **20 posts aleatorios** por carga
- **Pull-to-refresh** para ver posts diferentes
- **Descubrimiento de contenido** en lugar de timeline
- **Sin scroll infinito** (mantiene la experiencia simple)

### ❌ Lo que NO es:
- No es cronológico (no verás los posts más recientes primero)
- No es paginado (no hay "cargar más")
- No es personalizado (todos ven posts aleatorios)

---

## 🔧 Cómo Funciona

### 1. **Función SQL en Supabase**

Se creó una función `get_random_posts()` que:
```sql
SELECT * FROM posts
INNER JOIN profiles ON posts.author_id = profiles.id
ORDER BY RANDOM()
LIMIT 20;
```

**Ventajas:**
- ✅ Aleatorización en el servidor (más eficiente)
- ✅ Incluye JOIN con profiles automáticamente
- ✅ Rápido y optimizado

### 2. **Carga en la App**

```dart
_loadPosts() {
  // Intenta usar la función RPC
  final posts = await _supabase.rpc('get_random_posts', params: {'limit_count': 20});
  
  // Si falla, usa query normal (fallback)
  // ...
}
```

**Fallback:**
Si la función RPC no existe, usa la query normal con `ORDER BY created_at DESC LIMIT 20`

### 3. **Actualización Manual**

El usuario puede:
- **Deslizar hacia abajo** (pull-to-refresh) para ver otros 20 posts
- **Esperar 30 segundos** (auto-refresh automático)

---

## 📊 Comparación

### Antes (Timeline Cronológico):
```
Post 1 - Hace 5 min
Post 2 - Hace 10 min
Post 3 - Hace 15 min
...
Post 10 - Hace 2 horas
```
- Solo 10 posts
- Siempre los mismos (los más recientes)
- Aburrido si no hay posts nuevos

### Ahora (Aleatorio):
```
Post A - Hace 3 días
Post B - Hace 1 hora
Post C - Hace 2 semanas
...
Post T - Hace 5 min
```
- 20 posts
- Diferentes cada vez que actualizas
- Descubres contenido antiguo interesante

---

## 🚀 Instalación

### Paso 1: Crear la Función en Supabase

1. Ve a: https://supabase.com/dashboard/project/lwrlunndqzepwsbmofki/sql/new
2. Copia y pega el contenido de `SETUP_RANDOM_POSTS_FUNCTION.sql`
3. Click en **"Run"**
4. Verifica que diga: "Success. No rows returned"

### Paso 2: Reiniciar la App

```cmd
q
flutter run
```

### Paso 3: Probar

1. Abre la app
2. Ve al Dashboard (pantalla principal)
3. Desliza hacia abajo para refrescar
4. Verás 20 posts diferentes cada vez

---

## 🎨 Experiencia de Usuario

### Flujo Normal:
1. Usuario abre la app
2. Ve 20 posts aleatorios
3. Lee algunos posts
4. Desliza hacia abajo para refrescar
5. Ve otros 20 posts diferentes
6. Repite

### Ventajas:
- ✅ Siempre hay contenido "nuevo" para ver
- ✅ Descubres posts antiguos interesantes
- ✅ No te pierdes contenido por no estar conectado
- ✅ Más engagement (la gente refresca más)

### Desventajas:
- ❌ No ves los posts más recientes primero
- ❌ Puedes ver el mismo post dos veces (raro pero posible)
- ❌ No hay forma de buscar un post específico

---

## 🔮 Futuras Mejoras

### Opción 1: Tabs de Filtrado
```
[Aleatorio] [Recientes] [Populares]
```
- Aleatorio: Como está ahora
- Recientes: Timeline cronológico
- Populares: Por likes/comentarios

### Opción 2: Personalización
```sql
-- Posts de tus conexiones + aleatorios
SELECT * FROM posts
WHERE author_id IN (SELECT connected_id FROM connections WHERE user_id = $1)
   OR author_id IN (SELECT random_users())
ORDER BY RANDOM()
LIMIT 20;
```

### Opción 3: Algoritmo Inteligente
- Posts de tu ubicación
- Posts de tu género musical
- Posts de artistas verificados
- Posts con más engagement

---

## 🐛 Troubleshooting

### Problema: "Error cargando posts"
**Solución:** La función RPC no existe. Ejecuta `SETUP_RANDOM_POSTS_FUNCTION.sql` en Supabase.

### Problema: "Siempre veo los mismos posts"
**Solución:** 
1. Verifica que la función use `ORDER BY RANDOM()`
2. Asegúrate de que hay más de 20 posts en la base de datos
3. Prueba hacer pull-to-refresh

### Problema: "No veo ningún post"
**Solución:**
1. Verifica que existan posts en la tabla `posts`
2. Verifica que los autores tengan perfiles en `profiles`
3. Revisa los logs: `flutter logs`

---

## 📝 Notas Técnicas

### Performance:
- `ORDER BY RANDOM()` es eficiente para <10,000 posts
- Para más posts, considera usar `TABLESAMPLE` o un índice aleatorio

### Caché:
- Los posts NO se cachean
- Cada refresh hace una nueva query
- Esto asegura variedad pero consume más datos

### Límites:
- Máximo 20 posts por carga
- No hay límite de refreshes
- Auto-refresh cada 30 segundos (puede desactivarse)

---

## ✅ Checklist de Implementación

- [x] Crear función SQL `get_random_posts()`
- [x] Modificar `_loadPosts()` para usar RPC
- [x] Modificar `_loadStreamData()` para usar RPC
- [x] Agregar fallback si RPC falla
- [x] Cambiar límite de 10 a 20 posts
- [x] Documentar el sistema
- [ ] Ejecutar SQL en Supabase
- [ ] Probar en la app
- [ ] Verificar que funciona el refresh

---

## 🎯 Resultado Final

El usuario ahora tiene una experiencia de "descubrimiento" donde cada vez que abre la app o refresca, ve contenido diferente e interesante, similar a TikTok For You o Instagram Explore.
