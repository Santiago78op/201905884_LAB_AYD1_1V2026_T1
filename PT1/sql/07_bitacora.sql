-- =============================================================================================
-- 07 · BITÁCORA  ·  EVENTCORE
-- =============================================================================================
-- LogActividad: respalda el reporte "Log de todas las actividades del sistema".
-- LogID es BIGINT porque esta tabla crece mucho. UsuarioID NULL si la acción la hace el sistema.
-- Requiere: 03_catalogos_base.sql (Usuarios)  ·  Correr con Alt+X (⌥X).
-- =============================================================================================

USE Cumbre;

CREATE TABLE dbo.LogActividad (
    LogID           BIGINT         NOT NULL IDENTITY(1,1),
    UsuarioID       INT            NULL,
    Accion          NVARCHAR(50)   NOT NULL,
    EntidadAfectada NVARCHAR(50)   NOT NULL,
    Descripcion     NVARCHAR(500)  NULL,
    FechaHora       DATETIME2(0)   NOT NULL CONSTRAINT DF_LogActividad_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_LogActividad          PRIMARY KEY (LogID),
    CONSTRAINT FK_LogActividad_Usuarios FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuarios (UsuarioID)
);
CREATE NONCLUSTERED INDEX IX_LogActividad_UsuarioID ON dbo.LogActividad (UsuarioID) WHERE UsuarioID IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_LogActividad_FechaHora ON dbo.LogActividad (FechaHora DESC);
