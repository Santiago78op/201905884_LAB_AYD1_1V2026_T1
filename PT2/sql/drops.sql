-- =============================================================================================
-- TRACKFLOW-HUB · LIMPIEZA (DROP de todas las tablas)  ·  sin "GO"
-- =============================================================================================
-- Qué hace: borra las 31 tablas de TrackFlow. Úsalo para "empezar de cero" antes de re-correr
--           el DDL, o para desmontar el esquema completo.
--
-- LA REGLA DE ORO DEL ORDEN:
--   No podés borrar una tabla "padre" si todavía existe una "hija" que la referencia por FK.
--   Por eso se borra en ORDEN INVERSO al de creación: PRIMERO LOS HIJOS, AL FINAL LOS PADRES.
--   `DROP TABLE IF EXISTS` = idempotente: si la tabla no existe, no falla.
--
-- CÓMO CORRERLO en DBeaver: posicioná la conexión en la base TrackFlow y ejecutá con Alt+X (⌥X).
-- =============================================================================================

USE TrackFlow;

-- ---- NIVEL HOJA: nadie depende de ellas (07 soporte + interacción) ----------------------------
DROP TABLE IF EXISTS dbo.LogActividad;             -- bitácora; solo apunta a Usuarios
DROP TABLE IF EXISTS dbo.Notificaciones;           -- solo apunta a Usuarios
DROP TABLE IF EXISTS dbo.ReunionesVirtuales;       -- solo apunta a Usuarios
DROP TABLE IF EXISTS dbo.SolicitudesCambioPerfil;  -- apunta a Usuarios / EstadosSolicitud
DROP TABLE IF EXISTS dbo.Tokens;                   -- apunta a Usuarios
DROP TABLE IF EXISTS dbo.Sanciones;                -- hija de Usuarios / Reportes
DROP TABLE IF EXISTS dbo.EvidenciasReporte;        -- hija de Reportes (ON DELETE CASCADE)
DROP TABLE IF EXISTS dbo.CuponesCanjeados;         -- hija de Cupones / Usuarios / Reservaciones
DROP TABLE IF EXISTS dbo.Calificaciones;           -- hija de Reservaciones / Usuarios
DROP TABLE IF EXISTS dbo.Pagos;                    -- hija de Reservaciones / Tarjetas / EstadosPago

-- ---- NIVEL INTERMEDIO: ya borrados sus hijos --------------------------------------------------
DROP TABLE IF EXISTS dbo.Reportes;                 -- la referenciaban Sanciones, EvidenciasReporte
DROP TABLE IF EXISTS dbo.Cupones;                  -- la referenciaba CuponesCanjeados
DROP TABLE IF EXISTS dbo.Reservaciones;            -- la referenciaban Pagos, Calificaciones, Reportes...
DROP TABLE IF EXISTS dbo.ItemsCarrito;             -- hija de Usuarios / ServiciosEnvio / Rutas
DROP TABLE IF EXISTS dbo.Tarjetas;                 -- la referenciaba Pagos
DROP TABLE IF EXISTS dbo.FotosServicio;            -- hija de ServiciosEnvio (ON DELETE CASCADE)

-- ---- PROVEEDORES Y PERFILES -------------------------------------------------------------------
DROP TABLE IF EXISTS dbo.Flota;                    -- hija de Usuarios
DROP TABLE IF EXISTS dbo.Rutas;                    -- la referenciaban ItemsCarrito, Reservaciones
DROP TABLE IF EXISTS dbo.ServiciosEnvio;           -- la referenciaban FotosServicio, ItemsCarrito, Reservaciones
DROP TABLE IF EXISTS dbo.PerfilEmpresa;            -- subtipo de Usuarios
DROP TABLE IF EXISTS dbo.PerfilOperador;           -- subtipo de Usuarios
DROP TABLE IF EXISTS dbo.PerfilCliente;            -- subtipo de Usuarios
DROP TABLE IF EXISTS dbo.Usuarios;                 -- la referenciaba casi todo

-- ---- LOOKUP / CATÁLOGOS: los "padres raíz", se borran al final --------------------------------
DROP TABLE IF EXISTS dbo.Zonas;                    -- la referenciaban PerfilOperador, ServiciosEnvio, Rutas
DROP TABLE IF EXISTS dbo.EstadosReporte;           -- la referenciaba Reportes
DROP TABLE IF EXISTS dbo.EstadosPago;              -- la referenciaba Pagos
DROP TABLE IF EXISTS dbo.EstadosReserva;           -- la referenciaba Reservaciones
DROP TABLE IF EXISTS dbo.EstadosSolicitud;         -- la referenciaban PerfilOperador/Empresa, SolicitudesCambioPerfil
DROP TABLE IF EXISTS dbo.EstadosCuenta;            -- la referenciaba Usuarios
DROP TABLE IF EXISTS dbo.Generos;                  -- la referenciaba PerfilOperador
DROP TABLE IF EXISTS dbo.Roles;                    -- la referenciaba Usuarios

-- Tip: para borrar TAMBIÉN la base entera, primero salí de ella y luego:
--   USE master;
--   DROP DATABASE IF EXISTS TrackFlow;
