-- =============================================================================================
-- EVENTCORE · LIMPIEZA (DROP de todas las tablas)  ·  sin "GO"
-- =============================================================================================
-- Qué hace: borra las 21 tablas de EventCore. Úsalo para "empezar de cero" antes de re-correr
--           el DDL, o para desmontar el esquema completo.
--
-- LA REGLA DE ORO DEL ORDEN:
--   No podés borrar una tabla "padre" si todavía existe una "hija" que la referencia por FK
--   (el motor te lo impide para no dejar referencias huérfanas). Por eso se borra en ORDEN
--   INVERSO al de creación: PRIMERO LOS HIJOS, AL FINAL LOS PADRES.
--
--   `DROP TABLE IF EXISTS` = idempotente: si la tabla no existe, no falla (no rompe el script).
--
-- CÓMO CORRERLO en DBeaver: posicioná la conexión en la base EventCore y ejecutá con Alt+X (⌥X).
-- =============================================================================================

USE EventCore;

-- ---- NIVEL HOJA: nadie depende de ellas, se borran primero -----------------------------------
DROP TABLE IF EXISTS dbo.LogActividad;            -- bitácora; solo apunta a Usuarios (nadie la referencia)
DROP TABLE IF EXISTS dbo.SolicitudesCancelacion;  -- hija de Inscripciones / Usuarios / EstadosSolicitud
DROP TABLE IF EXISTS dbo.Pagos;                   -- hija de Inscripciones / Tarjetas / Usuarios / EstadosPago
DROP TABLE IF EXISTS dbo.InscripcionSesion;       -- tabla puente N:M (hija de Inscripciones y Sesiones)
DROP TABLE IF EXISTS dbo.CodigosInvitacion;       -- hija de Eventos / Usuarios
DROP TABLE IF EXISTS dbo.Tarjetas;                -- hija de Usuarios (la referencia Pagos, ya borrada arriba)
DROP TABLE IF EXISTS dbo.MaterialesRecurso;       -- hija de Sesiones (ON DELETE CASCADE)

-- ---- NIVEL INTERMEDIO: ya borrados sus hijos, ahora se pueden quitar -------------------------
DROP TABLE IF EXISTS dbo.Inscripciones;           -- la referenciaban Pagos, SolicitudesCancelacion, InscripcionSesion
DROP TABLE IF EXISTS dbo.Sesiones;                -- la referenciaban MaterialesRecurso e InscripcionSesion
DROP TABLE IF EXISTS dbo.Eventos;                 -- la referenciaban Sesiones, Inscripciones, CodigosInvitacion

-- ---- CATÁLOGOS BASE: solo se borran cuando ya no queda quién los referencie -------------------
DROP TABLE IF EXISTS dbo.TiposEntrada;            -- la referenciaba Inscripciones
DROP TABLE IF EXISTS dbo.Salas;                   -- la referenciaba Sesiones
DROP TABLE IF EXISTS dbo.Ponentes;                -- la referenciaba Sesiones
DROP TABLE IF EXISTS dbo.Usuarios;                -- la referenciaba casi todo (admin, asistente, revisor…)

-- ---- CATÁLOGOS DE AGENDA: se borran DESPUÉS de Sesiones, que los referencia -------------------
DROP TABLE IF EXISTS dbo.Horarios;                -- la referenciaba Sesiones (HorarioID)
DROP TABLE IF EXISTS dbo.Dias;                    -- la referenciaba Sesiones (DiaID)

-- ---- LOOKUP DE ESTADOS/ROL: son los "padres raíz", se borran al final ------------------------
DROP TABLE IF EXISTS dbo.EstadosSolicitud;        -- la referenciaba SolicitudesCancelacion
DROP TABLE IF EXISTS dbo.EstadosPago;             -- la referenciaba Pagos
DROP TABLE IF EXISTS dbo.EstadosInscripcion;      -- la referenciaba Inscripciones
DROP TABLE IF EXISTS dbo.EstadosEvento;           -- la referenciaba Eventos
DROP TABLE IF EXISTS dbo.Roles;                   -- la referenciaba Usuarios

-- Tip: si querés borrar TAMBIÉN la base entera, primero salí de ella y luego:
--   USE master;
--   DROP DATABASE IF EXISTS EventCore;
