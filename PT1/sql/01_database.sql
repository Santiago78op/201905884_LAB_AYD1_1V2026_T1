-- =============================================================================================
-- 01 · BASE DE DATOS  ·  EVENTCORE
-- =============================================================================================
-- Crea la base (si no existe) y se posiciona dentro de ella.
-- Idempotente: DB_ID() devuelve NULL si la base no existe -> solo la crea la primera vez.
-- En una sola línea para que DBeaver no parta la sentencia.
-- Correr con Alt+X (⌥X).
-- =============================================================================================

IF DB_ID(N'Cumbre') IS NULL CREATE DATABASE Cumbre;

USE Cumbre;

SELECT DB_NAME() AS BaseDeDatosActual;   -- debe devolver 'Cumbre'
