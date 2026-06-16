-- =============================================================================================
-- 08 · SEED (datos iniciales de catálogos)  ·  TRACKFLOW-HUB
-- =============================================================================================
-- Llena los catálogos que nacen vacíos: roles, género, estados y zonas geográficas.
-- Los IDs van A MANO (no IDENTITY) para que sean estables y citables desde el backend.
-- Requiere: 02_lookups.sql (las tablas deben existir)  ·  Correr con Alt+X (⌥X).
-- =============================================================================================

USE TrackFlow;

INSERT INTO dbo.Roles (RolID, Codigo, Descripcion) VALUES
    (1, N'CLIENTE',  N'Cliente que contrata envíos y transporte'),
    (2, N'OPERADOR', N'Operador logístico (servicios de envío)'),
    (3, N'EMPRESA',  N'Empresa de transporte (rutas y flota)'),
    (4, N'ADMIN',    N'Administrador de la plataforma');

INSERT INTO dbo.Generos (GeneroID, Codigo, Descripcion) VALUES
    (1, N'MASCULINO', N'Masculino'),
    (2, N'FEMENINO',  N'Femenino'),
    (3, N'OTRO',      N'Otro / prefiere no decir');

-- EsTerminal = 1 marca estados "cerrados" (sin más transiciones).
INSERT INTO dbo.EstadosCuenta (EstadoCuentaID, Codigo, Descripcion, EsTerminal) VALUES
    (1, N'ACTIVA',     N'Cuenta operativa',                 0),
    (2, N'SUSPENDIDA', N'Suspensión temporal por sanción',  0),
    (3, N'VETADA',     N'Veto permanente (sin apelación)',  1);

INSERT INTO dbo.EstadosSolicitud (EstadoSolicitudID, Codigo, Descripcion, EsTerminal) VALUES
    (1, N'PENDIENTE', N'En espera de revisión del administrador', 0),
    (2, N'ACEPTADA',  N'Aprobada por el administrador',           1),
    (3, N'RECHAZADA', N'Rechazada por el administrador',          1);

INSERT INTO dbo.EstadosReserva (EstadoReservaID, Codigo, Descripcion, EsTerminal) VALUES
    (1, N'ACTIVO',     N'Reserva confirmada y vigente',  0),
    (2, N'EN_TRANSITO',N'Envío/trayecto en curso',       0),
    (3, N'ENTREGADO',  N'Servicio completado',           1),
    (4, N'CANCELADO',  N'Reserva cancelada',             1);

INSERT INTO dbo.EstadosPago (EstadoPagoID, Codigo, Descripcion, EsTerminal) VALUES
    (1, N'PENDIENTE', N'Pago iniciado, sin procesar', 0),
    (2, N'PROCESADO', N'Pago exitoso',                1),
    (3, N'RECHAZADO', N'Pago rechazado',              1);

INSERT INTO dbo.EstadosReporte (EstadoReporteID, Codigo, Descripcion, EsTerminal) VALUES
    (1, N'ENVIADO',     N'Recibido pero no revisado', 0),
    (2, N'EN_REVISION', N'En proceso de análisis',    0),
    (3, N'ACEPTADO',    N'Procede y se aplica sanción',1),
    (4, N'RECHAZADO',   N'Desestimado',               1);

-- Zonas geográficas predefinidas (ejemplo: departamentos de Guatemala + internacional).
-- Ampliá esta lista según las zonas reales que maneje la plataforma; el frontend elige por ZonaID.
INSERT INTO dbo.Zonas (ZonaID, Nombre, Tipo) VALUES
    (1, N'Guatemala',       N'NACIONAL'),
    (2, N'Sacatepéquez',    N'NACIONAL'),
    (3, N'Quetzaltenango',  N'NACIONAL'),
    (4, N'Escuintla',       N'NACIONAL'),
    (5, N'Petén',           N'NACIONAL'),
    (6, N'Izabal',          N'NACIONAL'),
    (7, N'Huehuetenango',   N'NACIONAL'),
    (8, N'Internacional',   N'INTERNACIONAL');

-- Verificación rápida del seed:
SELECT 'Roles' AS Catalogo, COUNT(*) AS Filas FROM dbo.Roles
UNION ALL SELECT 'Generos',          COUNT(*) FROM dbo.Generos
UNION ALL SELECT 'EstadosCuenta',    COUNT(*) FROM dbo.EstadosCuenta
UNION ALL SELECT 'EstadosSolicitud', COUNT(*) FROM dbo.EstadosSolicitud
UNION ALL SELECT 'EstadosReserva',   COUNT(*) FROM dbo.EstadosReserva
UNION ALL SELECT 'EstadosPago',      COUNT(*) FROM dbo.EstadosPago
UNION ALL SELECT 'EstadosReporte',   COUNT(*) FROM dbo.EstadosReporte
UNION ALL SELECT 'Zonas',            COUNT(*) FROM dbo.Zonas;
