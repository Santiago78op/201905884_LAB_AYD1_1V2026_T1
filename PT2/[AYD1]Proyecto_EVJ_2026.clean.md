# Sistema de Gestión de Envíos y Logística — TrackFlow-HUB

> **Análisis y Diseño de Sistemas 1 · Proyecto Escuela de Vacaciones 2026**
> Universidad San Carlos de Guatemala · Facultad de Ingeniería · Ingeniería en Ciencias y Sistemas
> Ing. José Manuel Ruiz Juárez · Aux: Douglas Josué Martínez Huit
> **Ponderación: 50 pts**

> Documento refinado a partir de `[AYD1]Proyecto_EVJ_2026.pdf` (conversión markitdown + limpieza
> de headers/footers de paginación y reconstrucción de las tablas de Cronograma y Scrum).

---

## 1. Competencias

- Identifica requerimientos funcionales y no funcionales mediante el análisis de procesos actuales, revisión de documentación y elaboración de casos de uso para asegurar que el sistema cumpla con las necesidades del negocio.
- Utiliza metodologías ágiles como Scrum y tableros Kanban para planificar, ejecutar y entregar software funcional en iteraciones cortas.
- Selecciona metodologías de desarrollo apropiadas comparando los requerimientos del proyecto con las características de cada metodología.
- Coordina el desarrollo de soluciones grupales empleando metodologías ágiles y herramientas colaborativas para organizar reuniones efectivas que favorezcan la toma de decisiones y el cumplimiento de objetivos.

## 2. Objetivos

### 2.1. Objetivo General

Desarrollar una plataforma web funcional y escalable para la gestión de envíos, paquetes y servicios logísticos que permita a clientes, operadores y administradores interactuar de manera eficiente, asegurando la calidad del software mediante pruebas unitarias, pruebas end-to-end y despliegue en la nube.

### 2.2. Objetivos Específicos

- Diseñar e implementar los módulos principales del sistema según los roles definidos, garantizando que cada usuario pueda realizar sus funciones clave dentro de una interfaz intuitiva y segura.
- Mantener una base de código modular y testeable, integrando pruebas unitarias para validar el correcto funcionamiento de componentes individuales.
- Desarrollar flujos completos de interacción y realizar pruebas end-to-end (E2E) que aseguren que los procesos críticos del sistema se ejecuten correctamente desde la perspectiva del usuario final.
- Establecer una arquitectura de software desplegada en un servicio en la nube utilizando contenedores Docker.
- Implementar un proceso de Integración Continua/Despliegue Continuo (CI/CD) para lograr un despliegue eficiente y automatizado del backend.

---

## 3. Enunciado del Proyecto

### 3.1 Descripción del problema o necesidad a resolver

Se propone el desarrollo de una plataforma digital integral que permita a los usuarios registrar, rastrear y gestionar envíos y servicios de logística de manera sencilla, rápida y segura. El sistema centralizará las principales operaciones del mercado logístico en un solo lugar, ofreciendo una experiencia intuitiva que optimice el proceso de coordinación de envíos.

La plataforma incluirá funcionalidades de seguimiento en tiempo real, gestión de paquetes, métodos de pago seguros y soporte administrativo. Su objetivo principal es proporcionar una herramienta eficiente que reduzca el tiempo y la complejidad asociados a la gestión de envíos y transporte de paquetes, posicionándose como una solución especializada para estos servicios esenciales de la logística moderna.

### 3.2 Alcance del proyecto

La empresa de logística TrackFlow-HUB se dedica a la coordinación de envíos nacionales e internacionales. Actualmente opera únicamente con procesos presenciales y telefónicos, lo cual ha limitado su capacidad de escalar y ofrecer servicios de manera ágil a sus clientes. Por ello, han solicitado transformar su negocio en un portal web que permita a clientes y operadores gestionar envíos desde cualquier lugar.

---

## 4. Gestión de usuarios

Existen **4 tipos de usuarios**: clientes, operadores logísticos, empresas de transporte y administradores.

> **Nota:** Todos los usuarios deberán proporcionar una contraseña segura y confirmarla dos veces.

### 4.1 Registro de clientes

Los clientes deben registrarse para poder utilizar la plataforma. Información mínima requerida:

- Nombre\*
- Apellido\*
- Teléfono\*
- Correo electrónico\*
- Contraseña\*
- Dirección de origen predeterminada

### 4.2 Registro de operadores logísticos

Los operadores logísticos deben poder registrarse con información verificable. Información mínima:

- Nombre\*
- Apellido\*
- DPI/CUI\*
- Teléfono\*
- Teléfono de respaldo
- Correo electrónico\*
- Fotografía\*
- Zona de operación\*
- Género\*

### 4.3 Registro de empresas de transporte

Las empresas de transporte deben registrarse con información verificable. Información mínima:

- Nombre de la empresa\*
- Teléfono\*
- Teléfono de respaldo
- Correo electrónico\*
- NIT\*
- Número de licencia operativa\*

### 4.4 Registro de administradores

Solo se podrán registrar nuevos administradores desde el panel de administración. Los campos de registro quedan a criterio del equipo de desarrollo.

### 4.5 Ingreso de clientes

Para ingresar, los clientes deben verificar su correo electrónico mediante un **token único de 6 caracteres** enviado al correo registrado. El token se solicita inmediatamente después del registro, o en cualquier intento de inicio de sesión mientras no se haya verificado.

### 4.6 Ingreso de operadores logísticos

Para ingresar, los operadores deben haber verificado su correo electrónico y ser aceptados por el administrador. La verificación de correo se realiza de la misma manera que los clientes. Una vez verificado, el operador recibirá una notificación indicando que su perfil está en proceso de revisión. Al ser aceptado, se le enviará una **contraseña temporal** que deberá cambiar en su primer ingreso.

### 4.7 Ingreso de empresas de transporte

Para ingresar, las empresas de transporte deben haber verificado su correo y ser aceptadas por el administrador. El proceso incluye una **reunión virtual** con el administrador donde la empresa presentará su propuesta de servicios. Una vez aprobada la reunión, el administrador proporcionará credenciales de acceso especiales.

### 4.8 Ingreso del administrador

Los administradores tendrán **doble factor de autenticación (2FA)**: además de su contraseña, se les enviará un token al correo electrónico con vigencia de 2 minutos, que deberán ingresar para completar el inicio de sesión.

---

## 5. Módulo de administrador

### 5.1 Gestión de registros

El administrador gestionará las solicitudes de registro de operadores logísticos (aceptar o rechazar, notificando al operador en ambos casos). También podrá observar solicitudes de empresas de transporte y agendar reuniones virtuales, enviando la información de fecha, hora y enlace al correo de la empresa. Adicionalmente, podrá registrar nuevos administradores.

### 5.2 Gestión de usuarios

El administrador tendrá un panel para observar todos los usuarios registrados, filtrados por rol. Podrá editar usuarios y **vetarlos** de la plataforma, solicitando un motivo de veto. El usuario vetado recibirá una notificación por correo indicando la razón. Al intentar iniciar sesión, se le mostrará un mensaje informando que está vetado y debe contactar al administrador. No existirá módulo de apelaciones.

### 5.3 Gestión de reportes

El administrador podrá observar todos los reportes generados en la plataforma y tomar acciones contra usuarios infractores, desde suspensiones temporales hasta veto permanente. Los estados de los reportes son: **Enviado** (recibido pero no revisado), **En revisión** (en proceso de análisis), **Aceptado** (procede y se aplica sanción) y **Rechazado** (desestimado).

### 5.4 Gestión de cambios en perfiles

Los operadores logísticos y las empresas de transporte podrán solicitar cambios en su información de perfil. El administrador revisará y verificará los nuevos datos, pudiendo aceptar o rechazar los cambios. El usuario recibirá una notificación en su vista principal sobre la resolución.

### 5.5 Visualización de información

El administrador podrá observar en detalle los servicios de transporte registrados en la plataforma, ordenarlos por zona geográfica y empresa que los ofrece. También podrá ver los envíos registrados por los operadores logísticos, ordenados por destino y operador.

### 5.6 Reportes del administrador

El administrador deberá poder observar y **descargar en PDF** los siguientes reportes:

- Logs de registros y vetos de usuarios (clientes completados, no completados, operadores solicitados/aceptados/rechazados, empresas de transporte solicitadas/aceptadas/rechazadas).
- Gráfica de usuarios aceptados/rechazados por tipo de usuario.
- Gráfica de zonas con mayor volumen de envíos.
- Gráfica de servicios de transporte más utilizados.
- Gráfica de ingresos generados por la plataforma (por tipo de servicio).
- Resumen de reportes emitidos y su estado.
- Historial de usuarios con mayor gasto en la plataforma.
- Historial de envíos realizados.
- Historial de servicios de transporte.
- Gráfica de destinos más frecuentes.
- Gráfica de uso de clientes: solo envíos, solo transporte, ambos servicios.

---

## 6. Módulo de operadores logísticos

### 6.1 Gestión de servicios

El operador logístico podrá registrar los servicios de envío que ofrecerá a los clientes mediante un formulario. Los datos mínimos son: zona de cobertura, capacidad de carga (kg), precio por envío y fotografías del vehículo/bodega (mínimo 3). El equipo de desarrollo definirá campos adicionales relevantes.

Los operadores podrán modificar y eliminar sus servicios. Existirá una opción de «**suspender temporalmente**» el servicio, que lo ocultará de la vista de los clientes sin eliminarlo del sistema, útil para mantenimientos o periodos de inactividad.

Los operadores podrán ver las calificaciones y comentarios que los clientes hayan dejado, así como responder a dichos comentarios.

Los operadores podrán ver en una **vista tipo calendario** las fechas en que los clientes han programado envíos, tanto individual por servicio como en vista general de todos sus servicios.

La distribución de ganancias será: el operador logístico retiene el **80%** del costo del envío y TrackFlow-HUB retiene el **20%** por uso de plataforma.

### 6.2 Gestión de reportes

El operador puede reportar a los clientes que hayan infringido las condiciones del servicio (daño intencional a paquetes, información falsa de destino, entre otros), aportando evidencia fotográfica o en vídeo.

El operador puede observar los reportes que los clientes hayan realizado sobre sus servicios.

### 6.3 Gestión de cupones

Dependiendo de la temporada o fechas especiales, el operador puede generar cupones o códigos de descuento para sus clientes. El mecanismo de selección de clientes beneficiarios queda a criterio del equipo de desarrollo.

### 6.4 Editar perfil

El operador logístico podrá ver y solicitar cambios en su perfil, pero dichos cambios requerirán aprobación del administrador antes de hacerse efectivos.

### 6.5 Reportes del operador

1. Reporte PDF de ganancias generadas por servicio y en general.
2. Historial de clientes que han utilizado sus servicios.
3. Reporte de calificaciones y comentarios recibidos.

---

## 7. Módulo de empresas de transporte

### 7.1 Gestión de rutas y flota

Las empresas de transporte podrán cargar su flota y rutas en formato **CSV** (campos a definir por el equipo de desarrollo). También podrán registrar rutas manualmente mediante un formulario.

Las empresas podrán editar rutas individuales, con reflejos inmediatos en la vista del cliente. Podrán cancelar o suspender rutas por emergencias o condiciones climáticas; los clientes afectados serán notificados inmediatamente por correo electrónico.

La distribución de ganancias será: la empresa de transporte retiene el **90%** del costo del servicio y TrackFlow-HUB retiene el **10%** por uso de plataforma.

### 7.2 Gestión de reportes

Las empresas podrán observar los reportes de los clientes sobre sus servicios (retrasos, cancelaciones, cobros extras, entre otros). Las empresas de transporte **no pueden reportar directamente a los clientes**, ya que estos se rigen bajo normativa propia.

### 7.3 Gestión de cupones

Las empresas de transporte pueden generar cupones o códigos de descuento por temporada, enviados al correo de los clientes seleccionados según criterio del equipo de desarrollo.

### 7.4 Editar perfil

Las empresas de transporte podrán solicitar cambios en su perfil, sujetos a aprobación del administrador.

### 7.5 Reportes de la empresa

1. Reporte de ganancias generadas por los servicios.
2. Historial de servicios contratados.
3. Reporte de calificaciones y reseñas recibidas.
4. Reporte del estado de las rutas.

---

## 8. Módulo de clientes

### 8.1 Gestión de envíos

Los clientes podrán buscar servicios de envío por zona de cobertura, operador logístico y nombre del servicio. Podrán filtrar por orden alfabético, mejor calificación, precio (ambas direcciones) y capacidad de carga.

Los clientes verán un resumen del servicio en el listado y al hacer clic accederán a los detalles completos. Podrán programar un envío con al menos **24 horas de anticipación**, seleccionando un rango de fechas sin traslape con reservaciones existentes.

### 8.2 Gestión de transporte

Los clientes podrán buscar servicios de transporte por destino, fecha, empresa y tipo de servicio. Los filtros disponibles incluyen: hora de inicio, empresa proveedora, tiempo estimado de entrega, precio y calificación de la empresa (ambas direcciones).

**Consideraciones de las reservaciones:**

1. El cliente puede contratar solo envíos, solo transporte, o ambos servicios.
2. Si el cliente elige primero un servicio de envío, se le sugerirán los **3 operadores logísticos mejor calificados** para la misma zona, con opción de ver todos.
3. Si el cliente elige primero un servicio de transporte, se le sugerirán los **3 operadores de envío mejor calificados** del destino, con opción de ver todos.
4. El cliente tendrá un apartado donde podrá ver todos los servicios contratados o completados, incluyendo el estado actual (**activo, en tránsito, entregado, cancelado**).

### 8.3 Gestión de pagos

Para confirmar un servicio, el cliente debe realizar el pago. Los clientes administrarán sus métodos de pago en un apartado dedicado. El método principal es por **tarjeta de crédito o débito simulada**: al registrar una tarjeta ficticia se asigna un saldo inicial de **Q1,000**; las compras se descuentan de ese saldo. Las tarjetas deben contener todos los campos estándar (número, nombre, fecha de vencimiento, CVV) y el número debe ser validado mediante el **algoritmo de Luhn implementado manualmente**. El equipo debe implementar un **segundo método de pago alternativo simulado** (puede ser tipo wallet o transferencia). Las reservaciones únicamente se confirman cuando el pago haya sido procesado exitosamente.

El cliente podrá cancelar su reservación hasta **24 horas antes**. El mecanismo de reembolso queda a criterio del equipo de desarrollo. Todos los servicios se agregan a un **carrito de compras persistente**, que se mantiene aunque el cliente cierre sesión.

### 8.4 Gestión de calificaciones y reseñas

Los clientes podrán calificar los servicios de envío una vez concluida la fecha de entrega programada. Para servicios de transporte, podrán calificar una vez finalizado el trayecto contratado. En ambos casos podrán dejar un comentario y una puntuación.

### 8.5 Gestión de reportes

Los clientes tendrán un apartado para reportar problemas relacionados con sus servicios contratados. Para envíos: operador no realizó la recolección a tiempo, cobro no acordado, daño al paquete, entre otros. Para transporte: retrasos no justificados, cobros extra, cancelaciones sin aviso, entre otros. Los clientes podrán adjuntar evidencias y ver el historial de reportes con sus estados: **Enviado, En estudio, Aceptado y Rechazado**.

### 8.6 Gestión de cupones

Los clientes podrán canjear cupones otorgados por operadores o empresas de transporte, y verán un historial de cupones utilizados junto con sus condiciones y restricciones.

### 8.7 Editar perfil

El cliente podrá ver y editar su información de perfil. El **correo electrónico no podrá modificarse** salvo en circunstancias debidamente justificadas.

---

## 9. Metodología

### 9.1 Gitflow

El equipo debe utilizar la estrategia de branching Gitflow, que incluye las ramas principales **main** y **develop**, así como las ramas auxiliares: **feature**, **release** y **hotfix**. Se debe usar GitHub como plataforma de control de versiones.

### 9.2 Conventional Commits

Se deben seguir las buenas prácticas de Conventional Commits para que cada commit brinde información clara. Se debe realizar un merge a la rama main con versionamiento semántico para cada release. La versión final deberá ser la **v3.0.0** con su respectivo tag.

### 9.3 Scrum

El equipo debe utilizar Scrum como marco de trabajo ágil. Eventos requeridos:

- **Sprint:** Cada ciclo de desarrollo se denominará Sprint. El proyecto debe contar con un mínimo de **3 sprints de 6 días** cada uno.
- **Sprint Planning:** Reunión al inicio de cada sprint donde se planifica qué se desarrollará y cómo. Participan el Scrum Master, el Product Owner y el equipo de desarrollo. *Nota: se deben realizar 3 Sprint Planning como mínimo. Cada reunión debe tener como evidencia una captura donde estén todos los integrantes presentes, identificada con fecha y hora.*
- **Daily Scrum:** Reunión diaria del equipo donde cada integrante responde: ¿Qué hice ayer? ¿Qué haré hoy? ¿Hay algún impedimento? *Nota: se deben realizar al menos 9 dailys distribuidas equitativamente en los sprints. Cada daily se debe documentar con nombre, carnet, fecha y respuestas de cada integrante en un archivo.*
- **Sprint Retrospective:** Evento al final de cada sprint donde el equipo reflexiona sobre lo que salió bien, lo que salió mal y las mejoras a implementar. Cada integrante debe responder individualmente: ¿Qué se hizo bien? ¿Qué se hizo mal? ¿Qué mejorar?

### 9.4 Tablero Kanban

El equipo debe mantener un tablero Kanban actualizado con al menos las columnas: **Por hacer, En proceso y Realizado**. Se debe utilizar una herramienta de gestión de proyectos (Jira, Trello, GitHub Projects, u otra). El estado del tablero debe mostrarse en todos los eventos de Scrum.

### 9.5 Pruebas unitarias

Se deben implementar un mínimo de **10 pruebas unitarias**. Esto garantiza el correcto funcionamiento individual de cada componente y permite detectar regresiones al agregar nuevas funcionalidades. Cada integrante del equipo de backend deberá realizar **2 pruebas unitarias** como mínimo.

### 9.6 Pruebas E2E

Se deben realizar pruebas end-to-end que simulan la experiencia del usuario de principio a fin, cubriendo los flujos críticos del sistema. El equipo debe implementar un mínimo de **10 pruebas E2E** diferentes utilizando **Selenium o Playwright**.

### 9.7 CI/CD

Se implementará un pipeline de Integración Continua/Despliegue Continuo en **GitHub Actions** con las siguientes etapas:

- **Build:** Compilación del código fuente y generación de artefactos para despliegue.
- **Test:** Ejecución automática de pruebas unitarias para validar la calidad del código.
- **Deploy:** Despliegue automatizado del backend al entorno de producción.

> **Nota:** El proceso CI/CD se ejecuta únicamente cuando se realiza push a la rama main.

### 9.8 Arquitectura

El equipo debe desplegar la aplicación completa en una máquina virtual o servidor en la nube, utilizando **Docker** tanto para el backend como para el frontend. El uso de contenedores garantiza la consistencia entre entornos de desarrollo y producción.

- El lenguaje, framework y librerías del backend y frontend queda a libre elección del grupo, siempre que se justifique técnicamente.
- Levantar la aplicación de forma reproducible en cualquier entorno.
- Evitar conflictos de dependencias entre desarrollo y producción.
- Simplificar el despliegue y escalado de los servicios.

Se puede usar una base de datos relacional en la nube; de lo contrario se debe dockerizar la misma. Se permite cualquier lenguaje de modelado de bases de datos.

### 9.9 Requisitos de UI/UX

Todos los grupos deberán aplicar buenas prácticas de diseño UI/UX en todas las pantallas del sistema. **No se permite** el uso de plantillas descargadas sin personalización ni Bootstrap. Se recomienda el uso de **Tailwind CSS** u otro framework de estilizado.

Aplicación de los principios heurísticos de **Jakob Nielsen**:

1. Visibilidad del estado del sistema (mensajes de carga, confirmaciones, errores).
2. Coincidencia entre el sistema y el mundo real (uso de términos comprensibles para el usuario).
3. Control y libertad del usuario (opciones para deshacer o cancelar acciones).
4. Consistencia y estándares (iconografía, paleta de colores y ubicaciones coherentes).
5. Prevención de errores (confirmaciones antes de eliminar, validaciones de formulario).
6. Reconocimiento antes que memorización (menús visibles, etiquetas descriptivas).
7. Flexibilidad y eficiencia (accesos directos, flujos reducidos de pasos).
8. Diseño estético y minimalista (solo la información necesaria en cada vista).
9. Ayuda al usuario a reconocer, diagnosticar y recuperarse de errores.
10. Ayuda y documentación accesible dentro del sistema.

Cada grupo deberá seleccionar **al menos 6** de estos principios, documentar cuáles eligió y demostrar su aplicación concreta en el sistema como parte de los entregables de UI/UX.

---

## 10. Documentación

- Requerimientos Funcionales y No Funcionales
- Diagrama de casos de uso
- Historias de usuario
- Diagrama de clases
- Diagrama de secuencias
- Diagrama de componentes
- Diagrama de despliegue
- Diagrama entidad relación
- Manual Técnico
- Manual de Usuario
- Prototipo de Interfaces
- Link de la herramienta de Gestión de Proyectos (Kanban)
- Sección de calificación del equipo por parte del Scrum Master (escala 1-100)

La documentación debe ser almacenada en el repositorio de GitHub en formato Markdown, dentro de una carpeta llamada **`Proyecto/documentacion`**.

---

## 11. Consideraciones

- La documentación debe almacenarse en el repositorio en formato Markdown.
- El lenguaje, frameworks y librerías del backend y frontend quedan a libre elección del grupo.
- Es obligatorio el uso de la estrategia de branching Gitflow.
- Se debe desarrollar con los grupos establecidos en el laboratorio.
- Para la calificación, el proyecto se presentará desde una computadora de alguno de los integrantes.
- Se deben hacer al menos **3 releases** a la rama main.
- Solo se calificará el último commit con el tag **v3.0.0**.
- Es obligatorio el uso de Conventional Commits.
- Es obligatorio el uso de Scrum.
- Se revisará que el tablero Kanban haya sido creado y actualizado correctamente durante el desarrollo.
- El repositorio debe nombrarse: **`AYD1_Proyecto_VD_G#`** y entregarse en UEDI.
- Debe utilizarse GitHub como plataforma de control de versiones.
- El auxiliar del curso debe ser añadido como colaborador: **`douglasmhuit`**.
- Queda prohibido adelantar partes que no sean de los entregables.
- En cada entregable cada integrante debe tener al menos una rama feature (`feature/funcion_carnet`).

---

## 12. Entregables

- **Primer entregable (v1.0.0) — 17/06/2026:** Módulo de ingreso, login y registro para todos los tipos de usuario; Módulo de Administrador (solamente lo relacionado a creación de usuarios), junto con validación de Gitflow, Conventional Commits y documentación inicial completa.
- **Segundo entregable (v2.0.0) — 23/06/2026:** Módulo de operadores logísticos y módulo de empresas de transporte, junto con pruebas unitarias y pruebas E2E.
- **Tercer entregable (v3.0.0) — 30/06/2026:** Módulo de clientes y módulo de administrador (completo), junto con Scrum completo, tablero Kanban, UI/UX y CI/CD.

---

## 13. Cronograma

| Tipo | Fecha |
|------|-------|
| Entrega de enunciado | 11 de junio de 2026 |
| Primer entregable (v1.0.0) | 18 de junio de 2026 |
| Segundo entregable (v2.0.0) | 23 de junio de 2026 |
| Tercer entregable (v3.0.0) | 30 de junio de 2026 |

> **Nota:** la sección de Entregables fecha el primer entregable el 17/06/2026 y el Cronograma el 18/06/2026 (discrepancia del enunciado original; confirmar con el auxiliar).

---

## 14. Calendarización de Actividades Scrum

| Actividad | Fecha |
|-----------|-------|
| Sprint Planning 1 | 12/06/2026 |
| Daily 1 – Daily 3 | 13/06/2026 – 16/06/2026 |
| Sprint Retrospective 1 | 17/06/2026 |
| Sprint Planning 2 | 18/06/2026 |
| Daily 4 – Daily 6 | 19/06/2026 – 22/06/2026 |
| Sprint Retrospective 2 | 23/06/2026 |
| Sprint Planning 3 | 24/06/2026 |
| Daily 7 – Daily 9 | 25/06/2026 – 29/06/2026 |
| Sprint Retrospective 3 | 30/06/2026 |

---

## 15. Rúbrica de Calificación

> *En el PDF original esta sección está vacía (sin contenido de rúbrica). Pendiente de que el auxiliar la publique.*
