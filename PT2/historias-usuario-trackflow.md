# TRACKFLOW-HUB — Historias de usuario

> Documento de PT2 (entregable §10) y base del **backlog** del tablero Kanban (Scrum).
> Formato: *Como `<rol>` quiero `<objetivo>` para `<beneficio>`*, con **criterios de aceptación**,
> **requerimientos** que cubre (ver `requerimientos-trackflow.md`), **entregable** y **prioridad**.

Convención de estimación: puntos de historia (PH) en escala Fibonacci (1, 2, 3, 5, 8).

---

## 1. Cuenta y acceso (todos los roles)

### HU-01 · Registro de cliente
**Como** visitante **quiero** registrarme como cliente **para** poder contratar servicios.
- **Criterios:** formulario con nombre, apellido, teléfono, correo, contraseña (x2) y dirección opcional; rechaza correo duplicado; exige contraseña segura y que ambas coincidan; al guardar, queda pendiente de confirmar correo.
- **Requerimientos:** RF-01, RF-04, RF-05 · **Entregable:** v1.0.0 · **Prioridad:** Alta · **PH:** 3

### HU-02 · Confirmación de correo
**Como** usuario recién registrado **quiero** confirmar mi correo con un token de 6 caracteres **para** poder iniciar sesión.
- **Criterios:** el token llega al correo; ingresarlo correctamente marca el correo como confirmado; un token vencido o inválido muestra error; sin confirmar, el login se bloquea.
- **Requerimientos:** RF-05 · **Entregable:** v1.0.0 · **Prioridad:** Alta · **PH:** 3

### HU-03 · Registro de operador logístico
**Como** operador **quiero** registrarme con mis datos verificables **para** ofrecer servicios de envío.
- **Criterios:** captura DPI/CUI, fotografía, zona y género; tras confirmar correo queda **en revisión**; recibe notificación de que su perfil está en revisión.
- **Requerimientos:** RF-02, RF-06 · **Entregable:** v1.0.0 · **Prioridad:** Alta · **PH:** 3

### HU-04 · Registro de empresa de transporte
**Como** empresa **quiero** registrarme con NIT y licencia **para** ofrecer rutas de transporte.
- **Criterios:** captura NIT y número de licencia (únicos); tras confirmar correo queda a la espera de la reunión virtual con el administrador.
- **Requerimientos:** RF-03, RF-07 · **Entregable:** v1.0.0 · **Prioridad:** Alta · **PH:** 3

### HU-05 · Inicio de sesión con 2FA (admin)
**Como** administrador **quiero** un segundo factor por correo **para** proteger el acceso al panel.
- **Criterios:** tras validar la contraseña se envía un token con vigencia de 2 minutos; el código correcto y vigente concede acceso; vencido o incorrecto lo niega.
- **Requerimientos:** RF-08 · **Entregable:** v1.0.0 · **Prioridad:** Alta · **PH:** 3

### HU-06 · Cambio de contraseña temporal (operador)
**Como** operador aceptado **quiero** cambiar mi contraseña temporal en el primer ingreso **para** asegurar mi cuenta.
- **Criterios:** al iniciar sesión con la contraseña temporal, el sistema obliga a definir una nueva antes de continuar.
- **Requerimientos:** RF-06 · **Entregable:** v1.0.0 · **Prioridad:** Media · **PH:** 2

---

## 2. Administrador

### HU-07 · Aprobar/rechazar operadores
**Como** administrador **quiero** aceptar o rechazar solicitudes de operadores **para** controlar quién opera.
- **Criterios:** lista de solicitudes pendientes; al aceptar se genera y envía contraseña temporal; al rechazar se notifica; en ambos casos se notifica por correo.
- **Requerimientos:** RF-11 · **Entregable:** v1.0.0 · **Prioridad:** Alta · **PH:** 3

### HU-08 · Agendar reunión con empresa
**Como** administrador **quiero** agendar una reunión virtual con la empresa **para** evaluar su propuesta antes de aprobarla.
- **Criterios:** registra fecha, hora y enlace; se envían al correo de la empresa; tras aprobar, se entregan credenciales especiales.
- **Requerimientos:** RF-12 · **Entregable:** v1.0.0 · **Prioridad:** Alta · **PH:** 3

### HU-09 · Registrar administradores
**Como** administrador **quiero** crear otros administradores **para** delegar la gestión.
- **Criterios:** solo accesible desde el panel; el nuevo admin queda activo con 2FA.
- **Requerimientos:** RF-09 · **Entregable:** v1.0.0 · **Prioridad:** Media · **PH:** 2

### HU-10 · Gestionar y vetar usuarios
**Como** administrador **quiero** ver, editar y vetar usuarios **para** mantener sana la plataforma.
- **Criterios:** panel filtrable por rol; vetar exige **motivo**; el vetado recibe correo y, al intentar entrar, ve un mensaje con la razón; no hay apelaciones.
- **Requerimientos:** RF-13, RF-10 · **Entregable:** v3.0.0 · **Prioridad:** Alta · **PH:** 5

### HU-11 · Resolver reportes y sancionar
**Como** administrador **quiero** revisar reportes y aplicar sanciones **para** actuar contra infractores.
- **Criterios:** estados Enviado → En revisión → Aceptado/Rechazado; al aceptar puede aplicar suspensión temporal o veto permanente; se notifica al sancionado.
- **Requerimientos:** RF-14 · **Entregable:** v3.0.0 · **Prioridad:** Alta · **PH:** 5

### HU-12 · Aprobar cambios de perfil
**Como** administrador **quiero** aprobar o rechazar cambios de perfil de operadores/empresas **para** validar datos sensibles.
- **Criterios:** ve los datos propuestos; aceptar los aplica, rechazar los descarta; el usuario recibe notificación de la resolución.
- **Requerimientos:** RF-15 · **Entregable:** v3.0.0 · **Prioridad:** Media · **PH:** 3

### HU-13 · Reportes y gráficas en PDF
**Como** administrador **quiero** descargar reportes y gráficas en PDF **para** analizar la operación.
- **Criterios:** genera todos los reportes del enunciado (logs, aceptados/rechazados, zonas, servicios, ingresos, gastos, historiales, destinos, uso de clientes) descargables en PDF.
- **Requerimientos:** RF-16, RF-17 · **Entregable:** v3.0.0 · **Prioridad:** Alta · **PH:** 8

---

## 3. Operador logístico

### HU-14 · Publicar servicio de envío
**Como** operador **quiero** registrar un servicio con sus datos y fotos **para** ofrecerlo a clientes.
- **Criterios:** captura zona, capacidad (kg) y precio; exige **mínimo 3 fotografías**; el servicio queda visible para clientes.
- **Requerimientos:** RF-18 · **Entregable:** v2.0.0 · **Prioridad:** Alta · **PH:** 5

### HU-15 · Suspender/editar/eliminar servicio
**Como** operador **quiero** suspender temporalmente un servicio **para** ocultarlo sin perder su historial.
- **Criterios:** suspender lo oculta a clientes sin borrarlo; se puede reactivar, editar o eliminar.
- **Requerimientos:** RF-19 · **Entregable:** v2.0.0 · **Prioridad:** Alta · **PH:** 3

### HU-16 · Responder comentarios
**Como** operador **quiero** responder a las reseñas de clientes **para** atender su retroalimentación.
- **Criterios:** ve calificaciones y comentarios; puede escribir una respuesta visible junto al comentario.
- **Requerimientos:** RF-20 · **Entregable:** v2.0.0 · **Prioridad:** Media · **PH:** 2

### HU-17 · Calendario de envíos
**Como** operador **quiero** ver mis envíos programados en un calendario **para** organizar mi operación.
- **Criterios:** vista por servicio individual y vista general de todos los servicios.
- **Requerimientos:** RF-21 · **Entregable:** v2.0.0 · **Prioridad:** Media · **PH:** 3

### HU-18 · Reportar clientes
**Como** operador **quiero** reportar a clientes infractores con evidencia **para** que el admin actúe.
- **Criterios:** adjunta foto/vídeo; el reporte nace en estado Enviado; puede ver los reportes recibidos sobre sus servicios.
- **Requerimientos:** RF-22 · **Entregable:** v2.0.0 · **Prioridad:** Media · **PH:** 3

### HU-19 · Reportes PDF del operador
**Como** operador **quiero** descargar mis reportes en PDF **para** llevar control de mi negocio.
- **Criterios:** ganancias por servicio y general, historial de clientes y calificaciones recibidas.
- **Requerimientos:** RF-25, RF-26 · **Entregable:** v2.0.0 · **Prioridad:** Media · **PH:** 3

---

## 4. Empresa de transporte

### HU-20 · Cargar flota y rutas por CSV
**Como** empresa **quiero** subir mi flota y rutas por CSV **para** publicarlas rápido.
- **Criterios:** acepta CSV con los campos definidos; valida el formato; también permite alta manual de rutas.
- **Requerimientos:** RF-27 · **Entregable:** v2.0.0 · **Prioridad:** Alta · **PH:** 5

### HU-21 · Editar y cancelar rutas con aviso
**Como** empresa **quiero** editar o cancelar rutas **para** reaccionar a emergencias o clima.
- **Criterios:** la edición se refleja de inmediato en la vista del cliente; cancelar/suspender notifica por correo a los clientes afectados.
- **Requerimientos:** RF-28 · **Entregable:** v2.0.0 · **Prioridad:** Alta · **PH:** 5

### HU-22 · Reportes PDF de la empresa
**Como** empresa **quiero** descargar reportes en PDF **para** analizar mi desempeño.
- **Criterios:** ganancias, historial de servicios contratados, calificaciones y estado de rutas; puede ver reportes de clientes (no puede reportar clientes).
- **Requerimientos:** RF-29, RF-32, RF-33 · **Entregable:** v2.0.0 · **Prioridad:** Media · **PH:** 3

---

## 5. Cliente

### HU-23 · Buscar y filtrar servicios
**Como** cliente **quiero** buscar y filtrar envíos y transporte **para** encontrar lo que necesito.
- **Criterios:** búsqueda de envíos por zona/operador/nombre y de transporte por destino/fecha/empresa/tipo; filtros por calificación, precio (asc/desc), capacidad, hora y tiempo estimado.
- **Requerimientos:** RF-34, RF-35 · **Entregable:** v3.0.0 · **Prioridad:** Alta · **PH:** 5

### HU-24 · Sugerencia de servicios complementarios
**Como** cliente **quiero** ver los 3 mejor calificados complementarios **para** completar mi viaje fácilmente.
- **Criterios:** al elegir primero envío, sugiere 3 operadores de la misma zona; al elegir primero transporte, sugiere 3 de envío del destino; con opción de ver todos.
- **Requerimientos:** RF-36 · **Entregable:** v3.0.0 · **Prioridad:** Media · **PH:** 3

### HU-25 · Programar reserva
**Como** cliente **quiero** programar una reserva con anticipación **para** asegurar el servicio.
- **Criterios:** exige ≥ 24 h de anticipación; impide traslape con reservas existentes; muestra resumen antes de confirmar.
- **Requerimientos:** RF-37 · **Entregable:** v3.0.0 · **Prioridad:** Alta · **PH:** 5

### HU-26 · Carrito persistente
**Como** cliente **quiero** que mi carrito se conserve **para** retomar la compra después.
- **Criterios:** los ítems permanecen aunque cierre sesión y vuelva a entrar.
- **Requerimientos:** RF-38 · **Entregable:** v3.0.0 · **Prioridad:** Alta · **PH:** 3

### HU-27 · Pagar con tarjeta simulada (Luhn)
**Como** cliente **quiero** pagar con una tarjeta simulada **para** confirmar mi reserva.
- **Criterios:** la tarjeta nace con saldo **Q1,000**; el número se valida por **Luhn**; el pago descuenta del saldo; la reserva se confirma **solo** si el pago fue procesado; existe un **segundo método** (wallet/transferencia).
- **Requerimientos:** RF-39, RF-40 · **Entregable:** v3.0.0 · **Prioridad:** Alta · **PH:** 8

### HU-28 · Cancelar reserva
**Como** cliente **quiero** cancelar hasta 24 h antes **para** tener flexibilidad.
- **Criterios:** permite cancelar dentro de la ventana; aplica el mecanismo de reembolso definido; fuera de la ventana lo impide.
- **Requerimientos:** RF-41 · **Entregable:** v3.0.0 · **Prioridad:** Media · **PH:** 3

### HU-29 · Ver servicios contratados con estado
**Como** cliente **quiero** ver todos mis servicios con su estado **para** seguir su avance.
- **Criterios:** lista con estado activo, en tránsito, entregado o cancelado.
- **Requerimientos:** RF-42 · **Entregable:** v3.0.0 · **Prioridad:** Alta · **PH:** 3

### HU-30 · Calificar y reseñar
**Como** cliente **quiero** calificar el servicio recibido **para** orientar a otros clientes.
- **Criterios:** envío calificable tras la fecha de entrega; transporte tras el trayecto; permite puntuación y comentario; una calificación por reserva.
- **Requerimientos:** RF-43 · **Entregable:** v3.0.0 · **Prioridad:** Media · **PH:** 3

### HU-31 · Reportar un problema
**Como** cliente **quiero** reportar problemas con evidencia **para** que se resuelvan.
- **Criterios:** adjunta evidencias; ve el historial con estados Enviado, En estudio, Aceptado, Rechazado.
- **Requerimientos:** RF-44 · **Entregable:** v3.0.0 · **Prioridad:** Media · **PH:** 3

### HU-32 · Canjear cupones
**Como** cliente **quiero** canjear cupones **para** obtener descuentos.
- **Criterios:** valida vigencia/condiciones; muestra historial de cupones usados con sus restricciones.
- **Requerimientos:** RF-45 · **Entregable:** v3.0.0 · **Prioridad:** Baja · **PH:** 2

### HU-33 · Editar perfil
**Como** cliente **quiero** editar mi perfil **para** mantener mis datos al día.
- **Criterios:** permite editar datos; el **correo no** se cambia salvo justificación.
- **Requerimientos:** RF-46 · **Entregable:** v3.0.0 · **Prioridad:** Media · **PH:** 2

---

## 6. Definición de Hecho (DoD) — aplica a toda historia

Una historia se considera **Hecha** cuando:
1. Cumple todos sus criterios de aceptación y los RF asociados.
2. Tiene pruebas (unitarias y/o E2E) que cubren su flujo crítico (aporta a RNF-09/RNF-10).
3. Pasa el pipeline de CI (Build + Test) en GitHub Actions (RNF-11).
4. Respeta UI/UX y las heurísticas de Nielsen elegidas (RNF-06/RNF-07).
5. Se integró por rama `feature/funcion_carnet` con **Conventional Commits** y PR revisado (RNF-12).
6. Quedó reflejada en el tablero Kanban como *Realizado*.
