-- =============================================================================================
-- 08 · SEED (datos iniciales de catálogos)  ·  EVENTCORE
-- =============================================================================================
-- Llena los catálogos que nacen vacíos: roles, estados y los catálogos de agenda (Dias, Horarios).
-- Los IDs van A MANO (no IDENTITY) para que sean estables y citables desde el backend.
-- Requiere: 02_lookups.sql (las tablas deben existir)  ·  Correr con Alt+X (⌥X).
-- =============================================================================================

USE Cumbre;

INSERT INTO dbo.Roles (RolID, Codigo, Descripcion) VALUES
    (1, N'ADMIN',     N'Administrador de la plataforma'),
    (2, N'ASISTENTE', N'Asistente / participante');

-- EsTerminal = 1 marca estados "cerrados" (sin más transiciones).
INSERT INTO dbo.EstadosEvento (EstadoEventoID, Codigo, Descripcion, EsTerminal) VALUES
    (1, N'BORRADOR',   N'Evento en edición, no visible',  0),
    (2, N'PUBLICADO',  N'Evento abierto a inscripciones', 0),
    (3, N'CANCELADO',  N'Evento cancelado',               1),
    (4, N'FINALIZADO', N'Evento ya realizado',            1);

INSERT INTO dbo.EstadosInscripcion (EstadoInscripcionID, Codigo, Descripcion, EsTerminal) VALUES
    (1, N'PENDIENTE',  N'Registrada, pendiente de aprobación/pago', 0),
    (2, N'APROBADA',   N'Aprobada por el administrador',            0),
    (3, N'RECHAZADA',  N'Rechazada por el administrador',           1),
    (4, N'CONFIRMADA', N'Confirmada (pago verificado)',             0),
    (5, N'CANCELADA',  N'Cancelada por el asistente',               1);

INSERT INTO dbo.EstadosPago (EstadoPagoID, Codigo, Descripcion, EsTerminal) VALUES
    (1, N'PENDIENTE',  N'Pago registrado, pendiente de verificación', 0),
    (2, N'CONFIRMADO', N'Pago confirmado',                            1),
    (3, N'RECHAZADO',  N'Pago rechazado',                             1);

INSERT INTO dbo.EstadosSolicitud (EstadoSolicitudID, Codigo, Descripcion, EsTerminal) VALUES
    (1, N'PENDIENTE', N'Solicitud de cancelación en revisión', 0),
    (2, N'PROCESADA', N'Reembolso procesado',                  1),
    (3, N'RECHAZADA', N'Solicitud rechazada',                  1);

-- Días de la semana (ISO-8601: 1 = Lunes … 7 = Domingo). El frontend solo referencia el DiaID.
INSERT INTO dbo.Dias (DiaID, Nombre, Abreviatura) VALUES
    (1, N'Lunes',     N'LUN'),
    (2, N'Martes',    N'MAR'),
    (3, N'Miércoles', N'MIE'),
    (4, N'Jueves',    N'JUE'),
    (5, N'Viernes',   N'VIE'),
    (6, N'Sábado',    N'SAB'),
    (7, N'Domingo',   N'DOM');

-- Bloques de horario predefinidos. Ajustá/agregá filas según los horarios reales del evento.
INSERT INTO dbo.Horarios (HorarioID, HoraInicio, HoraFin, Etiqueta) VALUES
    (1, '08:00', '09:30', N'08:00-09:30'),
    (2, '09:30', '11:00', N'09:30-11:00'),
    (3, '11:00', '12:30', N'11:00-12:30'),
    (4, '13:30', '15:00', N'13:30-15:00'),
    (5, '15:00', '16:30', N'15:00-16:30'),
    (6, '16:30', '18:00', N'16:30-18:00');

-- Verificación rápida del seed:
SELECT 'Roles' AS Catalogo, COUNT(*) AS Filas FROM dbo.Roles
UNION ALL SELECT 'EstadosEvento',      COUNT(*) FROM dbo.EstadosEvento
UNION ALL SELECT 'EstadosInscripcion', COUNT(*) FROM dbo.EstadosInscripcion
UNION ALL SELECT 'EstadosPago',        COUNT(*) FROM dbo.EstadosPago
UNION ALL SELECT 'EstadosSolicitud',   COUNT(*) FROM dbo.EstadosSolicitud
UNION ALL SELECT 'Dias',               COUNT(*) FROM dbo.Dias
UNION ALL SELECT 'Horarios',           COUNT(*) FROM dbo.Horarios;
