# Estructura de la Tabla `profiles`

## Columnas de la tabla `profiles` en Supabase

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id` | UUID | ID del usuario (FK a auth.users) |
| `email` | TEXT | Email del usuario |
| `nombre_artistico` | TEXT | Nombre artístico del usuario |
| `bio` | TEXT | Biografía del usuario |
| `foto_perfil` | TEXT | URL de la foto de perfil |
| `banner` | TEXT | URL del banner |
| `ubicacion` | TEXT | Ubicación del usuario |
| `pais` | TEXT | País del usuario |
| `created_at` | TIMESTAMPTZ | Fecha de creación |
| `updated_at` | TIMESTAMPTZ | Fecha de última actualización |
| `open_to_work` | BOOLEAN | Si está disponible para trabajar |
| `ranking_tipo` | TEXT | Tipo de ranking (regular, premium, etc) |
| `ranking_fecha_expiracion` | TIMESTAMPTZ | Fecha de expiración del ranking |
| `rating_promedio` | NUMERIC | Calificación promedio |
| `total_calificaciones` | INTEGER | Total de calificaciones recibidas |
| `total_referencias` | INTEGER | Total de referencias |
| `perfil_completo` | BOOLEAN | Si el perfil está completo |
| `verificado` | BOOLEAN | Si el usuario está verificado |
| `instrumento_principal` | TEXT | Instrumento principal que toca |
| `rol_principal` | TEXT | Rol principal (músico, banda, etc) |
| `avatar_url` | TEXT | URL del avatar (alternativa a foto_perfil) |
| `bio_rider` | TEXT | Bio rider técnico |
| `ubicacion_base` | TEXT | Ubicación base del usuario |

## Notas Importantes

- **NO existe la columna `nombre_completo`** - solo `nombre_artistico`
- Hay dos columnas para foto de perfil: `foto_perfil` y `avatar_url`
- Hay dos columnas para ubicación: `ubicacion` y `ubicacion_base`
- La tabla usa `nombre_artistico` como nombre principal del usuario

## Trigger Automático

Cuando un usuario se registra en `auth.users`, se debe crear automáticamente un registro en `profiles` con:
- `id` = user.id
- `email` = user.email  
- `nombre_artistico` = user.raw_user_meta_data->>'full_name' o email sin dominio

Ver: `FIX_PROFILE_CREATION.sql` para el trigger completo.
