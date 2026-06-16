# 📦 TRACKFLOW-HUB — Manual de la base de datos

Manual de referencia para **entender y explicar** el esquema: qué archivos lo componen, qué hace
cada tabla, qué reglas garantiza el motor y por qué está diseñado así.
**31 tablas · borrado lógico · patrón tabla base + subtipos.** Motor: SQL Server 2016+ / azure-sql-edge.

> Documento hermano del modelo conceptual `../modelo-trackflow.md` (ER Mermaid, casos de uso y
> reglas de negocio). Mismo estilo y convenciones que el manual de PT1 (`../../PT1/sql/README.md`).

---

## 1. 🗂️ Archivos

**Despliegue rápido (todo en uno):**

| Archivo | Qué hace |
|---|---|
| `trackflow_completo.sql` | TODO el esquema en un solo archivo, sin `GO`: base, limpieza, 31 tablas, índices y seeds. Pensado para AWS/contenedor. |

**Por pasos (didáctico, en orden 01 → 08):**

| # | Archivo | Crea / hace | Depende de |
|--:|---------|-------------|------------|
| 1 | `01_database.sql` | Crea la base `TrackFlow` y entra en ella | — |
| 2 | `02_lookups.sql` | `Roles`, `Generos`, 5× `Estados…`, `Zonas` | 01 |
| 3 | `03_usuarios_perfiles.sql` | `Usuarios` + `PerfilCliente` / `PerfilOperador` / `PerfilEmpresa` | 02 |
| 4 | `04_servicios_rutas.sql` | `ServiciosEnvio`, `FotosServicio`, `Rutas`, `Flota` | 02, 03 |
| 5 | `05_reservaciones.sql` | `Tarjetas`, `ItemsCarrito`, `Reservaciones`, `Pagos` | 03, 04 |
| 6 | `06_interaccion.sql` | `Calificaciones`, `Cupones`, `CuponesCanjeados`, `Reportes`, `EvidenciasReporte`, `Sanciones` | 03, 05 |
| 7 | `07_soporte.sql` | `Tokens`, `SolicitudesCambioPerfil`, `ReunionesVirtuales`, `Notificaciones`, `LogActividad` | 02, 03 |
| 8 | `08_seeds.sql` | Llena los catálogos (roles, género, estados, zonas) | 02 |

**Auxiliares:**

| Archivo | Para qué |
|---|---|
| `drops.sql` | Borra las 31 tablas en orden inverso a las FKs (reset) |
| `checks.sql` | Catálogo re-ejecutable de todas las reglas `CHECK` (referencia) |

---

## 2. 🏷️ Convenciones de nomenclatura

Mismo estándar que PT1: reconocer el prefijo te dice de inmediato qué es cada objeto.

| Patrón | Significa | Ejemplo |
|--------|-----------|---------|
| `PascalCase` plural | nombre de tabla | `Reservaciones`, `ServiciosEnvio` |
| `TablaID` | clave primaria | `ReservaID`, `ServicioID` |
| `PK_Tabla` | restricción de clave primaria | `PK_Reservaciones` |
| `FK_Hijo_Padre` | clave foránea | `FK_Pagos_Reservaciones` |
| `UQ_Tabla_Campo` | restricción única | `UQ_Usuarios_Correo` |
| `CK_Tabla_Regla` | restricción CHECK | `CK_Reservaciones_Coherencia` |
| `DF_Tabla_Campo` | valor por defecto | `DF_Tarjetas_Saldo` |
| `IX_Tabla_Campo` | índice no clúster | `IX_Reservaciones_ClienteID` |

---

## 3. 📐 Glosario de claves y tipos

| Clave | Qué es | Cómo lo explicás |
|---|---|---|
| **PK** | identifica única cada fila | “el identificador de la tabla” |
| **FK** | apunta al PK de otra tabla | “no puede existir un pago de una reserva inexistente” |
| **UQ** | valor que no se repite | “dos usuarios no pueden tener el mismo correo” |
| **CK** | regla que cada fila debe cumplir | “el motor rechaza una puntuación fuera de 1–5” |
| **IDENTITY** | id autonumérico del motor | “autonumérico 1,2,3…” |
| **PK = FK** (subtipo) | la PK del perfil es además FK a `Usuarios` | “el perfil comparte el id del usuario (1:1)” |
| **Borrado lógico** (`Activo` / estado) | se desactiva, no se borra | “marcamos inactivo para no perder historial” |

| Tipo | Guarda | Nota |
|------|--------|------|
| `TINYINT` | ids de catálogo (rol, estados, zona, género) | 0–255 |
| `INT` | ids de negocio | ±2,100 M |
| `BIGINT` | la bitácora (crece mucho) | `LogActividad` |
| `NVARCHAR(n)` / `NVARCHAR(MAX)` | texto Unicode (tildes/ñ) | descripciones, JSON de cambios |
| `DECIMAL(10,2)` | dinero / pesos | montos, saldo, capacidad |
| `DATETIME2(0)` | fecha + hora | precisión = segundos |
| `TIME(0)` | solo hora | `Rutas.HoraInicio` |
| `BIT` | booleano | flags `Activo`, `Suspendido`, `Leida` |

> Los literales de texto van con `N` adelante (`N'CLIENTE'`) porque las columnas son `NVARCHAR`.

---

## 4. 🧱 Diccionario por tabla

### Catálogos lookup (PK a mano, sembrados en `08_seeds.sql`)

- **`Roles`** — los 4 tipos de usuario (`1 CLIENTE`, `2 OPERADOR`, `3 EMPRESA`, `4 ADMIN`).
- **`Generos`** — catálogo del campo *Género* del operador.
- **`EstadosCuenta`** — ciclo de vida de la cuenta (`ACTIVA`/`SUSPENDIDA`/`VETADA`); `EsTerminal` marca el cerrado (`VETADA`).
- **`EstadosSolicitud`** — aprobación de registro (operador/empresa) y de cambios de perfil (`PENDIENTE`/`ACEPTADA`/`RECHAZADA`).
- **`EstadosReserva`** — `ACTIVO`/`EN_TRANSITO`/`ENTREGADO`/`CANCELADO` (los 4 del enunciado).
- **`EstadosPago`** — `PENDIENTE`/`PROCESADO`/`RECHAZADO`.
- **`EstadosReporte`** — `ENVIADO`/`EN_REVISION`/`ACEPTADO`/`RECHAZADO`.
- **`Zonas`** — catálogo geográfico predefinido (cobertura, operación, origen/destino); `Tipo` = NACIONAL/INTERNACIONAL.

### Identidad: tabla base + subtipos

- **`Usuarios`** — datos comunes a los 4 roles: `Correo` (UNIQUE), `Contrasena` (**hash**), `RolID`, `EstadoCuentaID`, `CorreoConfirmado`, `MotivoVeto` (NULL salvo al vetar), `RequiereCambioPassword` (operador con contraseña temporal).
- **`PerfilCliente` / `PerfilOperador` / `PerfilEmpresa`** — subtipos 1:1: `UsuarioID` es **PK y FK** a la vez. Operador trae `DpiCui` (UNIQUE), `ZonaOperacionID`, `GeneroID`, `EstadoSolicitudID`; empresa trae `Nit` y `NumeroLicencia` (UNIQUE) + `EstadoSolicitudID`. El ADMIN no tiene perfil (datos a criterio).

### Servicios y rutas (lo que ofrecen los proveedores)

- **`ServiciosEnvio`** — servicio del operador: `ZonaCoberturaID`, `CapacidadCargaKg`, `PrecioEnvio`, `Suspendido` (suspensión temporal), `Activo` (borrado lógico).
- **`FotosServicio`** — fotos del servicio (mín. 3 → backend). FK `ON DELETE CASCADE`.
- **`Rutas`** — ruta de la empresa: `ZonaOrigenID`/`ZonaDestinoID`, `HoraInicio`, `TiempoEstimadoMin`, `Precio`, `Estado` (ACTIVA/SUSPENDIDA/CANCELADA).
- **`Flota`** — vehículos de la empresa (carga CSV o manual).

### Cliente: carrito, reservas y pagos

- **`Tarjetas`** — método de pago simulado: `Saldo` (DEFAULT `1000.00`), `NumeroEnmascarado` (Luhn → backend), `Metodo` (TARJETA/WALLET = el segundo método del enunciado).
- **`ItemsCarrito`** — carrito persistente (sobrevive al cierre de sesión). `Tipo` + `ServicioEnvioID`/`RutaID` (uno NULL).
- **`Reservaciones`** — la reserva contratada: `Tipo` (ENVIO/TRANSPORTE), `ServicioEnvioID`/`RutaID` (uno NULL), rango de fechas, `EstadoReservaID`, `Monto`.
- **`Pagos`** — el pago de una reserva; `EstadoPagoID` nace `PENDIENTE` (DEFAULT) y pasa a `PROCESADO`/`RECHAZADO`.

### Interacción posterior

- **`Calificaciones`** — una por reserva (`UQ` en `ReservaID`); `Puntuacion` 1–5; `RespuestaProveedor` (el operador responde).
- **`Cupones`** — los emite un operador o empresa (`EmisorID` → `Usuarios`); `Codigo` UNIQUE, vigencia, condiciones.
- **`CuponesCanjeados`** — qué cliente canjeó qué cupón (`UQ (CuponID, ClienteID)`); `ReservaID` NULL si solo se guardó.
- **`Reportes`** — denuncia: `ReportanteID` y `ReportadoID` (ambos → `Usuarios`), `Tipo`, `EstadoReporteID`.
- **`EvidenciasReporte`** — fotos/vídeo del reporte; FK `ON DELETE CASCADE`.
- **`Sanciones`** — la aplica el admin: `Tipo` (SUSPENSION_TEMPORAL/VETO_PERMANENTE), `FechaFin` NULL si es permanente.

### Soporte (auth / proceso / auditoría)

- **`Tokens`** — un solo lugar para los 3 tokens: `CONFIRMACION_CORREO` (6 chars), `DOBLE_FACTOR_2FA` (2 min), `PASSWORD_TEMPORAL`.
- **`SolicitudesCambioPerfil`** — cambios de perfil de operador/empresa sujetos a aprobación; `DatosPropuestos` (JSON).
- **`ReunionesVirtuales`** — reunión empresa ↔ admin antes de aceptar a la empresa.
- **`Notificaciones`** — avisos en la vista del usuario.
- **`LogActividad`** — bitácora (`BIGINT`); `UsuarioID` NULL si la acción la hace el sistema.

---

## 5. 🌱 Catálogos sembrados (ids estables que el backend referencia como constantes)

- **Roles:** `1 CLIENTE` · `2 OPERADOR` · `3 EMPRESA` · `4 ADMIN`
- **Generos:** `1 MASCULINO` · `2 FEMENINO` · `3 OTRO`
- **EstadosCuenta** (`*` = terminal): `1 ACTIVA` · `2 SUSPENDIDA` · `3 VETADA*`
- **EstadosSolicitud:** `1 PENDIENTE` · `2 ACEPTADA*` · `3 RECHAZADA*`
- **EstadosReserva:** `1 ACTIVO` · `2 EN_TRANSITO` · `3 ENTREGADO*` · `4 CANCELADO*`
- **EstadosPago:** `1 PENDIENTE` · `2 PROCESADO*` · `3 RECHAZADO*`
- **EstadosReporte:** `1 ENVIADO` · `2 EN_REVISION` · `3 ACEPTADO*` · `4 RECHAZADO*`
- **Zonas:** `1 Guatemala` … `7 Huehuetenango` · `8 Internacional` (ampliable)

---

## 6. 🔗 Mapa de relaciones (las FKs)

“La FK vive en el lado **muchos** (hijo) y apunta al lado **uno** (padre)”.

| Tabla hijo | Columna(s) FK | → Padre |
|------------|---------------|---------|
| `Usuarios` | `RolID` · `EstadoCuentaID` | `Roles` · `EstadosCuenta` |
| `PerfilCliente` | `UsuarioID` | `Usuarios` |
| `PerfilOperador` | `UsuarioID` · `ZonaOperacionID` · `GeneroID` · `EstadoSolicitudID` | `Usuarios` · `Zonas` · `Generos` · `EstadosSolicitud` |
| `PerfilEmpresa` | `UsuarioID` · `EstadoSolicitudID` | `Usuarios` · `EstadosSolicitud` |
| `ServiciosEnvio` | `OperadorID` · `ZonaCoberturaID` | `Usuarios` · `Zonas` |
| `FotosServicio` | `ServicioID` (CASCADE) | `ServiciosEnvio` |
| `Rutas` | `EmpresaID` · `ZonaOrigenID` · `ZonaDestinoID` | `Usuarios` · `Zonas` · `Zonas` |
| `Flota` | `EmpresaID` | `Usuarios` |
| `Tarjetas` | `ClienteID` | `Usuarios` |
| `ItemsCarrito` | `ClienteID` · `ServicioEnvioID` · `RutaID` | `Usuarios` · `ServiciosEnvio` · `Rutas` |
| `Reservaciones` | `ClienteID` · `ServicioEnvioID` · `RutaID` · `EstadoReservaID` | `Usuarios` · `ServiciosEnvio` · `Rutas` · `EstadosReserva` |
| `Pagos` | `ReservaID` · `TarjetaID` · `EstadoPagoID` | `Reservaciones` · `Tarjetas` · `EstadosPago` |
| `Calificaciones` | `ReservaID` · `ClienteID` | `Reservaciones` · `Usuarios` |
| `Cupones` | `EmisorID` | `Usuarios` |
| `CuponesCanjeados` | `CuponID` · `ClienteID` · `ReservaID` | `Cupones` · `Usuarios` · `Reservaciones` |
| `Reportes` | `ReportanteID` · `ReportadoID` · `ReservaID` · `EstadoReporteID` | `Usuarios` · `Usuarios` · `Reservaciones` · `EstadosReporte` |
| `EvidenciasReporte` | `ReporteID` (CASCADE) | `Reportes` |
| `Sanciones` | `UsuarioID` · `ReporteID` · `AdminID` | `Usuarios` · `Reportes` · `Usuarios` |
| `Tokens` | `UsuarioID` | `Usuarios` |
| `SolicitudesCambioPerfil` | `UsuarioID` · `AdminRevisorID` · `EstadoSolicitudID` | `Usuarios` · `Usuarios` · `EstadosSolicitud` |
| `ReunionesVirtuales` | `EmpresaID` · `AdminID` | `Usuarios` · `Usuarios` |
| `Notificaciones` | `UsuarioID` | `Usuarios` |
| `LogActividad` | `UsuarioID` | `Usuarios` |

> **`Usuarios` es la tabla más “apuntada”**: cliente, operador, empresa, admin, emisor de cupones,
> reportante/reportado, revisor… Por eso una sola tabla base con `RolID`, y los datos propios de
> cada rol en su perfil 1:1.

---

## 7. ✅ Reglas que garantiza el motor

**Vía CHECK:**
- Formato de correo en `Usuarios`.
- Montos/precios/valores `≥ 0`; capacidades `> 0`; puntuación `BETWEEN 1 AND 5`.
- Coherencia de fechas: reserva/cupón/sanción `Fin ≥ Inicio`; token `FechaExpira > FechaCreacion`.
- **Coherencia tipo↔FK** en `Reservaciones` e `ItemsCarrito`: si `Tipo = ENVIO` entonces `ServicioEnvioID` NOT NULL y `RutaID` NULL (y al revés). El motor impide una reserva incoherente.
- Enums fijos por CHECK: `Metodo`, `TipoDescuento`, `Estado` de rutas/reuniones, `Tipo` de reportes/evidencias/sanciones, `Tipo` de zonas/tokens.
- `Rutas`: origen ≠ destino; `Reportes`: reportante ≠ reportado.

**Vía UNIQUE:** correo, DPI/CUI, NIT, número de licencia, código de cupón, código de catálogos, una calificación por reserva, un canje por (cupón, cliente).

**Vía FK + ON DELETE CASCADE:** integridad referencial total; al borrar un servicio se borran sus fotos, y al borrar un reporte se borran sus evidencias.

> Las reglas de **proceso** (24 h de anticipación, sin traslape de fechas, reparto 80/20 y 90/10,
> 3 mejor calificados, Luhn, vigencia de tokens) **no** son del esquema: viven en el backend.

---

## 8. ⚡ Estrategia de índices

> “Las FK no se indexan solas.” Cada FK tiene su índice `IX_…`. Además:
> - Índices **filtrados** (`WHERE … IS NOT NULL`) en las FK opcionales (`ServicioEnvioID`/`RutaID` de carrito y reservas, `AdminID` de reuniones, etc.): no indexan NULL → más chicos.
> - `LogActividad` indexa `FechaHora DESC` (la bitácora se consulta por “lo más reciente”).
> - `Tokens.Valor` indexado para el lookup de confirmación/2FA.
> - Los `UNIQUE` (correo, código de cupón…) ya crean su propio índice ideal para los lookups de login y canje.

---

## 9. 💡 Decisiones de diseño (las preguntas típicas del catedrático)

**¿Por qué tabla base `Usuarios` + perfiles subtipo, y no una sola tabla como en EventCore?**
Los 4 roles tienen datos **disjuntos** (operador: DPI/zona/género; empresa: NIT/licencia; cliente:
dirección). Una sola tabla quedaría llena de NULLs. La base guarda lo común (auth, estado) y cada
perfil cuelga 1:1 con `UsuarioID` como PK *y* FK. El rol da los permisos.

**¿Por qué una sola `Reservaciones` con `Tipo` + dos FKs opcionales?**
El cliente ve “sus servicios contratados con estado” en una sola vista, y puede contratar envío,
transporte o ambos. Una tabla con `Tipo` + `ServicioEnvioID`/`RutaID` (uno NULL) hace ese listado un
solo `SELECT`. El `CK_..._Coherencia` impide combinaciones inválidas. **NULL = “no aplica”, no “falta”.**

**¿Por qué los estados son tablas lookup y no `CHECK IN(...)`?**
Conjunto extensible o con metadatos (`EsTerminal`) = **lookup** (estados de cuenta/solicitud/reserva/
pago/reporte). Conjunto fijo que nunca cambia (método de pago, tipo de descuento, tipo de reporte) =
**CHECK**.

**¿Por qué borrado lógico?**
Para no romper FKs ni perder historial: un servicio con reservas no se borra, se suspende
(`Suspendido`) o se inactiva (`Activo`); un usuario vetado conserva su fila (`EstadoCuenta = VETADA`).

**¿Por qué `Saldo` en `Tarjetas` con DEFAULT 1000?**
El enunciado da Q1,000 al registrar una tarjeta ficticia; el DEFAULT lo garantiza sin que el backend
lo olvide. Las compras lo descuentan (lógica del backend). La validación Luhn también es del backend.

> Patrón que se repite (igual que en PT1): todo flujo revisable por un admin —registro de operador/
> empresa, cambio de perfil, reporte— **nace `PENDIENTE` por DEFAULT** y el admin lo mueve a un estado
> terminal; las reglas de **tiempo/porcentaje** viven en el backend con los datos que la base guarda.
