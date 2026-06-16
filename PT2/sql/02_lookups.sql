-- =============================================================================================
-- 02 · TABLAS LOOKUP / CATÁLOGO  ·  TRACKFLOW-HUB
-- =============================================================================================
-- Catálogos de rol, género, estados (cuenta/solicitud/reserva/pago/reporte) + Zonas geográficas.
-- No dependen de ninguna otra tabla -> se crean primero.
-- PK explícita (NO IDENTITY): los IDs se siembran a mano y son estables/citables en código.
-- Requiere: 01_database.sql  ·  Correr con Alt+X (⌥X).
-- =============================================================================================

USE TrackFlow;

-- ----------------- Roles (los 4 tipos de usuario del enunciado) -----------------
CREATE TABLE dbo.Roles (
    RolID       TINYINT       NOT NULL,
    Codigo      NVARCHAR(20)  NOT NULL,
    Descripcion NVARCHAR(100) NULL,
    CONSTRAINT PK_Roles     PRIMARY KEY (RolID),
    CONSTRAINT UQ_Roles_Cod UNIQUE (Codigo)
);

-- ----------------- Generos (catálogo del campo "Género" del operador) -----------------
CREATE TABLE dbo.Generos (
    GeneroID    TINYINT       NOT NULL,
    Codigo      NVARCHAR(15)  NOT NULL,
    Descripcion NVARCHAR(50)  NULL,
    CONSTRAINT PK_Generos     PRIMARY KEY (GeneroID),
    CONSTRAINT UQ_Generos_Cod UNIQUE (Codigo)
);

-- ----------------- Estados (misma estructura; EsTerminal marca el estado "cerrado") -----------------
CREATE TABLE dbo.EstadosCuenta (
    EstadoCuentaID TINYINT       NOT NULL,
    Codigo         NVARCHAR(20)  NOT NULL,
    Descripcion    NVARCHAR(100) NULL,
    EsTerminal     BIT           NOT NULL CONSTRAINT DF_EstadosCuenta_Terminal DEFAULT (0),
    CONSTRAINT PK_EstadosCuenta     PRIMARY KEY (EstadoCuentaID),
    CONSTRAINT UQ_EstadosCuenta_Cod UNIQUE (Codigo)
);

-- Cubre la aprobación de registro (operador/empresa) y las solicitudes de cambio de perfil.
CREATE TABLE dbo.EstadosSolicitud (
    EstadoSolicitudID TINYINT       NOT NULL,
    Codigo            NVARCHAR(20)  NOT NULL,
    Descripcion       NVARCHAR(100) NULL,
    EsTerminal        BIT           NOT NULL CONSTRAINT DF_EstadosSolicitud_Terminal DEFAULT (0),
    CONSTRAINT PK_EstadosSolicitud     PRIMARY KEY (EstadoSolicitudID),
    CONSTRAINT UQ_EstadosSolicitud_Cod UNIQUE (Codigo)
);

CREATE TABLE dbo.EstadosReserva (
    EstadoReservaID TINYINT       NOT NULL,
    Codigo          NVARCHAR(20)  NOT NULL,
    Descripcion     NVARCHAR(100) NULL,
    EsTerminal      BIT           NOT NULL CONSTRAINT DF_EstadosReserva_Terminal DEFAULT (0),
    CONSTRAINT PK_EstadosReserva     PRIMARY KEY (EstadoReservaID),
    CONSTRAINT UQ_EstadosReserva_Cod UNIQUE (Codigo)
);

CREATE TABLE dbo.EstadosPago (
    EstadoPagoID TINYINT       NOT NULL,
    Codigo       NVARCHAR(20)  NOT NULL,
    Descripcion  NVARCHAR(100) NULL,
    EsTerminal   BIT           NOT NULL CONSTRAINT DF_EstadosPago_Terminal DEFAULT (0),
    CONSTRAINT PK_EstadosPago     PRIMARY KEY (EstadoPagoID),
    CONSTRAINT UQ_EstadosPago_Cod UNIQUE (Codigo)
);

CREATE TABLE dbo.EstadosReporte (
    EstadoReporteID TINYINT       NOT NULL,
    Codigo          NVARCHAR(20)  NOT NULL,
    Descripcion     NVARCHAR(100) NULL,
    EsTerminal      BIT           NOT NULL CONSTRAINT DF_EstadosReporte_Terminal DEFAULT (0),
    CONSTRAINT PK_EstadosReporte     PRIMARY KEY (EstadoReporteID),
    CONSTRAINT UQ_EstadosReporte_Cod UNIQUE (Codigo)
);

-- ----------------- Zonas (catálogo geográfico PREDEFINIDO) -----------------
-- Cobertura de envíos, zona de operación del operador y origen/destino de rutas.
-- PK a mano: el frontend elige la zona por id (no texto libre). Ampliá filas en 08_seeds.sql.
CREATE TABLE dbo.Zonas (
    ZonaID TINYINT       NOT NULL,
    Nombre NVARCHAR(100) NOT NULL,
    Tipo   NVARCHAR(15)  NOT NULL,
    CONSTRAINT PK_Zonas        PRIMARY KEY (ZonaID),
    CONSTRAINT UQ_Zonas_Nombre UNIQUE (Nombre),
    CONSTRAINT CK_Zonas_Tipo   CHECK (Tipo IN (N'NACIONAL', N'INTERNACIONAL'))
);
