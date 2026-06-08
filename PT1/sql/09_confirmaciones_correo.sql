-- =============================================================================================
-- 09 · CONFIRMACIÓN DE CORREO (soporte de signup/login)  ·  EVENTCORE
-- =============================================================================================
-- Soporta la regla del enunciado: "para iniciar sesión, el asistente deberá confirmar su correo".
-- Flujo: en el registro, el backend genera un Token, lo guarda acá y lo envía por correo.
--        Al abrir el enlace (GET /confirmar/:token) el backend busca el Token, valida que NO esté
--        usado y NO esté vencido, marca Usuarios.CorreoConfirmado = 1, y aquí Usado = 1 + FechaUso.
-- "Reenviar verificación" = simplemente insertar una fila nueva (varias por usuario son válidas).
--
-- Depende SOLO de Usuarios (creada en 03). No lleva seed. Correr con Alt+X (⌥X).
-- =============================================================================================

USE Cumbre;

CREATE TABLE dbo.ConfirmacionesCorreo (
    ConfirmacionID INT           NOT NULL IDENTITY(1,1),
    UsuarioID      INT           NOT NULL,
    Token          NVARCHAR(100) NOT NULL,                  -- código aleatorio enviado por correo
    FechaCreacion  DATETIME2(0)  NOT NULL CONSTRAINT DF_ConfirmacionesCorreo_Creacion DEFAULT (SYSUTCDATETIME()),
    FechaExpira    DATETIME2(0)  NOT NULL,                  -- el backend la fija (p.ej. creación + 24h)
    Usado          BIT           NOT NULL CONSTRAINT DF_ConfirmacionesCorreo_Usado DEFAULT (0),
    FechaUso       DATETIME2(0)  NULL,                      -- cuándo se confirmó (NULL si aún no)

    CONSTRAINT PK_ConfirmacionesCorreo          PRIMARY KEY (ConfirmacionID),
    CONSTRAINT UQ_ConfirmacionesCorreo_Token    UNIQUE (Token),                      -- el token no se repite
    CONSTRAINT FK_ConfirmacionesCorreo_Usuarios FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuarios (UsuarioID),
    CONSTRAINT CK_ConfirmacionesCorreo_Fechas   CHECK (FechaExpira > FechaCreacion)  -- no puede vencer antes de crearse
);
CREATE NONCLUSTERED INDEX IX_ConfirmacionesCorreo_UsuarioID ON dbo.ConfirmacionesCorreo (UsuarioID);
-- (El UNIQUE de Token ya crea su propio índice, ideal para el lookup de GET /confirmar/:token.)
