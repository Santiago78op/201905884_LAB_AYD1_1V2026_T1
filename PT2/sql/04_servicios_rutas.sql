-- =============================================================================================
-- 04 · SERVICIOS DE ENVÍO Y RUTAS DE TRANSPORTE  ·  TRACKFLOW-HUB
-- =============================================================================================
-- Lo que ofrecen los proveedores: ServiciosEnvio (operador) + FotosServicio, y Rutas + Flota (empresa).
-- OperadorID/EmpresaID son FK -> Usuarios (que el rol sea el correcto lo valida el backend).
-- Borrado lógico: ServiciosEnvio.Activo; "suspender temporalmente" = Suspendido = 1.
-- Requiere: 02_lookups.sql (Zonas) y 03_usuarios_perfiles.sql (Usuarios)  ·  Correr con Alt+X (⌥X).
-- =============================================================================================

USE TrackFlow;

-- ----------------- ServiciosEnvio (los publica el operador logístico) -----------------
CREATE TABLE dbo.ServiciosEnvio (
    ServicioID       INT            NOT NULL IDENTITY(1,1),
    OperadorID       INT            NOT NULL,                      -- FK -> Usuarios (rol OPERADOR)
    ZonaCoberturaID  TINYINT        NOT NULL,
    CapacidadCargaKg DECIMAL(10,2)  NOT NULL,
    PrecioEnvio      DECIMAL(10,2)  NOT NULL,
    Descripcion      NVARCHAR(500)  NULL,
    Suspendido       BIT            NOT NULL CONSTRAINT DF_ServiciosEnvio_Suspendido DEFAULT (0),  -- suspensión temporal
    Activo           BIT            NOT NULL CONSTRAINT DF_ServiciosEnvio_Activo DEFAULT (1),       -- borrado lógico
    CONSTRAINT PK_ServiciosEnvio           PRIMARY KEY (ServicioID),
    CONSTRAINT FK_ServiciosEnvio_Usuarios  FOREIGN KEY (OperadorID)      REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_ServiciosEnvio_Zonas     FOREIGN KEY (ZonaCoberturaID) REFERENCES dbo.Zonas (ZonaID),
    CONSTRAINT CK_ServiciosEnvio_Capacidad CHECK (CapacidadCargaKg > 0),
    CONSTRAINT CK_ServiciosEnvio_Precio    CHECK (PrecioEnvio >= 0)
);
CREATE NONCLUSTERED INDEX IX_ServiciosEnvio_OperadorID      ON dbo.ServiciosEnvio (OperadorID);
CREATE NONCLUSTERED INDEX IX_ServiciosEnvio_ZonaCoberturaID ON dbo.ServiciosEnvio (ZonaCoberturaID);

-- ----------------- FotosServicio (entidad débil del servicio; mínimo 3 lo valida el backend) -----------------
CREATE TABLE dbo.FotosServicio (
    FotoID     INT            NOT NULL IDENTITY(1,1),
    ServicioID INT            NOT NULL,
    UrlArchivo NVARCHAR(300)  NOT NULL,
    CONSTRAINT PK_FotosServicio                 PRIMARY KEY (FotoID),
    CONSTRAINT FK_FotosServicio_ServiciosEnvio  FOREIGN KEY (ServicioID) REFERENCES dbo.ServiciosEnvio (ServicioID) ON DELETE CASCADE
);
CREATE NONCLUSTERED INDEX IX_FotosServicio_ServicioID ON dbo.FotosServicio (ServicioID);

-- ----------------- Rutas (las publica la empresa de transporte) -----------------
CREATE TABLE dbo.Rutas (
    RutaID            INT            NOT NULL IDENTITY(1,1),
    EmpresaID         INT            NOT NULL,                     -- FK -> Usuarios (rol EMPRESA)
    ZonaOrigenID      TINYINT        NOT NULL,
    ZonaDestinoID     TINYINT        NOT NULL,
    TipoServicio      NVARCHAR(50)   NOT NULL,
    HoraInicio        TIME(0)        NOT NULL,
    TiempoEstimadoMin INT            NOT NULL,                     -- tiempo estimado de entrega, en minutos
    Precio            DECIMAL(10,2)  NOT NULL,
    Estado            NVARCHAR(15)   NOT NULL CONSTRAINT DF_Rutas_Estado DEFAULT (N'ACTIVA'),
    CONSTRAINT PK_Rutas               PRIMARY KEY (RutaID),
    CONSTRAINT FK_Rutas_Usuarios      FOREIGN KEY (EmpresaID)     REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_Rutas_ZonaOrigen    FOREIGN KEY (ZonaOrigenID)  REFERENCES dbo.Zonas (ZonaID),
    CONSTRAINT FK_Rutas_ZonaDestino   FOREIGN KEY (ZonaDestinoID) REFERENCES dbo.Zonas (ZonaID),
    CONSTRAINT CK_Rutas_Estado        CHECK (Estado IN (N'ACTIVA', N'SUSPENDIDA', N'CANCELADA')),
    CONSTRAINT CK_Rutas_Tiempo        CHECK (TiempoEstimadoMin > 0),
    CONSTRAINT CK_Rutas_Precio        CHECK (Precio >= 0),
    CONSTRAINT CK_Rutas_Zonas         CHECK (ZonaOrigenID <> ZonaDestinoID)
);
CREATE NONCLUSTERED INDEX IX_Rutas_EmpresaID     ON dbo.Rutas (EmpresaID);
CREATE NONCLUSTERED INDEX IX_Rutas_ZonaOrigenID  ON dbo.Rutas (ZonaOrigenID);
CREATE NONCLUSTERED INDEX IX_Rutas_ZonaDestinoID ON dbo.Rutas (ZonaDestinoID);

-- ----------------- Flota (vehículos de la empresa; carga vía CSV o formulario) -----------------
CREATE TABLE dbo.Flota (
    VehiculoID    INT            NOT NULL IDENTITY(1,1),
    EmpresaID     INT            NOT NULL,
    Identificador NVARCHAR(50)   NOT NULL,                         -- placa / código interno
    Tipo          NVARCHAR(50)   NOT NULL,
    Capacidad     DECIMAL(10,2)  NOT NULL,
    Activo        BIT            NOT NULL CONSTRAINT DF_Flota_Activo DEFAULT (1),
    CONSTRAINT PK_Flota            PRIMARY KEY (VehiculoID),
    CONSTRAINT FK_Flota_Usuarios   FOREIGN KEY (EmpresaID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT CK_Flota_Capacidad  CHECK (Capacidad > 0)
);
CREATE NONCLUSTERED INDEX IX_Flota_EmpresaID ON dbo.Flota (EmpresaID);
