# 📦 EVENTCORE — Manual de la base de datos

Manual de referencia para **entender y explicar** el esquema: qué archivos lo componen, qué hace
cada tabla, qué significa cada campo, qué reglas garantiza el motor y por qué está diseñado así.
**22 tablas · 27 claves foráneas · 1 relación N:M** (Inscripciones ↔ Sesiones). Motor: SQL Server 2016+.

---

## 1. 🗂️ Archivos

**Despliegue rápido (todo en uno):**

| Archivo | Qué hace |
|---|---|
| `eventcore_completo.sql` | TODO el esquema en un solo archivo, sin `GO`: base, 22 tablas, índices y seeds. |

**Por pasos (didáctico, en orden 01 → 09):**

| # | Archivo | Crea / hace | Depende de |
|--:|---------|-------------|------------|
| 1 | `01_database.sql` | Crea la base `Cumbre` y entra en ella | — |
| 2 | `02_lookups.sql` | `Roles`, 4× `Estados…`, `Dias`, `Horarios` | 01 |
| 3 | `03_catalogos_base.sql` | `Usuarios`, `Ponentes`, `Salas`, `TiposEntrada` | 02 |
| 4 | `04_nucleo.sql` | `Eventos`, `Sesiones`, `MaterialesRecurso` | 02, 03 |
| 5 | `05_inscripciones.sql` | `Inscripciones`, `InscripcionSesion`, `CodigosInvitacion` | 03, 04 |
| 6 | `06_pagos_cancelaciones.sql` | `Tarjetas`, `Pagos`, `SolicitudesCancelacion` | 03, 05 |
| 7 | `07_bitacora.sql` | `LogActividad` | 03 |
| 8 | `08_seeds.sql` | Llena los catálogos (roles, estados, días, horarios) | 02 |
| 9 | `09_confirmaciones_correo.sql` | `ConfirmacionesCorreo` (confirmar correo en signup) | 03 |

**Auxiliares:**

| Archivo | Para qué |
|---|---|
| `drops.sql` | Borra las 22 tablas en orden inverso a las FKs (reset) |
| `checks.sql` | Catálogo re-ejecutable de todas las reglas `CHECK` (referencia) |

---

## 2. 🏷️ Convenciones de nomenclatura

Todo el esquema sigue un estándar fijo; reconocer el prefijo te dice de inmediato qué es cada objeto.

| Patrón | Significa | Ejemplo |
|--------|-----------|---------|
| `PascalCase` plural | nombre de tabla | `Inscripciones`, `TiposEntrada` |
| `TablaID` | clave primaria de esa tabla | `EventoID`, `SesionID` |
| `PK_Tabla` | restricción de clave primaria | `PK_Eventos` |
| `FK_Hijo_Padre` | clave foránea | `FK_Sesiones_Eventos` |
| `UQ_Tabla_Campo` | restricción única | `UQ_Usuarios_Correo` |
| `CK_Tabla_Regla` | restricción CHECK | `CK_Eventos_Fechas` |
| `DF_Tabla_Campo` | valor por defecto | `DF_Usuarios_Activo` |
| `IX_Tabla_Campo` | índice no clúster | `IX_Sesiones_PonenteID` |

**Por qué importa:** las restricciones llevan nombre explícito (no anónimo) para que un error sea
legible (“violación de `UQ_Usuarios_Correo`”) y se puedan modificar/borrar después.

---

## 3. 📐 Glosario de claves y tipos

| Clave | Qué es | Cómo lo explicás |
|---|---|---|
| **PK** | identifica única cada fila | “el identificador de la tabla” |
| **FK** | apunta al PK de otra tabla; integridad referencial | “no puede existir una sesión de un evento inexistente” |
| **UQ** | valor que no se repite (sin ser PK) | “dos usuarios no pueden tener el mismo correo” |
| **CK** | regla que cada fila debe cumplir | “el motor rechaza una capacidad negativa” |
| **IDENTITY** | id autonumérico generado por el motor | “autonumérico 1,2,3…” |
| **Borrado lógico** (`Activo`) | se desactiva, no se borra | “marcamos inactivo para no perder historial” |

| Tipo | Guarda | Rango / nota |
|------|--------|--------------|
| `TINYINT` | enteros chicos (ids de catálogo) | 0–255, 1 byte |
| `INT` | ids de negocio | ±2,100 M, 4 bytes |
| `BIGINT` | la bitácora (crece mucho) | 8 bytes |
| `NVARCHAR(n)` | texto Unicode (tildes/ñ) | hasta `n` |
| `NVARCHAR(MAX)` | texto largo | ~1 GB |
| `DECIMAL(10,2)` | dinero exacto | hasta 99,999,999.99 |
| `DATETIME2(0)` | fecha + hora | precisión = segundos |
| `TIME(0)` | solo hora | para los bloques de `Horarios` |
| `BIT` | booleano | 1/0 |

> El literal de texto va con `N` adelante (`N'ADMIN'`) porque las columnas son `NVARCHAR` (Unicode).

---

## 4. 🧱 Diccionario por tabla

Para cada tabla: **qué hace** y la definición de los campos que no se explican solos
(los `…ID`, `Nombre`, `Correo`, fechas obvias, etc. se omiten).

### Catálogos lookup (PK a mano, sembrados en `08_seeds.sql`)

**`Roles`** — catálogo de los tipos de usuario del sistema.
- `Codigo`: valor que el backend compara para dar permisos (`ADMIN`, `ASISTENTE`).

**`EstadosEvento` · `EstadosInscripcion` · `EstadosPago` · `EstadosSolicitud`** — el ciclo de vida
(los estados posibles) de cada flujo. Misma estructura en las cuatro.
- `Codigo`: nombre legible del estado (`PENDIENTE`, `CONFIRMADO`…).
- `EsTerminal`: `1` = estado **cerrado**, ya no admite más cambios. El backend lo usa para bloquear
  transiciones (un evento `CANCELADO` no vuelve a `BORRADOR`).

**`Dias`** — los 7 días de la semana, predefinidos (el frontend elige por id, no escribe texto).
- `DiaID`: `1` = Lunes … `7` = Domingo (ISO-8601), con `CHECK` que lo limita a 1–7.
- `Abreviatura`: forma corta para la UI (`LUN`, `MAR`…).

**`Horarios`** — los bloques de hora predefinidos (el frontend elige por id).
- `HoraInicio` / `HoraFin`: tipo `TIME`; un `CHECK` exige `HoraFin > HoraInicio`. El par es único.
- `Etiqueta`: texto ya listo para mostrar en pantalla (`08:00-09:30`).

### Catálogos base (PK `IDENTITY`)

**`Usuarios`** — administradores y asistentes en **una sola tabla**; los distingue `RolID`.
- `Contrasena`: se guarda el **hash**, nunca el texto plano.
- `RolID`: FK → `Roles`; define si el usuario es ADMIN o ASISTENTE.
- `CorreoConfirmado`: `1` cuando el usuario verificó su correo; es **requisito para iniciar sesión**.
- `Activo`: borrado lógico (`0` = desactivado, sin eliminar la fila).

**`Ponentes`** — expositores que imparten las sesiones.
- `AreaEspecializacion`: tema/rubro del ponente.
- `Activo`: permite desactivarlo sin borrarlo (regla: no eliminar si tiene sesiones).

**`Salas`** — espacios físicos donde ocurren las sesiones.
- `Capacidad`: aforo (`CHECK > 0`); alimenta el reporte de ocupación.

**`TiposEntrada`** — las tarifas/entradas que se pueden comprar.
- `Tarifa`: precio (`CHECK ≥ 0`; `0` = gratis).
- `Disponibilidad`: la regla de cupo en texto (“20% del cupo”, “máx 10”, etc.).

### Núcleo del evento

**`Eventos`** — el evento en sí; lo crea un administrador.
- `AdminID`: FK → `Usuarios` (el admin dueño).
- `Modalidad`: `PRESENCIAL` | `VIRTUAL` | `HIBRIDA` (enum por `CHECK`).
- `Categoria`: `ACADEMICO` | `CORPORATIVO` | `CULTURAL` | `TECNOLOGICO` | `OTRO`.
- `ModalidadInscripcion`: cómo se entra → `ABIERTA` | `APROBACION` | `INVITACION`.
- `EstadoEventoID`: FK → `EstadosEvento` (arranca en `1 = BORRADOR`).
- `EsPago`: `1` si el evento cobra entrada.
- `FechaInicio`/`FechaFin`: con `CHECK` `Fin ≥ Inicio`.

**`Sesiones`** — cada charla/actividad dentro de un evento.
- `DiaID` / `HorarioID`: **la agenda por id** (FK a los catálogos `Dias` y `Horarios`).
- `SalaID`: FK → `Salas`; **NULL si la sesión es virtual** (en ese caso se usa `Enlace`).
- `CupoMaximo`: cupo de la sesión (`CHECK > 0`).

**`MaterialesRecurso`** — archivos/recursos de una sesión (entidad débil: existe solo con su sesión).
- `SesionID`: FK con **`ON DELETE CASCADE`** → al borrar la sesión, sus materiales se borran solos.
- `UrlArchivo`: ruta/URL del recurso.

### Inscripciones

**`Inscripciones`** — vincula a un asistente con un evento (su “entrada” comprada).
- `AsistenteID`: FK → `Usuarios` (rol ASISTENTE).
- `TipoEntradaID`: FK → `TiposEntrada` (la tarifa elegida).
- `EstadoInscripcionID`: FK → `EstadosInscripcion` (PENDIENTE/APROBADA/…).
- `Monto`: lo que pagó; base para ingresos y cálculo de reembolso.

**`InscripcionSesion`** — **tabla puente** de la relación N:M Inscripción ↔ Sesión.
- **PK compuesta** (`InscripcionID` + `SesionID`): el par no se repite → no se puede registrar dos
  veces la misma sesión en una inscripción.

**`CodigosInvitacion`** — códigos para eventos de modalidad `INVITACION`.
- `Codigo`: el código en sí (único).
- `AsistenteID`: FK → `Usuarios`; **NULL hasta que alguien canjea** el código.
- `Usado`: `1` cuando ya se canjeó.

### Pagos y cancelaciones

**`Tarjetas`** — medios de pago guardados por el asistente.
- `NumeroEnmascarado`: **solo los últimos dígitos**, nunca el número completo (seguridad).
- `Tipo`: `DEBITO` | `CREDITO`.
- `FechaExpiracion`: formato `MM/AAAA`.

**`Pagos`** — el pago concreto de una inscripción.
- `Metodo`: `TARJETA` | `TRANSFERENCIA`.
- `TarjetaID`: FK → `Tarjetas`; NULL si el pago fue por transferencia.
- `AdminRevisorID`: FK → `Usuarios`; el admin que revisa la transferencia (NULL si fue con tarjeta).
- `EstadoPagoID`: FK → `EstadosPago` (PENDIENTE/CONFIRMADO/RECHAZADO).
- `ComprobanteUrl`: comprobante cargado en pagos por transferencia.

**`SolicitudesCancelacion`** — el pedido de cancelación/reembolso de una inscripción.
- `MontoReembolso`: monto a devolver (regla del enunciado: típicamente 80% de lo pagado).
- `AdminProcesadorID`: FK → `Usuarios`; el admin que procesa el reembolso (NULL hasta procesarse).
- `ComprobantePdfUrl`: PDF que el admin envía al solicitante.

### Soporte (auditoría / auth)

**`LogActividad`** — bitácora de todas las acciones del sistema (para el reporte de actividad).
- `LogID`: `BIGINT` porque esta tabla crece mucho.
- `UsuarioID`: FK → `Usuarios`; **NULL si la acción la ejecuta el sistema**.
- `Accion` / `EntidadAfectada`: qué se hizo y sobre qué tabla/registro.

**`ConfirmacionesCorreo`** — tokens para confirmar el correo en el registro (signup/login).
- `Token`: código aleatorio que se envía por correo (único; se busca en `GET /confirmar/:token`).
- `FechaExpira`: vencimiento del token (`CHECK FechaExpira > FechaCreacion`).
- `Usado` / `FechaUso`: `1` y la fecha cuando se confirmó (al validar se pone `Usuarios.CorreoConfirmado = 1`).

> El diccionario **campo por campo** (tipo, nulabilidad, default exacto) está en `../eventcore-tablas.md`.

---

## 5. 🌱 Catálogos sembrados (valores iniciales)

Lo que carga `08_seeds.sql`. Estos ids son **estables**: el backend los referencia directamente.

- **Roles:** `1 ADMIN` · `2 ASISTENTE`
- **EstadosEvento** (`*` = terminal): `1 BORRADOR` · `2 PUBLICADO` · `3 CANCELADO*` · `4 FINALIZADO*`
- **EstadosInscripcion:** `1 PENDIENTE` · `2 APROBADA` · `3 RECHAZADA*` · `4 CONFIRMADA` · `5 CANCELADA*`
- **EstadosPago:** `1 PENDIENTE` · `2 CONFIRMADO*` · `3 RECHAZADO*`
- **EstadosSolicitud:** `1 PENDIENTE` · `2 PROCESADA*` · `3 RECHAZADA*`
- **Dias:** `1 Lunes` … `7 Domingo` (ISO-8601)
- **Horarios:** `1 08:00-09:30` · `2 09:30-11:00` · `3 11:00-12:30` · `4 13:30-15:00` · `5 15:00-16:30` · `6 16:30-18:00`

---

## 6. 🔗 Mapa de relaciones (las 27 FKs)

“La FK vive en el lado **muchos** (hijo) y apunta al lado **uno** (padre)”.

| Tabla hijo | Columna(s) FK | → Padre |
|------------|---------------|---------|
| `Usuarios` | `RolID` | `Roles` |
| `Eventos` | `AdminID` · `EstadoEventoID` | `Usuarios` · `EstadosEvento` |
| `Sesiones` | `EventoID` · `PonenteID` · `SalaID` · `DiaID` · `HorarioID` | `Eventos` · `Ponentes` · `Salas` · `Dias` · `Horarios` |
| `MaterialesRecurso` | `SesionID` (CASCADE) | `Sesiones` |
| `Inscripciones` | `AsistenteID` · `EventoID` · `TipoEntradaID` · `EstadoInscripcionID` | `Usuarios` · `Eventos` · `TiposEntrada` · `EstadosInscripcion` |
| `InscripcionSesion` | `InscripcionID` · `SesionID` | `Inscripciones` · `Sesiones` |
| `CodigosInvitacion` | `EventoID` · `AsistenteID` | `Eventos` · `Usuarios` |
| `Tarjetas` | `AsistenteID` | `Usuarios` |
| `Pagos` | `InscripcionID` · `TarjetaID` · `AdminRevisorID` · `EstadoPagoID` | `Inscripciones` · `Tarjetas` · `Usuarios` · `EstadosPago` |
| `SolicitudesCancelacion` | `InscripcionID` · `AdminProcesadorID` · `EstadoSolicitudID` | `Inscripciones` · `Usuarios` · `EstadosSolicitud` |
| `LogActividad` | `UsuarioID` | `Usuarios` |
| `ConfirmacionesCorreo` | `UsuarioID` | `Usuarios` |

> **`Usuarios` es la tabla más “apuntada”** (recibe 8 FKs): admin, asistente, revisor de pagos,
> procesador de reembolsos, etc. Por eso una sola tabla `Usuarios` y el rol lo da `RolID`, en vez
> de tablas separadas para admin y asistente.

---

## 7. ✅ Reglas que garantiza el motor

**Vía CHECK (`checks.sql`):**
- Formato de correo en `Usuarios` y `Ponentes`.
- Montos y tarifas `≥ 0` (Inscripciones, Pagos, TiposEntrada, SolicitudesCancelacion).
- Capacidades y cupos `> 0` (Salas, Eventos, Sesiones).
- Coherencia de fechas: evento `FechaFin ≥ FechaInicio`; horario `HoraFin > HoraInicio`; token `FechaExpira > FechaCreacion`.
- Enums fijos: `Modalidad`, `Categoria`, `ModalidadInscripcion` (Eventos), `Tipo` (Tarjetas), `Metodo` (Pagos).
- Rango del día: `DiaID` entre 1 y 7.

**Vía UNIQUE:** correo de usuario, código de invitación, token de confirmación, nombre de tipo de entrada, bloque y etiqueta de horario.

**Vía FK + PK compuesta:** integridad referencial total y, en `InscripcionSesion`, que no se duplique el par inscripción–sesión.

> Las reglas de negocio “de proceso” (traslapes de horario, Early Bird 20%, VIP máx 10, ventanas
> 24h/48h, reembolso 80%) **no** son del esquema: viven en la lógica del backend.

---

## 8. ⚡ Estrategia de índices

> “Las FK no se indexan solas.” Cada FK tiene su índice `IX_…` para que los joins y los borrados
> sean rápidos. Además:
> - Índices **filtrados** (`WHERE … IS NOT NULL`) en las FK opcionales (ej. `Pagos.TarjetaID`): no
>   indexan filas NULL → más chicos.
> - `LogActividad` indexa `FechaHora DESC` (la bitácora casi siempre se consulta por “lo más reciente”).
> - El `UNIQUE` de `ConfirmacionesCorreo.Token` ya crea el índice ideal para `GET /confirmar/:token`.

---

## 9. 💡 Decisiones de diseño (las preguntas típicas del catedrático)

**¿Por qué los estados son tablas y no un `CHECK IN(...)`?**
Porque pueden crecer: agregar un estado es un `INSERT`, no alterar la tabla. Y guardan metadatos
(`EsTerminal`). Los enums que **nunca** cambian (modalidad, método de pago, tipo de tarjeta) sí van
como `CHECK`. → Distinción clave: *conjunto extensible = lookup; conjunto fijo = CHECK*.

**¿Por qué `Dias` y `Horarios` predefinidos?**
Para controlar la agenda: el frontend asigna día/hora **por id** (no texto libre) → menos errores,
datos consistentes y combos fáciles de llenar. `Horarios` usa `TIME` para validar `HoraFin > HoraInicio`.

**¿Cómo funciona el login/signup en la DB?**
Signup = `INSERT` en `Usuarios` (contraseña **hasheada**). Login = `SELECT` por `Correo`, verificar
hash, exigir `CorreoConfirmado = 1` y `Activo = 1`, y dar permisos según `RolID`. La confirmación de
correo usa `ConfirmacionesCorreo` (token con vencimiento; al validar se pone `CorreoConfirmado = 1`).
Hashear, el JWT y la “capa extra” del admin son lógica del **backend**, no de la base.

**¿Por qué PK con IDENTITY en unas tablas y a mano en otras?**
Los catálogos sembrados (Roles, Estados, Dias, Horarios) usan PK fija → id estable y citable. Las
tablas de negocio (Usuarios, Eventos…) usan `IDENTITY` → autonumérico.

**¿Por qué borrado lógico (`Activo`)?**
Para no perder historial ni romper FKs: un ponente con sesiones no se elimina, se desactiva.

> Diagrama ER y detalle completo: `../eventcore-er.svg/.png`, `../eventcore-tablas.md`,
> `../eventcore-relaciones.md`, `../entidades-y-foraneas.md`.
