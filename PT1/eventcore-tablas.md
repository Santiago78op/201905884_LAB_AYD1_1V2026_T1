# EVENTCORE — Tablas y campos

> Diccionario de datos de las **22 tablas** (15 de negocio + 7 lookup/catálogo). Coincide 1:1 con
> los scripts de `sql/`. Motor: **SQL Server 2016+**, schema `dbo`.
> Las **relaciones** (FKs, cardinalidades, diagrama ER) están en `eventcore-relaciones.md`.

---

## Cómo leer las tablas (leyenda)

| Marca | Significa | En el DDL |
|-------|-----------|-----------|
| **PK** | *Primary Key* — identifica de forma única cada fila. | `PRIMARY KEY (...)` |
| **FK** | *Foreign Key* — apunta al PK de otra tabla. | `FOREIGN KEY (...) REFERENCES ...` |
| **UQ** | *Unique* — no se permite repetir (pero no es la PK). | `UNIQUE (...)` |
| **CK** | *Check* — regla que el valor debe cumplir. | `CHECK (...)` |
| **IDENTITY** | El motor genera el número solo (1,2,3…). | `IDENTITY(1,1)` |
| **Nulo = Sí** | Campo opcional (puede quedar vacío). | columna `NULL` |
| **Nulo = No** | Campo obligatorio. | columna `NOT NULL` |
| `DEFAULT x` | Si no se manda valor, el motor pone `x`. | `DEFAULT (x)` |

**Tipos de dato (qué guarda y cuánto pesa):**

| Tipo | Qué guarda | Tamaño / rango |
|------|-----------|----------------|
| `TINYINT` | enteros muy pequeños (IDs de lookup) | 0 a 255 (1 byte) |
| `INT` | enteros normales (IDs de negocio) | ±2,100 millones (4 bytes) |
| `BIGINT` | enteros enormes (la bitácora crece mucho) | gigantesco (8 bytes) |
| `NVARCHAR(n)` | texto Unicode de **hasta `n`** caracteres | `n` = tope; ocupa lo que use |
| `NVARCHAR(MAX)` | texto largo sin tope práctico | hasta ~1 GB |
| `DECIMAL(10,2)` | dinero exacto: 10 dígitos, 2 decimales | hasta 99,999,999.99 |
| `DATETIME2(0)` | fecha + hora, sin fracciones de segundo | precisión = segundos |
| `BIT` | booleano (sí/no, 1/0) | 1 bit |

---

## 1. Lookup — PK explícita (no IDENTITY: los IDs se siembran a mano y son estables)

**`Roles`**  ·  *catálogo de roles de usuario*

| Campo | Tipo | Nulo | Clave | Regla | Notas |
|-------|------|:--:|-------|-------|-------|
| `RolID` | TINYINT | No | **PK** | — | se siembra 1, 2… |
| `Codigo` | NVARCHAR(20) | No | **UQ** | — | `ADMIN`, `ASISTENTE` |
| `Descripcion` | NVARCHAR(100) | Sí | — | — | texto legible |

> Semilla: `1 ADMIN`, `2 ASISTENTE`.

**`EstadosEvento` · `EstadosInscripcion` · `EstadosPago` · `EstadosSolicitud`** — misma estructura
(solo cambia el nombre del PK):

| Campo | Tipo | Nulo | Clave | Regla | Notas |
|-------|------|:--:|-------|-------|-------|
| `Estado…ID` | TINYINT | No | **PK** | — | `EstadoEventoID`, `EstadoInscripcionID`, etc. |
| `Codigo` | NVARCHAR(20) | No | **UQ** | — | `PENDIENTE`, `CONFIRMADO`… |
| `Descripcion` | NVARCHAR(100) | Sí | — | — | texto legible |
| `EsTerminal` | BIT | No | — | DEFAULT `0` | `1` = estado cerrado (sin más transiciones) |

> Semillas (`*` = terminal):
> - **EstadosEvento:** 1 BORRADOR · 2 PUBLICADO · 3 CANCELADO* · 4 FINALIZADO*
> - **EstadosInscripcion:** 1 PENDIENTE · 2 APROBADA · 3 RECHAZADA* · 4 CONFIRMADA · 5 CANCELADA*
> - **EstadosPago:** 1 PENDIENTE · 2 CONFIRMADO* · 3 RECHAZADO*
> - **EstadosSolicitud:** 1 PENDIENTE · 2 PROCESADA* · 3 RECHAZADA*

**`Dias`**  ·  *catálogo PREDEFINIDO de días de la semana — el frontend elige por `DiaID`, no crea días*

| Campo | Tipo | Nulo | Clave | Regla | Notas |
|-------|------|:--:|-------|-------|-------|
| `DiaID` | TINYINT | No | **PK + CK** | `1..7` | 1 = Lunes … 7 = Domingo (ISO-8601) |
| `Nombre` | NVARCHAR(15) | No | **UQ** | — | Lunes, Martes… |
| `Abreviatura` | NVARCHAR(3) | No | — | — | LUN, MAR, MIE… |

> Semilla: `1 Lunes`, `2 Martes`, `3 Miércoles`, `4 Jueves`, `5 Viernes`, `6 Sábado`, `7 Domingo`.

**`Horarios`**  ·  *catálogo PREDEFINIDO de bloques de hora — el frontend elige por `HorarioID`*

| Campo | Tipo | Nulo | Clave | Regla | Notas |
|-------|------|:--:|-------|-------|-------|
| `HorarioID` | TINYINT | No | **PK** | — | se siembra 1, 2… |
| `HoraInicio` | TIME(0) | No | **UQ** (bloque) | — | inicio del bloque |
| `HoraFin` | TIME(0) | No | **UQ** (bloque) + **CK** | `HoraFin > HoraInicio` | fin del bloque |
| `Etiqueta` | NVARCHAR(20) | No | **UQ** | — | texto para UI: `08:00-09:30` |

> Semilla (ajustable): `1 08:00-09:30`, `2 09:30-11:00`, `3 11:00-12:30`, `4 13:30-15:00`, `5 15:00-16:30`, `6 16:30-18:00`.

---

## 2. Catálogos base

**`Usuarios`**  ·  *administrador y asistente son la MISMA tabla, los distingue `RolID`*

| Campo | Tipo | Nulo | Clave | Regla | Notas |
|-------|------|:--:|-------|-------|-------|
| `UsuarioID` | INT IDENTITY | No | **PK** | — | autonumérico |
| `NombreCompleto` | NVARCHAR(150) | No | — | — | |
| `Correo` | NVARCHAR(150) | No | **UQ** + **CK** | formato `%_@_%._%` | identifica al usuario, no se repite |
| `Contrasena` | NVARCHAR(255) | No | — | — | **hash**, nunca texto plano |
| `Telefono` | NVARCHAR(30) | No | — | — | |
| `Organizacion` | NVARCHAR(150) | No | — | — | |
| `Cargo` | NVARCHAR(100) | **Sí** | — | — | opcional según enunciado |
| `PaisResidencia` | NVARCHAR(100) | No | — | — | |
| `FotoPerfil` | NVARCHAR(300) | No | — | — | URL/ruta |
| `RolID` | TINYINT | No | **FK** | → `Roles` | ADMIN o ASISTENTE |
| `CorreoConfirmado` | BIT | No | — | DEFAULT `0` | doble opt-in |
| `Activo` | BIT | No | — | DEFAULT `1` | borrado lógico |

**`Ponentes`**

| Campo | Tipo | Nulo | Clave | Regla | Notas |
|-------|------|:--:|-------|-------|-------|
| `PonenteID` | INT IDENTITY | No | **PK** | — | |
| `NombreCompleto` | NVARCHAR(150) | No | — | — | |
| `CorreoContacto` | NVARCHAR(150) | No | **CK** | formato `%_@_%._%` | |
| `Fotografia` | NVARCHAR(300) | No | — | — | |
| `Biografia` | NVARCHAR(MAX) | No | — | — | texto largo |
| `AreaEspecializacion` | NVARCHAR(150) | No | — | — | |
| `Organizacion` | NVARCHAR(150) | **Sí** | — | — | opcional |
| `WebRedes` | NVARCHAR(300) | **Sí** | — | — | opcional |
| `Activo` | BIT | No | — | DEFAULT `1` | “desactivar, no eliminar” |

**`Salas`**

| Campo | Tipo | Nulo | Clave | Regla | Notas |
|-------|------|:--:|-------|-------|-------|
| `SalaID` | INT IDENTITY | No | **PK** | — | |
| `Nombre` | NVARCHAR(100) | No | — | — | |
| `Ubicacion` | NVARCHAR(200) | No | — | — | |
| `Capacidad` | INT | No | **CK** | `> 0` | usada en el reporte de ocupación |
| `Activo` | BIT | No | — | DEFAULT `1` | borrado lógico |

**`TiposEntrada`**

| Campo | Tipo | Nulo | Clave | Regla | Notas |
|-------|------|:--:|-------|-------|-------|
| `TipoEntradaID` | TINYINT IDENTITY | No | **PK** | — | |
| `Nombre` | NVARCHAR(50) | No | **UQ** | — | EARLY_BIRD, GENERAL, VIP… |
| `Descripcion` | NVARCHAR(300) | No | — | — | |
| `Tarifa` | DECIMAL(10,2) | No | **CK** | `>= 0` | precio |
| `Disponibilidad` | NVARCHAR(200) | No | — | — | regla: “20% del cupo”, “máx 10”… |
| `Activo` | BIT | No | — | DEFAULT `1` | borrado lógico |

---

## 3. Núcleo del evento

**`Eventos`**

| Campo | Tipo | Nulo | Clave | Regla | Notas |
|-------|------|:--:|-------|-------|-------|
| `EventoID` | INT IDENTITY | No | **PK** | — | |
| `AdminID` | INT | No | **FK** | → `Usuarios` | admin (rol ADMIN) que lo crea |
| `Nombre` | NVARCHAR(200) | No | — | — | |
| `Descripcion` | NVARCHAR(MAX) | No | — | — | texto largo |
| `FechaInicio` | DATETIME2(0) | No | — | — | |
| `FechaFin` | DATETIME2(0) | No | **CK** | `FechaFin >= FechaInicio` | |
| `Modalidad` | NVARCHAR(15) | No | **CK** | `PRESENCIAL` \| `VIRTUAL` \| `HIBRIDA` | enum fijo |
| `Ubicacion` | NVARCHAR(300) | **Sí** | — | — | física, según modalidad |
| `EnlaceTransmision` | NVARCHAR(300) | **Sí** | — | — | según modalidad |
| `Categoria` | NVARCHAR(15) | No | **CK** | `ACADEMICO`\|`CORPORATIVO`\|`CULTURAL`\|`TECNOLOGICO`\|`OTRO` | enum fijo |
| `ImagenBanner` | NVARCHAR(300) | No | — | — | |
| `CapacidadMaxima` | INT | No | **CK** | `> 0` | |
| `EstadoEventoID` | TINYINT | No | **FK** | → `EstadosEvento` | DEFAULT `1` = BORRADOR |
| `ModalidadInscripcion` | NVARCHAR(15) | No | **CK** | `ABIERTA`\|`APROBACION`\|`INVITACION` | enum fijo |
| `EsPago` | BIT | No | — | DEFAULT `0` | ¿el evento cobra? |

**`Sesiones`**

| Campo | Tipo | Nulo | Clave | Regla | Notas |
|-------|------|:--:|-------|-------|-------|
| `SesionID` | INT IDENTITY | No | **PK** | — | |
| `EventoID` | INT | No | **FK** | → `Eventos` | |
| `PonenteID` | INT | No | **FK** | → `Ponentes` | |
| `SalaID` | INT | **Sí** | **FK** | → `Salas` | NULL si la sesión es virtual |
| `DiaID` | TINYINT | No | **FK** | → `Dias` | el frontend elige el día por id |
| `HorarioID` | TINYINT | No | **FK** | → `Horarios` | el frontend elige el bloque por id |
| `Titulo` | NVARCHAR(200) | No | — | — | |
| `Enlace` | NVARCHAR(300) | **Sí** | — | — | “sala o enlace asignado” |
| `CupoMaximo` | INT | No | **CK** | `> 0` | |

**`MaterialesRecurso`**  ·  *entidad débil: existe solo mientras exista su sesión*

| Campo | Tipo | Nulo | Clave | Regla | Notas |
|-------|------|:--:|-------|-------|-------|
| `MaterialID` | INT IDENTITY | No | **PK** | — | |
| `SesionID` | INT | No | **FK** | → `Sesiones` **ON DELETE CASCADE** | borrar la sesión borra sus materiales |
| `Nombre` | NVARCHAR(200) | No | — | — | |
| `UrlArchivo` | NVARCHAR(300) | No | — | — | |

---

## 4. Inscripciones

**`Inscripciones`**

| Campo | Tipo | Nulo | Clave | Regla | Notas |
|-------|------|:--:|-------|-------|-------|
| `InscripcionID` | INT IDENTITY | No | **PK** | — | |
| `AsistenteID` | INT | No | **FK** | → `Usuarios` | rol ASISTENTE |
| `EventoID` | INT | No | **FK** | → `Eventos` | |
| `TipoEntradaID` | TINYINT | No | **FK** | → `TiposEntrada` | tarifa elegida |
| `FechaInscripcion` | DATETIME2(0) | No | — | DEFAULT `SYSUTCDATETIME()` | |
| `EstadoInscripcionID` | TINYINT | No | **FK** | → `EstadosInscripcion` | DEFAULT `1` = PENDIENTE |
| `Monto` | DECIMAL(10,2) | No | **CK** | `>= 0`, DEFAULT `0` | base de ingresos y reembolso |

**`InscripcionSesion`**  ·  *tabla puente de la N:M — **PK compuesta**, sin id propio*

| Campo | Tipo | Nulo | Clave | Regla | Notas |
|-------|------|:--:|-------|-------|-------|
| `InscripcionID` | INT | No | **PK + FK** | → `Inscripciones` | mitad de la PK |
| `SesionID` | INT | No | **PK + FK** | → `Sesiones` | otra mitad de la PK |
| `FechaRegistro` | DATETIME2(0) | No | — | DEFAULT `SYSUTCDATETIME()` | |

> PK = (`InscripcionID`, `SesionID`) juntas → no se repite el par.

**`CodigosInvitacion`**

| Campo | Tipo | Nulo | Clave | Regla | Notas |
|-------|------|:--:|-------|-------|-------|
| `CodigoID` | INT IDENTITY | No | **PK** | — | |
| `EventoID` | INT | No | **FK** | → `Eventos` | |
| `AsistenteID` | INT | **Sí** | **FK** | → `Usuarios` | NULL hasta que se canjea |
| `Codigo` | NVARCHAR(50) | No | **UQ** | — | el código en sí |
| `CorreoDestinatario` | NVARCHAR(150) | No | — | — | a quién se envió |
| `Usado` | BIT | No | — | DEFAULT `0` | |

---

## 5. Pagos y cancelaciones

**`Tarjetas`**

| Campo | Tipo | Nulo | Clave | Regla | Notas |
|-------|------|:--:|-------|-------|-------|
| `TarjetaID` | INT IDENTITY | No | **PK** | — | |
| `AsistenteID` | INT | No | **FK** | → `Usuarios` | dueño |
| `Titular` | NVARCHAR(150) | No | — | — | |
| `NumeroEnmascarado` | NVARCHAR(25) | No | — | — | solo últimos dígitos, **nunca** el número completo |
| `Tipo` | NVARCHAR(10) | No | **CK** | `DEBITO` \| `CREDITO` | enum fijo |
| `FechaExpiracion` | NVARCHAR(7) | No | — | formato `MM/AAAA` | |

**`Pagos`**

| Campo | Tipo | Nulo | Clave | Regla | Notas |
|-------|------|:--:|-------|-------|-------|
| `PagoID` | INT IDENTITY | No | **PK** | — | |
| `InscripcionID` | INT | No | **FK** | → `Inscripciones` | qué se paga |
| `TarjetaID` | INT | **Sí** | **FK** | → `Tarjetas` | NULL si transferencia |
| `AdminRevisorID` | INT | **Sí** | **FK** | → `Usuarios` | admin que revisa transferencia |
| `Monto` | DECIMAL(10,2) | No | **CK** | `>= 0` | |
| `Metodo` | NVARCHAR(15) | No | **CK** | `TARJETA` \| `TRANSFERENCIA` | enum fijo |
| `EstadoPagoID` | TINYINT | No | **FK** | → `EstadosPago` | DEFAULT `1` = PENDIENTE |
| `FechaPago` | DATETIME2(0) | No | — | DEFAULT `SYSUTCDATETIME()` | base del reporte de ingresos |
| `ComprobanteUrl` | NVARCHAR(300) | **Sí** | — | — | comprobante de transferencia |

**`SolicitudesCancelacion`**

| Campo | Tipo | Nulo | Clave | Regla | Notas |
|-------|------|:--:|-------|-------|-------|
| `SolicitudID` | INT IDENTITY | No | **PK** | — | |
| `InscripcionID` | INT | No | **FK** | → `Inscripciones` | |
| `AdminProcesadorID` | INT | **Sí** | **FK** | → `Usuarios` | NULL hasta procesarse |
| `FechaSolicitud` | DATETIME2(0) | No | — | DEFAULT `SYSUTCDATETIME()` | |
| `EstadoSolicitudID` | TINYINT | No | **FK** | → `EstadosSolicitud` | DEFAULT `1` = PENDIENTE |
| `MontoReembolso` | DECIMAL(10,2) | No | **CK** | `>= 0`, DEFAULT `0` | 80% del monto pagado |
| `ComprobantePdfUrl` | NVARCHAR(300) | **Sí** | — | — | PDF que el admin envía |

---

## 6. Bitácora

**`LogActividad`**

| Campo | Tipo | Nulo | Clave | Regla | Notas |
|-------|------|:--:|-------|-------|-------|
| `LogID` | BIGINT IDENTITY | No | **PK** | — | crece mucho → BIGINT |
| `UsuarioID` | INT | **Sí** | **FK** | → `Usuarios` | NULL si la acción es del sistema |
| `Accion` | NVARCHAR(50) | No | — | — | CREAR, ACTUALIZAR… |
| `EntidadAfectada` | NVARCHAR(50) | No | — | — | qué tabla/registro |
| `Descripcion` | NVARCHAR(500) | **Sí** | — | — | detalle opcional |
| `FechaHora` | DATETIME2(0) | No | — | DEFAULT `SYSUTCDATETIME()` | |

---

## 7. Confirmación de correo (soporte de signup/login)

**`ConfirmacionesCorreo`**  ·  *token de verificación para "confirmar correo antes de iniciar sesión"*

| Campo | Tipo | Nulo | Clave | Regla | Notas |
|-------|------|:--:|-------|-------|-------|
| `ConfirmacionID` | INT IDENTITY | No | **PK** | — | |
| `UsuarioID` | INT | No | **FK** | → `Usuarios` | dueño del token |
| `Token` | NVARCHAR(100) | No | **UQ** | — | código aleatorio enviado por correo |
| `FechaCreacion` | DATETIME2(0) | No | — | DEFAULT `SYSUTCDATETIME()` | |
| `FechaExpira` | DATETIME2(0) | No | **CK** | `FechaExpira > FechaCreacion` | el backend la fija (ej. +24h) |
| `Usado` | BIT | No | — | DEFAULT `0` | `1` cuando ya se confirmó |
| `FechaUso` | DATETIME2(0) | **Sí** | — | — | cuándo se confirmó (NULL si aún no) |

> Al validar el token: `Usado = 1`, `FechaUso = ahora` y `Usuarios.CorreoConfirmado = 1`.
> "Reenviar verificación" = insertar otra fila (se admiten varias por usuario).
