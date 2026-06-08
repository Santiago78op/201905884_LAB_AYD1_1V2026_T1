-- =============================================================================================
-- 02 · TABLAS LOOKUP / CATÁLOGO  ·  EVENTCORE
-- =============================================================================================
-- Catálogos de estados/rol + catálogos de agenda (Dias, Horarios).
-- No dependen de ninguna otra tabla -> se crean primero.
-- PK explícita (NO IDENTITY): los IDs se siembran a mano y son estables/citables en código.
-- Requiere: 01_database.sql  ·  Correr con Alt+X (⌥X).
-- =============================================================================================

USE EventCore;

-- ----------------- Roles -----------------
CREATE TABLE dbo.Roles (
    RolID       TINYINT       NOT NULL,
    Codigo      NVARCHAR(20)  NOT NULL,
    Descripcion NVARCHAR(100) NULL,
    CONSTRAINT PK_Roles     PRIMARY KEY (RolID),
    CONSTRAINT UQ_Roles_Cod UNIQUE (Codigo)
);

-- ----------------- Estados (misma estructura; EsTerminal marca el estado "cerrado") -----------------
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

-- ----------------- Dias (catálogo PREDEFINIDO: día de la semana, 7 filas fijas) -----------------
-- El frontend NO crea días: elige uno de los 7 ya sembrados por su DiaID.
CREATE TABLE dbo.Dias (
    DiaID       TINYINT       NOT NULL,                 -- 1 = Lunes … 7 = Domingo (ISO-8601)
    Nombre      NVARCHAR(15)  NOT NULL,
    Abreviatura NVARCHAR(3)   NOT NULL,
    CONSTRAINT PK_Dias        PRIMARY KEY (DiaID),
    CONSTRAINT UQ_Dias_Nombre UNIQUE (Nombre),
    CONSTRAINT CK_Dias_Rango  CHECK (DiaID BETWEEN 1 AND 7)
);

-- ----------------- Horarios (catálogo PREDEFINIDO: bloques de hora) -----------------
-- HoraInicio/HoraFin como TIME -> se puede calcular duración y validar el orden.
CREATE TABLE dbo.Horarios (
    HorarioID  TINYINT      NOT NULL,
    HoraInicio TIME(0)      NOT NULL,
    HoraFin    TIME(0)      NOT NULL,
    Etiqueta   NVARCHAR(20) NOT NULL,                   -- p.ej. '08:00-09:30' (para mostrar en UI)
    CONSTRAINT PK_Horarios          PRIMARY KEY (HorarioID),
    CONSTRAINT UQ_Horarios_Bloque   UNIQUE (HoraInicio, HoraFin),
    CONSTRAINT UQ_Horarios_Etiqueta UNIQUE (Etiqueta),
    CONSTRAINT CK_Horarios_Orden    CHECK (HoraFin > HoraInicio)
);
