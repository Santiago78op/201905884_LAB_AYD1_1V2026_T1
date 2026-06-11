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
- `Activo`: borrado lógico — "eliminar" la tarjeta del perfil = ponerla en `0`, sin tocar los pagos que la referencian.

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

---

## 10. 🔐 Cómo usa el backend estos ids (signup / login)

Aquí se ve el “pago” de tener ids fijos: el backend los usa como **constantes** para registrar,
confirmar correo, autenticar y autorizar. Ejemplos en Flask + SQL Server (`pyodbc`).

**Los ids sembrados se vuelven constantes en el código** (nunca un número suelto):
```python
ROL_ADMIN     = 1
ROL_ASISTENTE = 2
```

### Signup → `INSERT` en `Usuarios`
El rol se fija con la constante; `CorreoConfirmado`/`Activo` los pone la BD por `DEFAULT`.
```python
hash_pw = generate_password_hash(d["contrasena"])      # nunca texto plano
cur.execute("""
    INSERT INTO dbo.Usuarios
        (NombreCompleto, Correo, Contrasena, Telefono, Organizacion,
         PaisResidencia, FotoPerfil, RolID)
    OUTPUT INSERTED.UsuarioID
    VALUES (?,?,?,?,?,?,?,?)
""", d["nombre"], d["correo"], hash_pw, d["telefono"],
     d["organizacion"], d["pais"], d["foto"], ROL_ASISTENTE)   # ← id fijo
usuario_id = cur.fetchone()[0]

# token de verificación (tabla ConfirmacionesCorreo)
token = secrets.token_urlsafe(32)
cur.execute("""
    INSERT INTO dbo.ConfirmacionesCorreo (UsuarioID, Token, FechaExpira)
    VALUES (?, ?, DATEADD(HOUR, 24, SYSUTCDATETIME()))
""", usuario_id, token)
enviar_correo(d["correo"], f"https://tuapp/confirmar/{token}")
```

### Confirmar correo → `GET /confirmar/:token`
Prende el flag `CorreoConfirmado` y marca el token como usado.
```python
fila = cur.execute("""
    SELECT ConfirmacionID, UsuarioID FROM dbo.ConfirmacionesCorreo
    WHERE Token = ? AND Usado = 0 AND FechaExpira > SYSUTCDATETIME()
""", token).fetchone()
if not fila:
    return "Token inválido o vencido", 400
cur.execute("UPDATE dbo.Usuarios SET CorreoConfirmado = 1 WHERE UsuarioID = ?", fila.UsuarioID)
cur.execute("UPDATE dbo.ConfirmacionesCorreo SET Usado = 1, FechaUso = SYSUTCDATETIME() WHERE ConfirmacionID = ?", fila.ConfirmacionID)
```

### Login → `SELECT` + verificaciones
Los flags y el rol deciden todo.
```python
u = cur.execute("""
    SELECT UsuarioID, Contrasena, RolID, CorreoConfirmado, Activo
    FROM dbo.Usuarios WHERE Correo = ?
""", d["correo"]).fetchone()

if not u or not check_password_hash(u.Contrasena, d["contrasena"]):
    return "Credenciales inválidas", 401
if u.CorreoConfirmado != 1:        # regla del enunciado: confirmar correo antes de entrar
    return "Confirmá tu correo primero", 403
if u.Activo != 1:                  # borrado lógico
    return "Cuenta desactivada", 403

token = crear_jwt({"uid": u.UsuarioID, "rol": u.RolID})   # el rol viaja en el token
return {"token": token}
```

### Autorización → comparar el rol contra la constante
```python
@app.route("/eventos", methods=["POST"])
def crear_evento():
    if request.usuario["rol"] != ROL_ADMIN:    # ← 1 = ADMIN, siempre
        return "Solo administradores", 403
    ...
```

### Resumen: qué campo decide qué
| Campo de la BD | Quién lo escribe | Qué decide en el backend |
|---|---|---|
| `RolID` (1/2) | el signup, con la constante | admin o asistente → permisos |
| `CorreoConfirmado` (0→1) | `/confirmar/:token` | si puede iniciar sesión |
| `Activo` (1/0) | admin / borrado lógico | si la cuenta sigue válida |
| `ConfirmacionesCorreo.Token` | el signup (único) | encontrar al usuario al confirmar |

> **División de responsabilidades:** la BD *guarda* el hash, los flags y los ids, y *garantiza*
> reglas (UNIQUE de correo, FK del rol). **Hashear la contraseña, emitir el JWT y la capa de
> seguridad extra del admin** son lógica del **backend**, no de la base.

---

## 11. 💸 Flujo del pago por transferencia (cómo se aplicó el requerimiento)

Requerimiento del enunciado: *"el asistente carga el comprobante de pago en el sistema; el
administrador revisa y confirma o rechaza el pago"*. Todo se resuelve **dentro de la misma tabla
`Pagos`** — no hace falta una tabla aparte de "revisiones", porque la revisión es un solo evento
con un solo responsable y cabe como atributos del propio pago.

| Parte del requerimiento | Columna que lo resuelve |
|---|---|
| "El pago es por transferencia" | `Metodo` con CHECK (`TARJETA` \| `TRANSFERENCIA`); si es transferencia, `TarjetaID` queda NULL |
| "El asistente carga el comprobante" | `ComprobanteUrl` — se guarda la **ruta/URL** del archivo, no el archivo en sí |
| "Queda esperando revisión" | `EstadoPagoID` con `DEFAULT (1)` → todo pago **nace PENDIENTE** automáticamente |
| "El admin confirma o rechaza" | `EstadoPagoID` pasa a `2 = CONFIRMADO` o `3 = RECHAZADO`, y `AdminRevisorID` guarda **quién** lo revisó |

**El ciclo de vida es un cambio de estado sobre la misma fila:**

```
INSERT pago (Metodo=TRANSFERENCIA, ComprobanteUrl=..., TarjetaID=NULL)
        → EstadoPagoID = 1 PENDIENTE      (lo pone el DEFAULT, nadie lo escribe)

UPDATE del admin
        → EstadoPagoID = 2 CONFIRMADO  ó  3 RECHAZADO   (ambos terminales)
        → AdminRevisorID = <su UsuarioID>                (queda registro de quién decidió)
```

**¿Y el pago con tarjeta?** Misma tabla, mismo esquema pero al revés: se llena `TarjetaID` y
quedan NULL `ComprobanteUrl` y `AdminRevisorID`, porque la pasarela confirma al instante y no
necesita revisión humana. Por eso esas columnas aceptan NULL: *vacío no es error, es que ese dato
no aplica para ese método de pago*.

| Columna | Transferencia | Tarjeta |
|---|---|---|
| `TarjetaID` | NULL | la tarjeta usada |
| `ComprobanteUrl` | URL del comprobante | NULL |
| `AdminRevisorID` | el admin que revisó | NULL |
| `EstadoPagoID` | nace 1, el admin lo mueve a 2 ó 3 | el backend lo confirma de una |

> **Límite honesto del diseño:** la base **no obliga** a que una transferencia traiga comprobante
> ni a que un pago confirmado tenga revisor — eso es regla del backend. Se podría endurecer con un
> CHECK tipo `(Metodo = N'TARJETA' OR ComprobanteUrl IS NOT NULL)`.

### ❓ "¿Y la FK a `Inscripciones`? Si la inscripción se confirma con el pago, ¿cómo inserto un pago antes?"

Es la objeción típica (el huevo y la gallina), pero parte de una premisa falsa: **la fila de
`Inscripciones` no se inserta cuando el pago se confirma — se inserta *antes* de pagar.**
Confirmar la inscripción no es un INSERT, es un **UPDATE de estado**. El orden real es:

```
1. El asistente se inscribe al evento
   → INSERT en Inscripciones          (estado 1 PENDIENTE o 2 APROBADA)
   → la fila YA EXISTE, ya tiene su InscripcionID
   → pero NO está confirmada: le falta pagar

2. El asistente paga (transferencia)
   → INSERT en Pagos con esa InscripcionID   ← la FK apunta a una fila que ya existe ✔
   → el pago nace 1 PENDIENTE

3. El admin confirma el pago
   → UPDATE Pagos          → EstadoPagoID = 2 CONFIRMADO
   → UPDATE Inscripciones  → EstadoInscripcionID = 4 CONFIRMADA
```

La confusión está en pensar que "inscripción" = "inscripción confirmada". En el modelo, la
inscripción es una fila que **vive todo el ciclo** y va cambiando de estado — por eso
`EstadosInscripcion` tiene 5 valores:

| Estado | Significa |
|---|---|
| 1 PENDIENTE | pidió entrar, el admin aún no aprueba (modalidad con aprobación) |
| 2 APROBADA | puede entrar, **pero aún no ha pagado** |
| 3 RECHAZADA | el admin no la aprobó |
| **4 CONFIRMADA** | **ya pagó** — este estado existe justamente para "pago confirmado" |
| 5 CANCELADA | la canceló y se reembolsó |

Si la fila de `Inscripciones` solo existiera al confirmar el pago, el estado `4 CONFIRMADA` no
tendría sentido (¿confirmada respecto a qué?), y no habría dónde colgar el pago pendiente ni la
solicitud de cancelación.

**La clave conceptual:** la FK solo exige *"no puede existir un pago de una inscripción que no
existe"* — no dice nada del **estado** de esa inscripción. **La FK valida existencia; el estado
valida el momento del proceso.** Son dos cosas distintas. El propio enunciado lo dice así: *"el
asistente deberá completar el proceso de pago **para confirmar** su inscripción"* — la
inscripción ya está hecha y el pago es lo que la confirma.

**Respuesta corta:** la inscripción se inserta al inscribirse (sin pagar) y nace pendiente; el
pago la referencia sin problema porque la fila ya existe; "confirmar" es cambiarle el estado a 4,
nunca insertarla.

**Resumen en una línea:** una sola fila en `Pagos` cuenta toda la historia — con qué se pagó, el
comprobante que subió el asistente, en qué estado va, y qué admin lo aprobó o rechazó.

---

## 12. 🗺️ Las demás directrices del enunciado, tabla por tabla

Misma idea que la sección 11, pero para **todo el resto del enunciado**: qué pide cada directriz
y qué tabla/columna la resuelve. Pensado para alguien que no vio el proyecto y quiere entender
cómo funciona de un vistazo.

### 12.1 Gestión de usuarios

| Directriz del enunciado | Cómo se resolvió |
|---|---|
| "Dos tipos de usuario: Administrador y Asistente" | **Una sola tabla `Usuarios`** y el tipo lo da `RolID` (FK → `Roles`: `1 ADMIN`, `2 ASISTENTE`). No hay dos tablas porque ambos comparten los mismos datos |
| "Información mínima del registro" | Columnas de `Usuarios`: `NombreCompleto`, `Correo` (UNIQUE — no se repite), `Contrasena` (**solo el hash**), `Telefono`, `Organizacion`, `PaisResidencia`, `FotoPerfil`. `Cargo` acepta NULL porque el enunciado lo marca **opcional** |
| "Para iniciar sesión debe confirmar su correo" | Tabla `ConfirmacionesCorreo`: al registrarse se genera un `Token` único con vencimiento (`FechaExpira`); cuando el usuario hace clic en el link, se marca `Usado = 1` y se prende `Usuarios.CorreoConfirmado = 1`. El login exige ese flag |
| "Autenticación por roles, JWT, capa extra del admin" | **Backend, no base**: la BD solo guarda `RolID` y el hash; el JWT y la capa extra son lógica de la API |

### 12.2 Eventos y sesiones

| Directriz del enunciado | Cómo se resolvió |
|---|---|
| "Información mínima de un evento" | Columnas de `Eventos`: nombre, descripción, fechas (con CHECK `Fin ≥ Inicio`), `Modalidad` (CHECK `PRESENCIAL`\|`VIRTUAL`\|`HIBRIDA`), `Categoria` (CHECK con las 5 del enunciado), banner, capacidad (CHECK `> 0`) |
| "Estado del evento (borrador, publicado, cancelado, finalizado)" | `EstadoEventoID` → lookup `EstadosEvento`. Nace en `1 BORRADOR` por DEFAULT; `CANCELADO` y `FINALIZADO` son **terminales** (`EsTerminal = 1`, ya no se mueven) |
| "El administrador es el único que crea/edita/cancela" | `Eventos.AdminID` (FK → `Usuarios`) guarda el dueño; que **solo** un admin pueda hacerlo lo valida el backend con el rol |
| "Cada sesión con su ponente, sala, horario y cupo" | Tabla `Sesiones`: `PonenteID`, `SalaID`, `DiaID` + `HorarioID` (la agenda **por id**, no texto libre), `CupoMaximo` (CHECK `> 0`) |
| "Sala **o enlace** según modalidad" | `SalaID` acepta NULL: si la sesión es virtual queda NULL y se usa `Enlace`. Igual que en `Pagos`: *NULL = no aplica, no error* |
| "Materiales o recursos adjuntos (opcional)" | Tabla `MaterialesRecurso` con `ON DELETE CASCADE`: si se borra la sesión, sus materiales se van solos (entidad débil) |
| "No traslapes de sesiones para un asistente / ponente" | Por eso la agenda es **por id**: comparar `DiaID + HorarioID` es trivial. La validación la hace el backend antes de insertar (es regla de proceso, no de esquema) |
| "Ver ocupación de salas y sesiones" | Consulta: `Sesiones.CupoMaximo` y `Salas.Capacidad` vs `COUNT(*)` de `InscripcionSesion` |

### 12.3 Las 3 modalidades de inscripción

La modalidad la fija `Eventos.ModalidadInscripcion` (CHECK `ABIERTA` \| `APROBACION` \| `INVITACION`):

| Modalidad | Cómo fluye en las tablas |
|---|---|
| **Abierta** | El asistente inserta directo en `Inscripciones` mientras haya cupo. La regla "hasta 24 h antes" la valida el backend comparando contra `Eventos.FechaInicio` |
| **Con aprobación** | Igual que el pago por transferencia: la inscripción **nace `1 PENDIENTE`** (DEFAULT de `EstadoInscripcionID`) y el admin la mueve a `2 APROBADA` o `3 RECHAZADA`. El correo de notificación lo manda el backend |
| **Por invitación** | Tabla `CodigosInvitacion`: el admin genera códigos (`Codigo` UNIQUE) para un evento; `AsistenteID` queda **NULL hasta que alguien lo canjea** y entonces se marca `Usado = 1`. Sin código válido no hay inscripción |

Además, "inscribirse a sesiones individuales respetando cupos" es la tabla puente
`InscripcionSesion`: su **PK compuesta** (`InscripcionID` + `SesionID`) garantiza que nadie
registre dos veces la misma sesión; el cupo lo verifica el backend contando filas.

### 12.4 Tarifas y tarjetas

| Directriz del enunciado | Cómo se resolvió |
|---|---|
| "Tarifas: Early Bird Q150, General Q250, Estudiante Q100, Sesión individual Q50, VIP Q500" | Tabla `TiposEntrada`: cada tarifa es **una fila** (`Tarifa` con CHECK `≥ 0`), no una columna. Agregar una tarifa nueva = un INSERT, sin tocar el esquema |
| "Disponibilidad: 20% del cupo, máx 10 por evento…" | `TiposEntrada.Disponibilidad` guarda la regla en texto; **hacerla cumplir** (contar inscritos, comparar contra el cupo) es del backend |
| "Registrar, editar y eliminar tarjeta en su perfil" | Tabla `Tarjetas` (FK → `Usuarios`). `NumeroEnmascarado` guarda **solo los últimos dígitos**, nunca el número completo (seguridad); `Tipo` con CHECK `DEBITO`\|`CREDITO`. "Eliminar" = borrado lógico (`Activo = 0`) para no romper los pagos que la referencian |
| "Confirmación del pago con tarjeta inmediata" | El backend inserta el pago ya confirmado; no hay revisión humana (ver tabla comparativa de la sección 11) |
| "Pago por transferencia" | **→ Sección 11** completa |

### 12.5 Cancelación y reembolso (el espejo de la sección 11)

Mismo patrón que el pago por transferencia, pero con `SolicitudesCancelacion`:

```
El asistente pide cancelar desde su panel
   → INSERT en SolicitudesCancelacion  → EstadoSolicitudID = 1 PENDIENTE (DEFAULT)
   → MontoReembolso = 80% de Inscripciones.Monto   (lo calcula el backend)

El admin la ve en su módulo y la procesa
   → EstadoSolicitudID = 2 PROCESADA  ó  3 RECHAZADA   (ambos terminales)
   → AdminProcesadorID = <su UsuarioID>
   → ComprobantePdfUrl = PDF del reembolso que se envía por correo
```

| Directriz del enunciado | Cómo se resolvió |
|---|---|
| "Cancelar hasta 48 h antes; después es irrevocable" | Regla de **tiempo** → backend, comparando contra `Eventos.FechaInicio` antes de aceptar la solicitud |
| "Se devuelve el 80% del monto pagado" | `MontoReembolso` (CHECK `≥ 0`); el 80% lo calcula el backend a partir de `Inscripciones.Monto` |
| "El admin procesa y envía un comprobante PDF" | `AdminProcesadorID` (quién) + `ComprobantePdfUrl` (el PDF); el correo lo manda el backend |

### 12.6 Ponentes

| Directriz del enunciado | Cómo se resolvió |
|---|---|
| "Catálogo de ponentes, entidad independiente, asignable a múltiples sesiones" | Tabla `Ponentes` propia; `Sesiones.PonenteID` la apunta — un ponente, muchas sesiones (1:N) |
| "Un ponente no puede tener dos sesiones en el mismo horario, ni en eventos distintos" | Backend: busca sesiones del mismo `PonenteID` con igual `DiaID + HorarioID` antes de asignar (otra vez: la agenda por id hace fácil la comparación) |
| "Editar o desactivar, pero **no eliminar** si tiene sesiones" | `Ponentes.Activo` = **borrado lógico**: se pone en `0` y la fila queda, así las FKs de sus sesiones no se rompen ni se pierde historial |

### 12.7 Reportes — de qué tabla sale cada uno

| Reporte del enunciado | De dónde sale |
|---|---|
| Historial de eventos (estado final + nº de asistentes) | `Eventos` + `EstadosEvento` + `COUNT` de `Inscripciones` |
| Ingresos del último mes por tipo de entrada y método, con reembolsos | `Pagos` (`FechaPago`, `Metodo`, `Monto`) unido a `Inscripciones` → `TiposEntrada`; los reembolsos salen de `SolicitudesCancelacion.MontoReembolso` |
| Eventos y sesiones con mayor % de ocupación | inscritos (`InscripcionSesion`) ÷ `Sesiones.CupoMaximo`; a nivel evento, `Inscripciones` ÷ `Eventos.CapacidadMaxima` |
| Historial de cancelaciones y reembolsos | `SolicitudesCancelacion` completa (estado, monto, admin, fecha) |
| Log de todas las actividades | `LogActividad`: cada acción inserta una fila (quién, qué `Accion`, sobre qué `EntidadAfectada`, cuándo). `UsuarioID` NULL = lo hizo el sistema |

> **El patrón que se repite en todo el diseño** (y que vale la pena contar al explicar el
> proyecto): cada flujo que requiere revisión humana — pago por transferencia, inscripción con
> aprobación, solicitud de cancelación — funciona **igual**: la fila *nace* `PENDIENTE` por
> DEFAULT, un admin la *mueve* a un estado terminal (confirmar/aprobar/procesar o rechazar), y
> queda guardado **quién** decidió. Las reglas de **tiempo y porcentaje** (24 h, 48 h, 80%,
> 20% del cupo, máx 10 VIP) nunca viven en la base: son del backend; la base aporta las fechas
> y montos para validarlas.

**Resumen en una línea:** el enunciado entero se reduce a tres patrones — lookups de estado con
DEFAULT `PENDIENTE` para todo lo que un admin revisa, NULLs que significan "no aplica" según el
método/modalidad, y reglas de tiempo/cupo que valida el backend con los datos que la base garantiza.

---

## 13. 🔌 Cómo se vincula la base con el proyecto (el porqué de cada decisión)

La sección 10 mostró el vínculo BD ↔ backend para signup/login. Acá está el **resto de los
flujos**: qué endpoint dispara qué SQL, y **por qué** la base se diseñó para que ese código
quede así de simple. Ejemplos en Flask + `pyodbc` (mismo stack de la sección 10).

### 13.0 La conexión física

```python
import pyodbc
conn = pyodbc.connect(
    "DRIVER={ODBC Driver 18 for SQL Server};SERVER=localhost;"
    "DATABASE=Cumbre;UID=...;PWD=...;TrustServerCertificate=yes"
)
```

**Por qué SQL Server:** restricción del enunciado ("el motor debe ser SQL Server"). **Por qué
`pyodbc` con `?`:** los parámetros van separados del SQL → la BD nunca interpreta datos del
usuario como código (**previene inyección SQL**). Nunca se concatena texto en una consulta.

### 13.1 El reparto de responsabilidades (la decisión madre)

Cada regla del enunciado vive en **una sola capa**, la que mejor la puede garantizar:

| La regla | Vive en | Por qué ahí |
|---|---|---|
| "El correo no se repite", "el monto no es negativo", "la FK existe" | **BD** (UNIQUE, CHECK, FK) | La BD es la **última línea de defensa**: aunque el backend tenga un bug o alguien inserte a mano, el motor lo rechaza |
| "Nace PENDIENTE", "la fecha de pago es ahora" | **BD** (DEFAULT) | Si lo pone la BD, **ningún** endpoint puede olvidarlo o ponerlo mal |
| "Hasta 24 h antes", "80% de reembolso", "20% del cupo", "sin traslapes" | **Backend** | Son reglas de *proceso* que comparan varias filas o la hora actual; un CHECK no puede mirar otras tablas |
| "Solo el admin puede X" | **Backend** (rol del JWT) | La BD guarda `RolID`; quién llama al endpoint solo lo sabe la API |

> Esa es la respuesta a "¿por qué validás dos veces?": no es repetir, es **defensa en
> profundidad** — el backend valida para dar mensajes amables, la BD garantiza para que el dato
> malo no entre *jamás*.

### 13.2 Inscripción (las 3 modalidades en un solo endpoint)

`POST /eventos/<id>/inscripciones` — el backend lee `ModalidadInscripcion` del evento y decide:

```python
ev = cur.execute("""
    SELECT ModalidadInscripcion, FechaInicio, CapacidadMaxima, EstadoEventoID
    FROM dbo.Eventos WHERE EventoID = ?""", evento_id).fetchone()

if ev.EstadoEventoID != ESTADO_EVENTO_PUBLICADO:            # solo eventos publicados
    return "Evento no disponible", 409
if ev.FechaInicio <= ahora_mas_24h():                        # regla 24 h → backend
    return "Inscripciones cerradas (24 h antes)", 409

inscritos = cur.execute("""
    SELECT COUNT(*) FROM dbo.Inscripciones
    WHERE EventoID = ? AND EstadoInscripcionID NOT IN (3,5)  -- no cuenta rechazadas/canceladas
""", evento_id).fetchone()[0]
if inscritos >= ev.CapacidadMaxima:                          # cupo → backend cuenta filas
    return "Cupo lleno", 409

estado = (EST_INS_PENDIENTE if ev.ModalidadInscripcion == "APROBACION"
          else EST_INS_APROBADA)                             # abierta entra directo
cur.execute("""
    INSERT INTO dbo.Inscripciones (AsistenteID, EventoID, TipoEntradaID, EstadoInscripcionID, Monto)
    VALUES (?,?,?,?,?)""", uid, evento_id, tipo_entrada, estado, monto)
```

**Por qué la BD lo hace fácil:** los estados son **ids estables** (sembrados en `08_seeds.sql`)
→ el backend los usa como constantes legibles; y como `Inscripciones` guarda `Monto`, el
reembolso del 80% después no depende de que la tarifa haya cambiado.

**Aprobación del admin** = el mismo patrón de la sección 11, en otra tabla:

```python
# PATCH /inscripciones/<id>  (solo rol ADMIN)
cur.execute("""
    UPDATE dbo.Inscripciones SET EstadoInscripcionID = ?    -- 2 APROBADA ó 3 RECHAZADA
    WHERE InscripcionID = ? AND EstadoInscripcionID = 1     -- solo si sigue PENDIENTE
""", nuevo_estado, ins_id)
```

El `AND EstadoInscripcionID = 1` evita que dos admins aprueben/rechacen a la vez: el segundo
UPDATE afecta 0 filas y el backend responde "ya fue procesada". **La fila misma actúa de
candado.**

### 13.3 Canje de código de invitación

```python
# POST /eventos/<id>/canjear  {codigo}
fila = cur.execute("""
    UPDATE dbo.CodigosInvitacion
    SET AsistenteID = ?, Usado = 1
    OUTPUT INSERTED.CodigoID
    WHERE Codigo = ? AND EventoID = ? AND Usado = 0          -- válido y sin usar
""", uid, codigo, evento_id).fetchone()
if not fila:
    return "Código inválido o ya usado", 400
# ... y recién entonces se inserta la Inscripcion
```

**Por qué `AsistenteID` empieza NULL:** el código existe *antes* de saber quién lo va a usar;
al canjearlo, la misma fila pasa de "emitido" a "canjeado por X". Un solo UPDATE atómico hace
validación + canje: no hay ventana para que dos personas usen el mismo código.

### 13.4 Pago por transferencia (el código de la sección 11)

```python
# POST /inscripciones/<id>/pagos   (el asistente sube su comprobante)
cur.execute("""
    INSERT INTO dbo.Pagos (InscripcionID, Monto, Metodo, ComprobanteUrl)
    VALUES (?, ?, N'TRANSFERENCIA', ?)""", ins_id, monto, url_comprobante)
# EstadoPagoID NO se menciona: la BD le pone 1 PENDIENTE sola (DEFAULT)

# PATCH /pagos/<id>/revision      (solo rol ADMIN)
cur.execute("""
    UPDATE dbo.Pagos
    SET EstadoPagoID = ?, AdminRevisorID = ?                 -- 2 CONFIRMADO ó 3 RECHAZADO
    WHERE PagoID = ? AND EstadoPagoID = 1
""", veredicto, admin_id, pago_id)
enviar_correo(...)                                           # la notificación es del backend
```

**Fijate el detalle:** el INSERT **no menciona** `EstadoPagoID` ni `FechaPago` — los DEFAULT de
la BD los ponen. Esa fue la decisión: *lo que debe pasar siempre, lo hace la base; así ningún
programador del grupo puede olvidarlo.*

### 13.5 Cancelación con reembolso del 80%

```python
# POST /inscripciones/<id>/cancelacion   (panel del asistente)
ins = cur.execute("""
    SELECT i.Monto, e.FechaInicio
    FROM dbo.Inscripciones i JOIN dbo.Eventos e ON e.EventoID = i.EventoID
    WHERE i.InscripcionID = ? AND i.AsistenteID = ?""", ins_id, uid).fetchone()

if ins.FechaInicio <= ahora_mas_48h():                       # regla 48 h → backend
    return "Ya no es posible cancelar (48 h antes)", 409

cur.execute("""
    INSERT INTO dbo.SolicitudesCancelacion (InscripcionID, MontoReembolso)
    VALUES (?, ?)""", ins_id, round(ins.Monto * 0.80, 2))    # 80% → backend lo calcula
# EstadoSolicitudID nace 1 PENDIENTE por DEFAULT → aparece sola en el módulo del admin
```

**Por qué "aparece en el módulo del admin" sin código extra:** el módulo del admin es
literalmente `SELECT ... WHERE EstadoSolicitudID = 1`. No hay colas ni notificaciones internas:
**el estado ES la bandeja de entrada.** Misma idea para pagos pendientes e inscripciones por
aprobar.

### 13.6 La bitácora se alimenta desde un solo lugar

```python
def log(cur, uid, accion, entidad, detalle=None):
    cur.execute("""
        INSERT INTO dbo.LogActividad (UsuarioID, Accion, EntidadAfectada, Detalle)
        VALUES (?,?,?,?)""", uid, accion, entidad, detalle)

# y cada endpoint la llama al final:
log(cur, uid, "PAGO_CONFIRMADO", "Pagos", f"PagoID={pago_id}")
```

**Por qué una tabla genérica** (`Accion` + `EntidadAfectada` en texto) y no una por módulo: el
reporte "log de todas las actividades" pide **todo junto y ordenado por fecha**; con una sola
tabla es un `SELECT ... ORDER BY FechaHora DESC` que además ya tiene índice (sección 8).

### 13.7 Los reportes son solo SELECTs (la prueba de que el diseño funciona)

Ninguno de los 5 reportes necesitó tablas nuevas — si el modelo está bien, reportar es leer:

```sql
-- Ingresos del último mes por tipo de entrada y método
SELECT te.Nombre, p.Metodo, SUM(p.Monto) AS Ingresos
FROM dbo.Pagos p
JOIN dbo.Inscripciones i ON i.InscripcionID = p.InscripcionID
JOIN dbo.TiposEntrada  te ON te.TipoEntradaID = i.TipoEntradaID
WHERE p.EstadoPagoID = 2                                  -- solo CONFIRMADOS
  AND p.FechaPago >= DATEADD(MONTH, -1, SYSUTCDATETIME())
GROUP BY te.Nombre, p.Metodo;
```

**Por qué sale tan directo:** `FechaPago` tiene DEFAULT (siempre existe), `EstadoPagoID`
distingue confirmados de pendientes/rechazados (no se cuentan pagos no revisados), y la cadena
`Pagos → Inscripciones → TiposEntrada` existe por las FKs. Cada decisión de diseño de las
secciones 9, 11 y 12 se cobra acá.

### Resumen: el contrato entre la base y la API

| La base le promete a la API | La API le promete a la base |
|---|---|
| Todo flujo revisable nace `PENDIENTE` solo (DEFAULT) | Validar reglas de tiempo/cupo **antes** de insertar |
| Ningún dato inválido entra (CHECK, UNIQUE, FK) | Usar siempre parámetros `?`, nunca concatenar SQL |
| Los ids de catálogo no cambian (seeds estables) | Referirlos como constantes con nombre, no números sueltos |
| Las fechas/montos para validar 24 h, 48 h, 80% están guardados | Calcular y mandar correos — eso no es trabajo de la base |

**Resumen en una línea:** la base hace inevitable lo que siempre debe pasar (DEFAULTs, CHECKs,
FKs) y la API decide lo que depende del momento y del rol — por eso cada endpoint del proyecto
se reduce a un SELECT de validación + un INSERT/UPDATE corto.

---

## 14. ❓ Preguntas frecuentes — las objeciones típicas y su respuesta

Mismo estilo que la pregunta de la FK en la sección 11: la objeción tal como te la harían, la
premisa falsa (si la hay), y la respuesta corta para defenderla. Útil para la calificación y
para quien no vio el proyecto.

### "Si el pago sale RECHAZADO, ¿se borra la inscripción y hay que empezar de cero?"

No se borra **nada**. La relación `Pagos → Inscripciones` es 1:N a propósito: una inscripción
puede tener **varios intentos de pago**. Si el admin rechaza el comprobante, esa fila de `Pagos`
queda en `3 RECHAZADO` (terminal, ya no se mueve) y el asistente sube **otro** comprobante = otra
fila nueva que nace `PENDIENTE`. La inscripción ni se entera: sigue en su estado, esperando un
pago que sí se confirme.

**Bonus:** eso te deja gratis el historial de intentos — podés responder "¿cuántos comprobantes
rechazó el admin este mes?" con un simple `SELECT`.

**Respuesta corta:** rechazar un pago mata *ese intento*, no la inscripción; cada reintento es
una fila nueva en `Pagos`.

### "¿Por qué `Inscripciones` guarda `Monto` si la tarifa ya está en `TiposEntrada`? ¿No es dato duplicado?"

No es duplicado: es una **foto del precio al momento de inscribirse**. `TiposEntrada.Tarifa` es
el precio *vigente* (puede cambiar mañana); `Inscripciones.Monto` es lo que *esa persona pagó*.
Si el admin sube la tarifa General de Q250 a Q300, los ya inscritos siguen con su Q250 — y el
reembolso del 80% se calcula sobre **lo que pagaron**, no sobre el precio nuevo.

**Respuesta corta:** uno es el precio de lista (cambia), el otro es el precio pactado
(histórico). Duplicado sería si los dos significaran lo mismo — y no.

### "¿Por qué `SalaID` es NULL en sesiones virtuales? ¿No era mejor crear una sala llamada 'VIRTUAL'?"

Una sala falsa contamina todo lo que depende de salas reales: tiene que inventarse una
`Capacidad` (¿infinita?), aparecería en el reporte de **ocupación de salas** distorsionándolo, y
mentiría sobre el mundo real (no existe ese espacio físico). El NULL dice la verdad: *esta sesión
no usa sala* — y el dato que sí aplica está en `Enlace`. Es el mismo patrón de `Pagos`
(`TarjetaID` NULL si fue transferencia): **NULL = "no aplica", no "falta el dato"**.

**Respuesta corta:** una sala fantasma rompe los reportes de capacidad; el NULL modela
exactamente la realidad.

### "¿Qué impide que un asistente se inscriba dos veces al mismo evento?"

**Respuesta honesta: la base, nada — lo valida el backend.** No hay un
`UNIQUE (AsistenteID, EventoID)` porque sería **incorrecto**: una inscripción `RECHAZADA` o
`CANCELADA` debe quedar en el historial, y la persona tiene derecho a inscribirse de nuevo — el
UNIQUE se lo impediría para siempre. La regla real es *"no más de una inscripción **viva** por
evento"*, y "viva" depende del estado → eso es una consulta del backend antes de insertar
(`WHERE EstadoInscripcionID NOT IN (3,5)`). En cambio, donde el par sí es absoluto —
`InscripcionSesion` — sí hay PK compuesta que lo garantiza a nivel motor.

**Respuesta corta:** un UNIQUE bloquearía reinscribirse tras cancelar; como la regla depende del
estado, la valida el backend. Donde la regla es absoluta (sesiones), sí la garantiza la base.

### "El enunciado dice que el asistente puede ELIMINAR su tarjeta. ¿Y si esa tarjeta ya tiene pagos? ¿No truena la FK?"

Sí — y eso es **a favor** del diseño, no en contra: la FK `Pagos → Tarjetas` impide borrar una
tarjeta con pagos porque borrarla destruiría el historial contable (¿con qué se pagó esa
inscripción?). Por eso `Tarjetas` tiene `Activo` (borrado lógico, igual que `Ponentes` y
`Usuarios`): "eliminar la tarjeta del perfil" = `UPDATE ... SET Activo = 0`. La tarjeta
desaparece de la vista del asistente, pero los pagos viejos siguen apuntando a ella y el
historial contable queda intacto.

**Respuesta corta:** "eliminar del perfil" es borrado lógico (`Activo = 0`), nunca un `DELETE`;
la FK protege el historial de pagos a propósito.

### "¿Por qué la agenda usa `DiaID` + `HorarioID` en vez de guardar fecha y hora reales (`DATETIME`)?"

Por la regla más difícil del enunciado: **sin traslapes** (ni para el asistente ni para el
ponente). Con `DATETIME` libre, detectar traslape es comparar rangos que se solapan parcialmente
— lógica fácil de equivocar. Con bloques predefinidos, dos sesiones chocan **si y solo si**
tienen el mismo `DiaID + HorarioID`: la validación se vuelve una igualdad. Además el frontend
llena combos desde el catálogo (nadie tipea horas) y el `CHECK HoraFin > HoraInicio` vive una
sola vez en `Horarios`, no en cada sesión.

**Respuesta corta:** convertimos "detectar solapamiento de rangos" (difícil) en "comparar dos
ids" (trivial). Ese fue el trade-off: menos flexibilidad horaria a cambio de una regla crítica
imposible de programar mal.

### "¿Para qué sirve `EsTerminal` en los catálogos de estados? ¿No basta con conocer los ids?"

Es la **máquina de estados en datos**: marca cuáles estados son finales (`CANCELADO`,
`RECHAZADO`, `PROCESADA`…) para que el backend tenga UNA regla genérica — *"si el estado actual
es terminal, no se toca"* — en vez de una lista de ifs quemada en el código (`if estado == 3 or
estado == 5 or ...`). Si mañana agregan un estado nuevo, es un INSERT con su `EsTerminal`
correcto y el backend no cambia ni una línea.

**Respuesta corta:** `EsTerminal` convierte "qué transiciones están prohibidas" en dato en vez
de código — y los datos se actualizan sin redesplegar.

### "¿Por qué el admin que revisa el pago y el que procesa el reembolso son FKs a `Usuarios` y no a una tabla `Administradores`?"

Porque **no existe** una tabla `Administradores`: admin es un *rol* (`RolID = 1`), no una
entidad distinta — un admin tiene exactamente los mismos datos que cualquier usuario. Separarlo
duplicaría la estructura y obligaría a `Eventos.AdminID`, `Pagos.AdminRevisorID` y
`SolicitudesCancelacion.AdminProcesadorID` a apuntar a otra tabla sin ganar nada. Que quien
revisa sea *efectivamente* admin lo garantiza el backend con el rol del JWT (la FK garantiza que
sea un usuario real; el rol, que tenga permiso).

**Respuesta corta:** admin es un rol, no una tabla; la FK valida que la persona exista y el
backend valida que tenga el rol. Por eso `Usuarios` recibe 8 FKs (sección 6).

> **El hilo común de todas las respuestas:** cuando la regla es **absoluta** (existencia, par
> único, dato no negativo) la garantiza la **base**; cuando depende del **estado, el momento o
> el rol**, la decide el **backend** usando los datos que la base le guarda fielmente. Si te
> hacen una objeción nueva, buscá primero de cuál de los dos lados cae — la respuesta sale sola.
