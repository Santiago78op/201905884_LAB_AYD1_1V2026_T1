# 📦 EVENTCORE — Manual de la base de datos

Manual de apoyo para **entender y explicar** el esquema: cómo se ejecuta, qué hace cada tabla,
qué significa cada campo y por qué está diseñado así. Pensado para usarlo al presentar el proyecto.

- **Motor:** SQL Server 2016+ (probado en `azure-sql-edge` local y desplegable en **AWS** RDS/EC2).
- **Modelo:** **22 tablas · 27 claves foráneas · 1 relación N:M** (Inscripciones ↔ Sesiones).
- **Sin `GO`:** todos los scripts usan `;` como separador → corren directo en DBeaver / clientes AWS.

---

## 1. 🗂️ Archivos

### Despliegue rápido (todo de una)
| Archivo | Qué hace |
|---|---|
| **`eventcore_completo.sql`** | **TODO el esquema en un solo archivo, sin `GO`.** Crea base, 22 tablas, índices y seeds. Ideal para **AWS**: lo ejecutás de una pasada. |

### Por pasos (didáctico, en orden 01 → 09)
| # | Archivo | Crea / hace | Depende de |
|--:|---------|-------------|------------|
| 1 | `01_database.sql` | Crea la base `EventCore` y entra en ella | — |
| 2 | `02_lookups.sql` | `Roles`, 4× `Estados…`, `Dias`, `Horarios` | 01 |
| 3 | `03_catalogos_base.sql` | `Usuarios`, `Ponentes`, `Salas`, `TiposEntrada` | 02 |
| 4 | `04_nucleo.sql` | `Eventos`, `Sesiones`, `MaterialesRecurso` | 02, 03 |
| 5 | `05_inscripciones.sql` | `Inscripciones`, `InscripcionSesion`, `CodigosInvitacion` | 03, 04 |
| 6 | `06_pagos_cancelaciones.sql` | `Tarjetas`, `Pagos`, `SolicitudesCancelacion` | 03, 05 |
| 7 | `07_bitacora.sql` | `LogActividad` | 03 |
| 8 | `08_seeds.sql` | Llena los catálogos (roles, estados, días, horarios) | 02 |
| 9 | `09_confirmaciones_correo.sql` | `ConfirmacionesCorreo` (confirmar correo en signup) | 03 |

### Auxiliares
| Archivo | Para qué |
|---|---|
| `drops.sql` | Borra las 22 tablas en orden inverso a las FKs (reset) |
| `checks.sql` | Catálogo re-ejecutable de todas las reglas `CHECK` (referencia) |

---

## 2. ▶️ Cómo ejecutarlo

### Local (DBeaver + azure-sql-edge)
1. Conexión a SQL Server → activá **"Trust server certificate"**. Host: `localhost` (o IP de la VM); puerto `1433`; user `sa`.
2. Corré los scripts con **"Execute SQL Script" → `Alt+X` (`⌥X`)**, **no** `⌘+Enter`.
3. Opción A: ejecutá `eventcore_completo.sql` (una sola vez). Opción B: `01` → `09` en orden.

### AWS (RDS / EC2 con SQL Server)
1. Conectate a la instancia (DBeaver, Azure Data Studio o `sqlcmd`).
2. Ejecutá **`eventcore_completo.sql`**.
3. Si tu instancia **ya tiene una base creada** y no te deja crear otra, **comentá** las líneas
   `CREATE DATABASE` y `USE` del inicio, y corré el resto sobre esa base.

### Verificar (deben salir 22 tablas y 27 FKs)
```sql
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME;
SELECT OBJECT_NAME(parent_object_id) AS Hijo, name AS FK, OBJECT_NAME(referenced_object_id) AS Padre
FROM sys.foreign_keys ORDER BY Hijo;
```

### Reset
Corré `drops.sql` y volvé a lanzar el DDL.

---

## 3. 📖 Glosario (para explicar con propiedad)

| Término | Qué es | Cómo lo decís al presentar |
|---|---|---|
| **PK** (Primary Key) | Identifica **única** cada fila. | "esta columna es el identificador de la tabla" |
| **FK** (Foreign Key) | Apunta al PK de otra tabla; garantiza integridad. | "no puede existir una sesión de un evento que no exista" |
| **UQ** (Unique) | Valor que **no se repite** (sin ser la PK). | "dos usuarios no pueden tener el mismo correo" |
| **CK** (Check) | Regla que cada fila debe cumplir. | "el motor rechaza una capacidad negativa" |
| **IDENTITY** | El id lo genera el motor (1,2,3…). | "autonumérico" |
| **Lookup** | Tabla-catálogo de valores (estados/roles). | "en vez de texto suelto, los estados viven en su tabla" |
| **Borrado lógico** (`Activo`) | Se desactiva, no se elimina. | "no borramos, marcamos inactivo para no perder historial" |
| **Índice** (`IX_…`) | Acelera búsquedas/joins. | "cada FK tiene su índice para que los joins sean rápidos" |
| **N:M** | Muchos-a-muchos resuelto con tabla puente. | "una inscripción cubre varias sesiones y viceversa" |

**Tipos de dato más usados:** `TINYINT` (0–255, ids de catálogo) · `INT` (ids de negocio) ·
`BIGINT` (la bitácora crece mucho) · `NVARCHAR(n)` (texto Unicode) · `DECIMAL(10,2)` (dinero) ·
`DATETIME2(0)` (fecha+hora) · `TIME(0)` (solo hora) · `BIT` (sí/no).

---

## 4. 🧱 Diccionario por tabla (qué es y campos clave)

### Catálogos lookup
- **`Roles`** — tipos de usuario. `RolID` (PK), `Codigo` (`ADMIN`/`ASISTENTE`). Sembrado a mano.
- **`EstadosEvento` / `EstadosInscripcion` / `EstadosPago` / `EstadosSolicitud`** — los estados de cada
  flujo. Campos: `…ID` (PK), `Codigo`, `EsTerminal` (`1` = estado cerrado, sin más cambios).
- **`Dias`** — días de la semana **predefinidos**. `DiaID` (1=Lunes … 7=Domingo), `Nombre`, `Abreviatura`.
- **`Horarios`** — bloques de hora **predefinidos**. `HorarioID`, `HoraInicio`/`HoraFin` (`TIME`), `Etiqueta`.

### Catálogos base
- **`Usuarios`** — admin y asistente en **una sola tabla**, distinguidos por `RolID`. Campos clave:
  `Correo` (UQ + CK de formato), `Contrasena` (**hash**), `RolID` (FK), `CorreoConfirmado`, `Activo`.
- **`Ponentes`** — quienes imparten sesiones. `Biografia`, `AreaEspecializacion`, `Activo`.
- **`Salas`** — espacios físicos. `Capacidad` (CK > 0), usada en el reporte de ocupación.
- **`TiposEntrada`** — tarifas (`EARLY_BIRD`, `GENERAL`, `VIP`…). `Tarifa`, `Disponibilidad`.

### Núcleo del evento
- **`Eventos`** — el evento. `AdminID` (FK→Usuarios), `Modalidad`/`Categoria`/`ModalidadInscripcion`
  (enums fijos por CK), `EstadoEventoID` (FK), `EsPago`, fechas con CK `Fin ≥ Inicio`.
- **`Sesiones`** — charla dentro de un evento. **Se agenda por id:** `DiaID` (FK→Dias) y `HorarioID`
  (FK→Horarios). Además `PonenteID`, `SalaID` (NULL si es virtual), `CupoMaximo`.
- **`MaterialesRecurso`** — archivos de una sesión. **`ON DELETE CASCADE`**: si se borra la sesión,
  sus materiales se van con ella.

### Inscripciones
- **`Inscripciones`** — un asistente inscrito a un evento. `AsistenteID`, `TipoEntradaID`,
  `EstadoInscripcionID`, `Monto`.
- **`InscripcionSesion`** — **tabla puente N:M** (Inscripción ↔ Sesión). **PK compuesta**
  (`InscripcionID`+`SesionID`): no se puede registrar dos veces la misma sesión.
- **`CodigosInvitacion`** — códigos para eventos privados. `Codigo` (UQ), `Usado`, `AsistenteID` (NULL hasta canjear).

### Pagos y cancelaciones
- **`Tarjetas`** — medios de pago. `NumeroEnmascarado` (solo últimos dígitos, **nunca** el completo), `Tipo` (CK).
- **`Pagos`** — pago de una inscripción. `Metodo` (CK), `EstadoPagoID`, `TarjetaID`/`AdminRevisorID` (uno u otro según método).
- **`SolicitudesCancelacion`** — pedido de reembolso. `MontoReembolso` (≥0), `EstadoSolicitudID`, `AdminProcesadorID`.

### Soporte
- **`LogActividad`** — bitácora del sistema (reporte de actividades). `LogID` (BIGINT), `UsuarioID` (NULL si lo hace el sistema), `Accion`, `EntidadAfectada`.
- **`ConfirmacionesCorreo`** — confirmación de correo para signup/login. `Token` (UQ), `FechaExpira`,
  `Usado`, `FechaUso`. Al confirmar se pone `Usuarios.CorreoConfirmado = 1`.

---

## 5. 💡 Decisiones de diseño (las preguntas típicas del catedrático)

**¿Por qué los estados son tablas y no un `CHECK IN(...)`?**
Porque pueden crecer: agregar un estado nuevo es un `INSERT`, no alterar la tabla. Además guardan
metadatos (`EsTerminal`). Los enums que **nunca** cambian (modalidad, método de pago, tipo de tarjeta)
sí van como `CHECK`.

**¿Por qué `Dias` y `Horarios` predefinidos?**
Para tener control y que el frontend asigne día/hora **por id** (no texto libre): menos errores, datos
consistentes y fáciles de listar en un combo. `Horarios` usa `TIME` para validar `HoraFin > HoraInicio`.

**¿Cómo funciona el login/signup en la DB?**
Signup = `INSERT` en `Usuarios` (la contraseña se guarda **hasheada**). Login = `SELECT` por `Correo`,
verificar hash, exigir `CorreoConfirmado = 1` y `Activo = 1`, y dar permisos según `RolID`.
La confirmación de correo usa la tabla `ConfirmacionesCorreo` (token con vencimiento).
El hash, el JWT y la "capa extra" del admin son lógica del **backend**, no de la base.

**¿Por qué un índice por cada FK?**
Las FK no se indexan solas; sin índice, los joins y los borrados serían lentos. Por eso cada FK
tiene su `IX_…`.

> Diccionario de datos completo y diagrama ER en la carpeta superior:
> `../eventcore-tablas.md`, `../eventcore-relaciones.md`, `../entidades-y-foraneas.md`, `../eventcore-er.*`.
