# TRACKFLOW-HUB — Diagramas de secuencia (flujos críticos)

> Borrador de trabajo para el manual técnico de PT2. Renderiza en GitHub y en VS Code
> (extensión *Markdown Preview Mermaid Support*). Mismo estilo que `modelo-trackflow.md`
> y `clases-trackflow.md`.

> Cada secuencia muestra cómo colaboran las capas en el tiempo: el **actor** (rol), el **Frontend**,
> el **Backend (API)** con sus servicios (`AuthService`, `PagoService`, `ReservaService` de
> `clases-trackflow.md`), la **Base de datos** y el **Servicio de correo**. Las tablas y estados que
> se tocan son los del DDL (`sql/`) y el ER.

Flujos incluidos:
1. [Registro de cliente + confirmación de correo](#1-registro-de-cliente--confirmación-de-correo) → `trackflow-seq-01-registro.mmd`
2. [Login con doble factor (2FA) del administrador](#2-login-con-doble-factor-2fa-del-administrador) → `trackflow-seq-02-login2fa.mmd`
3. [Programar reserva + pago](#3-programar-reserva--pago) → `trackflow-seq-03-reserva-pago.mmd`
4. [Registro y aprobación de operador logístico](#4-registro-y-aprobación-de-operador-logístico)
5. [Reporte de un cliente y resolución del administrador](#5-reporte-y-resolución-del-administrador)

---

## 1. Registro de cliente + confirmación de correo

> Tablas: `Usuarios`, `PerfilCliente`, `Tokens` (tipo `CONFIRMACION_CORREO`, 6 caracteres).
> El login queda bloqueado hasta que `Usuarios.CorreoConfirmado = 1`.

```mermaid
sequenceDiagram
    autonumber
    actor C as Cliente
    participant UI as Frontend
    participant API as Backend (API)
    participant DB as Base de datos
    participant MAIL as Servicio de correo

    C->>UI: Llena registro (nombre, correo, contraseña x2)
    UI->>API: POST /registro (rol = CLIENTE)
    API->>API: Valida contraseña segura y que ambas coincidan

    alt Datos válidos y correo no repetido
        API->>DB: INSERT Usuarios (hash, CorreoConfirmado = 0, Estado = ACTIVA)
        API->>DB: INSERT PerfilCliente (UsuarioID)
        API->>DB: INSERT Tokens (CONFIRMACION_CORREO, valor 6 chars, FechaExpira)
        API->>MAIL: Enviar token al correo
        API-->>UI: 201 Creado — "Confirmá tu correo"
    else Correo ya registrado / contraseña débil
        API-->>UI: 409 / 400 con el detalle
    end

    C->>UI: Ingresa el token de 6 caracteres
    UI->>API: POST /confirmar { token }
    API->>DB: SELECT Tokens WHERE Valor = ? AND Usado = 0 AND FechaExpira > ahora

    alt Token válido y vigente
        API->>DB: UPDATE Usuarios SET CorreoConfirmado = 1
        API->>DB: UPDATE Tokens SET Usado = 1, FechaUso = ahora
        API-->>UI: 200 — "Correo confirmado, ya podés iniciar sesión"
    else Token inválido o vencido
        API-->>UI: 400 — "Token inválido o vencido"
    end
```

---

## 2. Login con doble factor (2FA) del administrador

> El admin tiene 2FA: tras validar la contraseña se le envía un `Token` (tipo `DOBLE_FACTOR_2FA`)
> con vigencia de **2 minutos**. Los demás roles entran directo si el correo está confirmado y la
> cuenta no está vetada.

```mermaid
sequenceDiagram
    autonumber
    actor A as Administrador
    participant UI as Frontend
    participant API as Backend (API)
    participant DB as Base de datos
    participant MAIL as Servicio de correo

    A->>UI: Ingresa correo y contraseña
    UI->>API: POST /login { correo, contraseña }
    API->>DB: SELECT Usuarios WHERE Correo = ?
    API->>API: AuthService verifica el hash

    alt Cuenta VETADA
        API-->>UI: 403 — "Cuenta vetada, contactá al administrador"
    else Credenciales inválidas
        API-->>UI: 401 — "Credenciales inválidas"
    else Credenciales correctas
        alt Rol = ADMIN
            API->>DB: INSERT Tokens (DOBLE_FACTOR_2FA, FechaExpira = ahora + 2 min)
            API->>MAIL: Enviar token 2FA
            API-->>UI: 200 — "Ingresá el código enviado a tu correo"
            A->>UI: Ingresa el código 2FA
            UI->>API: POST /login/2fa { valor }
            API->>DB: SELECT Tokens (2FA) WHERE Valor = ? AND Usado = 0 AND FechaExpira > ahora
            alt Código válido y vigente
                API->>DB: UPDATE Tokens SET Usado = 1
                API-->>UI: 200 + JWT { uid, rol = ADMIN }
            else Código inválido o vencido (2 min)
                API-->>UI: 401 — "Código inválido o expirado"
            end
        else Rol = CLIENTE / OPERADOR / EMPRESA
            API->>API: Verifica CorreoConfirmado = 1 (y aprobación, según el rol)
            API-->>UI: 200 + JWT { uid, rol }
        end
    end
```

---

## 3. Programar reserva + pago

> El carrito es persistente (`ItemsCarrito`). `ReservaService` valida las **24 h de anticipación** y
> el **no-traslape** de fechas; `PagoService` valida **Luhn** y descuenta del **saldo** de la tarjeta.
> La reserva solo se confirma (`Reservaciones.Estado = ACTIVO`) cuando el `Pago` llega a `PROCESADO`.

```mermaid
sequenceDiagram
    autonumber
    actor C as Cliente
    participant UI as Frontend
    participant API as Backend (API)
    participant DB as Base de datos
    participant MAIL as Servicio de correo

    C->>UI: Elige un servicio de envío y un rango de fechas
    UI->>API: POST /carrito (Tipo = ENVIO, ServicioEnvioID, fechas)
    API->>DB: INSERT ItemsCarrito
    API-->>UI: 200 — Ítem agregado al carrito

    C->>UI: Confirma la compra (checkout)
    UI->>API: POST /reservas (desde el carrito) + TarjetaID
    API->>API: ReservaService valida ≥ 24 h y sin traslape

    alt No cumple 24 h o hay traslape
        API-->>UI: 409 — "No disponible en ese rango"
    else Reglas de fecha OK
        API->>DB: INSERT Reservaciones (Estado = ACTIVO, Monto)
        API->>DB: INSERT Pagos (Estado = PENDIENTE)
        API->>API: PagoService valida Luhn y consulta saldo de la Tarjeta

        alt Luhn OK y saldo suficiente
            API->>DB: UPDATE Tarjetas SET Saldo = Saldo - Monto
            API->>DB: UPDATE Pagos SET Estado = PROCESADO
            API->>DB: DELETE ItemsCarrito (ítem comprado)
            API->>MAIL: Enviar confirmación de la reserva
            API-->>UI: 201 — Reserva confirmada
        else Luhn inválido o saldo insuficiente
            API->>DB: UPDATE Pagos SET Estado = RECHAZADO
            API->>DB: UPDATE Reservaciones SET Estado = CANCELADO
            API-->>UI: 402 — "Pago rechazado"
        end
    end
```

---

## 4. Registro y aprobación de operador logístico

> El operador, además de confirmar correo, necesita ser **aceptado por el admin**. Al aceptarlo se
> genera una **contraseña temporal** (`Tokens` tipo `PASSWORD_TEMPORAL` + `Usuarios.RequiereCambioPassword = 1`)
> que el operador debe cambiar en su primer ingreso. Tablas: `PerfilOperador.EstadoSolicitud`.

```mermaid
sequenceDiagram
    autonumber
    actor O as Operador
    actor A as Administrador
    participant API as Backend (API)
    participant DB as Base de datos
    participant MAIL as Servicio de correo

    O->>API: POST /registro (rol = OPERADOR, DPI, zona, género, foto)
    API->>DB: INSERT Usuarios + PerfilOperador (EstadoSolicitud = PENDIENTE)
    API->>DB: INSERT Tokens (CONFIRMACION_CORREO)
    API->>MAIL: Enviar token de confirmación
    O->>API: POST /confirmar { token }
    API->>DB: UPDATE Usuarios SET CorreoConfirmado = 1
    API->>MAIL: "Tu perfil está en revisión"

    Note over A,DB: El admin ve la solicitud (EstadoSolicitud = PENDIENTE)
    A->>API: PATCH /operadores/{id} { decision }

    alt Acepta
        API->>DB: UPDATE PerfilOperador SET EstadoSolicitud = ACEPTADA
        API->>DB: UPDATE Usuarios SET RequiereCambioPassword = 1
        API->>DB: INSERT Tokens (PASSWORD_TEMPORAL)
        API->>MAIL: Enviar contraseña temporal
    else Rechaza
        API->>DB: UPDATE PerfilOperador SET EstadoSolicitud = RECHAZADA
        API->>MAIL: Notificar rechazo
    end

    O->>API: POST /login (con contraseña temporal)
    API->>API: Detecta RequiereCambioPassword = 1
    API-->>O: Fuerza cambio de contraseña antes de continuar
```

---

## 5. Reporte y resolución del administrador

> Estados de `Reportes`: `ENVIADO → EN_REVISION → ACEPTADO | RECHAZADO`. Si procede, el admin crea una
> `Sancion` (suspensión temporal o veto permanente); el veto pone `Usuarios.EstadoCuenta = VETADA` con
> su `MotivoVeto`. Las evidencias van en `EvidenciasReporte`.

```mermaid
sequenceDiagram
    autonumber
    actor C as Cliente
    actor A as Administrador
    participant API as Backend (API)
    participant DB as Base de datos
    participant MAIL as Servicio de correo

    C->>API: POST /reportes (reportado, descripción, evidencias)
    API->>DB: INSERT Reportes (Estado = ENVIADO)
    API->>DB: INSERT EvidenciasReporte (fotos/video)
    API-->>C: 201 — "Reporte enviado"

    Note over A,DB: El admin revisa los reportes en estado ENVIADO
    A->>API: PATCH /reportes/{id} { Estado = EN_REVISION }
    API->>DB: UPDATE Reportes SET Estado = EN_REVISION

    alt El reporte procede
        A->>API: PATCH /reportes/{id} { decision = ACEPTAR, sancion }
        API->>DB: UPDATE Reportes SET Estado = ACEPTADO
        API->>DB: INSERT Sanciones (SUSPENSION_TEMPORAL o VETO_PERMANENTE)
        opt Sanción = veto permanente
            API->>DB: UPDATE Usuarios SET EstadoCuenta = VETADA, MotivoVeto = ?
        end
        API->>MAIL: Notificar al usuario sancionado
    else El reporte se desestima
        A->>API: PATCH /reportes/{id} { decision = RECHAZAR }
        API->>DB: UPDATE Reportes SET Estado = RECHAZADO
    end
```

---

## Notas de diseño

- **El estado es la bandeja de entrada.** Igual que en PT1: el módulo del admin es un `SELECT … WHERE
  Estado = 'PENDIENTE' / 'ENVIADO'`. No hacen falta colas; el estado por DEFAULT hace que la solicitud
  o el reporte "aparezcan" solos.
- **La reserva nace y se confirma con el pago.** La fila de `Reservaciones` existe antes de pagar; el
  pago no la inserta, le cambia el estado — por eso `Pagos` puede referenciarla (la FK valida
  existencia, el estado valida el momento). Mismo razonamiento que el pago por transferencia de PT1.
- **Las reglas de tiempo/porcentaje viven en los servicios**, no en la base: 24 h, no-traslape, Luhn,
  vigencia de 2 min del 2FA y reparto 80/20–90/10 los resuelve el backend con los datos que la BD
  garantiza (fechas, montos, saldo).
- **Defensa en profundidad:** el backend valida para dar mensajes amables; la base garantiza con
  `CHECK`/`UNIQUE`/`FK` que un dato inválido no entre jamás.
