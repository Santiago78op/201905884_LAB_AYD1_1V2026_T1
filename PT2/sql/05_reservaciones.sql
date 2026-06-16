-- =============================================================================================
-- 05 · CARRITO, RESERVACIONES Y PAGOS  ·  TRACKFLOW-HUB
-- =============================================================================================
-- Tarjetas (método de pago simulado), ItemsCarrito (carrito persistente), Reservaciones y Pagos.
-- PATRÓN CLAVE: Reservaciones e ItemsCarrito usan Tipo (ENVIO|TRANSPORTE) + dos FKs opcionales
-- (ServicioEnvioID / RutaID); uno queda NULL según el tipo -> "NULL = no aplica", no "falta dato".
-- La reserva se confirma SOLO cuando su Pago llega a PROCESADO (regla del backend).
-- Requiere: 03_usuarios_perfiles.sql y 04_servicios_rutas.sql  ·  Correr con Alt+X (⌥X).
-- =============================================================================================

USE TrackFlow;

-- ----------------- Tarjetas (tarjeta simulada Q1000 + segundo método tipo wallet) -----------------
CREATE TABLE dbo.Tarjetas (
    TarjetaID         INT            NOT NULL IDENTITY(1,1),
    ClienteID         INT            NOT NULL,
    Titular           NVARCHAR(150)  NOT NULL,
    NumeroEnmascarado NVARCHAR(25)   NOT NULL,                     -- validado por Luhn en el backend
    FechaVencimiento  NVARCHAR(7)    NOT NULL,                     -- formato MM/AAAA
    Saldo             DECIMAL(10,2)  NOT NULL CONSTRAINT DF_Tarjetas_Saldo DEFAULT (1000.00),  -- saldo inicial Q1000
    Metodo            NVARCHAR(10)   NOT NULL,
    Activo            BIT            NOT NULL CONSTRAINT DF_Tarjetas_Activo DEFAULT (1),
    CONSTRAINT PK_Tarjetas          PRIMARY KEY (TarjetaID),
    CONSTRAINT FK_Tarjetas_Usuarios FOREIGN KEY (ClienteID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT CK_Tarjetas_Metodo   CHECK (Metodo IN (N'TARJETA', N'WALLET')),
    CONSTRAINT CK_Tarjetas_Saldo    CHECK (Saldo >= 0)
);
CREATE NONCLUSTERED INDEX IX_Tarjetas_ClienteID ON dbo.Tarjetas (ClienteID);

-- ----------------- ItemsCarrito (carrito persistente: sobrevive al cierre de sesión) -----------------
CREATE TABLE dbo.ItemsCarrito (
    ItemID          INT            NOT NULL IDENTITY(1,1),
    ClienteID       INT            NOT NULL,
    Tipo            NVARCHAR(12)   NOT NULL,
    ServicioEnvioID INT            NULL,                           -- NULL si Tipo = TRANSPORTE
    RutaID          INT            NULL,                           -- NULL si Tipo = ENVIO
    FechaProgramada DATETIME2(0)   NOT NULL,
    Monto           DECIMAL(10,2)  NOT NULL,
    CONSTRAINT PK_ItemsCarrito                 PRIMARY KEY (ItemID),
    CONSTRAINT FK_ItemsCarrito_Usuarios        FOREIGN KEY (ClienteID)       REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_ItemsCarrito_ServiciosEnvio  FOREIGN KEY (ServicioEnvioID) REFERENCES dbo.ServiciosEnvio (ServicioID),
    CONSTRAINT FK_ItemsCarrito_Rutas           FOREIGN KEY (RutaID)          REFERENCES dbo.Rutas (RutaID),
    CONSTRAINT CK_ItemsCarrito_Tipo            CHECK (Tipo IN (N'ENVIO', N'TRANSPORTE')),
    CONSTRAINT CK_ItemsCarrito_Monto           CHECK (Monto >= 0),
    -- coherencia: ENVIO -> ServicioEnvioID NOT NULL y RutaID NULL ; TRANSPORTE -> al revés
    CONSTRAINT CK_ItemsCarrito_Coherencia      CHECK (
        (Tipo = N'ENVIO'      AND ServicioEnvioID IS NOT NULL AND RutaID IS NULL) OR
        (Tipo = N'TRANSPORTE' AND RutaID          IS NOT NULL AND ServicioEnvioID IS NULL)
    )
);
CREATE NONCLUSTERED INDEX IX_ItemsCarrito_ClienteID       ON dbo.ItemsCarrito (ClienteID);
CREATE NONCLUSTERED INDEX IX_ItemsCarrito_ServicioEnvioID ON dbo.ItemsCarrito (ServicioEnvioID) WHERE ServicioEnvioID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_ItemsCarrito_RutaID          ON dbo.ItemsCarrito (RutaID)          WHERE RutaID IS NOT NULL;

-- ----------------- Reservaciones (envío o transporte; una sola vista de "servicios contratados") -----------------
CREATE TABLE dbo.Reservaciones (
    ReservaID       INT            NOT NULL IDENTITY(1,1),
    ClienteID       INT            NOT NULL,
    Tipo            NVARCHAR(12)   NOT NULL,
    ServicioEnvioID INT            NULL,                           -- NULL si Tipo = TRANSPORTE
    RutaID          INT            NULL,                           -- NULL si Tipo = ENVIO
    FechaInicio     DATETIME2(0)   NOT NULL,
    FechaFin        DATETIME2(0)   NULL,                           -- rango (envío); NULL si es un solo momento
    EstadoReservaID TINYINT        NOT NULL CONSTRAINT DF_Reservaciones_Estado DEFAULT (1),  -- 1 = ACTIVO
    Monto           DECIMAL(10,2)  NOT NULL,
    FechaCreacion   DATETIME2(0)   NOT NULL CONSTRAINT DF_Reservaciones_Creacion DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Reservaciones                 PRIMARY KEY (ReservaID),
    CONSTRAINT FK_Reservaciones_Usuarios        FOREIGN KEY (ClienteID)       REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_Reservaciones_ServiciosEnvio  FOREIGN KEY (ServicioEnvioID) REFERENCES dbo.ServiciosEnvio (ServicioID),
    CONSTRAINT FK_Reservaciones_Rutas           FOREIGN KEY (RutaID)          REFERENCES dbo.Rutas (RutaID),
    CONSTRAINT FK_Reservaciones_EstadosReserva  FOREIGN KEY (EstadoReservaID) REFERENCES dbo.EstadosReserva (EstadoReservaID),
    CONSTRAINT CK_Reservaciones_Tipo            CHECK (Tipo IN (N'ENVIO', N'TRANSPORTE')),
    CONSTRAINT CK_Reservaciones_Monto           CHECK (Monto >= 0),
    CONSTRAINT CK_Reservaciones_Fechas          CHECK (FechaFin IS NULL OR FechaFin >= FechaInicio),
    CONSTRAINT CK_Reservaciones_Coherencia      CHECK (
        (Tipo = N'ENVIO'      AND ServicioEnvioID IS NOT NULL AND RutaID IS NULL) OR
        (Tipo = N'TRANSPORTE' AND RutaID          IS NOT NULL AND ServicioEnvioID IS NULL)
    )
);
CREATE NONCLUSTERED INDEX IX_Reservaciones_ClienteID       ON dbo.Reservaciones (ClienteID);
CREATE NONCLUSTERED INDEX IX_Reservaciones_ServicioEnvioID ON dbo.Reservaciones (ServicioEnvioID) WHERE ServicioEnvioID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_Reservaciones_RutaID          ON dbo.Reservaciones (RutaID)          WHERE RutaID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_Reservaciones_EstadoReservaID ON dbo.Reservaciones (EstadoReservaID);

-- ----------------- Pagos (la reserva se confirma solo si el pago llega a PROCESADO) -----------------
CREATE TABLE dbo.Pagos (
    PagoID       INT            NOT NULL IDENTITY(1,1),
    ReservaID    INT            NOT NULL,
    TarjetaID    INT            NOT NULL,
    Monto        DECIMAL(10,2)  NOT NULL,
    EstadoPagoID TINYINT        NOT NULL CONSTRAINT DF_Pagos_Estado DEFAULT (1),  -- 1 = PENDIENTE
    Fecha        DATETIME2(0)   NOT NULL CONSTRAINT DF_Pagos_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Pagos                PRIMARY KEY (PagoID),
    CONSTRAINT FK_Pagos_Reservaciones  FOREIGN KEY (ReservaID)    REFERENCES dbo.Reservaciones (ReservaID),
    CONSTRAINT FK_Pagos_Tarjetas       FOREIGN KEY (TarjetaID)    REFERENCES dbo.Tarjetas (TarjetaID),
    CONSTRAINT FK_Pagos_EstadosPago    FOREIGN KEY (EstadoPagoID) REFERENCES dbo.EstadosPago (EstadoPagoID),
    CONSTRAINT CK_Pagos_Monto          CHECK (Monto >= 0)
);
CREATE NONCLUSTERED INDEX IX_Pagos_ReservaID    ON dbo.Pagos (ReservaID);
CREATE NONCLUSTERED INDEX IX_Pagos_TarjetaID    ON dbo.Pagos (TarjetaID);
CREATE NONCLUSTERED INDEX IX_Pagos_EstadoPagoID ON dbo.Pagos (EstadoPagoID);
