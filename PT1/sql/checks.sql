-- =============================================================================================
-- EVENTCORE · RESTRICCIONES CHECK (CK)  ·  catálogo de reglas de validación  ·  sin "GO"
-- =============================================================================================
-- Qué es un CHECK: una regla que CADA FILA debe cumplir; el motor rechaza el INSERT/UPDATE que
--                  la viole. Es validación de datos garantizada por la base, no por el backend.
--
-- IMPORTANTE: estos mismos CHECK YA ESTÁN definidos en línea dentro de cada CREATE TABLE del DDL
--             principal. Este archivo los reúne aparte como REFERENCIA/DOCUMENTACIÓN y, además,
--             es re-ejecutable: cada bloque hace DROP IF EXISTS + ADD, así lo podés correr para
--             re-aplicar una regla sin tocar el resto del esquema.
--
-- ¿CHECK o tabla lookup?  Los CHECK aquí son para ENUMS FIJOS (no cambian nunca: modalidad, método
--             de pago, tipo de tarjeta) y para REGLAS NUMÉRICAS/DE FECHA. Los conjuntos que SÍ
--             pueden crecer (estados, roles) NO van en CHECK: van en tablas lookup con FK.
--
-- CÓMO CORRERLO en DBeaver: conexión sobre Cumbre, ejecutar con Alt+X (⌥X).
-- =============================================================================================

USE Cumbre;

-- ---- Dias --------------------------------------------------------------------------------------
-- El día de la semana solo puede ser 1..7 (1 = Lunes … 7 = Domingo, ISO-8601). Blinda el catálogo.
ALTER TABLE dbo.Dias DROP CONSTRAINT IF EXISTS CK_Dias_Rango;
ALTER TABLE dbo.Dias ADD CONSTRAINT CK_Dias_Rango CHECK (DiaID BETWEEN 1 AND 7);

-- ---- Horarios ----------------------------------------------------------------------------------
-- Un bloque de hora no puede terminar antes (ni igual) de empezar. Evita horarios imposibles.
ALTER TABLE dbo.Horarios DROP CONSTRAINT IF EXISTS CK_Horarios_Orden;
ALTER TABLE dbo.Horarios ADD CONSTRAINT CK_Horarios_Orden CHECK (HoraFin > HoraInicio);

-- ---- Usuarios ----------------------------------------------------------------------------------
-- El correo debe tener forma de email (algo @ algo . algo). Validación mínima a nivel BD.
ALTER TABLE dbo.Usuarios DROP CONSTRAINT IF EXISTS CK_Usuarios_Correo;
ALTER TABLE dbo.Usuarios ADD CONSTRAINT CK_Usuarios_Correo CHECK (Correo LIKE N'%_@_%._%');

-- ---- Ponentes ----------------------------------------------------------------------------------
-- Mismo criterio de email para el correo de contacto del ponente.
ALTER TABLE dbo.Ponentes DROP CONSTRAINT IF EXISTS CK_Ponentes_Correo;
ALTER TABLE dbo.Ponentes ADD CONSTRAINT CK_Ponentes_Correo CHECK (CorreoContacto LIKE N'%_@_%._%');

-- ---- Salas -------------------------------------------------------------------------------------
-- Una sala con capacidad 0 o negativa no tiene sentido (se usa en el reporte de ocupación).
ALTER TABLE dbo.Salas DROP CONSTRAINT IF EXISTS CK_Salas_Capacidad;
ALTER TABLE dbo.Salas ADD CONSTRAINT CK_Salas_Capacidad CHECK (Capacidad > 0);

-- ---- TiposEntrada ------------------------------------------------------------------------------
-- Una tarifa no puede ser negativa (0 es válido: entradas gratis).
ALTER TABLE dbo.TiposEntrada DROP CONSTRAINT IF EXISTS CK_TiposEntrada_Tarifa;
ALTER TABLE dbo.TiposEntrada ADD CONSTRAINT CK_TiposEntrada_Tarifa CHECK (Tarifa >= 0);

-- ---- Eventos -----------------------------------------------------------------------------------
-- Modalidad: enum FIJO del dominio. Solo estos tres valores.
ALTER TABLE dbo.Eventos DROP CONSTRAINT IF EXISTS CK_Eventos_Modalidad;
ALTER TABLE dbo.Eventos ADD CONSTRAINT CK_Eventos_Modalidad
    CHECK (Modalidad IN (N'PRESENCIAL', N'VIRTUAL', N'HIBRIDA'));

-- Categoría: enum FIJO. Clasifica el tipo de evento.
ALTER TABLE dbo.Eventos DROP CONSTRAINT IF EXISTS CK_Eventos_Categoria;
ALTER TABLE dbo.Eventos ADD CONSTRAINT CK_Eventos_Categoria
    CHECK (Categoria IN (N'ACADEMICO', N'CORPORATIVO', N'CULTURAL', N'TECNOLOGICO', N'OTRO'));

-- Modalidad de inscripción: enum FIJO. Cómo se entra al evento.
ALTER TABLE dbo.Eventos DROP CONSTRAINT IF EXISTS CK_Eventos_ModInscripcion;
ALTER TABLE dbo.Eventos ADD CONSTRAINT CK_Eventos_ModInscripcion
    CHECK (ModalidadInscripcion IN (N'ABIERTA', N'APROBACION', N'INVITACION'));

-- Capacidad máxima del evento: siempre positiva.
ALTER TABLE dbo.Eventos DROP CONSTRAINT IF EXISTS CK_Eventos_Capacidad;
ALTER TABLE dbo.Eventos ADD CONSTRAINT CK_Eventos_Capacidad CHECK (CapacidadMaxima > 0);

-- Coherencia de fechas: el evento no puede terminar antes de empezar.
ALTER TABLE dbo.Eventos DROP CONSTRAINT IF EXISTS CK_Eventos_Fechas;
ALTER TABLE dbo.Eventos ADD CONSTRAINT CK_Eventos_Fechas CHECK (FechaFin >= FechaInicio);

-- ---- Sesiones ----------------------------------------------------------------------------------
-- El cupo de una sesión debe ser positivo.
ALTER TABLE dbo.Sesiones DROP CONSTRAINT IF EXISTS CK_Sesiones_Cupo;
ALTER TABLE dbo.Sesiones ADD CONSTRAINT CK_Sesiones_Cupo CHECK (CupoMaximo > 0);

-- ---- Inscripciones -----------------------------------------------------------------------------
-- El monto de la inscripción no puede ser negativo (0 = evento gratis).
ALTER TABLE dbo.Inscripciones DROP CONSTRAINT IF EXISTS CK_Inscripciones_Monto;
ALTER TABLE dbo.Inscripciones ADD CONSTRAINT CK_Inscripciones_Monto CHECK (Monto >= 0);

-- ---- Tarjetas ----------------------------------------------------------------------------------
-- Tipo de tarjeta: enum FIJO. Solo débito o crédito.
ALTER TABLE dbo.Tarjetas DROP CONSTRAINT IF EXISTS CK_Tarjetas_Tipo;
ALTER TABLE dbo.Tarjetas ADD CONSTRAINT CK_Tarjetas_Tipo CHECK (Tipo IN (N'DEBITO', N'CREDITO'));

-- ---- Pagos -------------------------------------------------------------------------------------
-- Método de pago: enum FIJO. Tarjeta o transferencia.
ALTER TABLE dbo.Pagos DROP CONSTRAINT IF EXISTS CK_Pagos_Metodo;
ALTER TABLE dbo.Pagos ADD CONSTRAINT CK_Pagos_Metodo CHECK (Metodo IN (N'TARJETA', N'TRANSFERENCIA'));

-- El monto del pago no puede ser negativo.
ALTER TABLE dbo.Pagos DROP CONSTRAINT IF EXISTS CK_Pagos_Monto;
ALTER TABLE dbo.Pagos ADD CONSTRAINT CK_Pagos_Monto CHECK (Monto >= 0);

-- ---- SolicitudesCancelacion --------------------------------------------------------------------
-- El monto a reembolsar no puede ser negativo (regla del enunciado: típicamente 80% de lo pagado).
ALTER TABLE dbo.SolicitudesCancelacion DROP CONSTRAINT IF EXISTS CK_SolicitudesCancelacion_Monto;
ALTER TABLE dbo.SolicitudesCancelacion ADD CONSTRAINT CK_SolicitudesCancelacion_Monto CHECK (MontoReembolso >= 0);

-- ---- ConfirmacionesCorreo ----------------------------------------------------------------------
-- Un token de confirmación no puede vencer antes (ni igual) de cuando se creó.
ALTER TABLE dbo.ConfirmacionesCorreo DROP CONSTRAINT IF EXISTS CK_ConfirmacionesCorreo_Fechas;
ALTER TABLE dbo.ConfirmacionesCorreo ADD CONSTRAINT CK_ConfirmacionesCorreo_Fechas CHECK (FechaExpira > FechaCreacion);

-- =============================================================================================
-- Verificación: lista todos los CHECK del esquema y su definición.
-- =============================================================================================
SELECT
    OBJECT_NAME(cc.parent_object_id) AS Tabla,
    cc.name                          AS NombreCheck,
    cc.definition                    AS Regla
FROM sys.check_constraints cc
ORDER BY Tabla, NombreCheck;
