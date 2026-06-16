-- =============================================================================================
-- DDL COMPLETO - TRACKFLOW-HUB  ·  TODO EN UN ARCHIVO, SIN "GO"  ·  para desplegar en AWS
-- Proyecto AYD1 - Escuela de Vacaciones 2026
-- =============================================================================================
-- Qué es: el esquema entero (31 tablas) en un solo script, sin "GO", para ejecutarlo de una sola
--         pasada contra SQL Server en AWS (RDS / EC2) o en el contenedor azure-sql-edge.
--
-- CONTENIDO (en orden): base -> limpieza -> lookups -> usuarios/perfiles -> servicios/rutas ->
--                       carrito/reservas/pagos -> interacción -> soporte -> seeds.
--
-- AWS — leé esto antes:
--   * RDS for SQL Server: el usuario maestro PUEDE crear bases con CREATE DATABASE. Si tu instancia
--     ya te dio una base, COMENTÁ las líneas "CREATE DATABASE" y "USE" y corré el resto sobre ella.
--   * Mantené el orden: hay FKs; si reordenás, fallará por dependencias.
--   * Es re-ejecutable: la sección de limpieza borra todo en orden inverso antes de crear.
-- =============================================================================================

SET NOCOUNT ON;

-- =============================================================================================
-- 0. BASE DE DATOS  (idempotente, en una línea para no romper el parser sin GO)
-- =============================================================================================
IF DB_ID(N'TrackFlow') IS NULL CREATE DATABASE TrackFlow;
USE TrackFlow;

-- =============================================================================================
-- 1. LIMPIEZA (orden inverso a las FKs; re-ejecutable)
-- =============================================================================================
DROP TABLE IF EXISTS dbo.LogActividad;
DROP TABLE IF EXISTS dbo.Notificaciones;
DROP TABLE IF EXISTS dbo.ReunionesVirtuales;
DROP TABLE IF EXISTS dbo.SolicitudesCambioPerfil;
DROP TABLE IF EXISTS dbo.Tokens;
DROP TABLE IF EXISTS dbo.Sanciones;
DROP TABLE IF EXISTS dbo.EvidenciasReporte;
DROP TABLE IF EXISTS dbo.CuponesCanjeados;
DROP TABLE IF EXISTS dbo.Calificaciones;
DROP TABLE IF EXISTS dbo.Pagos;
DROP TABLE IF EXISTS dbo.Reportes;
DROP TABLE IF EXISTS dbo.Cupones;
DROP TABLE IF EXISTS dbo.Reservaciones;
DROP TABLE IF EXISTS dbo.ItemsCarrito;
DROP TABLE IF EXISTS dbo.Tarjetas;
DROP TABLE IF EXISTS dbo.FotosServicio;
DROP TABLE IF EXISTS dbo.Flota;
DROP TABLE IF EXISTS dbo.Rutas;
DROP TABLE IF EXISTS dbo.ServiciosEnvio;
DROP TABLE IF EXISTS dbo.PerfilEmpresa;
DROP TABLE IF EXISTS dbo.PerfilOperador;
DROP TABLE IF EXISTS dbo.PerfilCliente;
DROP TABLE IF EXISTS dbo.Usuarios;
DROP TABLE IF EXISTS dbo.Zonas;
DROP TABLE IF EXISTS dbo.EstadosReporte;
DROP TABLE IF EXISTS dbo.EstadosPago;
DROP TABLE IF EXISTS dbo.EstadosReserva;
DROP TABLE IF EXISTS dbo.EstadosSolicitud;
DROP TABLE IF EXISTS dbo.EstadosCuenta;
DROP TABLE IF EXISTS dbo.Generos;
DROP TABLE IF EXISTS dbo.Roles;

-- =============================================================================================
-- 2. LOOKUPS / CATÁLOGOS
-- =============================================================================================
CREATE TABLE dbo.Roles (
    RolID TINYINT NOT NULL, Codigo NVARCHAR(20) NOT NULL, Descripcion NVARCHAR(100) NULL,
    CONSTRAINT PK_Roles PRIMARY KEY (RolID), CONSTRAINT UQ_Roles_Cod UNIQUE (Codigo)
);
CREATE TABLE dbo.Generos (
    GeneroID TINYINT NOT NULL, Codigo NVARCHAR(15) NOT NULL, Descripcion NVARCHAR(50) NULL,
    CONSTRAINT PK_Generos PRIMARY KEY (GeneroID), CONSTRAINT UQ_Generos_Cod UNIQUE (Codigo)
);
CREATE TABLE dbo.EstadosCuenta (
    EstadoCuentaID TINYINT NOT NULL, Codigo NVARCHAR(20) NOT NULL, Descripcion NVARCHAR(100) NULL,
    EsTerminal BIT NOT NULL CONSTRAINT DF_EstadosCuenta_Terminal DEFAULT (0),
    CONSTRAINT PK_EstadosCuenta PRIMARY KEY (EstadoCuentaID), CONSTRAINT UQ_EstadosCuenta_Cod UNIQUE (Codigo)
);
CREATE TABLE dbo.EstadosSolicitud (
    EstadoSolicitudID TINYINT NOT NULL, Codigo NVARCHAR(20) NOT NULL, Descripcion NVARCHAR(100) NULL,
    EsTerminal BIT NOT NULL CONSTRAINT DF_EstadosSolicitud_Terminal DEFAULT (0),
    CONSTRAINT PK_EstadosSolicitud PRIMARY KEY (EstadoSolicitudID), CONSTRAINT UQ_EstadosSolicitud_Cod UNIQUE (Codigo)
);
CREATE TABLE dbo.EstadosReserva (
    EstadoReservaID TINYINT NOT NULL, Codigo NVARCHAR(20) NOT NULL, Descripcion NVARCHAR(100) NULL,
    EsTerminal BIT NOT NULL CONSTRAINT DF_EstadosReserva_Terminal DEFAULT (0),
    CONSTRAINT PK_EstadosReserva PRIMARY KEY (EstadoReservaID), CONSTRAINT UQ_EstadosReserva_Cod UNIQUE (Codigo)
);
CREATE TABLE dbo.EstadosPago (
    EstadoPagoID TINYINT NOT NULL, Codigo NVARCHAR(20) NOT NULL, Descripcion NVARCHAR(100) NULL,
    EsTerminal BIT NOT NULL CONSTRAINT DF_EstadosPago_Terminal DEFAULT (0),
    CONSTRAINT PK_EstadosPago PRIMARY KEY (EstadoPagoID), CONSTRAINT UQ_EstadosPago_Cod UNIQUE (Codigo)
);
CREATE TABLE dbo.EstadosReporte (
    EstadoReporteID TINYINT NOT NULL, Codigo NVARCHAR(20) NOT NULL, Descripcion NVARCHAR(100) NULL,
    EsTerminal BIT NOT NULL CONSTRAINT DF_EstadosReporte_Terminal DEFAULT (0),
    CONSTRAINT PK_EstadosReporte PRIMARY KEY (EstadoReporteID), CONSTRAINT UQ_EstadosReporte_Cod UNIQUE (Codigo)
);
CREATE TABLE dbo.Zonas (
    ZonaID TINYINT NOT NULL, Nombre NVARCHAR(100) NOT NULL, Tipo NVARCHAR(15) NOT NULL,
    CONSTRAINT PK_Zonas PRIMARY KEY (ZonaID), CONSTRAINT UQ_Zonas_Nombre UNIQUE (Nombre),
    CONSTRAINT CK_Zonas_Tipo CHECK (Tipo IN (N'NACIONAL', N'INTERNACIONAL'))
);

-- =============================================================================================
-- 3. USUARIOS Y PERFILES
-- =============================================================================================
CREATE TABLE dbo.Usuarios (
    UsuarioID INT NOT NULL IDENTITY(1,1),
    RolID TINYINT NOT NULL,
    Correo NVARCHAR(150) NOT NULL,
    Contrasena NVARCHAR(255) NOT NULL,
    CorreoConfirmado BIT NOT NULL CONSTRAINT DF_Usuarios_CorreoConf DEFAULT (0),
    EstadoCuentaID TINYINT NOT NULL CONSTRAINT DF_Usuarios_Estado DEFAULT (1),
    MotivoVeto NVARCHAR(300) NULL,
    RequiereCambioPassword BIT NOT NULL CONSTRAINT DF_Usuarios_ReqPwd DEFAULT (0),
    FechaRegistro DATETIME2(0) NOT NULL CONSTRAINT DF_Usuarios_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Usuarios PRIMARY KEY (UsuarioID),
    CONSTRAINT UQ_Usuarios_Correo UNIQUE (Correo),
    CONSTRAINT FK_Usuarios_Roles FOREIGN KEY (RolID) REFERENCES dbo.Roles (RolID),
    CONSTRAINT FK_Usuarios_EstadosCuenta FOREIGN KEY (EstadoCuentaID) REFERENCES dbo.EstadosCuenta (EstadoCuentaID),
    CONSTRAINT CK_Usuarios_Correo CHECK (Correo LIKE N'%_@_%._%')
);
CREATE NONCLUSTERED INDEX IX_Usuarios_RolID ON dbo.Usuarios (RolID);
CREATE NONCLUSTERED INDEX IX_Usuarios_EstadoCuentaID ON dbo.Usuarios (EstadoCuentaID);

CREATE TABLE dbo.PerfilCliente (
    UsuarioID INT NOT NULL, Nombre NVARCHAR(100) NOT NULL, Apellido NVARCHAR(100) NOT NULL,
    Telefono NVARCHAR(30) NOT NULL, DireccionOrigen NVARCHAR(300) NULL,
    CONSTRAINT PK_PerfilCliente PRIMARY KEY (UsuarioID),
    CONSTRAINT FK_PerfilCliente_Usuarios FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuarios (UsuarioID)
);
CREATE TABLE dbo.PerfilOperador (
    UsuarioID INT NOT NULL, Nombre NVARCHAR(100) NOT NULL, Apellido NVARCHAR(100) NOT NULL,
    DpiCui NVARCHAR(20) NOT NULL, Telefono NVARCHAR(30) NOT NULL, TelefonoRespaldo NVARCHAR(30) NULL,
    Fotografia NVARCHAR(300) NOT NULL, ZonaOperacionID TINYINT NOT NULL, GeneroID TINYINT NOT NULL,
    EstadoSolicitudID TINYINT NOT NULL CONSTRAINT DF_PerfilOperador_Estado DEFAULT (1),
    CONSTRAINT PK_PerfilOperador PRIMARY KEY (UsuarioID),
    CONSTRAINT UQ_PerfilOperador_DpiCui UNIQUE (DpiCui),
    CONSTRAINT FK_PerfilOperador_Usuarios FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_PerfilOperador_Zonas FOREIGN KEY (ZonaOperacionID) REFERENCES dbo.Zonas (ZonaID),
    CONSTRAINT FK_PerfilOperador_Generos FOREIGN KEY (GeneroID) REFERENCES dbo.Generos (GeneroID),
    CONSTRAINT FK_PerfilOperador_EstadosSolicitud FOREIGN KEY (EstadoSolicitudID) REFERENCES dbo.EstadosSolicitud (EstadoSolicitudID)
);
CREATE NONCLUSTERED INDEX IX_PerfilOperador_ZonaOperacionID ON dbo.PerfilOperador (ZonaOperacionID);
CREATE NONCLUSTERED INDEX IX_PerfilOperador_GeneroID ON dbo.PerfilOperador (GeneroID);
CREATE NONCLUSTERED INDEX IX_PerfilOperador_EstadoSolicitudID ON dbo.PerfilOperador (EstadoSolicitudID);

CREATE TABLE dbo.PerfilEmpresa (
    UsuarioID INT NOT NULL, NombreEmpresa NVARCHAR(150) NOT NULL, Telefono NVARCHAR(30) NOT NULL,
    TelefonoRespaldo NVARCHAR(30) NULL, Nit NVARCHAR(20) NOT NULL, NumeroLicencia NVARCHAR(50) NOT NULL,
    EstadoSolicitudID TINYINT NOT NULL CONSTRAINT DF_PerfilEmpresa_Estado DEFAULT (1),
    CONSTRAINT PK_PerfilEmpresa PRIMARY KEY (UsuarioID),
    CONSTRAINT UQ_PerfilEmpresa_Nit UNIQUE (Nit),
    CONSTRAINT UQ_PerfilEmpresa_Licencia UNIQUE (NumeroLicencia),
    CONSTRAINT FK_PerfilEmpresa_Usuarios FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_PerfilEmpresa_EstadosSolicitud FOREIGN KEY (EstadoSolicitudID) REFERENCES dbo.EstadosSolicitud (EstadoSolicitudID)
);
CREATE NONCLUSTERED INDEX IX_PerfilEmpresa_EstadoSolicitudID ON dbo.PerfilEmpresa (EstadoSolicitudID);

-- =============================================================================================
-- 4. SERVICIOS DE ENVÍO Y RUTAS
-- =============================================================================================
CREATE TABLE dbo.ServiciosEnvio (
    ServicioID INT NOT NULL IDENTITY(1,1), OperadorID INT NOT NULL, ZonaCoberturaID TINYINT NOT NULL,
    CapacidadCargaKg DECIMAL(10,2) NOT NULL, PrecioEnvio DECIMAL(10,2) NOT NULL, Descripcion NVARCHAR(500) NULL,
    Suspendido BIT NOT NULL CONSTRAINT DF_ServiciosEnvio_Suspendido DEFAULT (0),
    Activo BIT NOT NULL CONSTRAINT DF_ServiciosEnvio_Activo DEFAULT (1),
    CONSTRAINT PK_ServiciosEnvio PRIMARY KEY (ServicioID),
    CONSTRAINT FK_ServiciosEnvio_Usuarios FOREIGN KEY (OperadorID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_ServiciosEnvio_Zonas FOREIGN KEY (ZonaCoberturaID) REFERENCES dbo.Zonas (ZonaID),
    CONSTRAINT CK_ServiciosEnvio_Capacidad CHECK (CapacidadCargaKg > 0),
    CONSTRAINT CK_ServiciosEnvio_Precio CHECK (PrecioEnvio >= 0)
);
CREATE NONCLUSTERED INDEX IX_ServiciosEnvio_OperadorID ON dbo.ServiciosEnvio (OperadorID);
CREATE NONCLUSTERED INDEX IX_ServiciosEnvio_ZonaCoberturaID ON dbo.ServiciosEnvio (ZonaCoberturaID);

CREATE TABLE dbo.FotosServicio (
    FotoID INT NOT NULL IDENTITY(1,1), ServicioID INT NOT NULL, UrlArchivo NVARCHAR(300) NOT NULL,
    CONSTRAINT PK_FotosServicio PRIMARY KEY (FotoID),
    CONSTRAINT FK_FotosServicio_ServiciosEnvio FOREIGN KEY (ServicioID) REFERENCES dbo.ServiciosEnvio (ServicioID) ON DELETE CASCADE
);
CREATE NONCLUSTERED INDEX IX_FotosServicio_ServicioID ON dbo.FotosServicio (ServicioID);

CREATE TABLE dbo.Rutas (
    RutaID INT NOT NULL IDENTITY(1,1), EmpresaID INT NOT NULL, ZonaOrigenID TINYINT NOT NULL,
    ZonaDestinoID TINYINT NOT NULL, TipoServicio NVARCHAR(50) NOT NULL, HoraInicio TIME(0) NOT NULL,
    TiempoEstimadoMin INT NOT NULL, Precio DECIMAL(10,2) NOT NULL,
    Estado NVARCHAR(15) NOT NULL CONSTRAINT DF_Rutas_Estado DEFAULT (N'ACTIVA'),
    CONSTRAINT PK_Rutas PRIMARY KEY (RutaID),
    CONSTRAINT FK_Rutas_Usuarios FOREIGN KEY (EmpresaID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_Rutas_ZonaOrigen FOREIGN KEY (ZonaOrigenID) REFERENCES dbo.Zonas (ZonaID),
    CONSTRAINT FK_Rutas_ZonaDestino FOREIGN KEY (ZonaDestinoID) REFERENCES dbo.Zonas (ZonaID),
    CONSTRAINT CK_Rutas_Estado CHECK (Estado IN (N'ACTIVA', N'SUSPENDIDA', N'CANCELADA')),
    CONSTRAINT CK_Rutas_Tiempo CHECK (TiempoEstimadoMin > 0),
    CONSTRAINT CK_Rutas_Precio CHECK (Precio >= 0),
    CONSTRAINT CK_Rutas_Zonas CHECK (ZonaOrigenID <> ZonaDestinoID)
);
CREATE NONCLUSTERED INDEX IX_Rutas_EmpresaID ON dbo.Rutas (EmpresaID);
CREATE NONCLUSTERED INDEX IX_Rutas_ZonaOrigenID ON dbo.Rutas (ZonaOrigenID);
CREATE NONCLUSTERED INDEX IX_Rutas_ZonaDestinoID ON dbo.Rutas (ZonaDestinoID);

CREATE TABLE dbo.Flota (
    VehiculoID INT NOT NULL IDENTITY(1,1), EmpresaID INT NOT NULL, Identificador NVARCHAR(50) NOT NULL,
    Tipo NVARCHAR(50) NOT NULL, Capacidad DECIMAL(10,2) NOT NULL,
    Activo BIT NOT NULL CONSTRAINT DF_Flota_Activo DEFAULT (1),
    CONSTRAINT PK_Flota PRIMARY KEY (VehiculoID),
    CONSTRAINT FK_Flota_Usuarios FOREIGN KEY (EmpresaID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT CK_Flota_Capacidad CHECK (Capacidad > 0)
);
CREATE NONCLUSTERED INDEX IX_Flota_EmpresaID ON dbo.Flota (EmpresaID);

-- =============================================================================================
-- 5. CARRITO, RESERVACIONES Y PAGOS
-- =============================================================================================
CREATE TABLE dbo.Tarjetas (
    TarjetaID INT NOT NULL IDENTITY(1,1), ClienteID INT NOT NULL, Titular NVARCHAR(150) NOT NULL,
    NumeroEnmascarado NVARCHAR(25) NOT NULL, FechaVencimiento NVARCHAR(7) NOT NULL,
    Saldo DECIMAL(10,2) NOT NULL CONSTRAINT DF_Tarjetas_Saldo DEFAULT (1000.00),
    Metodo NVARCHAR(10) NOT NULL, Activo BIT NOT NULL CONSTRAINT DF_Tarjetas_Activo DEFAULT (1),
    CONSTRAINT PK_Tarjetas PRIMARY KEY (TarjetaID),
    CONSTRAINT FK_Tarjetas_Usuarios FOREIGN KEY (ClienteID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT CK_Tarjetas_Metodo CHECK (Metodo IN (N'TARJETA', N'WALLET')),
    CONSTRAINT CK_Tarjetas_Saldo CHECK (Saldo >= 0)
);
CREATE NONCLUSTERED INDEX IX_Tarjetas_ClienteID ON dbo.Tarjetas (ClienteID);

CREATE TABLE dbo.ItemsCarrito (
    ItemID INT NOT NULL IDENTITY(1,1), ClienteID INT NOT NULL, Tipo NVARCHAR(12) NOT NULL,
    ServicioEnvioID INT NULL, RutaID INT NULL, FechaProgramada DATETIME2(0) NOT NULL, Monto DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_ItemsCarrito PRIMARY KEY (ItemID),
    CONSTRAINT FK_ItemsCarrito_Usuarios FOREIGN KEY (ClienteID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_ItemsCarrito_ServiciosEnvio FOREIGN KEY (ServicioEnvioID) REFERENCES dbo.ServiciosEnvio (ServicioID),
    CONSTRAINT FK_ItemsCarrito_Rutas FOREIGN KEY (RutaID) REFERENCES dbo.Rutas (RutaID),
    CONSTRAINT CK_ItemsCarrito_Tipo CHECK (Tipo IN (N'ENVIO', N'TRANSPORTE')),
    CONSTRAINT CK_ItemsCarrito_Monto CHECK (Monto >= 0),
    CONSTRAINT CK_ItemsCarrito_Coherencia CHECK (
        (Tipo = N'ENVIO' AND ServicioEnvioID IS NOT NULL AND RutaID IS NULL) OR
        (Tipo = N'TRANSPORTE' AND RutaID IS NOT NULL AND ServicioEnvioID IS NULL))
);
CREATE NONCLUSTERED INDEX IX_ItemsCarrito_ClienteID ON dbo.ItemsCarrito (ClienteID);
CREATE NONCLUSTERED INDEX IX_ItemsCarrito_ServicioEnvioID ON dbo.ItemsCarrito (ServicioEnvioID) WHERE ServicioEnvioID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_ItemsCarrito_RutaID ON dbo.ItemsCarrito (RutaID) WHERE RutaID IS NOT NULL;

CREATE TABLE dbo.Reservaciones (
    ReservaID INT NOT NULL IDENTITY(1,1), ClienteID INT NOT NULL, Tipo NVARCHAR(12) NOT NULL,
    ServicioEnvioID INT NULL, RutaID INT NULL, FechaInicio DATETIME2(0) NOT NULL, FechaFin DATETIME2(0) NULL,
    EstadoReservaID TINYINT NOT NULL CONSTRAINT DF_Reservaciones_Estado DEFAULT (1), Monto DECIMAL(10,2) NOT NULL,
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Reservaciones_Creacion DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Reservaciones PRIMARY KEY (ReservaID),
    CONSTRAINT FK_Reservaciones_Usuarios FOREIGN KEY (ClienteID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_Reservaciones_ServiciosEnvio FOREIGN KEY (ServicioEnvioID) REFERENCES dbo.ServiciosEnvio (ServicioID),
    CONSTRAINT FK_Reservaciones_Rutas FOREIGN KEY (RutaID) REFERENCES dbo.Rutas (RutaID),
    CONSTRAINT FK_Reservaciones_EstadosReserva FOREIGN KEY (EstadoReservaID) REFERENCES dbo.EstadosReserva (EstadoReservaID),
    CONSTRAINT CK_Reservaciones_Tipo CHECK (Tipo IN (N'ENVIO', N'TRANSPORTE')),
    CONSTRAINT CK_Reservaciones_Monto CHECK (Monto >= 0),
    CONSTRAINT CK_Reservaciones_Fechas CHECK (FechaFin IS NULL OR FechaFin >= FechaInicio),
    CONSTRAINT CK_Reservaciones_Coherencia CHECK (
        (Tipo = N'ENVIO' AND ServicioEnvioID IS NOT NULL AND RutaID IS NULL) OR
        (Tipo = N'TRANSPORTE' AND RutaID IS NOT NULL AND ServicioEnvioID IS NULL))
);
CREATE NONCLUSTERED INDEX IX_Reservaciones_ClienteID ON dbo.Reservaciones (ClienteID);
CREATE NONCLUSTERED INDEX IX_Reservaciones_ServicioEnvioID ON dbo.Reservaciones (ServicioEnvioID) WHERE ServicioEnvioID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_Reservaciones_RutaID ON dbo.Reservaciones (RutaID) WHERE RutaID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_Reservaciones_EstadoReservaID ON dbo.Reservaciones (EstadoReservaID);

CREATE TABLE dbo.Pagos (
    PagoID INT NOT NULL IDENTITY(1,1), ReservaID INT NOT NULL, TarjetaID INT NOT NULL, Monto DECIMAL(10,2) NOT NULL,
    EstadoPagoID TINYINT NOT NULL CONSTRAINT DF_Pagos_Estado DEFAULT (1),
    Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_Pagos_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Pagos PRIMARY KEY (PagoID),
    CONSTRAINT FK_Pagos_Reservaciones FOREIGN KEY (ReservaID) REFERENCES dbo.Reservaciones (ReservaID),
    CONSTRAINT FK_Pagos_Tarjetas FOREIGN KEY (TarjetaID) REFERENCES dbo.Tarjetas (TarjetaID),
    CONSTRAINT FK_Pagos_EstadosPago FOREIGN KEY (EstadoPagoID) REFERENCES dbo.EstadosPago (EstadoPagoID),
    CONSTRAINT CK_Pagos_Monto CHECK (Monto >= 0)
);
CREATE NONCLUSTERED INDEX IX_Pagos_ReservaID ON dbo.Pagos (ReservaID);
CREATE NONCLUSTERED INDEX IX_Pagos_TarjetaID ON dbo.Pagos (TarjetaID);
CREATE NONCLUSTERED INDEX IX_Pagos_EstadoPagoID ON dbo.Pagos (EstadoPagoID);

-- =============================================================================================
-- 6. CALIFICACIONES, CUPONES, REPORTES Y SANCIONES
-- =============================================================================================
CREATE TABLE dbo.Calificaciones (
    CalificacionID INT NOT NULL IDENTITY(1,1), ReservaID INT NOT NULL, ClienteID INT NOT NULL,
    Puntuacion TINYINT NOT NULL, Comentario NVARCHAR(500) NULL, RespuestaProveedor NVARCHAR(500) NULL,
    Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_Calificaciones_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Calificaciones PRIMARY KEY (CalificacionID),
    CONSTRAINT UQ_Calificaciones_Reserva UNIQUE (ReservaID),
    CONSTRAINT FK_Calificaciones_Reservaciones FOREIGN KEY (ReservaID) REFERENCES dbo.Reservaciones (ReservaID),
    CONSTRAINT FK_Calificaciones_Usuarios FOREIGN KEY (ClienteID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT CK_Calificaciones_Puntuacion CHECK (Puntuacion BETWEEN 1 AND 5)
);
CREATE NONCLUSTERED INDEX IX_Calificaciones_ClienteID ON dbo.Calificaciones (ClienteID);

CREATE TABLE dbo.Cupones (
    CuponID INT NOT NULL IDENTITY(1,1), EmisorID INT NOT NULL, Codigo NVARCHAR(40) NOT NULL,
    TipoDescuento NVARCHAR(12) NOT NULL, ValorDescuento DECIMAL(10,2) NOT NULL, Condiciones NVARCHAR(500) NULL,
    FechaInicio DATETIME2(0) NOT NULL, FechaFin DATETIME2(0) NOT NULL,
    Activo BIT NOT NULL CONSTRAINT DF_Cupones_Activo DEFAULT (1),
    CONSTRAINT PK_Cupones PRIMARY KEY (CuponID),
    CONSTRAINT UQ_Cupones_Codigo UNIQUE (Codigo),
    CONSTRAINT FK_Cupones_Usuarios FOREIGN KEY (EmisorID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT CK_Cupones_TipoDesc CHECK (TipoDescuento IN (N'PORCENTAJE', N'MONTO')),
    CONSTRAINT CK_Cupones_Valor CHECK (ValorDescuento >= 0),
    CONSTRAINT CK_Cupones_Fechas CHECK (FechaFin >= FechaInicio)
);
CREATE NONCLUSTERED INDEX IX_Cupones_EmisorID ON dbo.Cupones (EmisorID);

CREATE TABLE dbo.CuponesCanjeados (
    CanjeID INT NOT NULL IDENTITY(1,1), CuponID INT NOT NULL, ClienteID INT NOT NULL, ReservaID INT NULL,
    FechaCanje DATETIME2(0) NOT NULL CONSTRAINT DF_CuponesCanjeados_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_CuponesCanjeados PRIMARY KEY (CanjeID),
    CONSTRAINT UQ_CuponesCanjeados_CuponCliente UNIQUE (CuponID, ClienteID),
    CONSTRAINT FK_CuponesCanjeados_Cupones FOREIGN KEY (CuponID) REFERENCES dbo.Cupones (CuponID),
    CONSTRAINT FK_CuponesCanjeados_Usuarios FOREIGN KEY (ClienteID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_CuponesCanjeados_Reservaciones FOREIGN KEY (ReservaID) REFERENCES dbo.Reservaciones (ReservaID)
);
CREATE NONCLUSTERED INDEX IX_CuponesCanjeados_ClienteID ON dbo.CuponesCanjeados (ClienteID);
CREATE NONCLUSTERED INDEX IX_CuponesCanjeados_ReservaID ON dbo.CuponesCanjeados (ReservaID) WHERE ReservaID IS NOT NULL;

CREATE TABLE dbo.Reportes (
    ReporteID INT NOT NULL IDENTITY(1,1), ReportanteID INT NOT NULL, ReportadoID INT NOT NULL, ReservaID INT NULL,
    Tipo NVARCHAR(12) NOT NULL, Descripcion NVARCHAR(MAX) NOT NULL,
    EstadoReporteID TINYINT NOT NULL CONSTRAINT DF_Reportes_Estado DEFAULT (1),
    FechaReporte DATETIME2(0) NOT NULL CONSTRAINT DF_Reportes_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Reportes PRIMARY KEY (ReporteID),
    CONSTRAINT FK_Reportes_Reportante FOREIGN KEY (ReportanteID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_Reportes_Reportado FOREIGN KEY (ReportadoID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_Reportes_Reservaciones FOREIGN KEY (ReservaID) REFERENCES dbo.Reservaciones (ReservaID),
    CONSTRAINT FK_Reportes_EstadosReporte FOREIGN KEY (EstadoReporteID) REFERENCES dbo.EstadosReporte (EstadoReporteID),
    CONSTRAINT CK_Reportes_Tipo CHECK (Tipo IN (N'ENVIO', N'TRANSPORTE', N'CLIENTE')),
    CONSTRAINT CK_Reportes_Distintos CHECK (ReportanteID <> ReportadoID)
);
CREATE NONCLUSTERED INDEX IX_Reportes_ReportanteID ON dbo.Reportes (ReportanteID);
CREATE NONCLUSTERED INDEX IX_Reportes_ReportadoID ON dbo.Reportes (ReportadoID);
CREATE NONCLUSTERED INDEX IX_Reportes_ReservaID ON dbo.Reportes (ReservaID) WHERE ReservaID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_Reportes_EstadoReporteID ON dbo.Reportes (EstadoReporteID);

CREATE TABLE dbo.EvidenciasReporte (
    EvidenciaID INT NOT NULL IDENTITY(1,1), ReporteID INT NOT NULL, UrlArchivo NVARCHAR(300) NOT NULL, Tipo NVARCHAR(10) NOT NULL,
    CONSTRAINT PK_EvidenciasReporte PRIMARY KEY (EvidenciaID),
    CONSTRAINT FK_EvidenciasReporte_Reportes FOREIGN KEY (ReporteID) REFERENCES dbo.Reportes (ReporteID) ON DELETE CASCADE,
    CONSTRAINT CK_EvidenciasReporte_Tipo CHECK (Tipo IN (N'FOTO', N'VIDEO'))
);
CREATE NONCLUSTERED INDEX IX_EvidenciasReporte_ReporteID ON dbo.EvidenciasReporte (ReporteID);

CREATE TABLE dbo.Sanciones (
    SancionID INT NOT NULL IDENTITY(1,1), UsuarioID INT NOT NULL, ReporteID INT NULL, AdminID INT NOT NULL,
    Tipo NVARCHAR(20) NOT NULL, Motivo NVARCHAR(300) NOT NULL,
    FechaInicio DATETIME2(0) NOT NULL CONSTRAINT DF_Sanciones_Inicio DEFAULT (SYSUTCDATETIME()), FechaFin DATETIME2(0) NULL,
    CONSTRAINT PK_Sanciones PRIMARY KEY (SancionID),
    CONSTRAINT FK_Sanciones_Usuario FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_Sanciones_Reportes FOREIGN KEY (ReporteID) REFERENCES dbo.Reportes (ReporteID),
    CONSTRAINT FK_Sanciones_Admin FOREIGN KEY (AdminID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT CK_Sanciones_Tipo CHECK (Tipo IN (N'SUSPENSION_TEMPORAL', N'VETO_PERMANENTE')),
    CONSTRAINT CK_Sanciones_Fechas CHECK (FechaFin IS NULL OR FechaFin >= FechaInicio)
);
CREATE NONCLUSTERED INDEX IX_Sanciones_UsuarioID ON dbo.Sanciones (UsuarioID);
CREATE NONCLUSTERED INDEX IX_Sanciones_ReporteID ON dbo.Sanciones (ReporteID) WHERE ReporteID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_Sanciones_AdminID ON dbo.Sanciones (AdminID);

-- =============================================================================================
-- 7. SOPORTE (auth, solicitudes, reuniones, notificaciones, bitácora)
-- =============================================================================================
CREATE TABLE dbo.Tokens (
    TokenID INT NOT NULL IDENTITY(1,1), UsuarioID INT NOT NULL, Tipo NVARCHAR(25) NOT NULL, Valor NVARCHAR(100) NOT NULL,
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Tokens_Creacion DEFAULT (SYSUTCDATETIME()),
    FechaExpira DATETIME2(0) NOT NULL, Usado BIT NOT NULL CONSTRAINT DF_Tokens_Usado DEFAULT (0), FechaUso DATETIME2(0) NULL,
    CONSTRAINT PK_Tokens PRIMARY KEY (TokenID),
    CONSTRAINT FK_Tokens_Usuarios FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT CK_Tokens_Tipo CHECK (Tipo IN (N'CONFIRMACION_CORREO', N'DOBLE_FACTOR_2FA', N'PASSWORD_TEMPORAL')),
    CONSTRAINT CK_Tokens_Fechas CHECK (FechaExpira > FechaCreacion)
);
CREATE NONCLUSTERED INDEX IX_Tokens_UsuarioID ON dbo.Tokens (UsuarioID);
CREATE NONCLUSTERED INDEX IX_Tokens_Valor ON dbo.Tokens (Valor);

CREATE TABLE dbo.SolicitudesCambioPerfil (
    SolicitudID INT NOT NULL IDENTITY(1,1), UsuarioID INT NOT NULL, DatosPropuestos NVARCHAR(MAX) NOT NULL,
    EstadoSolicitudID TINYINT NOT NULL CONSTRAINT DF_SolicitudesCambioPerfil_Estado DEFAULT (1), AdminRevisorID INT NULL,
    FechaSolicitud DATETIME2(0) NOT NULL CONSTRAINT DF_SolicitudesCambioPerfil_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_SolicitudesCambioPerfil PRIMARY KEY (SolicitudID),
    CONSTRAINT FK_SolicitudesCambioPerfil_Usuario FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_SolicitudesCambioPerfil_Admin FOREIGN KEY (AdminRevisorID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_SolicitudesCambioPerfil_EstadosSolicitud FOREIGN KEY (EstadoSolicitudID) REFERENCES dbo.EstadosSolicitud (EstadoSolicitudID)
);
CREATE NONCLUSTERED INDEX IX_SolicitudesCambioPerfil_UsuarioID ON dbo.SolicitudesCambioPerfil (UsuarioID);
CREATE NONCLUSTERED INDEX IX_SolicitudesCambioPerfil_AdminRevisorID ON dbo.SolicitudesCambioPerfil (AdminRevisorID) WHERE AdminRevisorID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_SolicitudesCambioPerfil_EstadoSolicitudID ON dbo.SolicitudesCambioPerfil (EstadoSolicitudID);

CREATE TABLE dbo.ReunionesVirtuales (
    ReunionID INT NOT NULL IDENTITY(1,1), EmpresaID INT NOT NULL, AdminID INT NULL, FechaHora DATETIME2(0) NOT NULL,
    Enlace NVARCHAR(300) NOT NULL, Estado NVARCHAR(15) NOT NULL CONSTRAINT DF_ReunionesVirtuales_Estado DEFAULT (N'AGENDADA'),
    CONSTRAINT PK_ReunionesVirtuales PRIMARY KEY (ReunionID),
    CONSTRAINT FK_ReunionesVirtuales_Empresa FOREIGN KEY (EmpresaID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT FK_ReunionesVirtuales_Admin FOREIGN KEY (AdminID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT CK_ReunionesVirtuales_Estado CHECK (Estado IN (N'AGENDADA', N'REALIZADA', N'CANCELADA'))
);
CREATE NONCLUSTERED INDEX IX_ReunionesVirtuales_EmpresaID ON dbo.ReunionesVirtuales (EmpresaID);
CREATE NONCLUSTERED INDEX IX_ReunionesVirtuales_AdminID ON dbo.ReunionesVirtuales (AdminID) WHERE AdminID IS NOT NULL;

CREATE TABLE dbo.Notificaciones (
    NotificacionID INT NOT NULL IDENTITY(1,1), UsuarioID INT NOT NULL, Tipo NVARCHAR(50) NOT NULL, Mensaje NVARCHAR(500) NOT NULL,
    Leida BIT NOT NULL CONSTRAINT DF_Notificaciones_Leida DEFAULT (0),
    Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_Notificaciones_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Notificaciones PRIMARY KEY (NotificacionID),
    CONSTRAINT FK_Notificaciones_Usuarios FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuarios (UsuarioID)
);
CREATE NONCLUSTERED INDEX IX_Notificaciones_UsuarioID ON dbo.Notificaciones (UsuarioID);

CREATE TABLE dbo.LogActividad (
    LogID BIGINT NOT NULL IDENTITY(1,1), UsuarioID INT NULL, Accion NVARCHAR(50) NOT NULL, EntidadAfectada NVARCHAR(50) NOT NULL,
    Descripcion NVARCHAR(500) NULL, FechaHora DATETIME2(0) NOT NULL CONSTRAINT DF_LogActividad_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_LogActividad PRIMARY KEY (LogID),
    CONSTRAINT FK_LogActividad_Usuarios FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuarios (UsuarioID)
);
CREATE NONCLUSTERED INDEX IX_LogActividad_UsuarioID ON dbo.LogActividad (UsuarioID) WHERE UsuarioID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_LogActividad_FechaHora ON dbo.LogActividad (FechaHora DESC);

-- =============================================================================================
-- 8. SEED (catálogos)
-- =============================================================================================
INSERT INTO dbo.Roles (RolID, Codigo, Descripcion) VALUES
    (1, N'CLIENTE', N'Cliente que contrata envíos y transporte'),
    (2, N'OPERADOR', N'Operador logístico (servicios de envío)'),
    (3, N'EMPRESA', N'Empresa de transporte (rutas y flota)'),
    (4, N'ADMIN', N'Administrador de la plataforma');

INSERT INTO dbo.Generos (GeneroID, Codigo, Descripcion) VALUES
    (1, N'MASCULINO', N'Masculino'), (2, N'FEMENINO', N'Femenino'), (3, N'OTRO', N'Otro / prefiere no decir');

INSERT INTO dbo.EstadosCuenta (EstadoCuentaID, Codigo, Descripcion, EsTerminal) VALUES
    (1, N'ACTIVA', N'Cuenta operativa', 0), (2, N'SUSPENDIDA', N'Suspensión temporal por sanción', 0),
    (3, N'VETADA', N'Veto permanente (sin apelación)', 1);

INSERT INTO dbo.EstadosSolicitud (EstadoSolicitudID, Codigo, Descripcion, EsTerminal) VALUES
    (1, N'PENDIENTE', N'En espera de revisión del administrador', 0),
    (2, N'ACEPTADA', N'Aprobada por el administrador', 1), (3, N'RECHAZADA', N'Rechazada por el administrador', 1);

INSERT INTO dbo.EstadosReserva (EstadoReservaID, Codigo, Descripcion, EsTerminal) VALUES
    (1, N'ACTIVO', N'Reserva confirmada y vigente', 0), (2, N'EN_TRANSITO', N'Envío/trayecto en curso', 0),
    (3, N'ENTREGADO', N'Servicio completado', 1), (4, N'CANCELADO', N'Reserva cancelada', 1);

INSERT INTO dbo.EstadosPago (EstadoPagoID, Codigo, Descripcion, EsTerminal) VALUES
    (1, N'PENDIENTE', N'Pago iniciado, sin procesar', 0), (2, N'PROCESADO', N'Pago exitoso', 1),
    (3, N'RECHAZADO', N'Pago rechazado', 1);

INSERT INTO dbo.EstadosReporte (EstadoReporteID, Codigo, Descripcion, EsTerminal) VALUES
    (1, N'ENVIADO', N'Recibido pero no revisado', 0), (2, N'EN_REVISION', N'En proceso de análisis', 0),
    (3, N'ACEPTADO', N'Procede y se aplica sanción', 1), (4, N'RECHAZADO', N'Desestimado', 1);

INSERT INTO dbo.Zonas (ZonaID, Nombre, Tipo) VALUES
    (1, N'Guatemala', N'NACIONAL'), (2, N'Sacatepéquez', N'NACIONAL'), (3, N'Quetzaltenango', N'NACIONAL'),
    (4, N'Escuintla', N'NACIONAL'), (5, N'Petén', N'NACIONAL'), (6, N'Izabal', N'NACIONAL'),
    (7, N'Huehuetenango', N'NACIONAL'), (8, N'Internacional', N'INTERNACIONAL');

SELECT 'TrackFlow desplegado: ' + CAST(COUNT(*) AS NVARCHAR(10)) + ' tablas' AS Resultado
FROM sys.tables;
