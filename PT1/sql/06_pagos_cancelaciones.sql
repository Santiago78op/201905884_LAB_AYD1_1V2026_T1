-- =============================================================================================
-- 06 · PAGOS Y CANCELACIONES  ·  EVENTCORE
-- =============================================================================================
-- Tarjetas, Pagos y SolicitudesCancelacion.
-- Requiere: 03_catalogos_base.sql y 05_inscripciones.sql  ·  Correr con Alt+X (⌥X).
-- =============================================================================================

USE Cumbre;

-- ----------------- Tarjetas -----------------
CREATE TABLE dbo.Tarjetas (
    TarjetaID         INT            NOT NULL IDENTITY(1,1),
    AsistenteID       INT            NOT NULL,
    Titular           NVARCHAR(150)  NOT NULL,
    NumeroEnmascarado NVARCHAR(25)   NOT NULL,               -- solo últimos dígitos, nunca completo
    Tipo              NVARCHAR(10)   NOT NULL,
    FechaExpiracion   NVARCHAR(7)    NOT NULL,               -- formato MM/AAAA
    Activo            BIT            NOT NULL CONSTRAINT DF_Tarjetas_Activo DEFAULT (1),
    CONSTRAINT PK_Tarjetas          PRIMARY KEY (TarjetaID),
    CONSTRAINT FK_Tarjetas_Usuarios FOREIGN KEY (AsistenteID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT CK_Tarjetas_Tipo     CHECK (Tipo IN (N'DEBITO', N'CREDITO'))
);
CREATE NONCLUSTERED INDEX IX_Tarjetas_AsistenteID ON dbo.Tarjetas (AsistenteID);

-- ----------------- Pagos -----------------
CREATE TABLE dbo.Pagos (
    PagoID         INT            NOT NULL IDENTITY(1,1),
    InscripcionID  INT            NOT NULL,
    TarjetaID      INT            NULL,                      -- NULL si fue transferencia
    AdminRevisorID INT            NULL,                      -- admin que revisa la transferencia
    Monto          DECIMAL(10,2)  NOT NULL,
    Metodo         NVARCHAR(15)   NOT NULL,
    EstadoPagoID   TINYINT        NOT NULL CONSTRAINT DF_Pagos_Estado DEFAULT (1),  -- 1 = PENDIENTE
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

-- ----------------- SolicitudesCancelacion -----------------
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
