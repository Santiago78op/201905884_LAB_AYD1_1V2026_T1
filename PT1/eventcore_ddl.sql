-- =============================================================================================
-- DDL - EVENTCORE (Sistema de gestión de eventos y conferencias)
-- Proyecto AYD1 - Escuela de Vacaciones 2026
-- =============================================================================================
-- Descripción : Esquema relacional en SQL Server para EVENTCORE. Estilo académico-limpio:
--               un solo schema (dbo), PK/FK/UNIQUE/CHECK con nombres explícitos, índices sobre
--               todas las claves foráneas, tablas lookup para los estados (en vez de CHECK IN)
--               y borrado lógico (Activo) en los catálogos maestros.
-- Motor       : SQL Server 2016 o superior.
-- Modelo base : entidades-y-foraneas.md  (14 entidades + 5 tablas lookup de estados/rol)
--
-- Buenas prácticas aplicadas (curso SQL Server para Analistas de Datos):
--   §8  CREATE TABLE: toda tabla con PK, NOT NULL y restricciones explícitas.
--   §9  Tipos de datos: el tipo más restrictivo que cubre el caso real.
--   §10 Claves foráneas: integridad referencial garantizada por el motor, no por disciplina.
--   §7  Índices: "las FK no se indexan solas" -> un índice NONCLUSTERED por cada FK.
--   §6  Normalización + §4 relaciones: la N:M Inscripción<->Sesión se resuelve con tabla puente.
--   §14 Borrado lógico: los maestros se desactivan (Activo = 0), no se borran.
--   v2  Estados como lookup extensible (con EsTerminal), no como CHECK IN hardcodeado.
-- =============================================================================================

SET NOCOUNT ON;
GO

-- =============================================================================================
-- 0. CREACIÓN DE LA BASE DE DATOS
-- =============================================================================================
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = N'EventCore')
BEGIN
    CREATE DATABASE EventCore;
    PRINT N'Base de datos EventCore creada.';
END
ELSE
    PRINT N'Base de datos EventCore ya existe — continuando.';
GO

USE EventCore;
GO
SELECT DB_NAME() AS BaseDeDatosActual;
GO

-- =============================================================================================
-- 1. TABLAS LOOKUP (catálogos de estados / rol)
--    PK explícita (no IDENTITY) para que los IDs sembrados sean estables y citables en código.
--    EsTerminal distingue los estados "cerrados" (no admiten más transiciones).
-- =============================================================================================

CREATE TABLE dbo.Roles (
    RolID      TINYINT       NOT NULL,
    Codigo     NVARCHAR(20)  NOT NULL,
    Descripcion NVARCHAR(100) NULL,

    CONSTRAINT PK_Roles      PRIMARY KEY (RolID),
    CONSTRAINT UQ_Roles_Cod  UNIQUE (Codigo)
);
GO

CREATE TABLE dbo.EstadosEvento (
    EstadoEventoID TINYINT       NOT NULL,
    Codigo         NVARCHAR(20)  NOT NULL,
    Descripcion    NVARCHAR(100) NULL,
    EsTerminal     BIT           NOT NULL CONSTRAINT DF_EstadosEvento_Terminal DEFAULT (0),

    CONSTRAINT PK_EstadosEvento     PRIMARY KEY (EstadoEventoID),
    CONSTRAINT UQ_EstadosEvento_Cod UNIQUE (Codigo)
);
GO

CREATE TABLE dbo.EstadosInscripcion (
    EstadoInscripcionID TINYINT       NOT NULL,
    Codigo              NVARCHAR(20)  NOT NULL,
    Descripcion         NVARCHAR(100) NULL,
    EsTerminal          BIT           NOT NULL CONSTRAINT DF_EstadosInscripcion_Terminal DEFAULT (0),

    CONSTRAINT PK_EstadosInscripcion     PRIMARY KEY (EstadoInscripcionID),
    CONSTRAINT UQ_EstadosInscripcion_Cod UNIQUE (Codigo)
);
GO

CREATE TABLE dbo.EstadosPago (
    EstadoPagoID TINYINT       NOT NULL,
    Codigo       NVARCHAR(20)  NOT NULL,
    Descripcion  NVARCHAR(100) NULL,
    EsTerminal   BIT           NOT NULL CONSTRAINT DF_EstadosPago_Terminal DEFAULT (0),

    CONSTRAINT PK_EstadosPago     PRIMARY KEY (EstadoPagoID),
    CONSTRAINT UQ_EstadosPago_Cod UNIQUE (Codigo)
);
GO

CREATE TABLE dbo.EstadosSolicitud (
    EstadoSolicitudID TINYINT       NOT NULL,
    Codigo            NVARCHAR(20)  NOT NULL,
    Descripcion       NVARCHAR(100) NULL,
    EsTerminal        BIT           NOT NULL CONSTRAINT DF_EstadosSolicitud_Terminal DEFAULT (0),

    CONSTRAINT PK_EstadosSolicitud     PRIMARY KEY (EstadoSolicitudID),
    CONSTRAINT UQ_EstadosSolicitud_Cod UNIQUE (Codigo)
);
GO

-- =============================================================================================
-- 2. CATÁLOGOS BASE (sin FK) — se crean primero porque todo lo demás depende de ellos.
-- =============================================================================================

-- ----------------- Usuarios (Administrador / Asistente, distinguidos por RolID) -----------------
CREATE TABLE dbo.Usuarios (
    UsuarioID        INT            NOT NULL IDENTITY(1,1),
    NombreCompleto   NVARCHAR(150)  NOT NULL,
    Correo           NVARCHAR(150)  NOT NULL,
    Contrasena       NVARCHAR(255)  NOT NULL,                 -- hash, nunca texto plano
    Telefono         NVARCHAR(30)   NOT NULL,
    Organizacion     NVARCHAR(150)  NOT NULL,
    Cargo            NVARCHAR(100)  NULL,                     -- opcional según enunciado
    PaisResidencia   NVARCHAR(100)  NOT NULL,
    FotoPerfil       NVARCHAR(300)  NOT NULL,
    RolID            TINYINT        NOT NULL,
    CorreoConfirmado BIT            NOT NULL CONSTRAINT DF_Usuarios_CorreoConf DEFAULT (0),
    Activo           BIT            NOT NULL CONSTRAINT DF_Usuarios_Activo DEFAULT (1),  -- borrado lógico §14

    CONSTRAINT PK_Usuarios        PRIMARY KEY (UsuarioID),
    CONSTRAINT UQ_Usuarios_Correo UNIQUE (Correo),           -- el correo identifica, no se repite
    CONSTRAINT FK_Usuarios_Roles  FOREIGN KEY (RolID) REFERENCES dbo.Roles (RolID),
    CONSTRAINT CK_Usuarios_Correo CHECK (Correo LIKE N'%_@_%._%')
);
GO
CREATE NONCLUSTERED INDEX IX_Usuarios_RolID ON dbo.Usuarios (RolID);
GO

-- ----------------- Ponentes -----------------
CREATE TABLE dbo.Ponentes (
    PonenteID          INT            NOT NULL IDENTITY(1,1),
    NombreCompleto     NVARCHAR(150)  NOT NULL,
    CorreoContacto     NVARCHAR(150)  NOT NULL,
    Fotografia         NVARCHAR(300)  NOT NULL,
    Biografia          NVARCHAR(MAX)  NOT NULL,
    AreaEspecializacion NVARCHAR(150) NOT NULL,
    Organizacion       NVARCHAR(150)  NULL,                  -- opcional
    WebRedes           NVARCHAR(300)  NULL,                  -- opcional
    Activo             BIT            NOT NULL CONSTRAINT DF_Ponentes_Activo DEFAULT (1),  -- "desactivar, no eliminar"

    CONSTRAINT PK_Ponentes        PRIMARY KEY (PonenteID),
    CONSTRAINT CK_Ponentes_Correo CHECK (CorreoContacto LIKE N'%_@_%._%')
);
GO

-- ----------------- Salas -----------------
CREATE TABLE dbo.Salas (
    SalaID     INT            NOT NULL IDENTITY(1,1),
    Nombre     NVARCHAR(100)  NOT NULL,
    Ubicacion  NVARCHAR(200)  NOT NULL,
    Capacidad  INT            NOT NULL,                       -- vital para el reporte de ocupación
    Activo     BIT            NOT NULL CONSTRAINT DF_Salas_Activo DEFAULT (1),

    CONSTRAINT PK_Salas           PRIMARY KEY (SalaID),
    CONSTRAINT CK_Salas_Capacidad CHECK (Capacidad > 0)
);
GO

-- ----------------- TiposEntrada (tarifas del enunciado) -----------------
CREATE TABLE dbo.TiposEntrada (
    TipoEntradaID  TINYINT        NOT NULL IDENTITY(1,1),
    Nombre         NVARCHAR(50)   NOT NULL,                   -- EARLY_BIRD | GENERAL | ESTUDIANTE | SESION_INDIVIDUAL | VIP
    Descripcion    NVARCHAR(300)  NOT NULL,
    Tarifa         DECIMAL(10,2)  NOT NULL,
    Disponibilidad NVARCHAR(200)  NOT NULL,                   -- regla: "20% del cupo", "máx 10", etc.
    Activo         BIT            NOT NULL CONSTRAINT DF_TiposEntrada_Activo DEFAULT (1),

    CONSTRAINT PK_TiposEntrada        PRIMARY KEY (TipoEntradaID),
    CONSTRAINT UQ_TiposEntrada_Nombre UNIQUE (Nombre),
    CONSTRAINT CK_TiposEntrada_Tarifa CHECK (Tarifa >= 0)
);
GO

-- =============================================================================================
-- 3. NÚCLEO DEL EVENTO
-- =============================================================================================

-- ----------------- Eventos -----------------
CREATE TABLE dbo.Eventos (
    EventoID             INT            NOT NULL IDENTITY(1,1),
    AdminID              INT            NOT NULL,             -- FK -> Usuarios (rol ADMIN)
    Nombre               NVARCHAR(200)  NOT NULL,
    Descripcion          NVARCHAR(MAX)  NOT NULL,
    FechaInicio          DATETIME2(0)   NOT NULL,
    FechaFin             DATETIME2(0)   NOT NULL,
    Modalidad            NVARCHAR(15)   NOT NULL,
    Ubicacion            NVARCHAR(300)  NULL,                 -- física, según modalidad
    EnlaceTransmision    NVARCHAR(300)  NULL,                 -- según modalidad
    Categoria            NVARCHAR(15)   NOT NULL,
    ImagenBanner         NVARCHAR(300)  NOT NULL,
    CapacidadMaxima      INT            NOT NULL,
    EstadoEventoID       TINYINT        NOT NULL CONSTRAINT DF_Eventos_Estado DEFAULT (1),  -- 1 = BORRADOR
    ModalidadInscripcion NVARCHAR(15)   NOT NULL,
    EsPago               BIT            NOT NULL CONSTRAINT DF_Eventos_EsPago DEFAULT (0),

    CONSTRAINT PK_Eventos               PRIMARY KEY (EventoID),
    CONSTRAINT FK_Eventos_Usuarios      FOREIGN KEY (AdminID)        REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_Eventos_EstadosEvento FOREIGN KEY (EstadoEventoID) REFERENCES dbo.EstadosEvento (EstadoEventoID),
    -- Enums fijos del dominio: van como CHECK (no cambian con el tiempo, a diferencia de los estados)
    CONSTRAINT CK_Eventos_Modalidad     CHECK (Modalidad IN (N'PRESENCIAL', N'VIRTUAL', N'HIBRIDA')),
    CONSTRAINT CK_Eventos_Categoria     CHECK (Categoria IN (N'ACADEMICO', N'CORPORATIVO', N'CULTURAL', N'TECNOLOGICO', N'OTRO')),
    CONSTRAINT CK_Eventos_ModInscripcion CHECK (ModalidadInscripcion IN (N'ABIERTA', N'APROBACION', N'INVITACION')),
    CONSTRAINT CK_Eventos_Capacidad     CHECK (CapacidadMaxima > 0),
    CONSTRAINT CK_Eventos_Fechas        CHECK (FechaFin >= FechaInicio)
);
GO
CREATE NONCLUSTERED INDEX IX_Eventos_AdminID        ON dbo.Eventos (AdminID);
CREATE NONCLUSTERED INDEX IX_Eventos_EstadoEventoID ON dbo.Eventos (EstadoEventoID);
GO

-- ----------------- Sesiones -----------------
CREATE TABLE dbo.Sesiones (
    SesionID         INT            NOT NULL IDENTITY(1,1),
    EventoID         INT            NOT NULL,
    PonenteID        INT            NOT NULL,
    SalaID           INT            NULL,                     -- NULL si la sesión es por enlace (virtual)
    Titulo           NVARCHAR(200)  NOT NULL,
    Enlace           NVARCHAR(300)  NULL,                     -- "Sala o enlace asignado"
    FechaHoraInicio  DATETIME2(0)   NOT NULL,
    FechaHoraFin     DATETIME2(0)   NOT NULL,
    CupoMaximo       INT            NOT NULL,

    CONSTRAINT PK_Sesiones           PRIMARY KEY (SesionID),
    CONSTRAINT FK_Sesiones_Eventos   FOREIGN KEY (EventoID)  REFERENCES dbo.Eventos (EventoID),
    CONSTRAINT FK_Sesiones_Ponentes  FOREIGN KEY (PonenteID) REFERENCES dbo.Ponentes (PonenteID),
    CONSTRAINT FK_Sesiones_Salas     FOREIGN KEY (SalaID)    REFERENCES dbo.Salas (SalaID),
    CONSTRAINT CK_Sesiones_Cupo      CHECK (CupoMaximo > 0),
    CONSTRAINT CK_Sesiones_Fechas    CHECK (FechaHoraFin >= FechaHoraInicio)
);
GO
CREATE NONCLUSTERED INDEX IX_Sesiones_EventoID  ON dbo.Sesiones (EventoID);
CREATE NONCLUSTERED INDEX IX_Sesiones_PonenteID ON dbo.Sesiones (PonenteID);
CREATE NONCLUSTERED INDEX IX_Sesiones_SalaID    ON dbo.Sesiones (SalaID) WHERE SalaID IS NOT NULL;
GO

-- ----------------- MaterialesRecurso (entidad débil de Sesión) -----------------
CREATE TABLE dbo.MaterialesRecurso (
    MaterialID INT            NOT NULL IDENTITY(1,1),
    SesionID   INT            NOT NULL,
    Nombre     NVARCHAR(200)  NOT NULL,
    UrlArchivo NVARCHAR(300)  NOT NULL,

    CONSTRAINT PK_MaterialesRecurso          PRIMARY KEY (MaterialID),
    -- Composición: si se elimina la sesión, sus materiales se van con ella (camino único, sin conflicto de cascada)
    CONSTRAINT FK_MaterialesRecurso_Sesiones FOREIGN KEY (SesionID)
        REFERENCES dbo.Sesiones (SesionID) ON DELETE CASCADE
);
GO
CREATE NONCLUSTERED INDEX IX_MaterialesRecurso_SesionID ON dbo.MaterialesRecurso (SesionID);
GO

-- =============================================================================================
-- 4. INSCRIPCIONES
-- =============================================================================================

-- ----------------- Inscripciones -----------------
CREATE TABLE dbo.Inscripciones (
    InscripcionID       INT            NOT NULL IDENTITY(1,1),
    AsistenteID         INT            NOT NULL,             -- FK -> Usuarios (rol ASISTENTE)
    EventoID            INT            NOT NULL,
    TipoEntradaID       TINYINT        NOT NULL,
    FechaInscripcion    DATETIME2(0)   NOT NULL CONSTRAINT DF_Inscripciones_Fecha DEFAULT (SYSUTCDATETIME()),
    EstadoInscripcionID TINYINT        NOT NULL CONSTRAINT DF_Inscripciones_Estado DEFAULT (1),  -- 1 = PENDIENTE
    Monto               DECIMAL(10,2)  NOT NULL CONSTRAINT DF_Inscripciones_Monto DEFAULT (0),    -- vital: ingresos y reembolso

    CONSTRAINT PK_Inscripciones                    PRIMARY KEY (InscripcionID),
    CONSTRAINT FK_Inscripciones_Usuarios           FOREIGN KEY (AsistenteID)         REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_Inscripciones_Eventos            FOREIGN KEY (EventoID)            REFERENCES dbo.Eventos (EventoID),
    CONSTRAINT FK_Inscripciones_TiposEntrada       FOREIGN KEY (TipoEntradaID)       REFERENCES dbo.TiposEntrada (TipoEntradaID),
    CONSTRAINT FK_Inscripciones_EstadosInscripcion FOREIGN KEY (EstadoInscripcionID) REFERENCES dbo.EstadosInscripcion (EstadoInscripcionID),
    CONSTRAINT CK_Inscripciones_Monto              CHECK (Monto >= 0)
);
GO
CREATE NONCLUSTERED INDEX IX_Inscripciones_AsistenteID         ON dbo.Inscripciones (AsistenteID);
CREATE NONCLUSTERED INDEX IX_Inscripciones_EventoID            ON dbo.Inscripciones (EventoID);
CREATE NONCLUSTERED INDEX IX_Inscripciones_TipoEntradaID       ON dbo.Inscripciones (TipoEntradaID);
CREATE NONCLUSTERED INDEX IX_Inscripciones_EstadoInscripcionID ON dbo.Inscripciones (EstadoInscripcionID);
GO

-- ----------------- InscripcionSesion (TABLA PUENTE de la N:M Inscripción <-> Sesión) -----------------
-- PK compuesta: impide registrar dos veces la misma sesión en una inscripción (integridad §4/§6).
CREATE TABLE dbo.InscripcionSesion (
    InscripcionID INT          NOT NULL,
    SesionID      INT          NOT NULL,
    FechaRegistro DATETIME2(0) NOT NULL CONSTRAINT DF_InscripcionSesion_Fecha DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_InscripcionSesion               PRIMARY KEY (InscripcionID, SesionID),
    CONSTRAINT FK_InscripcionSesion_Inscripciones FOREIGN KEY (InscripcionID) REFERENCES dbo.Inscripciones (InscripcionID),
    CONSTRAINT FK_InscripcionSesion_Sesiones      FOREIGN KEY (SesionID)      REFERENCES dbo.Sesiones (SesionID)
);
GO
-- La PK ya indexa (InscripcionID, SesionID); agregamos el índice inverso para consultas por sesión.
CREATE NONCLUSTERED INDEX IX_InscripcionSesion_SesionID ON dbo.InscripcionSesion (SesionID);
GO

-- ----------------- CodigosInvitacion -----------------
CREATE TABLE dbo.CodigosInvitacion (
    CodigoID           INT            NOT NULL IDENTITY(1,1),
    EventoID           INT            NOT NULL,
    AsistenteID        INT            NULL,                  -- NULL hasta que alguien canjea el código
    Codigo             NVARCHAR(50)   NOT NULL,
    CorreoDestinatario NVARCHAR(150)  NOT NULL,
    Usado              BIT            NOT NULL CONSTRAINT DF_CodigosInvitacion_Usado DEFAULT (0),

    CONSTRAINT PK_CodigosInvitacion          PRIMARY KEY (CodigoID),
    CONSTRAINT UQ_CodigosInvitacion_Codigo   UNIQUE (Codigo),
    CONSTRAINT FK_CodigosInvitacion_Eventos  FOREIGN KEY (EventoID)    REFERENCES dbo.Eventos (EventoID),
    CONSTRAINT FK_CodigosInvitacion_Usuarios FOREIGN KEY (AsistenteID) REFERENCES dbo.Usuarios (UsuarioID)
);
GO
CREATE NONCLUSTERED INDEX IX_CodigosInvitacion_EventoID    ON dbo.CodigosInvitacion (EventoID);
CREATE NONCLUSTERED INDEX IX_CodigosInvitacion_AsistenteID ON dbo.CodigosInvitacion (AsistenteID) WHERE AsistenteID IS NOT NULL;
GO

-- =============================================================================================
-- 5. PAGOS Y CANCELACIONES
-- =============================================================================================

-- ----------------- Tarjetas -----------------
CREATE TABLE dbo.Tarjetas (
    TarjetaID         INT            NOT NULL IDENTITY(1,1),
    AsistenteID       INT            NOT NULL,
    Titular           NVARCHAR(150)  NOT NULL,
    NumeroEnmascarado NVARCHAR(25)   NOT NULL,               -- solo los últimos dígitos, nunca el número completo
    Tipo              NVARCHAR(10)   NOT NULL,
    FechaExpiracion   NVARCHAR(7)    NOT NULL,               -- formato MM/AAAA

    CONSTRAINT PK_Tarjetas          PRIMARY KEY (TarjetaID),
    CONSTRAINT FK_Tarjetas_Usuarios FOREIGN KEY (AsistenteID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT CK_Tarjetas_Tipo     CHECK (Tipo IN (N'DEBITO', N'CREDITO'))
);
GO
CREATE NONCLUSTERED INDEX IX_Tarjetas_AsistenteID ON dbo.Tarjetas (AsistenteID);
GO

-- ----------------- Pagos -----------------
CREATE TABLE dbo.Pagos (
    PagoID         INT            NOT NULL IDENTITY(1,1),
    InscripcionID  INT            NOT NULL,
    TarjetaID      INT            NULL,                      -- NULL si el pago fue por transferencia
    AdminRevisorID INT            NULL,                      -- admin que revisa la transferencia (NULL en pago con tarjeta)
    Monto          DECIMAL(10,2)  NOT NULL,
    Metodo         NVARCHAR(15)   NOT NULL,
    EstadoPagoID   TINYINT        NOT NULL CONSTRAINT DF_Pagos_Estado DEFAULT (1),  -- 1 = PENDIENTE
    FechaPago      DATETIME2(0)   NOT NULL CONSTRAINT DF_Pagos_Fecha DEFAULT (SYSUTCDATETIME()),  -- vital: reporte de ingresos
    ComprobanteUrl NVARCHAR(300)  NULL,                      -- comprobante cargado en transferencia

    CONSTRAINT PK_Pagos                  PRIMARY KEY (PagoID),
    CONSTRAINT FK_Pagos_Inscripciones    FOREIGN KEY (InscripcionID)  REFERENCES dbo.Inscripciones (InscripcionID),
    CONSTRAINT FK_Pagos_Tarjetas         FOREIGN KEY (TarjetaID)      REFERENCES dbo.Tarjetas (TarjetaID),
    CONSTRAINT FK_Pagos_UsuariosRevisor  FOREIGN KEY (AdminRevisorID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_Pagos_EstadosPago      FOREIGN KEY (EstadoPagoID)   REFERENCES dbo.EstadosPago (EstadoPagoID),
    CONSTRAINT CK_Pagos_Metodo           CHECK (Metodo IN (N'TARJETA', N'TRANSFERENCIA')),
    CONSTRAINT CK_Pagos_Monto            CHECK (Monto >= 0)
);
GO
CREATE NONCLUSTERED INDEX IX_Pagos_InscripcionID  ON dbo.Pagos (InscripcionID);
CREATE NONCLUSTERED INDEX IX_Pagos_TarjetaID      ON dbo.Pagos (TarjetaID)      WHERE TarjetaID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_Pagos_AdminRevisorID ON dbo.Pagos (AdminRevisorID) WHERE AdminRevisorID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_Pagos_EstadoPagoID   ON dbo.Pagos (EstadoPagoID);
GO

-- ----------------- SolicitudesCancelacion -----------------
CREATE TABLE dbo.SolicitudesCancelacion (
    SolicitudID       INT            NOT NULL IDENTITY(1,1),
    InscripcionID     INT            NOT NULL,
    AdminProcesadorID INT            NULL,                   -- admin que procesa el reembolso (NULL hasta procesarse)
    FechaSolicitud    DATETIME2(0)   NOT NULL CONSTRAINT DF_SolicitudesCancelacion_Fecha DEFAULT (SYSUTCDATETIME()),
    EstadoSolicitudID TINYINT        NOT NULL CONSTRAINT DF_SolicitudesCancelacion_Estado DEFAULT (1),  -- 1 = PENDIENTE
    MontoReembolso    DECIMAL(10,2)  NOT NULL CONSTRAINT DF_SolicitudesCancelacion_Monto DEFAULT (0),    -- 80% del monto pagado
    ComprobantePdfUrl NVARCHAR(300)  NULL,                   -- PDF que el admin envía al solicitante

    CONSTRAINT PK_SolicitudesCancelacion                  PRIMARY KEY (SolicitudID),
    CONSTRAINT FK_SolicitudesCancelacion_Inscripciones    FOREIGN KEY (InscripcionID)     REFERENCES dbo.Inscripciones (InscripcionID),
    CONSTRAINT FK_SolicitudesCancelacion_UsuariosProc     FOREIGN KEY (AdminProcesadorID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_SolicitudesCancelacion_EstadosSolicitud FOREIGN KEY (EstadoSolicitudID) REFERENCES dbo.EstadosSolicitud (EstadoSolicitudID),
    CONSTRAINT CK_SolicitudesCancelacion_Monto            CHECK (MontoReembolso >= 0)
);
GO
CREATE NONCLUSTERED INDEX IX_SolicitudesCancelacion_InscripcionID     ON dbo.SolicitudesCancelacion (InscripcionID);
CREATE NONCLUSTERED INDEX IX_SolicitudesCancelacion_AdminProcesadorID ON dbo.SolicitudesCancelacion (AdminProcesadorID) WHERE AdminProcesadorID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_SolicitudesCancelacion_EstadoSolicitudID ON dbo.SolicitudesCancelacion (EstadoSolicitudID);
GO

-- =============================================================================================
-- 6. BITÁCORA (para el reporte "Log de todas las actividades del sistema")
-- =============================================================================================
CREATE TABLE dbo.LogActividad (
    LogID           BIGINT         NOT NULL IDENTITY(1,1),
    UsuarioID       INT            NULL,                     -- NULL si la acción la ejecuta el sistema
    Accion          NVARCHAR(50)   NOT NULL,
    EntidadAfectada NVARCHAR(50)   NOT NULL,
    Descripcion     NVARCHAR(500)  NULL,
    FechaHora       DATETIME2(0)   NOT NULL CONSTRAINT DF_LogActividad_Fecha DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_LogActividad          PRIMARY KEY (LogID),
    CONSTRAINT FK_LogActividad_Usuarios FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuarios (UsuarioID)
);
GO
CREATE NONCLUSTERED INDEX IX_LogActividad_UsuarioID ON dbo.LogActividad (UsuarioID) WHERE UsuarioID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_LogActividad_FechaHora ON dbo.LogActividad (FechaHora DESC);
GO

-- =============================================================================================
-- 7. SEED DE LOOKUPS (estados y roles)
-- =============================================================================================
INSERT INTO dbo.Roles (RolID, Codigo, Descripcion) VALUES
    (1, N'ADMIN',     N'Administrador de la plataforma'),
    (2, N'ASISTENTE', N'Asistente / participante');

INSERT INTO dbo.EstadosEvento (EstadoEventoID, Codigo, Descripcion, EsTerminal) VALUES
    (1, N'BORRADOR',   N'Evento en edición, no visible',     0),
    (2, N'PUBLICADO',  N'Evento abierto a inscripciones',    0),
    (3, N'CANCELADO',  N'Evento cancelado',                  1),
    (4, N'FINALIZADO', N'Evento ya realizado',               1);

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
GO

-- =============================================================================================
-- 8. VERIFICACIÓN (ejecutar a discreción, no es parte del deploy)
-- =============================================================================================
PRINT N'=== Tablas creadas ===';
SELECT TABLE_SCHEMA AS Esquema, TABLE_NAME AS Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = N'BASE TABLE'
ORDER BY TABLE_NAME;

PRINT N'=== Claves foráneas (de dónde sale cada una) ===';
SELECT
    fk.name                                                       AS NombreFK,
    OBJECT_NAME(fk.parent_object_id)                              AS TablaHijo,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id)          AS ColumnaHijo,
    OBJECT_NAME(fk.referenced_object_id)                          AS TablaPadre,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id)  AS ColumnaPadre
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
ORDER BY TablaHijo, NombreFK;

PRINT N'=== Índices (excluyendo PKs) ===';
SELECT OBJECT_NAME(i.object_id) AS Tabla, i.name AS Indice, i.type_desc AS Tipo, i.is_unique AS EsUnico, i.has_filter AS EsFiltrado
FROM sys.indexes i
WHERE i.is_primary_key = 0 AND i.name IS NOT NULL
  AND OBJECT_NAME(i.object_id) NOT IN (N'Roles', N'EstadosEvento', N'EstadosInscripcion', N'EstadosPago', N'EstadosSolicitud')
ORDER BY Tabla, i.name;
GO

PRINT N'>> DDL de EVENTCORE aplicado correctamente.';
GO
