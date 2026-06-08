-- =============================================================================================
-- 01 · BASE DE DATOS  ·  EVENTCORE
-- =============================================================================================
-- Crea la base (si no existe) y se posiciona dentro de ella.
-- Idempotente: DB_ID() devuelve NULL si la base no existe -> solo la crea la primera vez.
-- En una sola línea para que DBeaver no parta la sentencia.
-- Correr con Alt+X (⌥X).
-- =============================================================================================

IF DB_ID(N'EventCore') IS NULL CREATE DATABASE EventCore;

USE EventCore;

SELECT DB_NAME() AS BaseDeDatosActual;   -- debe devolver 'EventCore'
