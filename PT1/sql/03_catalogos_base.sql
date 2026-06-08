-- =============================================================================================
-- 03 · CATÁLOGOS BASE  ·  EVENTCORE
-- =============================================================================================
-- Usuarios, Ponentes, Salas, TiposEntrada. Solo Usuarios tiene FK (-> Roles).
-- PK con IDENTITY: el motor genera el id autonumérico (datos de negocio, no catálogo sembrado).
-- Borrado lógico: los maestros se desactivan (Activo = 0), no se borran.
-- Requiere: 02_lookups.sql  ·  Correr con Alt+X (⌥X).
-- =============================================================================================

USE EventCore;

-- ----------------- Usuarios (Administrador / Asistente, distinguidos por RolID) -----------------
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

-- ----------------- Ponentes -----------------
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

-- ----------------- Salas -----------------
CREATE TABLE dbo.Salas (
    SalaID     INT            NOT NULL IDENTITY(1,1),
    Nombre     NVARCHAR(100)  NOT NULL,
    Ubicacion  NVARCHAR(200)  NOT NULL,
    Capacidad  INT            NOT NULL,
    Activo     BIT            NOT NULL CONSTRAINT DF_Salas_Activo DEFAULT (1),
    CONSTRAINT PK_Salas           PRIMARY KEY (SalaID),
    CONSTRAINT CK_Salas_Capacidad CHECK (Capacidad > 0)
);

-- ----------------- TiposEntrada (tarifas del enunciado) -----------------
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
