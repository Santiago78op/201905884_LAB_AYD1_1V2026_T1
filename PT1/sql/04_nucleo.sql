-- =============================================================================================
-- 04 · NÚCLEO DEL EVENTO  ·  EVENTCORE
-- =============================================================================================
-- Eventos -> Sesiones -> MaterialesRecurso.
-- Sesiones se agenda por id: DiaID (-> Dias) y HorarioID (-> Horarios).
-- Enums fijos (Modalidad, Categoria…) van como CHECK; los estados van por FK a lookup.
-- Requiere: 02_lookups.sql y 03_catalogos_base.sql  ·  Correr con Alt+X (⌥X).
-- =============================================================================================

USE EventCore;

-- ----------------- Eventos -----------------
CREATE TABLE dbo.Eventos (
    EventoID             INT            NOT NULL IDENTITY(1,1),
    AdminID              INT            NOT NULL,             -- FK -> Usuarios (rol ADMIN)
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
    EstadoEventoID       TINYINT        NOT NULL CONSTRAINT DF_Eventos_Estado DEFAULT (1),  -- 1 = BORRADOR
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

-- ----------------- Sesiones (agendada por DiaID + HorarioID) -----------------
CREATE TABLE dbo.Sesiones (
    SesionID         INT            NOT NULL IDENTITY(1,1),
    EventoID         INT            NOT NULL,
    PonenteID        INT            NOT NULL,
    SalaID           INT            NULL,                     -- NULL si la sesión es por enlace (virtual)
    DiaID            TINYINT        NOT NULL,                 -- el frontend elige el día por id
    HorarioID        TINYINT        NOT NULL,                 -- el frontend elige el bloque por id
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

-- ----------------- MaterialesRecurso (entidad débil de Sesión, ON DELETE CASCADE) -----------------
CREATE TABLE dbo.MaterialesRecurso (
    MaterialID INT            NOT NULL IDENTITY(1,1),
    SesionID   INT            NOT NULL,
    Nombre     NVARCHAR(200)  NOT NULL,
    UrlArchivo NVARCHAR(300)  NOT NULL,
    CONSTRAINT PK_MaterialesRecurso          PRIMARY KEY (MaterialID),
    CONSTRAINT FK_MaterialesRecurso_Sesiones FOREIGN KEY (SesionID) REFERENCES dbo.Sesiones (SesionID) ON DELETE CASCADE
);
CREATE NONCLUSTERED INDEX IX_MaterialesRecurso_SesionID ON dbo.MaterialesRecurso (SesionID);
