# TRACKFLOW-HUB — Requerimientos funcionales y no funcionales

> Documento de PT2 (entregable §10). Derivado del enunciado `[AYD1]Proyecto_EVJ_2026.clean.md`.
> Cada requerimiento tiene **ID** (trazable desde las historias de usuario), **prioridad**
> (Alta/Media/Baja) y el **entregable** donde se implementa (v1.0.0 / v2.0.0 / v3.0.0).

Leyenda de entregables (enunciado §12):
- **v1.0.0** (17/06/2026): registro/login de los 4 roles + módulo admin (solo creación de usuarios).
- **v2.0.0** (23/06/2026): módulos de operador logístico y empresa de transporte + pruebas.
- **v3.0.0** (30/06/2026): módulo de cliente + admin completo + Scrum/Kanban/UI-UX/CI-CD.

---

## 1. Requerimientos funcionales (RF)

### 1.1 Gestión de usuarios y autenticación

| ID | Requerimiento | Prioridad | Entregable |
|----|---------------|-----------|------------|
| RF-01 | El sistema permite registrar **clientes** con nombre, apellido, teléfono, correo, contraseña y dirección de origen (opcional). | Alta | v1.0.0 |
| RF-02 | El sistema permite registrar **operadores logísticos** con nombre, apellido, DPI/CUI, teléfono (+respaldo), correo, fotografía, zona de operación y género. | Alta | v1.0.0 |
| RF-03 | El sistema permite registrar **empresas de transporte** con nombre, teléfono (+respaldo), correo, NIT y número de licencia operativa. | Alta | v1.0.0 |
| RF-04 | Toda contraseña debe ser **segura** y confirmarse **dos veces** en el registro. | Alta | v1.0.0 |
| RF-05 | El sistema exige **confirmar el correo** mediante un **token único de 6 caracteres** antes de permitir el inicio de sesión. | Alta | v1.0.0 |
| RF-06 | El **operador** solo ingresa tras confirmar correo **y** ser aceptado por el administrador; al aceptarse recibe una **contraseña temporal** que debe cambiar en el primer ingreso. | Alta | v1.0.0 |
| RF-07 | La **empresa** solo ingresa tras confirmar correo, una **reunión virtual** con el administrador y la entrega de credenciales especiales. | Alta | v1.0.0 |
| RF-08 | El **administrador** inicia sesión con **doble factor (2FA)**: token al correo con vigencia de **2 minutos**. | Alta | v1.0.0 |
| RF-09 | Solo se pueden registrar nuevos **administradores** desde el panel de administración. | Media | v1.0.0 |
| RF-10 | Un usuario **vetado** no puede iniciar sesión; se le muestra un mensaje y el motivo. No hay módulo de apelaciones. | Alta | v3.0.0 |

### 1.2 Módulo de administrador

| ID | Requerimiento | Prioridad | Entregable |
|----|---------------|-----------|------------|
| RF-11 | Gestionar solicitudes de registro de operadores: **aceptar/rechazar** notificando al operador. | Alta | v1.0.0 |
| RF-12 | Observar solicitudes de empresas y **agendar reuniones virtuales** (fecha, hora, enlace) por correo. | Alta | v1.0.0 |
| RF-13 | Panel de **todos los usuarios** filtrables por rol; editar y **vetar** con motivo (notificado por correo). | Alta | v3.0.0 |
| RF-14 | Observar todos los **reportes** y tomar acciones (suspensión temporal a veto permanente); estados: Enviado, En revisión, Aceptado, Rechazado. | Alta | v3.0.0 |
| RF-15 | Revisar y **aprobar/rechazar cambios de perfil** de operadores y empresas; notificar la resolución. | Media | v3.0.0 |
| RF-16 | **Visualizar** servicios de transporte (por zona y empresa) y envíos (por destino y operador). | Media | v3.0.0 |
| RF-17 | Observar y **descargar en PDF** los reportes: logs de registros/vetos, gráficas de aceptados/rechazados, zonas con más envíos, servicios más usados, ingresos por tipo, resumen de reportes, mayores gastos, historiales de envíos/servicios, destinos frecuentes y uso de clientes. | Alta | v3.0.0 |

### 1.3 Módulo de operador logístico

| ID | Requerimiento | Prioridad | Entregable |
|----|---------------|-----------|------------|
| RF-18 | Registrar servicios de envío (zona de cobertura, capacidad de carga kg, precio, **mínimo 3 fotografías**). | Alta | v2.0.0 |
| RF-19 | Modificar, eliminar y **suspender temporalmente** un servicio (lo oculta sin borrarlo). | Alta | v2.0.0 |
| RF-20 | Ver calificaciones/comentarios y **responder** a los comentarios. | Media | v2.0.0 |
| RF-21 | Ver en **calendario** las fechas de envíos programados (por servicio y general). | Media | v2.0.0 |
| RF-22 | **Reportar clientes** infractores aportando evidencia (foto/vídeo) y ver reportes recibidos. | Media | v2.0.0 |
| RF-23 | Generar **cupones** de descuento por temporada. | Baja | v2.0.0 |
| RF-24 | Ver y **solicitar cambios de perfil** (requieren aprobación del admin). | Media | v2.0.0 |
| RF-25 | Reportes PDF del operador: ganancias por servicio/general, historial de clientes, calificaciones recibidas. | Media | v2.0.0 |
| RF-26 | El operador retiene el **80%** del costo del envío; la plataforma el **20%**. | Alta | v2.0.0 |

### 1.4 Módulo de empresa de transporte

| ID | Requerimiento | Prioridad | Entregable |
|----|---------------|-----------|------------|
| RF-27 | Cargar flota y rutas por **CSV** y registrar rutas manualmente. | Alta | v2.0.0 |
| RF-28 | Editar rutas (reflejo inmediato al cliente) y **cancelar/suspender** rutas, notificando a los clientes afectados por correo. | Alta | v2.0.0 |
| RF-29 | Observar reportes de clientes (la empresa **no** puede reportar clientes). | Media | v2.0.0 |
| RF-30 | Generar **cupones** por temporada al correo de clientes seleccionados. | Baja | v2.0.0 |
| RF-31 | Solicitar **cambios de perfil** (sujetos a aprobación del admin). | Media | v2.0.0 |
| RF-32 | Reportes PDF de la empresa: ganancias, historial de servicios contratados, calificaciones, estado de rutas. | Media | v2.0.0 |
| RF-33 | La empresa retiene el **90%** del costo del servicio; la plataforma el **10%**. | Alta | v2.0.0 |

### 1.5 Módulo de cliente

| ID | Requerimiento | Prioridad | Entregable |
|----|---------------|-----------|------------|
| RF-34 | Buscar servicios de **envío** por zona, operador y nombre; filtrar por orden alfabético, calificación, precio (asc/desc) y capacidad. | Alta | v3.0.0 |
| RF-35 | Buscar servicios de **transporte** por destino, fecha, empresa y tipo; filtrar por hora, empresa, tiempo estimado, precio y calificación. | Alta | v3.0.0 |
| RF-36 | Sugerir los **3 mejor calificados** complementarios según el primer servicio elegido, con opción de ver todos. | Media | v3.0.0 |
| RF-37 | **Programar reserva** con ≥ 24 h de anticipación y **sin traslape** de fechas. | Alta | v3.0.0 |
| RF-38 | **Carrito persistente** que se mantiene aunque el cliente cierre sesión. | Alta | v3.0.0 |
| RF-39 | Administrar **métodos de pago**: tarjeta simulada con saldo inicial **Q1,000**, número validado por **Luhn**, más un **segundo método** (wallet/transferencia). | Alta | v3.0.0 |
| RF-40 | La reserva se confirma **solo si el pago fue procesado** exitosamente. | Alta | v3.0.0 |
| RF-41 | **Cancelar** la reserva hasta **24 h antes**; mecanismo de reembolso a criterio del equipo. | Media | v3.0.0 |
| RF-42 | Ver todos los servicios contratados/completados con su **estado** (activo, en tránsito, entregado, cancelado). | Alta | v3.0.0 |
| RF-43 | **Calificar y reseñar** envíos (tras la fecha de entrega) y transporte (tras el trayecto). | Media | v3.0.0 |
| RF-44 | **Reportar** problemas de sus servicios adjuntando evidencias y ver el historial de estados. | Media | v3.0.0 |
| RF-45 | **Canjear cupones** y ver historial con condiciones/restricciones. | Baja | v3.0.0 |
| RF-46 | Ver y editar el **perfil**; el correo **no** se modifica salvo justificación. | Media | v3.0.0 |

---

## 2. Requerimientos no funcionales (RNF)

| ID | Categoría | Requerimiento |
|----|-----------|---------------|
| RNF-01 | **Seguridad** | Las contraseñas se almacenan **hasheadas**, nunca en texto plano. |
| RNF-02 | **Seguridad** | Autenticación basada en **JWT**; el admin con **2FA** (token de 2 min). |
| RNF-03 | **Seguridad** | El número de tarjeta se valida con el **algoritmo de Luhn implementado manualmente**; nunca se guarda completo. |
| RNF-04 | **Seguridad** | Las entradas se validan en frontend y backend; las consultas usan parámetros (prevención de inyección SQL). |
| RNF-05 | **Integridad** | La base garantiza reglas con `CHECK`/`UNIQUE`/`FK` (correo único, montos ≥ 0, coherencia de estados). |
| RNF-06 | **Usabilidad (UI/UX)** | Aplicar buenas prácticas UI/UX y **≥ 6 heurísticas de Nielsen**, documentadas. No se permiten plantillas sin personalizar ni Bootstrap; se recomienda **Tailwind CSS**. |
| RNF-07 | **Usabilidad** | Mensajes de estado (carga, confirmaciones, errores) y confirmaciones antes de acciones destructivas. |
| RNF-08 | **Portabilidad** | App **dockerizada** (frontend y backend) y desplegada en VM/servidor en la nube; levantable de forma reproducible. |
| RNF-09 | **Mantenibilidad** | Código **modular y testeable**; mínimo **10 pruebas unitarias** (2 por integrante de backend). |
| RNF-10 | **Calidad** | Mínimo **10 pruebas E2E** con Selenium o Playwright sobre flujos críticos. |
| RNF-11 | **CI/CD** | Pipeline en **GitHub Actions** (Build → Test → Deploy) que se ejecuta **solo en push a `main`**. |
| RNF-12 | **Versionado** | **Gitflow** (main/develop/feature/release/hotfix), **Conventional Commits**, versionado semántico; release final **v3.0.0** con tag. |
| RNF-13 | **Comunicaciones** | Notificaciones por **correo electrónico** (tokens, aprobaciones, vetos, cancelaciones de ruta). |
| RNF-14 | **Disponibilidad/Datos** | Persistencia con **volumen** para no perder datos al recrear contenedores. |
| RNF-15 | **Compatibilidad** | Interfaz web responsiva, operable en navegadores modernos; idioma **español**. |
| RNF-16 | **Escalabilidad** | Arquitectura desacoplada (frontend / API / BD) que permita escalar servicios de forma independiente. |
| RNF-17 | **Trazabilidad** | Bitácora de actividad (`LogActividad`) que respalda los reportes de logs del administrador. |

---

## 3. Trazabilidad rápida (RF ↔ historias de usuario)

Las historias de usuario en `historias-usuario-trackflow.md` referencian estos IDs en su campo
*Requerimientos*. Regla: **toda HU mapea ≥ 1 RF**, y **todo RF de prioridad Alta tiene ≥ 1 HU** que lo
cubre. Los RNF se validan transversalmente en la Definición de Hecho (DoD) de cada sprint.
