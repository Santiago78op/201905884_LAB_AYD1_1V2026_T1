-- =============================================================================================
-- DDL COMPLETO - EVENTCORE  ·  TODO EN UN ARCHIVO, SIN "GO"  ·  para desplegar en AWS
-- Proyecto AYD1 - Escuela de Vacaciones 2026
-- =============================================================================================
-- Qué es: el esquema entero (22 tablas · 27 FKs) en un solo script, sin "GO", pensado para
--         ejecutarlo de una sola pasada contra SQL Server en AWS (RDS / EC2).
--
-- CONTENIDO (en orden): base -> limpieza -> lookups -> catálogos base -> núcleo ->
--                       inscripciones -> pagos -> bitácora -> confirmación de correo -> seeds.
--
-- AWS — leé esto antes:
--   * RDS for SQL Server: el usuario maestro PUEDE crear bases con CREATE DATABASE (forma simple).
--     Si tu instancia YA te dio una base creada y no podés crear otra, COMENTÁ la línea
--     "CREATE DATABASE" y la "USE", y ejecutá el resto sobre la base que ya tengas.
--   * Mantené el orden: hay FKs; si reordenás, fallará por dependencias.
--   * Es re-ejecutable: la sección de limpieza borra todo en orden inverso antes de crear.
-- =============================================================================================

SET NOCOUNT ON;

-- =============================================================================================
-- 0. BASE DE DATOS  (idempotente, en una línea para no romper el parser sin GO)
-- =============================================================================================
IF DB_ID(N'Cumbre') IS NULL CREATE DATABASE Cumbre;
USE Cumbre;

-- =============================================================================================
-- 0.1 LIMPIEZA re-ejecutable — orden INVERSO a las FKs (primero hijos, al final padres)
-- =============================================================================================
DROP TABLE IF EXISTS dbo.ConfirmacionesCorreo;
DROP TABLE IF EXISTS dbo.LogActividad;
DROP TABLE IF EXISTS dbo.SolicitudesCancelacion;
DROP TABLE IF EXISTS dbo.Pagos;
DROP TABLE IF EXISTS dbo.InscripcionSesion;
DROP TABLE IF EXISTS dbo.CodigosInvitacion;
DROP TABLE IF EXISTS dbo.Tarjetas;
DROP TABLE IF EXISTS dbo.Inscripciones;
DROP TABLE IF EXISTS dbo.MaterialesRecurso;
DROP TABLE IF EXISTS dbo.Sesiones;
DROP TABLE IF EXISTS dbo.Eventos;
DROP TABLE IF EXISTS dbo.TiposEntrada;
DROP TABLE IF EXISTS dbo.Salas;
DROP TABLE IF EXISTS dbo.Ponentes;
DROP TABLE IF EXISTS dbo.Usuarios;
DROP TABLE IF EXISTS dbo.Horarios;
DROP TABLE IF EXISTS dbo.Dias;
DROP TABLE IF EXISTS dbo.EstadosSolicitud;
DROP TABLE IF EXISTS dbo.EstadosPago;
DROP TABLE IF EXISTS dbo.EstadosInscripcion;
DROP TABLE IF EXISTS dbo.EstadosEvento;
DROP TABLE IF EXISTS dbo.Roles;

-- =============================================================================================
-- 1. LOOKUP / CATÁLOGOS (sin FK)
-- =============================================================================================
CREATE TABLE dbo.Roles (
    RolID       TINYINT       NOT NULL,
    Codigo      NVARCHAR(20)  NOT NULL,
    Descripcion NVARCHAR(100) NULL,
    CONSTRAINT PK_Roles     PRIMARY KEY (RolID),
    CONSTRAINT UQ_Roles_Cod UNIQUE (Codigo)
);

CREATE TABLE dbo.EstadosEvento (
    EstadoEventoID TINYINT       NOT NULL,
    Codigo         NVARCHAR(20)  NOT NULL,
    Descripcion    NVARCHAR(100) NULL,
    EsTerminal     BIT           NOT NULL CONSTRAINT DF_EstadosEvento_Terminal DEFAULT (0),
    CONSTRAINT PK_EstadosEvento     PRIMARY KEY (EstadoEventoID),
    CONSTRAINT UQ_EstadosEvento_Cod UNIQUE (Codigo)
);

CREATE TABLE dbo.EstadosInscripcion (
    EstadoInscripcionID TINYINT       NOT NULL,
    Codigo              NVARCHAR(20)  NOT NULL,
    Descripcion         NVARCHAR(100) NULL,
    EsTerminal          BIT           NOT NULL CONSTRAINT DF_EstadosInscripcion_Terminal DEFAULT (0),
    CONSTRAINT PK_EstadosInscripcion     PRIMARY KEY (EstadoInscripcionID),
    CONSTRAINT UQ_EstadosInscripcion_Cod UNIQUE (Codigo)
);

CREATE TABLE dbo.EstadosPago (
    EstadoPagoID TINYINT       NOT NULL,
    Codigo       NVARCHAR(20)  NOT NULL,
    Descripcion  NVARCHAR(100) NULL,
    EsTerminal   BIT           NOT NULL CONSTRAINT DF_EstadosPago_Terminal DEFAULT (0),
    CONSTRAINT PK_EstadosPago     PRIMARY KEY (EstadoPagoID),
    CONSTRAINT UQ_EstadosPago_Cod UNIQUE (Codigo)
);

CREATE TABLE dbo.EstadosSolicitud (
    EstadoSolicitudID TINYINT       NOT NULL,
    Codigo            NVARCHAR(20)  NOT NULL,
    Descripcion       NVARCHAR(100) NULL,
    EsTerminal        BIT           NOT NULL CONSTRAINT DF_EstadosSolicitud_Terminal DEFAULT (0),
    CONSTRAINT PK_EstadosSolicitud     PRIMARY KEY (EstadoSolicitudID),
    CONSTRAINT UQ_EstadosSolicitud_Cod UNIQUE (Codigo)
);

CREATE TABLE dbo.Dias (
    DiaID       TINYINT       NOT NULL,                 -- 1 = Lunes … 7 = Domingo (ISO-8601)
    Nombre      NVARCHAR(15)  NOT NULL,
    Abreviatura NVARCHAR(3)   NOT NULL,
    CONSTRAINT PK_Dias        PRIMARY KEY (DiaID),
    CONSTRAINT UQ_Dias_Nombre UNIQUE (Nombre),
    CONSTRAINT CK_Dias_Rango  CHECK (DiaID BETWEEN 1 AND 7)
);

CREATE TABLE dbo.Horarios (
    HorarioID  TINYINT      NOT NULL,
    HoraInicio TIME(0)      NOT NULL,
    HoraFin    TIME(0)      NOT NULL,
    Etiqueta   NVARCHAR(20) NOT NULL,
    CONSTRAINT PK_Horarios          PRIMARY KEY (HorarioID),
    CONSTRAINT UQ_Horarios_Bloque   UNIQUE (HoraInicio, HoraFin),
    CONSTRAINT UQ_Horarios_Etiqueta UNIQUE (Etiqueta),
    CONSTRAINT CK_Horarios_Orden    CHECK (HoraFin > HoraInicio)
);

-- =============================================================================================
-- 2. CATÁLOGOS BASE
-- =============================================================================================
CREATE TABLE dbo.Usuarios (
    UsuarioID        INT            NOT NULL IDENTITY(1,1),
    NombreCompleto   NVARCHAR(150)  NOT NULL,
    Correo           NVARCHAR(150)  NOT NULL,
    Contrasena       NVARCHAR(255)  NOT NULL,                 -- hash, nunca texto plano
    Telefono         NVARCHAR(30)   NOT NULL,
    Organizacion     NVARCHAR(150)  NOT NULL,
    Cargo            NVARCHAR(100)  NULL,
    PaisResidencia   NVARCHAR(100)  NOT NULL,
    FotoPerfil       NVARCHAR(300)  NOT NULL,
    RolID            TINYINT        NOT NULL,
    CorreoConfirmado BIT            NOT NULL CONSTRAINT DF_Usuarios_CorreoConf DEFAULT (0),
    Activo           BIT            NOT NULL CONSTRAINT DF_Usuarios_Activo DEFAULT (1),
    CONSTRAINT PK_Usuarios        PRIMARY KEY (UsuarioID),
    CONSTRAINT UQ_Usuarios_Correo UNIQUE (Correo),
    CONSTRAINT FK_Usuarios_Roles  FOREIGN KEY (RolID) REFERENCES dbo.Roles (RolID),
    CONSTRAINT CK_Usuarios_Correo CHECK (Correo LIKE N'%_@_%._%')
);
CREATE NONCLUSTERED INDEX IX_Usuarios_RolID ON dbo.Usuarios (RolID);

CREATE TABLE dbo.Ponentes (
    PonenteID          INT            NOT NULL IDENTITY(1,1),
    NombreCompleto     NVARCHAR(150)  NOT NULL,
    CorreoContacto     NVARCHAR(150)  NOT NULL,
    Fotografia         NVARCHAR(300)  NOT NULL,
    Biografia          NVARCHAR(MAX)  NOT NULL,
    AreaEspecializacion NVARCHAR(150) NOT NULL,
    Organizacion       NVARCHAR(150)  NULL,
    WebRedes           NVARCHAR(300)  NULL,
    Activo             BIT            NOT NULL CONSTRAINT DF_Ponentes_Activo DEFAULT (1),
    CONSTRAINT PK_Ponentes        PRIMARY KEY (PonenteID),
    CONSTRAINT CK_Ponentes_Correo CHECK (CorreoContacto LIKE N'%_@_%._%')
);

CREATE TABLE dbo.Salas (
    SalaID     INT            NOT NULL IDENTITY(1,1),
    Nombre     NVARCHAR(100)  NOT NULL,
    Ubicacion  NVARCHAR(200)  NOT NULL,
    Capacidad  INT            NOT NULL,
    Activo     BIT            NOT NULL CONSTRAINT DF_Salas_Activo DEFAULT (1),
    CONSTRAINT PK_Salas           PRIMARY KEY (SalaID),
    CONSTRAINT CK_Salas_Capacidad CHECK (Capacidad > 0)
);

CREATE TABLE dbo.TiposEntrada (
    TipoEntradaID  TINYINT        NOT NULL IDENTITY(1,1),
    Nombre         NVARCHAR(50)   NOT NULL,
    Descripcion    NVARCHAR(300)  NOT NULL,
    Tarifa         DECIMAL(10,2)  NOT NULL,
    Disponibilidad NVARCHAR(200)  NOT NULL,
    Activo         BIT            NOT NULL CONSTRAINT DF_TiposEntrada_Activo DEFAULT (1),
    CONSTRAINT PK_TiposEntrada        PRIMARY KEY (TipoEntradaID),
    CONSTRAINT UQ_TiposEntrada_Nombre UNIQUE (Nombre),
    CONSTRAINT CK_TiposEntrada_Tarifa CHECK (Tarifa >= 0)
);

-- =============================================================================================
-- 3. NÚCLEO DEL EVENTO
-- =============================================================================================
CREATE TABLE dbo.Eventos (
    EventoID             INT            NOT NULL IDENTITY(1,1),
    AdminID              INT            NOT NULL,
    Nombre               NVARCHAR(200)  NOT NULL,
    Descripcion          NVARCHAR(MAX)  NOT NULL,
    FechaInicio          DATETIME2(0)   NOT NULL,
    FechaFin             DATETIME2(0)   NOT NULL,
    Modalidad            NVARCHAR(15)   NOT NULL,
    Ubicacion            NVARCHAR(300)  NULL,
    EnlaceTransmision    NVARCHAR(300)  NULL,
    Categoria            NVARCHAR(15)   NOT NULL,
    ImagenBanner         NVARCHAR(300)  NOT NULL,
    CapacidadMaxima      INT            NOT NULL,
    EstadoEventoID       TINYINT        NOT NULL CONSTRAINT DF_Eventos_Estado DEFAULT (1),
    ModalidadInscripcion NVARCHAR(15)   NOT NULL,
    EsPago               BIT            NOT NULL CONSTRAINT DF_Eventos_EsPago DEFAULT (0),
    CONSTRAINT PK_Eventos                PRIMARY KEY (EventoID),
    CONSTRAINT FK_Eventos_Usuarios       FOREIGN KEY (AdminID)        REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_Eventos_EstadosEvento  FOREIGN KEY (EstadoEventoID) REFERENCES dbo.EstadosEvento (EstadoEventoID),
    CONSTRAINT CK_Eventos_Modalidad      CHECK (Modalidad IN (N'PRESENCIAL', N'VIRTUAL', N'HIBRIDA')),
    CONSTRAINT CK_Eventos_Categoria      CHECK (Categoria IN (N'ACADEMICO', N'CORPORATIVO', N'CULTURAL', N'TECNOLOGICO', N'OTRO')),
    CONSTRAINT CK_Eventos_ModInscripcion CHECK (ModalidadInscripcion IN (N'ABIERTA', N'APROBACION', N'INVITACION')),
    CONSTRAINT CK_Eventos_Capacidad      CHECK (CapacidadMaxima > 0),
    CONSTRAINT CK_Eventos_Fechas         CHECK (FechaFin >= FechaInicio)
);
CREATE NONCLUSTERED INDEX IX_Eventos_AdminID        ON dbo.Eventos (AdminID);
CREATE NONCLUSTERED INDEX IX_Eventos_EstadoEventoID ON dbo.Eventos (EstadoEventoID);

CREATE TABLE dbo.Sesiones (
    SesionID         INT            NOT NULL IDENTITY(1,1),
    EventoID         INT            NOT NULL,
    PonenteID        INT            NOT NULL,
    SalaID           INT            NULL,
    DiaID            TINYINT        NOT NULL,
    HorarioID        TINYINT        NOT NULL,
    Titulo           NVARCHAR(200)  NOT NULL,
    Enlace           NVARCHAR(300)  NULL,
    CupoMaximo       INT            NOT NULL,
    CONSTRAINT PK_Sesiones           PRIMARY KEY (SesionID),
    CONSTRAINT FK_Sesiones_Eventos   FOREIGN KEY (EventoID)  REFERENCES dbo.Eventos (EventoID),
    CONSTRAINT FK_Sesiones_Ponentes  FOREIGN KEY (PonenteID) REFERENCES dbo.Ponentes (PonenteID),
    CONSTRAINT FK_Sesiones_Salas     FOREIGN KEY (SalaID)    REFERENCES dbo.Salas (SalaID),
    CONSTRAINT FK_Sesiones_Dias      FOREIGN KEY (DiaID)     REFERENCES dbo.Dias (DiaID),
    CONSTRAINT FK_Sesiones_Horarios  FOREIGN KEY (HorarioID) REFERENCES dbo.Horarios (HorarioID),
    CONSTRAINT CK_Sesiones_Cupo      CHECK (CupoMaximo > 0)
);
CREATE NONCLUSTERED INDEX IX_Sesiones_EventoID  ON dbo.Sesiones (EventoID);
CREATE NONCLUSTERED INDEX IX_Sesiones_PonenteID ON dbo.Sesiones (PonenteID);
CREATE NONCLUSTERED INDEX IX_Sesiones_SalaID    ON dbo.Sesiones (SalaID) WHERE SalaID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_Sesiones_DiaID     ON dbo.Sesiones (DiaID);
CREATE NONCLUSTERED INDEX IX_Sesiones_HorarioID ON dbo.Sesiones (HorarioID);

CREATE TABLE dbo.MaterialesRecurso (
    MaterialID INT            NOT NULL IDENTITY(1,1),
    SesionID   INT            NOT NULL,
    Nombre     NVARCHAR(200)  NOT NULL,
    UrlArchivo NVARCHAR(300)  NOT NULL,
    CONSTRAINT PK_MaterialesRecurso          PRIMARY KEY (MaterialID),
    CONSTRAINT FK_MaterialesRecurso_Sesiones FOREIGN KEY (SesionID) REFERENCES dbo.Sesiones (SesionID) ON DELETE CASCADE
);
CREATE NONCLUSTERED INDEX IX_MaterialesRecurso_SesionID ON dbo.MaterialesRecurso (SesionID);

-- =============================================================================================
-- 4. INSCRIPCIONES
-- =============================================================================================
CREATE TABLE dbo.Inscripciones (
    InscripcionID       INT            NOT NULL IDENTITY(1,1),
    AsistenteID         INT            NOT NULL,
    EventoID            INT            NOT NULL,
    TipoEntradaID       TINYINT        NOT NULL,
    FechaInscripcion    DATETIME2(0)   NOT NULL CONSTRAINT DF_Inscripciones_Fecha DEFAULT (SYSUTCDATETIME()),
    EstadoInscripcionID TINYINT        NOT NULL CONSTRAINT DF_Inscripciones_Estado DEFAULT (1),
    Monto               DECIMAL(10,2)  NOT NULL CONSTRAINT DF_Inscripciones_Monto DEFAULT (0),
    CONSTRAINT PK_Inscripciones                    PRIMARY KEY (InscripcionID),
    CONSTRAINT FK_Inscripciones_Usuarios           FOREIGN KEY (AsistenteID)         REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_Inscripciones_Eventos            FOREIGN KEY (EventoID)            REFERENCES dbo.Eventos (EventoID),
    CONSTRAINT FK_Inscripciones_TiposEntrada       FOREIGN KEY (TipoEntradaID)       REFERENCES dbo.TiposEntrada (TipoEntradaID),
    CONSTRAINT FK_Inscripciones_EstadosInscripcion FOREIGN KEY (EstadoInscripcionID) REFERENCES dbo.EstadosInscripcion (EstadoInscripcionID),
    CONSTRAINT CK_Inscripciones_Monto              CHECK (Monto >= 0)
);
CREATE NONCLUSTERED INDEX IX_Inscripciones_AsistenteID         ON dbo.Inscripciones (AsistenteID);
CREATE NONCLUSTERED INDEX IX_Inscripciones_EventoID            ON dbo.Inscripciones (EventoID);
CREATE NONCLUSTERED INDEX IX_Inscripciones_TipoEntradaID       ON dbo.Inscripciones (TipoEntradaID);
CREATE NONCLUSTERED INDEX IX_Inscripciones_EstadoInscripcionID ON dbo.Inscripciones (EstadoInscripcionID);

CREATE TABLE dbo.InscripcionSesion (
    InscripcionID INT          NOT NULL,
    SesionID      INT          NOT NULL,
    FechaRegistro DATETIME2(0) NOT NULL CONSTRAINT DF_InscripcionSesion_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_InscripcionSesion               PRIMARY KEY (InscripcionID, SesionID),
    CONSTRAINT FK_InscripcionSesion_Inscripciones FOREIGN KEY (InscripcionID) REFERENCES dbo.Inscripciones (InscripcionID),
    CONSTRAINT FK_InscripcionSesion_Sesiones      FOREIGN KEY (SesionID)      REFERENCES dbo.Sesiones (SesionID)
);
CREATE NONCLUSTERED INDEX IX_InscripcionSesion_SesionID ON dbo.InscripcionSesion (SesionID);

CREATE TABLE dbo.CodigosInvitacion (
    CodigoID           INT            NOT NULL IDENTITY(1,1),
    EventoID           INT            NOT NULL,
    AsistenteID        INT            NULL,
    Codigo             NVARCHAR(50)   NOT NULL,
    CorreoDestinatario NVARCHAR(150)  NOT NULL,
    Usado              BIT            NOT NULL CONSTRAINT DF_CodigosInvitacion_Usado DEFAULT (0),
    CONSTRAINT PK_CodigosInvitacion          PRIMARY KEY (CodigoID),
    CONSTRAINT UQ_CodigosInvitacion_Codigo   UNIQUE (Codigo),
    CONSTRAINT FK_CodigosInvitacion_Eventos  FOREIGN KEY (EventoID)    REFERENCES dbo.Eventos (EventoID),
    CONSTRAINT FK_CodigosInvitacion_Usuarios FOREIGN KEY (AsistenteID) REFERENCES dbo.Usuarios (UsuarioID)
);
CREATE NONCLUSTERED INDEX IX_CodigosInvitacion_EventoID    ON dbo.CodigosInvitacion (EventoID);
CREATE NONCLUSTERED INDEX IX_CodigosInvitacion_AsistenteID ON dbo.CodigosInvitacion (AsistenteID) WHERE AsistenteID IS NOT NULL;

-- =============================================================================================
-- 5. PAGOS Y CANCELACIONES
-- =============================================================================================
CREATE TABLE dbo.Tarjetas (
    TarjetaID         INT            NOT NULL IDENTITY(1,1),
    AsistenteID       INT            NOT NULL,
    Titular           NVARCHAR(150)  NOT NULL,
    NumeroEnmascarado NVARCHAR(25)   NOT NULL,
    Tipo              NVARCHAR(10)   NOT NULL,
    FechaExpiracion   NVARCHAR(7)    NOT NULL,
    CONSTRAINT PK_Tarjetas          PRIMARY KEY (TarjetaID),
    CONSTRAINT FK_Tarjetas_Usuarios FOREIGN KEY (AsistenteID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT CK_Tarjetas_Tipo     CHECK (Tipo IN (N'DEBITO', N'CREDITO'))
);
CREATE NONCLUSTERED INDEX IX_Tarjetas_AsistenteID ON dbo.Tarjetas (AsistenteID);

CREATE TABLE dbo.Pagos (
    PagoID         INT            NOT NULL IDENTITY(1,1),
    InscripcionID  INT            NOT NULL,
    TarjetaID      INT            NULL,
    AdminRevisorID INT            NULL,
    Monto          DECIMAL(10,2)  NOT NULL,
    Metodo         NVARCHAR(15)   NOT NULL,
    EstadoPagoID   TINYINT        NOT NULL CONSTRAINT DF_Pagos_Estado DEFAULT (1),
    FechaPago      DATETIME2(0)   NOT NULL CONSTRAINT DF_Pagos_Fecha DEFAULT (SYSUTCDATETIME()),
    ComprobanteUrl NVARCHAR(300)  NULL,
    CONSTRAINT PK_Pagos                 PRIMARY KEY (PagoID),
    CONSTRAINT FK_Pagos_Inscripciones   FOREIGN KEY (InscripcionID)  REFERENCES dbo.Inscripciones (InscripcionID),
    CONSTRAINT FK_Pagos_Tarjetas        FOREIGN KEY (TarjetaID)      REFERENCES dbo.Tarjetas (TarjetaID),
    CONSTRAINT FK_Pagos_UsuariosRevisor FOREIGN KEY (AdminRevisorID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_Pagos_EstadosPago     FOREIGN KEY (EstadoPagoID)   REFERENCES dbo.EstadosPago (EstadoPagoID),
    CONSTRAINT CK_Pagos_Metodo          CHECK (Metodo IN (N'TARJETA', N'TRANSFERENCIA')),
    CONSTRAINT CK_Pagos_Monto           CHECK (Monto >= 0)
);
CREATE NONCLUSTERED INDEX IX_Pagos_InscripcionID  ON dbo.Pagos (InscripcionID);
CREATE NONCLUSTERED INDEX IX_Pagos_TarjetaID      ON dbo.Pagos (TarjetaID)      WHERE TarjetaID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_Pagos_AdminRevisorID ON dbo.Pagos (AdminRevisorID) WHERE AdminRevisorID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_Pagos_EstadoPagoID   ON dbo.Pagos (EstadoPagoID);

CREATE TABLE dbo.SolicitudesCancelacion (
    SolicitudID       INT            NOT NULL IDENTITY(1,1),
    InscripcionID     INT            NOT NULL,
    AdminProcesadorID INT            NULL,
    FechaSolicitud    DATETIME2(0)   NOT NULL CONSTRAINT DF_SolicitudesCancelacion_Fecha DEFAULT (SYSUTCDATETIME()),
    EstadoSolicitudID TINYINT        NOT NULL CONSTRAINT DF_SolicitudesCancelacion_Estado DEFAULT (1),
    MontoReembolso    DECIMAL(10,2)  NOT NULL CONSTRAINT DF_SolicitudesCancelacion_Monto DEFAULT (0),
    ComprobantePdfUrl NVARCHAR(300)  NULL,
    CONSTRAINT PK_SolicitudesCancelacion                  PRIMARY KEY (SolicitudID),
    CONSTRAINT FK_SolicitudesCancelacion_Inscripciones    FOREIGN KEY (InscripcionID)     REFERENCES dbo.Inscripciones (InscripcionID),
    CONSTRAINT FK_SolicitudesCancelacion_UsuariosProc     FOREIGN KEY (AdminProcesadorID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_SolicitudesCancelacion_EstadosSolicitud FOREIGN KEY (EstadoSolicitudID) REFERENCES dbo.EstadosSolicitud (EstadoSolicitudID),
    CONSTRAINT CK_SolicitudesCancelacion_Monto            CHECK (MontoReembolso >= 0)
);
CREATE NONCLUSTERED INDEX IX_SolicitudesCancelacion_InscripcionID     ON dbo.SolicitudesCancelacion (InscripcionID);
CREATE NONCLUSTERED INDEX IX_SolicitudesCancelacion_AdminProcesadorID ON dbo.SolicitudesCancelacion (AdminProcesadorID) WHERE AdminProcesadorID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_SolicitudesCancelacion_EstadoSolicitudID ON dbo.SolicitudesCancelacion (EstadoSolicitudID);

-- =============================================================================================
-- 6. BITÁCORA
-- =============================================================================================
CREATE TABLE dbo.LogActividad (
    LogID           BIGINT         NOT NULL IDENTITY(1,1),
    UsuarioID       INT            NULL,
    Accion          NVARCHAR(50)   NOT NULL,
    EntidadAfectada NVARCHAR(50)   NOT NULL,
    Descripcion     NVARCHAR(500)  NULL,
    FechaHora       DATETIME2(0)   NOT NULL CONSTRAINT DF_LogActividad_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_LogActividad          PRIMARY KEY (LogID),
    CONSTRAINT FK_LogActividad_Usuarios FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuarios (UsuarioID)
);
CREATE NONCLUSTERED INDEX IX_LogActividad_UsuarioID ON dbo.LogActividad (UsuarioID) WHERE UsuarioID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_LogActividad_FechaHora ON dbo.LogActividad (FechaHora DESC);

-- =============================================================================================
-- 7. CONFIRMACIÓN DE CORREO (soporte de signup/login)
-- =============================================================================================
CREATE TABLE dbo.ConfirmacionesCorreo (
    ConfirmacionID INT           NOT NULL IDENTITY(1,1),
    UsuarioID      INT           NOT NULL,
    Token          NVARCHAR(100) NOT NULL,
    FechaCreacion  DATETIME2(0)  NOT NULL CONSTRAINT DF_ConfirmacionesCorreo_Creacion DEFAULT (SYSUTCDATETIME()),
    FechaExpira    DATETIME2(0)  NOT NULL,
    Usado          BIT           NOT NULL CONSTRAINT DF_ConfirmacionesCorreo_Usado DEFAULT (0),
    FechaUso       DATETIME2(0)  NULL,
    CONSTRAINT PK_ConfirmacionesCorreo          PRIMARY KEY (ConfirmacionID),
    CONSTRAINT UQ_ConfirmacionesCorreo_Token    UNIQUE (Token),
    CONSTRAINT FK_ConfirmacionesCorreo_Usuarios FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT CK_ConfirmacionesCorreo_Fechas   CHECK (FechaExpira > FechaCreacion)
);
CREATE NONCLUSTERED INDEX IX_ConfirmacionesCorreo_UsuarioID ON dbo.ConfirmacionesCorreo (UsuarioID);

-- =============================================================================================
-- 8. SEED (catálogos)
-- =============================================================================================
INSERT INTO dbo.Roles (RolID, Codigo, Descripcion) VALUES
    (1, N'ADMIN',     N'Administrador de la plataforma'),
    (2, N'ASISTENTE', N'Asistente / participante');

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

INSERT INTO dbo.Dias (DiaID, Nombre, Abreviatura) VALUES
    (1, N'Lunes',     N'LUN'),
    (2, N'Martes',    N'MAR'),
    (3, N'Miércoles', N'MIE'),
    (4, N'Jueves',    N'JUE'),
    (5, N'Viernes',   N'VIE'),
    (6, N'Sábado',    N'SAB'),
    (7, N'Domingo',   N'DOM');

INSERT INTO dbo.Horarios (HorarioID, HoraInicio, HoraFin, Etiqueta) VALUES
    (1, '08:00', '09:30', N'08:00-09:30'),
    (2, '09:30', '11:00', N'09:30-11:00'),
    (3, '11:00', '12:30', N'11:00-12:30'),
    (4, '13:30', '15:00', N'13:30-15:00'),
    (5, '15:00', '16:30', N'15:00-16:30'),
    (6, '16:30', '18:00', N'16:30-18:00');

-- =============================================================================================
-- 9. VERIFICACIÓN (deben salir 22 tablas y 27 FKs)
-- =============================================================================================
SELECT TABLE_NAME AS Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = N'BASE TABLE'
ORDER BY TABLE_NAME;

SELECT
    OBJECT_NAME(fk.parent_object_id)     AS TablaHijo,
    fk.name                              AS NombreFK,
    OBJECT_NAME(fk.referenced_object_id) AS TablaPadre
FROM sys.foreign_keys fk
ORDER BY TablaHijo, NombreFK;
