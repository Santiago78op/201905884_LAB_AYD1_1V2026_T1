-- =============================================================================================
-- 06 · CALIFICACIONES, CUPONES, REPORTES Y SANCIONES  ·  TRACKFLOW-HUB
-- =============================================================================================
-- Interacción posterior a la reserva: Calificaciones, Cupones + CuponesCanjeados,
-- Reportes + EvidenciasReporte y Sanciones (las aplica el admin a un usuario infractor).
-- Reportes referencia DOS veces a Usuarios (reportante y reportado): admin/operador/cliente.
-- Requiere: 03_usuarios_perfiles.sql y 05_reservaciones.sql  ·  Correr con Alt+X (⌥X).
-- =============================================================================================

USE TrackFlow;

-- ----------------- Calificaciones (una por reserva; el proveedor puede responder) -----------------
CREATE TABLE dbo.Calificaciones (
    CalificacionID     INT            NOT NULL IDENTITY(1,1),
    ReservaID          INT            NOT NULL,
    ClienteID          INT            NOT NULL,
    Puntuacion         TINYINT        NOT NULL,
    Comentario         NVARCHAR(500)  NULL,
    RespuestaProveedor NVARCHAR(500)  NULL,                        -- el operador responde el comentario (NULL hasta entonces)
    Fecha              DATETIME2(0)   NOT NULL CONSTRAINT DF_Calificaciones_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Calificaciones                PRIMARY KEY (CalificacionID),
    CONSTRAINT UQ_Calificaciones_Reserva        UNIQUE (ReservaID),               -- 1 calificación por reserva
    CONSTRAINT FK_Calificaciones_Reservaciones  FOREIGN KEY (ReservaID) REFERENCES dbo.Reservaciones (ReservaID),
    CONSTRAINT FK_Calificaciones_Usuarios       FOREIGN KEY (ClienteID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT CK_Calificaciones_Puntuacion     CHECK (Puntuacion BETWEEN 1 AND 5)
);
CREATE NONCLUSTERED INDEX IX_Calificaciones_ClienteID ON dbo.Calificaciones (ClienteID);

-- ----------------- Cupones (los emite un operador o una empresa) -----------------
CREATE TABLE dbo.Cupones (
    CuponID         INT            NOT NULL IDENTITY(1,1),
    EmisorID        INT            NOT NULL,                       -- FK -> Usuarios (rol OPERADOR o EMPRESA)
    Codigo          NVARCHAR(40)   NOT NULL,
    TipoDescuento   NVARCHAR(12)   NOT NULL,
    ValorDescuento  DECIMAL(10,2)  NOT NULL,
    Condiciones     NVARCHAR(500)  NULL,
    FechaInicio     DATETIME2(0)   NOT NULL,
    FechaFin        DATETIME2(0)   NOT NULL,
    Activo          BIT            NOT NULL CONSTRAINT DF_Cupones_Activo DEFAULT (1),
    CONSTRAINT PK_Cupones            PRIMARY KEY (CuponID),
    CONSTRAINT UQ_Cupones_Codigo     UNIQUE (Codigo),
    CONSTRAINT FK_Cupones_Usuarios   FOREIGN KEY (EmisorID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT CK_Cupones_TipoDesc   CHECK (TipoDescuento IN (N'PORCENTAJE', N'MONTO')),
    CONSTRAINT CK_Cupones_Valor      CHECK (ValorDescuento >= 0),
    CONSTRAINT CK_Cupones_Fechas     CHECK (FechaFin >= FechaInicio)
);
CREATE NONCLUSTERED INDEX IX_Cupones_EmisorID ON dbo.Cupones (EmisorID);

-- ----------------- CuponesCanjeados (qué cliente canjeó qué cupón, en qué reserva) -----------------
CREATE TABLE dbo.CuponesCanjeados (
    CanjeID    INT            NOT NULL IDENTITY(1,1),
    CuponID    INT            NOT NULL,
    ClienteID  INT            NOT NULL,
    ReservaID  INT            NULL,                                -- NULL si solo se guardó, aún sin aplicar
    FechaCanje DATETIME2(0)   NOT NULL CONSTRAINT DF_CuponesCanjeados_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_CuponesCanjeados                PRIMARY KEY (CanjeID),
    CONSTRAINT UQ_CuponesCanjeados_CuponCliente   UNIQUE (CuponID, ClienteID),     -- un cliente canjea un cupón una vez
    CONSTRAINT FK_CuponesCanjeados_Cupones        FOREIGN KEY (CuponID)   REFERENCES dbo.Cupones (CuponID),
    CONSTRAINT FK_CuponesCanjeados_Usuarios       FOREIGN KEY (ClienteID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_CuponesCanjeados_Reservaciones  FOREIGN KEY (ReservaID) REFERENCES dbo.Reservaciones (ReservaID)
);
CREATE NONCLUSTERED INDEX IX_CuponesCanjeados_ClienteID ON dbo.CuponesCanjeados (ClienteID);
CREATE NONCLUSTERED INDEX IX_CuponesCanjeados_ReservaID ON dbo.CuponesCanjeados (ReservaID) WHERE ReservaID IS NOT NULL;

-- ----------------- Reportes (denuncias: cliente<->operador; estados Enviado/En revisión/Aceptado/Rechazado) -----------------
CREATE TABLE dbo.Reportes (
    ReporteID       INT            NOT NULL IDENTITY(1,1),
    ReportanteID    INT            NOT NULL,                       -- quién reporta
    ReportadoID     INT            NOT NULL,                       -- a quién se reporta
    ReservaID       INT            NULL,                           -- reserva relacionada (si aplica)
    Tipo            NVARCHAR(12)   NOT NULL,
    Descripcion     NVARCHAR(MAX)  NOT NULL,
    EstadoReporteID TINYINT        NOT NULL CONSTRAINT DF_Reportes_Estado DEFAULT (1),  -- 1 = ENVIADO
    FechaReporte    DATETIME2(0)   NOT NULL CONSTRAINT DF_Reportes_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Reportes                  PRIMARY KEY (ReporteID),
    CONSTRAINT FK_Reportes_Reportante       FOREIGN KEY (ReportanteID)    REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_Reportes_Reportado        FOREIGN KEY (ReportadoID)     REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_Reportes_Reservaciones    FOREIGN KEY (ReservaID)       REFERENCES dbo.Reservaciones (ReservaID),
    CONSTRAINT FK_Reportes_EstadosReporte   FOREIGN KEY (EstadoReporteID) REFERENCES dbo.EstadosReporte (EstadoReporteID),
    CONSTRAINT CK_Reportes_Tipo             CHECK (Tipo IN (N'ENVIO', N'TRANSPORTE', N'CLIENTE')),
    CONSTRAINT CK_Reportes_Distintos        CHECK (ReportanteID <> ReportadoID)
);
CREATE NONCLUSTERED INDEX IX_Reportes_ReportanteID    ON dbo.Reportes (ReportanteID);
CREATE NONCLUSTERED INDEX IX_Reportes_ReportadoID     ON dbo.Reportes (ReportadoID);
CREATE NONCLUSTERED INDEX IX_Reportes_ReservaID       ON dbo.Reportes (ReservaID) WHERE ReservaID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_Reportes_EstadoReporteID ON dbo.Reportes (EstadoReporteID);

-- ----------------- EvidenciasReporte (fotos/vídeo adjuntos; entidad débil, ON DELETE CASCADE) -----------------
CREATE TABLE dbo.EvidenciasReporte (
    EvidenciaID INT            NOT NULL IDENTITY(1,1),
    ReporteID   INT            NOT NULL,
    UrlArchivo  NVARCHAR(300)  NOT NULL,
    Tipo        NVARCHAR(10)   NOT NULL,
    CONSTRAINT PK_EvidenciasReporte           PRIMARY KEY (EvidenciaID),
    CONSTRAINT FK_EvidenciasReporte_Reportes  FOREIGN KEY (ReporteID) REFERENCES dbo.Reportes (ReporteID) ON DELETE CASCADE,
    CONSTRAINT CK_EvidenciasReporte_Tipo      CHECK (Tipo IN (N'FOTO', N'VIDEO'))
);
CREATE NONCLUSTERED INDEX IX_EvidenciasReporte_ReporteID ON dbo.EvidenciasReporte (ReporteID);

-- ----------------- Sanciones (suspensión temporal o veto permanente; las aplica el admin) -----------------
CREATE TABLE dbo.Sanciones (
    SancionID   INT            NOT NULL IDENTITY(1,1),
    UsuarioID   INT            NOT NULL,                           -- sancionado
    ReporteID   INT            NULL,                               -- reporte que la originó (si aplica)
    AdminID     INT            NOT NULL,                           -- admin que sanciona
    Tipo        NVARCHAR(20)   NOT NULL,
    Motivo      NVARCHAR(300)  NOT NULL,
    FechaInicio DATETIME2(0)   NOT NULL CONSTRAINT DF_Sanciones_Inicio DEFAULT (SYSUTCDATETIME()),
    FechaFin    DATETIME2(0)   NULL,                               -- NULL si es permanente (veto)
    CONSTRAINT PK_Sanciones            PRIMARY KEY (SancionID),
    CONSTRAINT FK_Sanciones_Usuario    FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_Sanciones_Reportes   FOREIGN KEY (ReporteID) REFERENCES dbo.Reportes (ReporteID),
    CONSTRAINT FK_Sanciones_Admin      FOREIGN KEY (AdminID)   REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT CK_Sanciones_Tipo       CHECK (Tipo IN (N'SUSPENSION_TEMPORAL', N'VETO_PERMANENTE')),
    CONSTRAINT CK_Sanciones_Fechas     CHECK (FechaFin IS NULL OR FechaFin >= FechaInicio)
);
CREATE NONCLUSTERED INDEX IX_Sanciones_UsuarioID ON dbo.Sanciones (UsuarioID);
CREATE NONCLUSTERED INDEX IX_Sanciones_ReporteID ON dbo.Sanciones (ReporteID) WHERE ReporteID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_Sanciones_AdminID   ON dbo.Sanciones (AdminID);
