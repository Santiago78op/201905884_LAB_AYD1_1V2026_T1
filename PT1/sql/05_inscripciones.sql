-- =============================================================================================
-- 05 · INSCRIPCIONES  ·  EVENTCORE
-- =============================================================================================
-- Inscripciones, la tabla puente InscripcionSesion (resuelve la N:M con Sesiones) y CodigosInvitacion.
-- Requiere: 03_catalogos_base.sql y 04_nucleo.sql  ·  Correr con Alt+X (⌥X).
-- =============================================================================================

USE EventCore;

-- ----------------- Inscripciones -----------------
CREATE TABLE dbo.Inscripciones (
    InscripcionID       INT            NOT NULL IDENTITY(1,1),
    AsistenteID         INT            NOT NULL,             -- FK -> Usuarios (rol ASISTENTE)
    EventoID            INT            NOT NULL,
    TipoEntradaID       TINYINT        NOT NULL,
    FechaInscripcion    DATETIME2(0)   NOT NULL CONSTRAINT DF_Inscripciones_Fecha DEFAULT (SYSUTCDATETIME()),
    EstadoInscripcionID TINYINT        NOT NULL CONSTRAINT DF_Inscripciones_Estado DEFAULT (1),  -- 1 = PENDIENTE
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

-- ----------------- InscripcionSesion (TABLA PUENTE N:M; PK compuesta evita duplicar el par) -----------------
CREATE TABLE dbo.InscripcionSesion (
    InscripcionID INT          NOT NULL,
    SesionID      INT          NOT NULL,
    FechaRegistro DATETIME2(0) NOT NULL CONSTRAINT DF_InscripcionSesion_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_InscripcionSesion               PRIMARY KEY (InscripcionID, SesionID),
    CONSTRAINT FK_InscripcionSesion_Inscripciones FOREIGN KEY (InscripcionID) REFERENCES dbo.Inscripciones (InscripcionID),
    CONSTRAINT FK_InscripcionSesion_Sesiones      FOREIGN KEY (SesionID)      REFERENCES dbo.Sesiones (SesionID)
);
CREATE NONCLUSTERED INDEX IX_InscripcionSesion_SesionID ON dbo.InscripcionSesion (SesionID);

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
CREATE NONCLUSTERED INDEX IX_CodigosInvitacion_EventoID    ON dbo.CodigosInvitacion (EventoID);
CREATE NONCLUSTERED INDEX IX_CodigosInvitacion_AsistenteID ON dbo.CodigosInvitacion (AsistenteID) WHERE AsistenteID IS NOT NULL;
