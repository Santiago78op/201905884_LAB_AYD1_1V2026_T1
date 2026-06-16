-- =============================================================================================
-- TRACKFLOW-HUB · RESTRICCIONES CHECK (CK)  ·  catálogo de reglas de validación  ·  sin "GO"
-- =============================================================================================
-- Qué es un CHECK: una regla que CADA FILA debe cumplir; el motor rechaza el INSERT/UPDATE que la
--                  viole. Es validación garantizada por la base, no por el backend.
--
-- IMPORTANTE: estos mismos CHECK YA ESTÁN definidos en línea dentro de cada CREATE TABLE del DDL
--             principal (02–07). Este archivo los reúne aparte como REFERENCIA y es re-ejecutable:
--             cada bloque hace DROP IF EXISTS + ADD, así podés re-aplicar una regla sin tocar el resto.
--
-- ¿CHECK o lookup?  CHECK = enums FIJOS (método de pago, tipo de descuento, estados de ruta/reunión)
--             y reglas numéricas/de fecha. Conjuntos que pueden crecer (estados con ciclo de vida) =
--             tablas lookup con FK.
--
-- CÓMO CORRERLO en DBeaver: conexión sobre TrackFlow, ejecutar con Alt+X (⌥X).
-- =============================================================================================

USE TrackFlow;

-- ---- Zonas -------------------------------------------------------------------------------------
ALTER TABLE dbo.Zonas DROP CONSTRAINT IF EXISTS CK_Zonas_Tipo;
ALTER TABLE dbo.Zonas ADD CONSTRAINT CK_Zonas_Tipo CHECK (Tipo IN (N'NACIONAL', N'INTERNACIONAL'));

-- ---- Usuarios ----------------------------------------------------------------------------------
ALTER TABLE dbo.Usuarios DROP CONSTRAINT IF EXISTS CK_Usuarios_Correo;
ALTER TABLE dbo.Usuarios ADD CONSTRAINT CK_Usuarios_Correo CHECK (Correo LIKE N'%_@_%._%');

-- ---- ServiciosEnvio ----------------------------------------------------------------------------
ALTER TABLE dbo.ServiciosEnvio DROP CONSTRAINT IF EXISTS CK_ServiciosEnvio_Capacidad;
ALTER TABLE dbo.ServiciosEnvio ADD CONSTRAINT CK_ServiciosEnvio_Capacidad CHECK (CapacidadCargaKg > 0);
ALTER TABLE dbo.ServiciosEnvio DROP CONSTRAINT IF EXISTS CK_ServiciosEnvio_Precio;
ALTER TABLE dbo.ServiciosEnvio ADD CONSTRAINT CK_ServiciosEnvio_Precio CHECK (PrecioEnvio >= 0);

-- ---- Rutas -------------------------------------------------------------------------------------
ALTER TABLE dbo.Rutas DROP CONSTRAINT IF EXISTS CK_Rutas_Estado;
ALTER TABLE dbo.Rutas ADD CONSTRAINT CK_Rutas_Estado CHECK (Estado IN (N'ACTIVA', N'SUSPENDIDA', N'CANCELADA'));
ALTER TABLE dbo.Rutas DROP CONSTRAINT IF EXISTS CK_Rutas_Tiempo;
ALTER TABLE dbo.Rutas ADD CONSTRAINT CK_Rutas_Tiempo CHECK (TiempoEstimadoMin > 0);
ALTER TABLE dbo.Rutas DROP CONSTRAINT IF EXISTS CK_Rutas_Precio;
ALTER TABLE dbo.Rutas ADD CONSTRAINT CK_Rutas_Precio CHECK (Precio >= 0);
ALTER TABLE dbo.Rutas DROP CONSTRAINT IF EXISTS CK_Rutas_Zonas;
ALTER TABLE dbo.Rutas ADD CONSTRAINT CK_Rutas_Zonas CHECK (ZonaOrigenID <> ZonaDestinoID);

-- ---- Flota -------------------------------------------------------------------------------------
ALTER TABLE dbo.Flota DROP CONSTRAINT IF EXISTS CK_Flota_Capacidad;
ALTER TABLE dbo.Flota ADD CONSTRAINT CK_Flota_Capacidad CHECK (Capacidad > 0);

-- ---- Tarjetas ----------------------------------------------------------------------------------
ALTER TABLE dbo.Tarjetas DROP CONSTRAINT IF EXISTS CK_Tarjetas_Metodo;
ALTER TABLE dbo.Tarjetas ADD CONSTRAINT CK_Tarjetas_Metodo CHECK (Metodo IN (N'TARJETA', N'WALLET'));
ALTER TABLE dbo.Tarjetas DROP CONSTRAINT IF EXISTS CK_Tarjetas_Saldo;
ALTER TABLE dbo.Tarjetas ADD CONSTRAINT CK_Tarjetas_Saldo CHECK (Saldo >= 0);

-- ---- ItemsCarrito (coherencia Tipo <-> FK) -----------------------------------------------------
ALTER TABLE dbo.ItemsCarrito DROP CONSTRAINT IF EXISTS CK_ItemsCarrito_Tipo;
ALTER TABLE dbo.ItemsCarrito ADD CONSTRAINT CK_ItemsCarrito_Tipo CHECK (Tipo IN (N'ENVIO', N'TRANSPORTE'));
ALTER TABLE dbo.ItemsCarrito DROP CONSTRAINT IF EXISTS CK_ItemsCarrito_Monto;
ALTER TABLE dbo.ItemsCarrito ADD CONSTRAINT CK_ItemsCarrito_Monto CHECK (Monto >= 0);
ALTER TABLE dbo.ItemsCarrito DROP CONSTRAINT IF EXISTS CK_ItemsCarrito_Coherencia;
ALTER TABLE dbo.ItemsCarrito ADD CONSTRAINT CK_ItemsCarrito_Coherencia CHECK (
    (Tipo = N'ENVIO'      AND ServicioEnvioID IS NOT NULL AND RutaID IS NULL) OR
    (Tipo = N'TRANSPORTE' AND RutaID          IS NOT NULL AND ServicioEnvioID IS NULL));

-- ---- Reservaciones (coherencia Tipo <-> FK + fechas) -------------------------------------------
ALTER TABLE dbo.Reservaciones DROP CONSTRAINT IF EXISTS CK_Reservaciones_Tipo;
ALTER TABLE dbo.Reservaciones ADD CONSTRAINT CK_Reservaciones_Tipo CHECK (Tipo IN (N'ENVIO', N'TRANSPORTE'));
ALTER TABLE dbo.Reservaciones DROP CONSTRAINT IF EXISTS CK_Reservaciones_Monto;
ALTER TABLE dbo.Reservaciones ADD CONSTRAINT CK_Reservaciones_Monto CHECK (Monto >= 0);
ALTER TABLE dbo.Reservaciones DROP CONSTRAINT IF EXISTS CK_Reservaciones_Fechas;
ALTER TABLE dbo.Reservaciones ADD CONSTRAINT CK_Reservaciones_Fechas CHECK (FechaFin IS NULL OR FechaFin >= FechaInicio);
ALTER TABLE dbo.Reservaciones DROP CONSTRAINT IF EXISTS CK_Reservaciones_Coherencia;
ALTER TABLE dbo.Reservaciones ADD CONSTRAINT CK_Reservaciones_Coherencia CHECK (
    (Tipo = N'ENVIO'      AND ServicioEnvioID IS NOT NULL AND RutaID IS NULL) OR
    (Tipo = N'TRANSPORTE' AND RutaID          IS NOT NULL AND ServicioEnvioID IS NULL));

-- ---- Pagos -------------------------------------------------------------------------------------
ALTER TABLE dbo.Pagos DROP CONSTRAINT IF EXISTS CK_Pagos_Monto;
ALTER TABLE dbo.Pagos ADD CONSTRAINT CK_Pagos_Monto CHECK (Monto >= 0);

-- ---- Calificaciones ----------------------------------------------------------------------------
ALTER TABLE dbo.Calificaciones DROP CONSTRAINT IF EXISTS CK_Calificaciones_Puntuacion;
ALTER TABLE dbo.Calificaciones ADD CONSTRAINT CK_Calificaciones_Puntuacion CHECK (Puntuacion BETWEEN 1 AND 5);

-- ---- Cupones -----------------------------------------------------------------------------------
ALTER TABLE dbo.Cupones DROP CONSTRAINT IF EXISTS CK_Cupones_TipoDesc;
ALTER TABLE dbo.Cupones ADD CONSTRAINT CK_Cupones_TipoDesc CHECK (TipoDescuento IN (N'PORCENTAJE', N'MONTO'));
ALTER TABLE dbo.Cupones DROP CONSTRAINT IF EXISTS CK_Cupones_Valor;
ALTER TABLE dbo.Cupones ADD CONSTRAINT CK_Cupones_Valor CHECK (ValorDescuento >= 0);
ALTER TABLE dbo.Cupones DROP CONSTRAINT IF EXISTS CK_Cupones_Fechas;
ALTER TABLE dbo.Cupones ADD CONSTRAINT CK_Cupones_Fechas CHECK (FechaFin >= FechaInicio);

-- ---- Reportes ----------------------------------------------------------------------------------
ALTER TABLE dbo.Reportes DROP CONSTRAINT IF EXISTS CK_Reportes_Tipo;
ALTER TABLE dbo.Reportes ADD CONSTRAINT CK_Reportes_Tipo CHECK (Tipo IN (N'ENVIO', N'TRANSPORTE', N'CLIENTE'));
ALTER TABLE dbo.Reportes DROP CONSTRAINT IF EXISTS CK_Reportes_Distintos;
ALTER TABLE dbo.Reportes ADD CONSTRAINT CK_Reportes_Distintos CHECK (ReportanteID <> ReportadoID);

-- ---- EvidenciasReporte -------------------------------------------------------------------------
ALTER TABLE dbo.EvidenciasReporte DROP CONSTRAINT IF EXISTS CK_EvidenciasReporte_Tipo;
ALTER TABLE dbo.EvidenciasReporte ADD CONSTRAINT CK_EvidenciasReporte_Tipo CHECK (Tipo IN (N'FOTO', N'VIDEO'));

-- ---- Sanciones ---------------------------------------------------------------------------------
ALTER TABLE dbo.Sanciones DROP CONSTRAINT IF EXISTS CK_Sanciones_Tipo;
ALTER TABLE dbo.Sanciones ADD CONSTRAINT CK_Sanciones_Tipo CHECK (Tipo IN (N'SUSPENSION_TEMPORAL', N'VETO_PERMANENTE'));
ALTER TABLE dbo.Sanciones DROP CONSTRAINT IF EXISTS CK_Sanciones_Fechas;
ALTER TABLE dbo.Sanciones ADD CONSTRAINT CK_Sanciones_Fechas CHECK (FechaFin IS NULL OR FechaFin >= FechaInicio);

-- ---- Tokens ------------------------------------------------------------------------------------
ALTER TABLE dbo.Tokens DROP CONSTRAINT IF EXISTS CK_Tokens_Tipo;
ALTER TABLE dbo.Tokens ADD CONSTRAINT CK_Tokens_Tipo CHECK (Tipo IN (N'CONFIRMACION_CORREO', N'DOBLE_FACTOR_2FA', N'PASSWORD_TEMPORAL'));
ALTER TABLE dbo.Tokens DROP CONSTRAINT IF EXISTS CK_Tokens_Fechas;
ALTER TABLE dbo.Tokens ADD CONSTRAINT CK_Tokens_Fechas CHECK (FechaExpira > FechaCreacion);

-- ---- ReunionesVirtuales ------------------------------------------------------------------------
ALTER TABLE dbo.ReunionesVirtuales DROP CONSTRAINT IF EXISTS CK_ReunionesVirtuales_Estado;
ALTER TABLE dbo.ReunionesVirtuales ADD CONSTRAINT CK_ReunionesVirtuales_Estado CHECK (Estado IN (N'AGENDADA', N'REALIZADA', N'CANCELADA'));
