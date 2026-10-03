-- Esquema inicial de gestion-de-turnos.
-- Fuente de verdad: docs/tecnologias/esquema-bd.md.
-- ddl-auto queda en 'validate': este archivo define el esquema, no Hibernate.

-- =============================================================================
-- 1. Extensiones
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;    -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS btree_gist;  -- permite mezclar = y && en una constraint de exclusión

-- =============================================================================
-- 2.1 platform_settings
-- =============================================================================

CREATE TABLE platform_settings (
  id                            smallint     PRIMARY KEY DEFAULT 1,
  min_booking_notice_minutes    integer      NOT NULL DEFAULT 30,
  cancellation_deadline_hours   integer      NOT NULL DEFAULT 3,
  max_reschedule_count          integer      NOT NULL DEFAULT 2,
  max_booking_advance_days      integer      NOT NULL DEFAULT 90, -- override posible via variable de entorno al arrancar
  updated_at                    timestamptz  NOT NULL DEFAULT now(),

  CONSTRAINT chk_settings_singleton    CHECK (id = 1),
  CONSTRAINT chk_settings_notice       CHECK (min_booking_notice_minutes > 0),
  CONSTRAINT chk_settings_deadline     CHECK (cancellation_deadline_hours > 0),
  CONSTRAINT chk_settings_reschedule   CHECK (max_reschedule_count >= 0),
  CONSTRAINT chk_settings_advance      CHECK (max_booking_advance_days > 0)
);

-- La fila única se inserta en la misma migración: la aplicación nunca la crea.
INSERT INTO platform_settings (id) VALUES (1);

-- =============================================================================
-- 2.2 company
-- =============================================================================

CREATE TABLE company (
  id             uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  name           varchar(120) NOT NULL,
  slug           varchar(60)  NOT NULL UNIQUE,
  description    text,
  address        varchar(200),
  phone          varchar(30),
  contact_email  varchar(150),
  category       varchar(30)  NOT NULL,
  timezone       varchar(50)  NOT NULL DEFAULT 'America/Argentina/Cordoba',
  logo_url       varchar(500),
  primary_color  varchar(7),
  status         varchar(20)  NOT NULL DEFAULT 'ACTIVE',
  created_at     timestamptz  NOT NULL DEFAULT now(),
  updated_at     timestamptz  NOT NULL DEFAULT now(),

  CONSTRAINT chk_company_status   CHECK (status IN ('ACTIVE', 'INACTIVE')),
  CONSTRAINT chk_company_category CHECK (category IN (
      'BARBERSHOP', 'HAIR_SALON', 'BEAUTY_CENTER', 'MEDICAL_OFFICE', 'DENTAL_OFFICE',
      'VETERINARY', 'NUTRITION', 'PSYCHOLOGY', 'PHYSIOTHERAPY', 'TATTOO_STUDIO', 'SPA', 'OTHER')),
  CONSTRAINT chk_company_slug     CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  CONSTRAINT chk_company_color    CHECK (primary_color IS NULL OR primary_color ~ '^#[0-9A-Fa-f]{6}$')
);

CREATE INDEX idx_company_status_created ON company (status, created_at);

-- =============================================================================
-- 2.3 app_user
-- =============================================================================

CREATE TABLE app_user (
  id          uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name  varchar(80)  NOT NULL,
  last_name   varchar(80)  NOT NULL,
  email       varchar(150) NOT NULL,
  phone       varchar(30)  NOT NULL,
  password    varchar(100),
  role        varchar(20)  NOT NULL,
  company_id  uuid         REFERENCES company (id),
  status      varchar(25)  NOT NULL,
  created_at  timestamptz  NOT NULL DEFAULT now(),
  updated_at  timestamptz  NOT NULL DEFAULT now(),

  CONSTRAINT chk_user_role   CHECK (role IN ('SUPERADMIN', 'COMPANY_ADMIN', 'CLIENT')),
  CONSTRAINT chk_user_status CHECK (status IN ('PENDING_ACTIVATION', 'ACTIVE', 'INACTIVE')),

  -- companyId es nulo si y solo si el rol es SUPERADMIN
  CONSTRAINT chk_user_company_by_role CHECK (
      (role =  'SUPERADMIN' AND company_id IS NULL) OR
      (role <> 'SUPERADMIN' AND company_id IS NOT NULL)),

  -- necesario para que appointment pueda referenciar (client_id, company_id)
  CONSTRAINT uq_user_id_company UNIQUE (id, company_id)
);

-- Unicidad de email: por empresa para admins y clientes...
CREATE UNIQUE INDEX ux_user_email_per_company
  ON app_user (company_id, lower(email))
  WHERE company_id IS NOT NULL;

-- ...y global entre superadmins. Hacen falta los dos índices porque en PostgreSQL
-- los NULL se consideran distintos entre sí: un UNIQUE (company_id, email) dejaría
-- pasar dos superadmins con el mismo email.
CREATE UNIQUE INDEX ux_superadmin_email
  ON app_user (lower(email))
  WHERE company_id IS NULL;

-- =============================================================================
-- 2.4 user_token
-- =============================================================================

CREATE TABLE user_token (
  id          uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid         NOT NULL REFERENCES app_user (id) ON DELETE CASCADE,
  token_hash  varchar(100) NOT NULL UNIQUE,
  type        varchar(20)  NOT NULL,
  expires_at  timestamptz  NOT NULL,
  used_at     timestamptz,
  created_at  timestamptz  NOT NULL DEFAULT now(),

  CONSTRAINT chk_token_type CHECK (type IN ('ACTIVATION', 'PASSWORD_RESET'))
);

-- Busca el token vigente de un usuario al reenviar un link o al validar uno entrante.
CREATE INDEX idx_user_token_lookup ON user_token (user_id, type) WHERE used_at IS NULL;

-- =============================================================================
-- 2.5 service
-- =============================================================================

CREATE TABLE service (
  id                uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid          NOT NULL REFERENCES company (id),
  name              varchar(120)  NOT NULL,
  description       text,
  price             numeric(10,2) NOT NULL,
  duration_minutes  integer       NOT NULL,
  status            varchar(20)   NOT NULL DEFAULT 'ACTIVE',
  created_at        timestamptz   NOT NULL DEFAULT now(),
  updated_at        timestamptz   NOT NULL DEFAULT now(),

  CONSTRAINT chk_service_status   CHECK (status IN ('ACTIVE', 'INACTIVE')),
  CONSTRAINT chk_service_price    CHECK (price >= 0),
  CONSTRAINT chk_service_duration CHECK (duration_minutes > 0),

  CONSTRAINT uq_service_id_company UNIQUE (id, company_id)
);

CREATE INDEX idx_service_company_status ON service (company_id, status);

-- =============================================================================
-- 2.6 business_hours
-- =============================================================================

CREATE TABLE business_hours (
  id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid        NOT NULL REFERENCES company (id) ON DELETE CASCADE,
  day_of_week       varchar(10) NOT NULL,
  start_time        time        NOT NULL,
  end_time          time        NOT NULL,
  interval_minutes  integer     NOT NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT chk_hours_day      CHECK (day_of_week IN (
      'MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY')),
  CONSTRAINT chk_hours_range    CHECK (end_time > start_time),
  CONSTRAINT chk_hours_interval CHECK (interval_minutes > 0),

  -- Se admiten varias franjas por día (jornada partida), pero nunca superpuestas.
  -- El offset sobre una fecha fija convierte `time` en `timestamp` para poder usar tsrange;
  -- PostgreSQL no trae un tipo de rango nativo para `time`.
  CONSTRAINT excl_hours_overlap EXCLUDE USING gist (
      company_id  WITH =,
      day_of_week WITH =,
      tsrange(DATE '2000-01-01' + start_time, DATE '2000-01-01' + end_time) WITH &&
  )
);

CREATE INDEX idx_hours_company_day ON business_hours (company_id, day_of_week);

-- =============================================================================
-- 2.7 schedule_exception
-- =============================================================================

CREATE TABLE schedule_exception (
  id                uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid         NOT NULL REFERENCES company (id) ON DELETE CASCADE,
  exception_date    date         NOT NULL,
  is_closed         boolean      NOT NULL DEFAULT true,
  start_time        time,
  end_time          time,
  interval_minutes  integer,
  reason            varchar(200),
  created_at        timestamptz  NOT NULL DEFAULT now(),
  updated_at        timestamptz  NOT NULL DEFAULT now(),

  CONSTRAINT uq_exception_company_date UNIQUE (company_id, exception_date),

  -- Cerrado: sin horario. Abierto con horario especial: los tres campos cargados.
  CONSTRAINT chk_exception_shape CHECK (
      (is_closed = true  AND start_time IS NULL AND end_time IS NULL AND interval_minutes IS NULL) OR
      (is_closed = false AND start_time IS NOT NULL AND end_time IS NOT NULL AND interval_minutes IS NOT NULL)),
  CONSTRAINT chk_exception_range    CHECK (end_time IS NULL OR end_time > start_time),
  CONSTRAINT chk_exception_interval CHECK (interval_minutes IS NULL OR interval_minutes > 0)
);

CREATE INDEX idx_exception_company_date ON schedule_exception (company_id, exception_date);

-- =============================================================================
-- 2.8 appointment
-- =============================================================================

CREATE TABLE appointment (
  id                         uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id                 uuid          NOT NULL REFERENCES company (id),
  service_id                 uuid          NOT NULL,
  client_id                  uuid,
  manual_client_name         varchar(160),
  manual_client_phone        varchar(30),
  price_snapshot             numeric(10,2) NOT NULL,
  duration_minutes_snapshot  integer       NOT NULL,
  start_date_time            timestamptz   NOT NULL,
  end_date_time              timestamptz   NOT NULL,
  previous_start_date_time   timestamptz,
  reschedule_count           integer       NOT NULL DEFAULT 0,
  origin                     varchar(10)   NOT NULL,
  status                     varchar(20)   NOT NULL DEFAULT 'PENDING',
  cancelled_by               varchar(10),
  cancellation_reason        text,
  cancelled_at               timestamptz,
  created_at                 timestamptz   NOT NULL DEFAULT now(),
  updated_at                 timestamptz   NOT NULL DEFAULT now(),

  -- FK compuestas: garantizan a nivel motor que el servicio y el cliente
  -- pertenecen a la MISMA empresa que el turno.
  CONSTRAINT fk_appointment_service FOREIGN KEY (service_id, company_id)
      REFERENCES service (id, company_id),
  CONSTRAINT fk_appointment_client  FOREIGN KEY (client_id, company_id)
      REFERENCES app_user (id, company_id),

  CONSTRAINT chk_appointment_status   CHECK (status IN ('PENDING', 'COMPLETED', 'CANCELLED')),
  CONSTRAINT chk_appointment_origin   CHECK (origin IN ('ONLINE', 'MANUAL')),
  CONSTRAINT chk_appointment_price    CHECK (price_snapshot >= 0),
  CONSTRAINT chk_appointment_duration CHECK (duration_minutes_snapshot > 0),
  CONSTRAINT chk_appointment_end      CHECK (end_date_time > start_date_time),

  -- O el turno está vinculado a una cuenta, o trae datos de contacto sueltos.
  -- Nunca ninguna de las dos: sería un turno que nadie puede contactar.
  CONSTRAINT chk_appointment_client_identity CHECK (
      (client_id IS NOT NULL AND manual_client_name IS NULL     AND manual_client_phone IS NULL) OR
      (client_id IS NULL     AND manual_client_name IS NOT NULL AND manual_client_phone IS NOT NULL)),

  CONSTRAINT chk_appointment_cancellation CHECK (
      (status =  'CANCELLED' AND cancelled_by IS NOT NULL AND cancelled_at IS NOT NULL) OR
      (status <> 'CANCELLED' AND cancelled_by IS NULL     AND cancelled_at IS NULL)),
  CONSTRAINT chk_appointment_cancelled_by CHECK (
      cancelled_by IS NULL OR cancelled_by IN ('CLIENT', 'COMPANY')),

  CONSTRAINT chk_appointment_reschedule CHECK (
      (reschedule_count = 0 AND previous_start_date_time IS NULL) OR
      (reschedule_count > 0 AND previous_start_date_time IS NOT NULL)),

  -- Red de seguridad del motor contra la doble reserva: dentro de una misma empresa,
  -- dos turnos no cancelados no pueden solapar sus rangos horarios.
  CONSTRAINT excl_appointment_overlap EXCLUDE USING gist (
      company_id WITH =,
      tstzrange(start_date_time, end_date_time) WITH &&
  ) WHERE (status <> 'CANCELLED')
);

-- Turnero del admin, filtrable por estado
CREATE INDEX idx_appointment_company_status_start
  ON appointment (company_id, status, start_date_time);

-- "Mis turnos" del cliente
CREATE INDEX idx_appointment_client_start
  ON appointment (client_id, start_date_time)
  WHERE client_id IS NOT NULL;

-- UC9: contar turnos futuros de un servicio antes de desactivarlo
CREATE INDEX idx_appointment_service_pending
  ON appointment (service_id)
  WHERE status = 'PENDING';

-- Job de cierre automático: sin este índice recorre la tabla completa en cada corrida
CREATE INDEX idx_appointment_pending_start
  ON appointment (start_date_time)
  WHERE status = 'PENDING';

-- =============================================================================
-- 2.9 notification
-- =============================================================================

CREATE TABLE notification (
  id              uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id  uuid         REFERENCES appointment (id) ON DELETE SET NULL,
  user_id         uuid         REFERENCES app_user (id) ON DELETE SET NULL,
  recipient_phone varchar(30)  NOT NULL,
  event_type      varchar(30)  NOT NULL,
  channel         varchar(15)  NOT NULL,
  status          varchar(15)  NOT NULL DEFAULT 'PENDING',
  attempt_count   integer      NOT NULL DEFAULT 0,
  sent_at         timestamptz,
  error_message   text,
  created_at      timestamptz  NOT NULL DEFAULT now(),

  CONSTRAINT chk_notification_event CHECK (event_type IN (
      'BOOKING_CONFIRMED', 'APPOINTMENT_CANCELLED', 'APPOINTMENT_RESCHEDULED',
      'ACCOUNT_ACTIVATION', 'PASSWORD_RESET')),
  CONSTRAINT chk_notification_channel CHECK (channel IN ('WHATSAPP', 'EMAIL')),
  CONSTRAINT chk_notification_status  CHECK (status IN ('PENDING', 'SENT', 'FAILED')),
  CONSTRAINT chk_notification_sent    CHECK (
      (status = 'SENT' AND sent_at IS NOT NULL) OR (status <> 'SENT' AND sent_at IS NULL))
);

-- Cola de pendientes y reintentos
CREATE INDEX idx_notification_pending ON notification (created_at)
  WHERE status IN ('PENDING', 'FAILED');

CREATE INDEX idx_notification_appointment ON notification (appointment_id);
