-- =============================================================================================
-- 07 · SOPORTE (auth, solicitudes, reuniones, notificaciones, bitácora)  ·  TRACKFLOW-HUB
-- =============================================================================================
-- Tablas transversales que dependen solo de Usuarios:
--   Tokens                   -> confirmación de correo (6 chars), 2FA del admin (2 min), pwd temporal
--   SolicitudesCambioPerfil  -> operador/empresa piden cambios; el admin aprueba/rechaza
--   ReunionesVirtuales       -> reunión empresa <-> admin antes de aceptar a la empresa
--   Notificaciones           -> avisos en la vista del usuario / correo
--   LogActividad             -> bitácora para los reportes de logs del admin (BIGINT: crece mucho)
-- Requiere: 03_usuarios_perfiles.sql (Usuarios) y 02_lookups.sql (EstadosSolicitud)  ·  Alt+X (⌥X).
-- =============================================================================================

USE TrackFlow;

-- ----------------- Tokens (un solo lugar para los 3 tipos de token del enunciado) -----------------
CREATE TABLE dbo.Tokens (
    TokenID       INT            NOT NULL IDENTITY(1,1),
    UsuarioID     INT            NOT NULL,
    Tipo          NVARCHAR(25)   NOT NULL,
    Valor         NVARCHAR(100)  NOT NULL,                         -- 6 chars (confirmación) o token 2FA
    FechaCreacion DATETIME2(0)   NOT NULL CONSTRAINT DF_Tokens_Creacion DEFAULT (SYSUTCDATETIME()),
    FechaExpira   DATETIME2(0)   NOT NULL,                         -- 2FA = +2 min ; confirmación = +24 h (lo fija el backend)
    Usado         BIT            NOT NULL CONSTRAINT DF_Tokens_Usado DEFAULT (0),
    FechaUso      DATETIME2(0)   NULL,
    CONSTRAINT PK_Tokens           PRIMARY KEY (TokenID),
    CONSTRAINT FK_Tokens_Usuarios  FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT CK_Tokens_Tipo      CHECK (Tipo IN (N'CONFIRMACION_CORREO', N'DOBLE_FACTOR_2FA', N'PASSWORD_TEMPORAL')),
    CONSTRAINT CK_Tokens_Fechas    CHECK (FechaExpira > FechaCreacion)
);
CREATE NONCLUSTERED INDEX IX_Tokens_UsuarioID ON dbo.Tokens (UsuarioID);
CREATE NONCLUSTERED INDEX IX_Tokens_Valor     ON dbo.Tokens (Valor);

-- ----------------- SolicitudesCambioPerfil (cambios de perfil sujetos a aprobación del admin) -----------------
CREATE TABLE dbo.SolicitudesCambioPerfil (
    SolicitudID       INT            NOT NULL IDENTITY(1,1),
    UsuarioID         INT            NOT NULL,                     -- operador o empresa
    DatosPropuestos   NVARCHAR(MAX)  NOT NULL,                     -- JSON con los campos a cambiar
    EstadoSolicitudID TINYINT        NOT NULL CONSTRAINT DF_SolicitudesCambioPerfil_Estado DEFAULT (1),  -- 1 = PENDIENTE
    AdminRevisorID    INT            NULL,                         -- NULL hasta que un admin la resuelve
    FechaSolicitud    DATETIME2(0)   NOT NULL CONSTRAINT DF_SolicitudesCambioPerfil_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_SolicitudesCambioPerfil                  PRIMARY KEY (SolicitudID),
    CONSTRAINT FK_SolicitudesCambioPerfil_Usuario          FOREIGN KEY (UsuarioID)         REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_SolicitudesCambioPerfil_Admin            FOREIGN KEY (AdminRevisorID)    REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_SolicitudesCambioPerfil_EstadosSolicitud FOREIGN KEY (EstadoSolicitudID) REFERENCES dbo.EstadosSolicitud (EstadoSolicitudID)
);
CREATE NONCLUSTERED INDEX IX_SolicitudesCambioPerfil_UsuarioID         ON dbo.SolicitudesCambioPerfil (UsuarioID);
CREATE NONCLUSTERED INDEX IX_SolicitudesCambioPerfil_AdminRevisorID    ON dbo.SolicitudesCambioPerfil (AdminRevisorID) WHERE AdminRevisorID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_SolicitudesCambioPerfil_EstadoSolicitudID ON dbo.SolicitudesCambioPerfil (EstadoSolicitudID);

-- ----------------- ReunionesVirtuales (empresa de transporte <-> admin, paso previo a aceptarla) -----------------
CREATE TABLE dbo.ReunionesVirtuales (
    ReunionID INT            NOT NULL IDENTITY(1,1),
    EmpresaID INT            NOT NULL,
    AdminID   INT            NULL,                                 -- el admin que agenda (NULL hasta agendarse)
    FechaHora DATETIME2(0)   NOT NULL,
    Enlace    NVARCHAR(300)  NOT NULL,
    Estado    NVARCHAR(15)   NOT NULL CONSTRAINT DF_ReunionesVirtuales_Estado DEFAULT (N'AGENDADA'),
    CONSTRAINT PK_ReunionesVirtuales          PRIMARY KEY (ReunionID),
    CONSTRAINT FK_ReunionesVirtuales_Empresa  FOREIGN KEY (EmpresaID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_ReunionesVirtuales_Admin    FOREIGN KEY (AdminID)   REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT CK_ReunionesVirtuales_Estado   CHECK (Estado IN (N'AGENDADA', N'REALIZADA', N'CANCELADA'))
);
CREATE NONCLUSTERED INDEX IX_ReunionesVirtuales_EmpresaID ON dbo.ReunionesVirtuales (EmpresaID);
CREATE NONCLUSTERED INDEX IX_ReunionesVirtuales_AdminID   ON dbo.ReunionesVirtuales (AdminID) WHERE AdminID IS NOT NULL;

-- ----------------- Notificaciones (aviso en la vista principal del usuario) -----------------
CREATE TABLE dbo.Notificaciones (
    NotificacionID INT            NOT NULL IDENTITY(1,1),
    UsuarioID      INT            NOT NULL,
    Tipo           NVARCHAR(50)   NOT NULL,
    Mensaje        NVARCHAR(500)  NOT NULL,
    Leida          BIT            NOT NULL CONSTRAINT DF_Notificaciones_Leida DEFAULT (0),
    Fecha          DATETIME2(0)   NOT NULL CONSTRAINT DF_Notificaciones_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Notificaciones          PRIMARY KEY (NotificacionID),
    CONSTRAINT FK_Notificaciones_Usuarios FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuarios (UsuarioID)
);
CREATE NONCLUSTERED INDEX IX_Notificaciones_UsuarioID ON dbo.Notificaciones (UsuarioID);

-- ----------------- LogActividad (bitácora; respalda los reportes de logs del admin) -----------------
CREATE TABLE dbo.LogActividad (
    LogID           BIGINT         NOT NULL IDENTITY(1,1),
    UsuarioID       INT            NULL,                           -- NULL si la acción la hace el sistema
    Accion          NVARCHAR(50)   NOT NULL,
    EntidadAfectada NVARCHAR(50)   NOT NULL,
    Descripcion     NVARCHAR(500)  NULL,
    FechaHora       DATETIME2(0)   NOT NULL CONSTRAINT DF_LogActividad_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_LogActividad          PRIMARY KEY (LogID),
    CONSTRAINT FK_LogActividad_Usuarios FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuarios (UsuarioID)
);
CREATE NONCLUSTERED INDEX IX_LogActividad_UsuarioID ON dbo.LogActividad (UsuarioID) WHERE UsuarioID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_LogActividad_FechaHora ON dbo.LogActividad (FechaHora DESC);
