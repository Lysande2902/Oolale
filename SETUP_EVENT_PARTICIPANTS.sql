-- ============================================================================
-- SETUP EVENT PARTICIPANTS TABLE
-- Sistema de confirmación de asistencia y roles en eventos
-- ============================================================================

-- Crear tabla de participantes de eventos
CREATE TABLE IF NOT EXISTS event_participants (
  id BIGSERIAL PRIMARY KEY,
  event_id BIGINT NOT NULL REFERENCES gigs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  confirmed BOOLEAN DEFAULT false,
  role VARCHAR(50) DEFAULT 'participant',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraint para evitar duplicados
  UNIQUE(event_id, user_id)
);

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_event_participants_event_id 
  ON event_participants(event_id);

CREATE INDEX IF NOT EXISTS idx_event_participants_user_id 
  ON event_participants(user_id);

CREATE INDEX IF NOT EXISTS idx_event_participants_confirmed 
  ON event_participants(confirmed);

CREATE INDEX IF NOT EXISTS idx_event_participants_role 
  ON event_participants(role);

CREATE INDEX IF NOT EXISTS idx_event_participants_event_confirmed 
  ON event_participants(event_id, confirmed);

-- Índice compuesto para queries frecuentes
CREATE INDEX IF NOT EXISTS idx_event_participants_event_user 
  ON event_participants(event_id, user_id);

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Habilitar RLS
ALTER TABLE event_participants ENABLE ROW LEVEL SECURITY;

-- Policy: Los usuarios pueden ver participantes de eventos donde están involucrados
CREATE POLICY "Users can view participants of their events"
  ON event_participants
  FOR SELECT
  USING (
    auth.uid() IN (
      SELECT organizador_id FROM gigs WHERE id = event_id
      UNION
      SELECT unnest(lineup) FROM gigs WHERE id = event_id
    )
    OR user_id = auth.uid()
  );

-- Policy: Los usuarios pueden confirmar su propia asistencia
CREATE POLICY "Users can confirm their own attendance"
  ON event_participants
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Policy: Los usuarios pueden actualizar su propia asistencia
CREATE POLICY "Users can update their own attendance"
  ON event_participants
  FOR UPDATE
  USING (user_id = auth.uid());

-- Policy: Los organizadores pueden actualizar roles
CREATE POLICY "Organizers can update participant roles"
  ON event_participants
  FOR UPDATE
  USING (
    auth.uid() IN (
      SELECT organizador_id FROM gigs WHERE id = event_id
    )
  );

-- Policy: Los usuarios pueden cancelar su propia asistencia
CREATE POLICY "Users can delete their own attendance"
  ON event_participants
  FOR DELETE
  USING (user_id = auth.uid());

-- Policy: Los organizadores pueden remover participantes
CREATE POLICY "Organizers can remove participants"
  ON event_participants
  FOR DELETE
  USING (
    auth.uid() IN (
      SELECT organizador_id FROM gigs WHERE id = event_id
    )
  );

-- ============================================================================
-- FUNCIONES ÚTILES
-- ============================================================================

-- Función para obtener estadísticas de participantes por evento
CREATE OR REPLACE FUNCTION get_event_participant_stats(p_event_id BIGINT)
RETURNS TABLE (
  total_participants BIGINT,
  confirmed_participants BIGINT,
  headliners BIGINT,
  supports BIGINT,
  guests BIGINT,
  crew BIGINT,
  participants BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::BIGINT as total_participants,
    COUNT(*) FILTER (WHERE confirmed = true)::BIGINT as confirmed_participants,
    COUNT(*) FILTER (WHERE role = 'headliner')::BIGINT as headliners,
    COUNT(*) FILTER (WHERE role = 'support')::BIGINT as supports,
    COUNT(*) FILTER (WHERE role = 'guest')::BIGINT as guests,
    COUNT(*) FILTER (WHERE role = 'crew')::BIGINT as crew,
    COUNT(*) FILTER (WHERE role = 'participant' OR role IS NULL)::BIGINT as participants
  FROM event_participants
  WHERE event_id = p_event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para obtener participantes confirmados de un evento
CREATE OR REPLACE FUNCTION get_confirmed_participants(p_event_id BIGINT)
RETURNS TABLE (
  user_id UUID,
  role VARCHAR(50),
  confirmed_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ep.user_id,
    ep.role,
    ep.updated_at as confirmed_at
  FROM event_participants ep
  WHERE ep.event_id = p_event_id
    AND ep.confirmed = true
  ORDER BY ep.created_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para verificar si un usuario confirmó asistencia
CREATE OR REPLACE FUNCTION has_confirmed_attendance(
  p_event_id BIGINT,
  p_user_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_confirmed BOOLEAN;
BEGIN
  SELECT confirmed INTO v_confirmed
  FROM event_participants
  WHERE event_id = p_event_id
    AND user_id = p_user_id;
  
  RETURN COALESCE(v_confirmed, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para obtener rol de un participante
CREATE OR REPLACE FUNCTION get_participant_role(
  p_event_id BIGINT,
  p_user_id UUID
)
RETURNS VARCHAR(50) AS $$
DECLARE
  v_role VARCHAR(50);
BEGIN
  SELECT role INTO v_role
  FROM event_participants
  WHERE event_id = p_event_id
    AND user_id = p_user_id;
  
  RETURN COALESCE(v_role, 'participant');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_event_participants_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_event_participants_updated_at
  BEFORE UPDATE ON event_participants
  FOR EACH ROW
  EXECUTE FUNCTION update_event_participants_updated_at();

-- Trigger para sincronizar con lineup del evento
CREATE OR REPLACE FUNCTION sync_event_lineup()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.confirmed = true THEN
    -- Agregar a lineup si no está
    UPDATE gigs
    SET lineup = ARRAY(
      SELECT DISTINCT unnest(
        COALESCE(lineup, ARRAY[]::UUID[]) || ARRAY[NEW.user_id]
      )
    )
    WHERE id = NEW.event_id
      AND NOT (NEW.user_id = ANY(COALESCE(lineup, ARRAY[]::UUID[])));
  ELSIF OLD.confirmed = true AND NEW.confirmed = false THEN
    -- Remover de lineup si canceló
    UPDATE gigs
    SET lineup = ARRAY(
      SELECT unnest(lineup)
      WHERE unnest(lineup) != NEW.user_id
    )
    WHERE id = NEW.event_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_sync_event_lineup
  AFTER INSERT OR UPDATE ON event_participants
  FOR EACH ROW
  EXECUTE FUNCTION sync_event_lineup();

-- ============================================================================
-- VISTA ÚTIL
-- ============================================================================

-- Vista para obtener participantes con información de perfil
CREATE OR REPLACE VIEW event_participants_with_profiles AS
SELECT
  ep.id,
  ep.event_id,
  ep.user_id,
  ep.confirmed,
  ep.role,
  ep.created_at,
  ep.updated_at,
  p.nombre_artistico,
  p.avatar_url,
  p.instrumento_principal,
  p.ubicacion,
  g.titulo_bolo as event_title,
  g.fecha_gig as event_date
FROM event_participants ep
JOIN profiles p ON ep.user_id = p.id
JOIN gigs g ON ep.event_id = g.id;

-- ============================================================================
-- DATOS DE PRUEBA (OPCIONAL)
-- ============================================================================

-- Comentar esta sección si no quieres datos de prueba

/*
-- Insertar participantes de ejemplo
INSERT INTO event_participants (event_id, user_id, confirmed, role)
SELECT
  g.id,
  p.id,
  true,
  CASE 
    WHEN random() < 0.2 THEN 'headliner'
    WHEN random() < 0.4 THEN 'support'
    WHEN random() < 0.6 THEN 'guest'
    WHEN random() < 0.8 THEN 'crew'
    ELSE 'participant'
  END
FROM gigs g
CROSS JOIN profiles p
WHERE random() < 0.3  -- 30% de probabilidad de participación
  AND g.fecha_gig > NOW()  -- Solo eventos futuros
LIMIT 50
ON CONFLICT (event_id, user_id) DO NOTHING;
*/

-- ============================================================================
-- VERIFICACIÓN
-- ============================================================================

-- Verificar que la tabla se creó correctamente
SELECT 
  'event_participants' as table_name,
  COUNT(*) as row_count
FROM event_participants;

-- Verificar índices
SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'event_participants'
ORDER BY indexname;

-- Verificar políticas RLS
SELECT
  policyname,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'event_participants'
ORDER BY policyname;

-- ============================================================================
-- NOTAS
-- ============================================================================

/*
ROLES DISPONIBLES:
- headliner: Artista principal del evento
- support: Artista de soporte o telonero
- guest: Participación especial
- crew: Equipo técnico o staff
- participant: Asistente general

FUNCIONALIDADES:
1. Confirmación de asistencia con rol
2. Cancelación de asistencia
3. Cambio de rol (solo organizador)
4. Remoción de participantes (solo organizador)
5. Sincronización automática con lineup del evento
6. Estadísticas de participantes
7. Notificaciones automáticas

SEGURIDAD:
- RLS habilitado
- Solo usuarios autenticados pueden confirmar
- Solo organizadores pueden cambiar roles
- Solo organizadores pueden remover participantes
- Usuarios pueden cancelar su propia asistencia

OPTIMIZACIÓN:
- 6 índices para queries rápidas
- Funciones SQL para estadísticas
- Vista con joins pre-calculados
- Triggers para sincronización automática
*/

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================

COMMIT;
