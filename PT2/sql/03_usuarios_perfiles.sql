-- =============================================================================================
-- 03 · USUARIOS Y PERFILES  ·  TRACKFLOW-HUB
-- =============================================================================================
-- Patrón TABLA BASE + SUBTIPOS: Usuarios guarda lo común a los 4 roles (auth, estado de cuenta);
-- cada rol con datos propios cuelga 1:1 en su tabla de perfil, con UsuarioID como PK *y* FK.
-- Así evitamos una tabla Usuarios llena de columnas NULL (un operador tiene DPI/zona/género; una
-- empresa, NIT/licencia; un cliente, dirección). El ADMIN no necesita perfil aparte (datos a criterio).
-- PK con IDENTITY en Usuarios; borrado lógico vía EstadoCuentaID (no DELETE).
-- Requiere: 02_lookups.sql  ·  Correr con Alt+X (⌥X).
-- =============================================================================================

USE TrackFlow;

-- ----------------- Usuarios (tabla base: identidad y acceso de los 4 roles) -----------------
CREATE TABLE dbo.Usuarios (
    UsuarioID              INT            NOT NULL IDENTITY(1,1),
    RolID                  TINYINT        NOT NULL,
    Correo                 NVARCHAR(150)  NOT NULL,
    Contrasena             NVARCHAR(255)  NOT NULL,                -- hash, nunca texto plano
    CorreoConfirmado       BIT            NOT NULL CONSTRAINT DF_Usuarios_CorreoConf DEFAULT (0),
    EstadoCuentaID         TINYINT        NOT NULL CONSTRAINT DF_Usuarios_Estado DEFAULT (1),  -- 1 = ACTIVA
    MotivoVeto             NVARCHAR(300)  NULL,                    -- obligatorio al vetar (lo exige el backend)
    RequiereCambioPassword BIT            NOT NULL CONSTRAINT DF_Usuarios_ReqPwd DEFAULT (0),   -- operador con contraseña temporal
    FechaRegistro          DATETIME2(0)   NOT NULL CONSTRAINT DF_Usuarios_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Usuarios               PRIMARY KEY (UsuarioID),
    CONSTRAINT UQ_Usuarios_Correo        UNIQUE (Correo),
    CONSTRAINT FK_Usuarios_Roles         FOREIGN KEY (RolID)          REFERENCES dbo.Roles (RolID),
    CONSTRAINT FK_Usuarios_EstadosCuenta FOREIGN KEY (EstadoCuentaID) REFERENCES dbo.EstadosCuenta (EstadoCuentaID),
    CONSTRAINT CK_Usuarios_Correo        CHECK (Correo LIKE N'%_@_%._%')
);
CREATE NONCLUSTERED INDEX IX_Usuarios_RolID          ON dbo.Usuarios (RolID);
CREATE NONCLUSTERED INDEX IX_Usuarios_EstadoCuentaID ON dbo.Usuarios (EstadoCuentaID);

-- ----------------- PerfilCliente (subtipo 1:1 de Usuarios; rol CLIENTE) -----------------
CREATE TABLE dbo.PerfilCliente (
    UsuarioID       INT            NOT NULL,                       -- PK y FK a la vez (1:1)
    Nombre          NVARCHAR(100)  NOT NULL,
    Apellido        NVARCHAR(100)  NOT NULL,
    Telefono        NVARCHAR(30)   NOT NULL,
    DireccionOrigen NVARCHAR(300)  NULL,                           -- dirección de origen predeterminada
    CONSTRAINT PK_PerfilCliente          PRIMARY KEY (UsuarioID),
    CONSTRAINT FK_PerfilCliente_Usuarios FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuarios (UsuarioID)
);

-- ----------------- PerfilOperador (subtipo 1:1; rol OPERADOR) -----------------
CREATE TABLE dbo.PerfilOperador (
    UsuarioID         INT            NOT NULL,
    Nombre            NVARCHAR(100)  NOT NULL,
    Apellido          NVARCHAR(100)  NOT NULL,
    DpiCui            NVARCHAR(20)   NOT NULL,
    Telefono          NVARCHAR(30)   NOT NULL,
    TelefonoRespaldo  NVARCHAR(30)   NULL,
    Fotografia        NVARCHAR(300)  NOT NULL,
    ZonaOperacionID   TINYINT        NOT NULL,
    GeneroID          TINYINT        NOT NULL,
    EstadoSolicitudID TINYINT        NOT NULL CONSTRAINT DF_PerfilOperador_Estado DEFAULT (1),  -- 1 = PENDIENTE
    CONSTRAINT PK_PerfilOperador                   PRIMARY KEY (UsuarioID),
    CONSTRAINT UQ_PerfilOperador_DpiCui            UNIQUE (DpiCui),
    CONSTRAINT FK_PerfilOperador_Usuarios          FOREIGN KEY (UsuarioID)         REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_PerfilOperador_Zonas             FOREIGN KEY (ZonaOperacionID)   REFERENCES dbo.Zonas (ZonaID),
    CONSTRAINT FK_PerfilOperador_Generos           FOREIGN KEY (GeneroID)          REFERENCES dbo.Generos (GeneroID),
    CONSTRAINT FK_PerfilOperador_EstadosSolicitud  FOREIGN KEY (EstadoSolicitudID) REFERENCES dbo.EstadosSolicitud (EstadoSolicitudID)
);
CREATE NONCLUSTERED INDEX IX_PerfilOperador_ZonaOperacionID   ON dbo.PerfilOperador (ZonaOperacionID);
CREATE NONCLUSTERED INDEX IX_PerfilOperador_GeneroID          ON dbo.PerfilOperador (GeneroID);
CREATE NONCLUSTERED INDEX IX_PerfilOperador_EstadoSolicitudID ON dbo.PerfilOperador (EstadoSolicitudID);

-- ----------------- PerfilEmpresa (subtipo 1:1; rol EMPRESA) -----------------
CREATE TABLE dbo.PerfilEmpresa (
    UsuarioID         INT            NOT NULL,
    NombreEmpresa     NVARCHAR(150)  NOT NULL,
    Telefono          NVARCHAR(30)   NOT NULL,
    TelefonoRespaldo  NVARCHAR(30)   NULL,
    Nit               NVARCHAR(20)   NOT NULL,
    NumeroLicencia    NVARCHAR(50)   NOT NULL,
    EstadoSolicitudID TINYINT        NOT NULL CONSTRAINT DF_PerfilEmpresa_Estado DEFAULT (1),  -- 1 = PENDIENTE
    CONSTRAINT PK_PerfilEmpresa                  PRIMARY KEY (UsuarioID),
    CONSTRAINT UQ_PerfilEmpresa_Nit              UNIQUE (Nit),
    CONSTRAINT UQ_PerfilEmpresa_Licencia         UNIQUE (NumeroLicencia),
    CONSTRAINT FK_PerfilEmpresa_Usuarios         FOREIGN KEY (UsuarioID)         REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_PerfilEmpresa_EstadosSolicitud FOREIGN KEY (EstadoSolicitudID) REFERENCES dbo.EstadosSolicitud (EstadoSolicitudID)
);
CREATE NONCLUSTERED INDEX IX_PerfilEmpresa_EstadoSolicitudID ON dbo.PerfilEmpresa (EstadoSolicitudID);
