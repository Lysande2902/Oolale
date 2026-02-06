-- ============================================
-- UPGRADE EVENTS SYSTEM - ÓOLALE MOBILE
-- Mejoras para el sistema de eventos completo
-- Fecha: 30 de Enero, 2026
-- ============================================

-- ============================================
-- 1. CREAR TABLA DE INVITACIONES (si no existe)
-- ============================================

CREATE TABLE IF NOT EXISTS event_invitations (
  id BIGSERIAL PRIMARY KEY,
  event_id BIGINT NOT NULL REFERENCES gigs(id) ON DELETE CASCADE,
  musician_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  organizer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(event_id, musician_id)
);

-- Índices para invitaciones
CREATE INDEX IF NOT EXISTS idx_event_invitations_musician ON event_invitations(musician_id, status);
CREATE INDEX IF NOT EXISTS idx_event_invitations_event ON event_invitations(event_id);
CREATE INDEX IF NOT EXISTS idx_event_invitations_organizer ON event_invitations(organizer_id);
CREATE INDEX IF NOT EXISTS idx_event_invitations_created ON event_invitations(created_at DESC);

-- ============================================
-- 2. ÍNDICES PARA MEJORAR RENDIMIENTO
-- ============================================

-- Índices en tabla gigs
CREATE INDEX IF NOT EXISTS idx_gigs_fecha ON gigs(fecha_gig);
CREATE INDEX IF NOT EXISTS idx_gigs_organizador ON gigs(organizador_id);
CREATE INDEX IF NOT EXISTS idx_gigs_tipo ON gigs(tipo);
CREATE INDEX IF NOT EXISTS idx_gigs_estatus ON gigs(estatus_bolo);
CREATE INDEX IF NOT EXISTS idx_gigs_fecha_tipo ON gigs(fecha_gig, tipo);

-- Índice para búsqueda de eventos por lineup (usando GIN para arrays)
CREATE INDEX IF NOT EXISTS idx_gigs_lineup ON gigs USING GIN(lineup);

-- ============================================
-- 3. FUNCIONES ÚTILES
-- ============================================

-- Función para obtener eventos próximos de un usuario
CREATE OR REPLACE FUNCTION get_user_upcoming_events(user_id UUID)
RETURNS TABLE (
  id BIGINT,
  titulo_bolo TEXT,
  fecha_gig TIMESTAMPTZ,
  lugar_nombre TEXT,
  tipo TEXT,
  organizador_id UUID,
  estatus_bolo TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    g.id,
    g.titulo_bolo,
    g.fecha_gig,
    g.lugar_nombre,
    g.tipo,
    g.organizador_id,
    g.estatus_bolo
  FROM gigs g
  WHERE 
    (g.organizador_id = user_id OR user_id = ANY(g.lineup))
    AND g.fecha_gig >= NOW()
    AND g.estatus_bolo != 'cancelado'
  ORDER BY g.fecha_gig ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para obtener historial de eventos de un usuario
CREATE OR REPLACE FUNCTION get_user_event_history(user_id UUID)
RETURNS TABLE (
  id BIGINT,
  titulo_bolo TEXT,
  fecha_gig TIMESTAMPTZ,
  lugar_nombre TEXT,
  tipo TEXT,
  organizador_id UUID,
  estatus_bolo TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    g.id,
    g.titulo_bolo,
    g.fecha_gig,
    g.lugar_nombre,
    g.tipo,
    g.organizador_id,
    g.estatus_bolo
  FROM gigs g
  WHERE 
    (g.organizador_id = user_id OR user_id = ANY(g.lineup))
    AND g.fecha_gig < NOW()
  ORDER BY g.fecha_gig DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para contar invitaciones pendientes
CREATE OR REPLACE FUNCTION count_pending_invitations(user_id UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::INTEGER
    FROM event_invitations
    WHERE musician_id = user_id AND status = 'pending'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para obtener eventos dentro de 24 horas
CREATE OR REPLACE FUNCTION get_events_within_24h(user_id UUID)
RETURNS TABLE (
  id BIGINT,
  titulo_bolo TEXT,
  fecha_gig TIMESTAMPTZ,
  lugar_nombre TEXT,
  tipo TEXT,
  organizador_id UUID
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    g.id,
    g.titulo_bolo,
    g.fecha_gig,
    g.lugar_nombre,
    g.tipo,
    g.organizador_id
  FROM gigs g
  WHERE 
    (g.organizador_id = user_id OR user_id = ANY(g.lineup))
    AND g.fecha_gig >= NOW()
    AND g.fecha_gig <= NOW() + INTERVAL '24 hours'
    AND g.estatus_bolo != 'cancelado'
  ORDER BY g.fecha_gig ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 4. TRIGGERS
-- ============================================

-- Trigger para actualizar updated_at en invitaciones
CREATE OR REPLACE FUNCTION update_invitation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_invitation_timestamp ON event_invitations;
CREATE TRIGGER trigger_update_invitation_timestamp
  BEFORE UPDATE ON event_invitations
  FOR EACH ROW
  EXECUTE FUNCTION update_invitation_timestamp();

-- ============================================
-- 5. RLS POLICIES PARA INVITACIONES
-- ============================================

-- Habilitar RLS
ALTER TABLE event_invitations ENABLE ROW LEVEL SECURITY;

-- Policy: Los usuarios pueden ver sus propias invitaciones
DROP POLICY IF EXISTS "Users can view their invitations" ON event_invitations;
CREATE POLICY "Users can view their invitations"
  ON event_invitations FOR SELECT
  USING (
    auth.uid() = musician_id 
    OR auth.uid() = organizer_id
  );

-- Policy: Los organizadores pueden crear invitaciones
DROP POLICY IF EXISTS "Organizers can create invitations" ON event_invitations;
CREATE POLICY "Organizers can create invitations"
  ON event_invitations FOR INSERT
  WITH CHECK (auth.uid() = organizer_id);

-- Policy: Los músicos pueden actualizar sus invitaciones (aceptar/rechazar)
DROP POLICY IF EXISTS "Musicians can update their invitations" ON event_invitations;
CREATE POLICY "Musicians can update their invitations"
  ON event_invitations FOR UPDATE
  USING (auth.uid() = musician_id);

-- Policy: Los organizadores pueden eliminar invitaciones
DROP POLICY IF EXISTS "Organizers can delete invitations" ON event_invitations;
CREATE POLICY "Organizers can delete invitations"
  ON event_invitations FOR DELETE
  USING (auth.uid() = organizer_id);

-- ============================================
-- 6. AGREGAR COLUMNAS FALTANTES (si no existen)
-- ============================================

-- Agregar columna de tipo si no existe
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'gigs' AND column_name = 'tipo'
  ) THEN
    ALTER TABLE gigs ADD COLUMN tipo TEXT DEFAULT 'otro' 
      CHECK (tipo IN ('concierto', 'ensayo', 'jam', 'otro'));
  END IF;
END $$;

-- Agregar columna de estatus si no existe
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'gigs' AND column_name = 'estatus_bolo'
  ) THEN
    ALTER TABLE gigs ADD COLUMN estatus_bolo TEXT DEFAULT 'programado'
      CHECK (estatus_bolo IN ('programado', 'confirmado', 'completado', 'cancelado'));
  END IF;
END $$;

-- Agregar columna de lineup si no existe (array de UUIDs)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'gigs' AND column_name = 'lineup'
  ) THEN
    ALTER TABLE gigs ADD COLUMN lineup UUID[] DEFAULT '{}';
  END IF;
END $$;

-- ============================================
-- 7. VISTA PARA ESTADÍSTICAS DE EVENTOS
-- ============================================

CREATE OR REPLACE VIEW event_statistics AS
SELECT 
  p.id as user_id,
  p.nombre_artistico,
  COUNT(DISTINCT CASE WHEN g.organizador_id = p.id THEN g.id END) as events_organized,
  COUNT(DISTINCT CASE WHEN p.id = ANY(g.lineup) THEN g.id END) as events_participated,
  COUNT(DISTINCT CASE WHEN g.fecha_gig >= NOW() THEN g.id END) as upcoming_events,
  COUNT(DISTINCT CASE WHEN g.fecha_gig < NOW() THEN g.id END) as past_events
FROM profiles p
LEFT JOIN gigs g ON (g.organizador_id = p.id OR p.id = ANY(g.lineup))
GROUP BY p.id, p.nombre_artistico;

-- ============================================
-- 8. FUNCIÓN PARA NOTIFICAR EVENTOS PRÓXIMOS
-- ============================================

CREATE OR REPLACE FUNCTION notify_upcoming_events()
RETURNS void AS $$
DECLARE
  event_record RECORD;
  participant_id UUID;
BEGIN
  -- Buscar eventos que empiezan en 24 horas
  FOR event_record IN 
    SELECT id, titulo_bolo, fecha_gig, organizador_id, lineup
    FROM gigs
    WHERE fecha_gig >= NOW() + INTERVAL '23 hours'
      AND fecha_gig <= NOW() + INTERVAL '25 hours'
      AND estatus_bolo != 'cancelado'
  LOOP
    -- Notificar al organizador
    INSERT INTO notifications (user_id, tipo, titulo, mensaje, leido, data)
    VALUES (
      event_record.organizador_id,
      'event_reminder',
      'Evento próximo',
      'Tu evento "' || event_record.titulo_bolo || '" es en 24 horas',
      false,
      jsonb_build_object('event_id', event_record.id)
    );
    
    -- Notificar a cada participante
    IF event_record.lineup IS NOT NULL THEN
      FOREACH participant_id IN ARRAY event_record.lineup
      LOOP
        INSERT INTO notifications (user_id, tipo, titulo, mensaje, leido, data)
        VALUES (
          participant_id,
          'event_reminder',
          'Evento próximo',
          'El evento "' || event_record.titulo_bolo || '" es en 24 horas',
          false,
          jsonb_build_object('event_id', event_record.id)
        );
      END LOOP;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- VERIFICACIÓN FINAL
-- ============================================

-- Verificar que todo se creó correctamente
DO $$
BEGIN
  RAISE NOTICE '✅ Sistema de eventos actualizado correctamente';
  RAISE NOTICE '📊 Tablas: event_invitations';
  RAISE NOTICE '🔍 Índices: 9 índices creados';
  RAISE NOTICE '⚡ Funciones: 5 funciones creadas';
  RAISE NOTICE '🔒 RLS: 4 policies configuradas';
  RAISE NOTICE '📈 Vistas: event_statistics';
END $$;
