# EVENTCORE — Entidades, relaciones y mapa de foráneas

> Hoja de trabajo para maquetar el ER a mano. **Coincide 1:1 con `eventcore_ddl.sql`**:
> mismos nombres de tabla y columna (PascalCase, plural), mismas FKs. Motor: **SQL Server**.
>
> Campos basados solo en el enunciado + lo vital para que el modelo funcione (PKs, FKs,
> lookups de estado). Ver el `.sql` para tipos de dato y constraints exactos.

---

## 0. Entidades (19 = 14 de negocio + 5 lookup)

Las **lookup** son la forma normalizada de los enums de estado/rol (en vez de `CHECK IN(...)`),
extensibles y con `EsTerminal`. Los enums *fijos* (modalidad, categoría, método, tipo de tarjeta)
quedaron como `CHECK` dentro de su tabla, **no** generan tabla aparte.

| Grupo | Tablas |
|-------|--------|
| **Lookup (catálogos de estado/rol, sin FK)** | `Roles`, `EstadosEvento`, `EstadosInscripcion`, `EstadosPago`, `EstadosSolicitud` |
| **Catálogos base (sin FK)** | `Usuarios`*, `Ponentes`, `Salas`, `TiposEntrada` |
| **Núcleo del evento** | `Eventos`, `Sesiones`, `MaterialesRecurso` |
| **Inscripciones** | `Inscripciones`, `InscripcionSesion`, `CodigosInvitacion` |
| **Pagos / cancelaciones** | `Tarjetas`, `Pagos`, `SolicitudesCancelacion` |
| **Bitácora** | `LogActividad` |

\* `Usuarios` no recibe FK de catálogos base, pero **sí apunta** a `Roles`. El punto de partida puro
del dibujo son las 5 lookup + `Ponentes`, `Salas`, `TiposEntrada`.

---

## 1. Mapa de foráneas (lo más importante)

Cada fila es **una FK**: *"la columna X de la tabla A apunta al PK de la tabla B"*.

### FKs de negocio (19)

| # | Tabla (origen FK) | Columna FK | → Tabla destino | → PK destino | ¿NULL? | Nota |
|---|-------------------|-----------|-----------------|--------------|--------|------|
| 1 | `Eventos` | `AdminID` | `Usuarios` | `UsuarioID` | No | admin que crea el evento |
| 2 | `Sesiones` | `EventoID` | `Eventos` | `EventoID` | No | |
| 3 | `Sesiones` | `PonenteID` | `Ponentes` | `PonenteID` | No | |
| 4 | `Sesiones` | `SalaID` | `Salas` | `SalaID` | **Sí** | NULL si es virtual (enlace) |
| 5 | `MaterialesRecurso` | `SesionID` | `Sesiones` | `SesionID` | No | `ON DELETE CASCADE` |
| 6 | `Inscripciones` | `AsistenteID` | `Usuarios` | `UsuarioID` | No | |
| 7 | `Inscripciones` | `EventoID` | `Eventos` | `EventoID` | No | |
| 8 | `Inscripciones` | `TipoEntradaID` | `TiposEntrada` | `TipoEntradaID` | No | |
| 9 | `InscripcionSesion` | `InscripcionID` | `Inscripciones` | `InscripcionID` | No | parte de PK compuesta |
| 10 | `InscripcionSesion` | `SesionID` | `Sesiones` | `SesionID` | No | parte de PK compuesta |
| 11 | `CodigosInvitacion` | `EventoID` | `Eventos` | `EventoID` | No | |
| 12 | `CodigosInvitacion` | `AsistenteID` | `Usuarios` | `UsuarioID` | **Sí** | NULL hasta canjearse |
| 13 | `Tarjetas` | `AsistenteID` | `Usuarios` | `UsuarioID` | No | |
| 14 | `Pagos` | `InscripcionID` | `Inscripciones` | `InscripcionID` | No | |
| 15 | `Pagos` | `TarjetaID` | `Tarjetas` | `TarjetaID` | **Sí** | NULL si transferencia |
| 16 | `Pagos` | `AdminRevisorID` | `Usuarios` | `UsuarioID` | **Sí** | admin que revisa transferencia |
| 17 | `SolicitudesCancelacion` | `InscripcionID` | `Inscripciones` | `InscripcionID` | No | |
| 18 | `SolicitudesCancelacion` | `AdminProcesadorID` | `Usuarios` | `UsuarioID` | **Sí** | admin que procesa reembolso |
| 19 | `LogActividad` | `UsuarioID` | `Usuarios` | `UsuarioID` | **Sí** | NULL si la acción es del sistema |

### FKs hacia las lookup (5)

| # | Tabla (origen FK) | Columna FK | → Tabla lookup | → PK destino | ¿NULL? |
|---|-------------------|-----------|----------------|--------------|--------|
| 20 | `Usuarios` | `RolID` | `Roles` | `RolID` | No |
| 21 | `Eventos` | `EstadoEventoID` | `EstadosEvento` | `EstadoEventoID` | No |
| 22 | `Inscripciones` | `EstadoInscripcionID` | `EstadosInscripcion` | `EstadoInscripcionID` | No |
| 23 | `Pagos` | `EstadoPagoID` | `EstadosPago` | `EstadoPagoID` | No |
| 24 | `SolicitudesCancelacion` | `EstadoSolicitudID` | `EstadosSolicitud` | `EstadoSolicitudID` | No |

**Total: 24 llaves foráneas.**

> `Usuarios` sigue siendo el destino de **7 FKs** de negocio (#1, 6, 12, 13, 16, 18, 19).
> Las lookup son destino de 1 FK cada una. Dibujá las lookup como cajitas pequeñas al borde.

---

## 2. ¿A dónde apunta cada tabla? (flechas que SALEN)

- **`Usuarios`** → `Roles`
- **`Eventos`** → `Usuarios` (admin), `EstadosEvento`
- **`Sesiones`** → `Eventos`, `Ponentes`, `Salas`
- **`MaterialesRecurso`** → `Sesiones`
- **`Inscripciones`** → `Usuarios` (asistente), `Eventos`, `TiposEntrada`, `EstadosInscripcion`
- **`InscripcionSesion`** → `Inscripciones`, `Sesiones`  *(puente N:M)*
- **`CodigosInvitacion`** → `Eventos`, `Usuarios` (asistente)
- **`Tarjetas`** → `Usuarios` (asistente)
- **`Pagos`** → `Inscripciones`, `Tarjetas`, `Usuarios` (admin revisor), `EstadosPago`
- **`SolicitudesCancelacion`** → `Inscripciones`, `Usuarios` (admin procesador), `EstadosSolicitud`
- **`LogActividad`** → `Usuarios`

## 3. ¿Quién apunta hacia cada tabla? (flechas que ENTRAN)

| Tabla destino | Recibe FK desde (cuántas) |
|---------------|---------------------------|
| `Usuarios` | Eventos, Inscripciones, CodigosInvitacion, Tarjetas, Pagos, SolicitudesCancelacion, LogActividad **(7)** |
| `Eventos` | Sesiones, Inscripciones, CodigosInvitacion **(3)** |
| `Sesiones` | MaterialesRecurso, InscripcionSesion **(2)** |
| `Inscripciones` | InscripcionSesion, Pagos, SolicitudesCancelacion **(3)** |
| `TiposEntrada` | Inscripciones **(1)** |
| `Ponentes` | Sesiones **(1)** |
| `Salas` | Sesiones **(1)** |
| `Tarjetas` | Pagos **(1)** |
| `Roles` | Usuarios **(1)** |
| `EstadosEvento` | Eventos **(1)** |
| `EstadosInscripcion` | Inscripciones **(1)** |
| `EstadosPago` | Pagos **(1)** |
| `EstadosSolicitud` | SolicitudesCancelacion **(1)** |
| `MaterialesRecurso`, `InscripcionSesion`, `CodigosInvitacion`, `LogActividad` | nadie (hojas) |

---

## 4. Cardinalidades (para rotular las relaciones)

`1 ──< N` = uno a muchos (el lado N lleva la FK). Las lookup son siempre el lado "1".

| Relación | Cardinalidad | Lado con la FK |
|----------|--------------|----------------|
| Roles clasifica Usuarios | 1 ──< N | Usuarios.RolID |
| Usuarios(admin) crea Eventos | 1 ──< N | Eventos.AdminID |
| EstadosEvento clasifica Eventos | 1 ──< N | Eventos.EstadoEventoID |
| Eventos contiene Sesiones | 1 ──< N | Sesiones.EventoID |
| Ponentes imparte Sesiones | 1 ──< N | Sesiones.PonenteID |
| Salas alberga Sesiones | 1 ──< N | Sesiones.SalaID (opcional) |
| Sesiones tiene MaterialesRecurso | 1 ──< N | MaterialesRecurso.SesionID |
| Usuarios(asistente) realiza Inscripciones | 1 ──< N | Inscripciones.AsistenteID |
| Eventos recibe Inscripciones | 1 ──< N | Inscripciones.EventoID |
| TiposEntrada clasifica Inscripciones | 1 ──< N | Inscripciones.TipoEntradaID |
| EstadosInscripcion clasifica Inscripciones | 1 ──< N | Inscripciones.EstadoInscripcionID |
| Eventos emite CodigosInvitacion | 1 ──< N | CodigosInvitacion.EventoID |
| Usuarios usa CodigosInvitacion | 0..1 ──< N | CodigosInvitacion.AsistenteID |
| Usuarios registra Tarjetas | 1 ──< N | Tarjetas.AsistenteID |
| Inscripciones genera Pagos | 1 ──< N | Pagos.InscripcionID |
| Tarjetas se usa en Pagos | 1 ──< N | Pagos.TarjetaID (opcional) |
| EstadosPago clasifica Pagos | 1 ──< N | Pagos.EstadoPagoID |
| Inscripciones tiene SolicitudesCancelacion | 1 ──< N | SolicitudesCancelacion.InscripcionID |
| EstadosSolicitud clasifica SolicitudesCancelacion | 1 ──< N | SolicitudesCancelacion.EstadoSolicitudID |
| Usuarios genera LogActividad | 1 ──< N | LogActividad.UsuarioID |
| **Inscripciones ↔ Sesiones** | **N:M** | resuelta con `InscripcionSesion` |

> **Única N:M:** un asistente (vía su inscripción) entra a varias sesiones, y una sesión recibe
> varias inscripciones → tabla puente `InscripcionSesion` con **PK compuesta** (`InscripcionID`+`SesionID`).

---

## 5. Campos por tabla (PK / FK marcados)

Leyenda: **PK** primaria · **FK** foránea (§1) · *UQ* único · `(NULL)` opcional · `CK` con CHECK.

### Lookup (PK explícita, no IDENTITY)

**Roles** — `RolID` **PK** · `Codigo` *UQ* · `Descripcion`
→ semilla: 1 ADMIN, 2 ASISTENTE

**EstadosEvento** — `EstadoEventoID` **PK** · `Codigo` *UQ* · `Descripcion` · `EsTerminal`
→ 1 BORRADOR, 2 PUBLICADO, 3 CANCELADO*, 4 FINALIZADO*  (*terminal)

**EstadosInscripcion** — `EstadoInscripcionID` **PK** · `Codigo` *UQ* · `Descripcion` · `EsTerminal`
→ 1 PENDIENTE, 2 APROBADA, 3 RECHAZADA*, 4 CONFIRMADA, 5 CANCELADA*

**EstadosPago** — `EstadoPagoID` **PK** · `Codigo` *UQ* · `Descripcion` · `EsTerminal`
→ 1 PENDIENTE, 2 CONFIRMADO*, 3 RECHAZADO*

**EstadosSolicitud** — `EstadoSolicitudID` **PK** · `Codigo` *UQ* · `Descripcion` · `EsTerminal`
→ 1 PENDIENTE, 2 PROCESADA*, 3 RECHAZADA*

### Catálogos base

**Usuarios**
- `UsuarioID` **PK**
- `RolID` **FK → Roles**
- `NombreCompleto`, `Correo` *UQ* `CK`, `Contrasena` (hash), `Telefono`, `Organizacion`
- `Cargo` (NULL), `PaisResidencia`, `FotoPerfil`
- `CorreoConfirmado` (bit), `Activo` (bit, borrado lógico)

**Ponentes**
- `PonenteID` **PK**
- `NombreCompleto`, `CorreoContacto` `CK`, `Fotografia`, `Biografia`, `AreaEspecializacion`
- `Organizacion` (NULL), `WebRedes` (NULL), `Activo` (bit; "desactivar, no eliminar")

**Salas**
- `SalaID` **PK**
- `Nombre`, `Ubicacion`, `Capacidad` `CK>0`, `Activo`

**TiposEntrada**
- `TipoEntradaID` **PK**
- `Nombre` *UQ*, `Descripcion`, `Tarifa` `CK>=0`, `Disponibilidad`, `Activo`

### Núcleo del evento

**Eventos**
- `EventoID` **PK**
- `AdminID` **FK → Usuarios**
- `EstadoEventoID` **FK → EstadosEvento** (default 1 = BORRADOR)
- `Nombre`, `Descripcion`, `FechaInicio`, `FechaFin` `CK fin>=inicio`
- `Modalidad` `CK(PRESENCIAL|VIRTUAL|HIBRIDA)`, `Ubicacion` (NULL), `EnlaceTransmision` (NULL)
- `Categoria` `CK(ACADEMICO|CORPORATIVO|CULTURAL|TECNOLOGICO|OTRO)`
- `ImagenBanner`, `CapacidadMaxima` `CK>0`
- `ModalidadInscripcion` `CK(ABIERTA|APROBACION|INVITACION)`, `EsPago` (bit)

**Sesiones**
- `SesionID` **PK**
- `EventoID` **FK → Eventos**, `PonenteID` **FK → Ponentes**, `SalaID` **FK → Salas** (NULL si virtual)
- `Titulo`, `Enlace` (NULL), `FechaHoraInicio`, `FechaHoraFin` `CK fin>=inicio`, `CupoMaximo` `CK>0`

**MaterialesRecurso**  *(entidad débil de Sesiones)*
- `MaterialID` **PK**
- `SesionID` **FK → Sesiones** (`ON DELETE CASCADE`)
- `Nombre`, `UrlArchivo`

### Inscripciones

**Inscripciones**
- `InscripcionID` **PK**
- `AsistenteID` **FK → Usuarios**, `EventoID` **FK → Eventos**, `TipoEntradaID` **FK → TiposEntrada**
- `EstadoInscripcionID` **FK → EstadosInscripcion** (default 1 = PENDIENTE)
- `FechaInscripcion`, `Monto` `CK>=0`

**InscripcionSesion**  *(puente N:M — PK compuesta)*
- `InscripcionID` **FK → Inscripciones** ─┐ **PK (InscripcionID, SesionID)**
- `SesionID` **FK → Sesiones**            ─┘
- `FechaRegistro`

**CodigosInvitacion**
- `CodigoID` **PK**
- `EventoID` **FK → Eventos**, `AsistenteID` **FK → Usuarios** (NULL hasta usarse)
- `Codigo` *UQ*, `CorreoDestinatario`, `Usado` (bit)

### Pagos y cancelaciones

**Tarjetas**
- `TarjetaID` **PK**
- `AsistenteID` **FK → Usuarios**
- `Titular`, `NumeroEnmascarado`, `Tipo` `CK(DEBITO|CREDITO)`, `FechaExpiracion` (MM/AAAA)

**Pagos**
- `PagoID` **PK**
- `InscripcionID` **FK → Inscripciones**, `TarjetaID` **FK → Tarjetas** (NULL si transferencia)
- `AdminRevisorID` **FK → Usuarios** (NULL), `EstadoPagoID` **FK → EstadosPago** (default 1)
- `Monto` `CK>=0`, `Metodo` `CK(TARJETA|TRANSFERENCIA)`, `FechaPago`, `ComprobanteUrl` (NULL)

**SolicitudesCancelacion**
- `SolicitudID` **PK**
- `InscripcionID` **FK → Inscripciones**, `AdminProcesadorID` **FK → Usuarios** (NULL)
- `EstadoSolicitudID` **FK → EstadosSolicitud** (default 1)
- `FechaSolicitud`, `MontoReembolso` `CK>=0` (80% del pago), `ComprobantePdfUrl` (NULL)

### Bitácora

**LogActividad**
- `LogID` **PK** (BIGINT)
- `UsuarioID` **FK → Usuarios** (NULL si la acción es del sistema)
- `Accion`, `EntidadAfectada`, `Descripcion` (NULL), `FechaHora`

---

## 6. Orden de creación (sin romper FKs)

1. **Lookup:** `Roles`, `EstadosEvento`, `EstadosInscripcion`, `EstadosPago`, `EstadosSolicitud`
2. **Catálogos base:** `Usuarios` (→Roles), `Ponentes`, `Salas`, `TiposEntrada`
3. `Eventos` (→Usuarios, EstadosEvento)
4. `Sesiones` (→Eventos, Ponentes, Salas)
5. `MaterialesRecurso` (→Sesiones)
6. `Inscripciones` (→Usuarios, Eventos, TiposEntrada, EstadosInscripcion)
7. `Tarjetas` (→Usuarios), `CodigosInvitacion` (→Eventos, Usuarios)
8. `InscripcionSesion` (→Inscripciones, Sesiones)
9. `Pagos` (→Inscripciones, Tarjetas, Usuarios, EstadosPago)
10. `SolicitudesCancelacion` (→Inscripciones, Usuarios, EstadosSolicitud)
11. `LogActividad` (→Usuarios)

> Es exactamente el orden de `eventcore_ddl.sql`.

---

## 7. Notas para no equivocarse al maquetar

- **`Usuarios` es UNA sola tabla**; el rol lo da `RolID → Roles`. Por eso unas FKs se llaman
  `AdminID`, otras `AsistenteID`/`AdminRevisorID`/`AdminProcesadorID`, pero **todas apuntan a
  `Usuarios.UsuarioID`**. No dibujes tablas separadas para admin y asistente.
- **FKs opcionales (NULL → línea punteada / "0..1"):** `Sesiones.SalaID`,
  `CodigosInvitacion.AsistenteID`, `Pagos.TarjetaID`, `Pagos.AdminRevisorID`,
  `SolicitudesCancelacion.AdminProcesadorID`, `LogActividad.UsuarioID`.
- **Lookup vs CHECK:** los *estados* van en tabla lookup (FK). Los enums *fijos* (`Modalidad`,
  `Categoria`, `ModalidadInscripcion`, `Pagos.Metodo`, `Tarjetas.Tipo`) son `CHECK` dentro de la
  tabla → **no se dibujan como entidad**, son una restricción de la columna.
- `InscripcionSesion` usa **PK compuesta** (`InscripcionID`+`SesionID`): no lleva id propio y
  además impide registrar dos veces la misma sesión en una inscripción.
- **No hay tabla de notificaciones**: en el enunciado todo es "notificación por correo" (email).
- Reglas de negocio (traslapes de horario, cupos, Early Bird 20%, VIP máx 10, ventanas 24h/48h,
  reembolso 80%) **no son entidades ni columnas**: van en la lógica/validaciones del backend.
