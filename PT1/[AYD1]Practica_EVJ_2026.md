Análisis y Diseño de Sistemas 1
Proyecto Escuela de Vacaciones 2026

Universidad San Carlos de Guatemala
Facultad de ingeniería.
Ingeniería en ciencias y sistemas
Ing. José Manuel Ruiz Juarez
Aux: Douglas Josué Martínez Huit

Sistema de gestión de eventos

y conferencias - EVENTCORE

PONDERACIÓN:  20 pts

Análisis y Diseño de Sistemas 1
Proyecto Escuela de Vacaciones 2026

Índice

1. Competencias.....................................................................................................................3
2. Objetivos............................................................................................................................. 3
2.1. Objetivo General......................................................................................................... 3
2.2. Objetivos Específicos.................................................................................................. 3
3. Enunciado del Proyecto.................................................................................................... 4
1. Gestión de usuarios................................................................................................. 4
2. Gestión de eventos y sesiones................................................................................ 5
3. Gestión de pagos e inscripciones............................................................................ 6
4. Gestión de ponentes y reportes............................................................................... 7
4.1 Gestión de ponentes........................................................................................ 7
4.2 Reportes........................................................................................................... 7
4. Documentación.................................................................................................................. 8
5. Entregables.........................................................................................................................8
6. Consideraciones................................................................................................................ 9
7. Restricciones....................................................................................................................11
8. Cronograma...................................................................................................................... 12
9. Rúbrica de Calificación................................................................................................... 12
10. Valores............................................................................................................................ 13

Análisis y Diseño de Sistemas 1
Proyecto Escuela de Vacaciones 2026

1.  Competencias

Coordinar el desarrollo de soluciones grupales empleando metodologías ágiles y
plataformas colaborativas para organizar y ejecutar reuniones que favorezcan la toma de
decisiones y el cumplimiento de objetivos en entornos de trabajo en equipo. Genera
soluciones de software aplicando buenas prácticas de análisis, control de versiones y
metodologías ágiles para garantizar proyectos eficientes y colaborativos en entornos
virtuales de trabajo

2.  Objetivos

2.1.  Objetivo General

Desarrollar una solución de software en equipos colaborativos aplicando buenas prácticas
de análisis, desarrollo y control de versiones, con el fin de garantizar un proyecto eficiente,
funcional y coordinado en un entorno de trabajo virtual.

2.2.  Objetivos Especíﬁcos

●  Aplicar técnicas de análisis de requerimientos para definir las funcionalidades del

sistema, considerando las necesidades del usuario y documentando de manera
clara y estructurada.

●  Utilizar herramientas de control de versiones para gestionar el código fuente de

forma colaborativa, asegurando trazabilidad, integridad del proyecto y resolución
efectiva de conflictos.

●  Entregar un producto de calidad siguiendo los estándares GitFlow para que, a través
del manejo de ramas, versionamiento semántico y tags, aprendan las ventajas que
ofrece en el desarrollo de software seguir estas normativas.

●  Aplicar principios de software genérico y buenas prácticas de diseño para entregar
un software que mantenga el equilibrio entre funcionamiento y diseño intuitivo para
el usuario final.

Análisis y Diseño de Sistemas 1
Proyecto Escuela de Vacaciones 2026

3.  Enunciado del Proyecto

El sector de eventos corporativos y académicos ha experimentado un crecimiento notable
en los últimos años, impulsado por la proliferación de conferencias, seminarios, talleres y
convenciones tanto presenciales como híbridas. La organización eficiente de estos eventos
representa un desafío logístico significativo: gestionar inscripciones, asignación de
espacios, ponentes, asistentes y pagos de forma simultánea y coordinada.

Ante esta necesidad, se le ha solicitado desarrollar EVENTCORE, un sistema web que
permita gestionar de manera integral la organización de eventos y conferencias,
optimizando los procesos administrativos y ofreciendo a los asistentes una plataforma
accesible e intuitiva para su participación.

1. Gestión de usuarios

El sistema deberá permitir el registro y autenticación de dos tipos de usuarios:
Administrador y Asistente. El administrador gestiona la plataforma completa; el asistente
puede explorar eventos, inscribirse y gestionar su perfil.

La información mínima requerida para el registro de un asistente es:

➔  Nombre completo*
➔  Correo electrónico*
➔  Contraseña*
➔  Número de teléfono*
➔  Organización o institución a la que pertenece*
➔  Cargo o puesto
➔  País de residencia*
➔  Fotografía de perfil*

*Campos obligatorios

Notas: Para iniciar sesión, el asistente deberá confirmar su correo electrónico; queda a
discreción del desarrollador la manera en que lo implemente. Debe existir autenticación
basada en roles; se sugiere el uso de JWT o cookies-session. El administrador debe tener
una capa de seguridad adicional, cuya implementación queda a criterio del desarrollador.

Análisis y Diseño de Sistemas 1
Proyecto Escuela de Vacaciones 2026

2. Gestión de eventos y sesiones

El núcleo del sistema es la administración de eventos. Un evento puede contener múltiples
sesiones (charlas, talleres, paneles), cada una con su propio ponente, sala, horario y cupo.
El administrador es el único que puede crear, editar y cancelar eventos.

La información mínima de un evento es:

●  Nombre del evento*
●  Descripción*
●  Fecha de inicio y fecha de fin*
●  Modalidad (presencial, virtual o híbrida)*
●  Ubicación física o enlace de transmisión según modalidad*
●  Categoría (académico, corporativo, cultural, tecnológico, otro)*
●
Imagen o banner del evento*
●  Capacidad máxima de asistentes*
●  Estado del evento (borrador, publicado, cancelado, finalizado)

Cada sesión dentro de un evento debe incluir:

●  Título de la sesión*
●  Ponente o expositor asignado*
●  Fecha y hora de inicio y fin*
●  Sala o enlace asignado*
●  Cupo máximo de participantes por sesión*
●  Materiales o recursos adjuntos (opcional)

Las modalidades de inscripción a eventos son:

➔  Inscripción abierta: el asistente puede registrarse directamente a un evento

publicado mientras haya cupo disponible. La inscripción puede realizarse hasta 24
horas antes del inicio del evento. El asistente puede inscribirse a sesiones
individuales dentro del evento, respetando los cupos por sesión.

➔  Inscripción con aprobación: el asistente envía una solicitud que el administrador

debe aprobar o rechazar. El asistente recibe una notificación por correo con el
resultado. Este tipo aplica a eventos con cupo limitado o de acceso restringido.
➔  Inscripción por invitación: el administrador genera y envía códigos de invitación
personalizados por correo electrónico. Solo los usuarios con código válido pueden
completar su registro al evento.

Notas: El sistema debe garantizar que no existan traslapes de sesiones para un mismo
asistente. El administrador podrá visualizar el estado de ocupación de cada sala y sesión.
La cancelación de inscripción por parte del asistente solo estará disponible hasta 48 horas
antes del inicio del evento.

Análisis y Diseño de Sistemas 1
Proyecto Escuela de Vacaciones 2026

3. Gestión de pagos e inscripciones

Los eventos pueden ser gratuitos o de pago. En caso de ser de pago, el asistente deberá
completar el proceso de pago para confirmar su inscripción. Se definen las siguientes
tarifas:

Tipo de Entrada

Descripción

Tarifa

Disponibilidad

Early Bird

General

Estudiante

Sesión individual

VIP /
Patrocinador

Acceso completo al
evento; aplica hasta
30 días antes del
inicio

Acceso completo al
evento en fechas
regulares

Acceso completo;
requiere carné
universitario vigente

Acceso únicamente
a la sesión
seleccionada

Acceso completo +
beneficios
exclusivos
(kit, networking,
grabaciones)

Q. 150.00

Limitada (20% del
cupo
total)

Q. 250.00

Hasta agotar cupo

Q. 100.00

Hasta agotar cupo

Q. 50.00

Según cupo de
sesión

Q. 500.00

Máximo 10 por
evento

Los métodos de pago disponibles son:

●  Pago con tarjeta de débito/crédito: el asistente puede registrar, editar y eliminar una

tarjeta en su perfil. Recibirá notificación por correo ante cualquier cambio. La
confirmación del pago es inmediata y automática.

●  Pago por transferencia bancaria: el asistente carga el comprobante de pago en el
sistema. El administrador revisa y confirma o rechaza el pago. El asistente es
notificado por correo con el resultado.

El asistente podrá cancelar su inscripción hasta 48 horas antes del inicio del evento. Pasado
ese tiempo, la inscripción es irrevocable y no procede reembolso. Si cancela con la
anticipación requerida, se le devolverá el 80% del monto pagado. Para ello, el asistente
deberá ingresar una solicitud de cancelación desde su panel; dicha solicitud aparecerá en el
módulo del administrador, quien procederá el reembolso enviando un comprobante PDF por
correo electrónico al solicitante.

Análisis y Diseño de Sistemas 1
Proyecto Escuela de Vacaciones 2026

4. Gestión de ponentes y reportes

4.1 Gestión de ponentes

El administrador podrá registrar y gestionar el catálogo de ponentes que participan en los
eventos del sistema. Cada ponente es una entidad independiente que puede ser asignada a
múltiples sesiones en distintos eventos.

La información mínima de un ponente es:

●  Nombre completo*
●  Correo electrónico de contacto*
●  Fotografía*
●  Biografía profesional*
●  Área de especialización*
●  Organización o institución de procedencia
●  Redes sociales o sitio web (opcional)

El sistema debe garantizar que un mismo ponente no tenga dos sesiones asignadas en el
mismo horario, incluso si pertenecen a eventos distintos. El administrador podrá editar o
desactivar a un ponente, pero no eliminarlo si tiene sesiones confirmadas.

4.2 Reportes

El administrador podrá generar los siguientes reportes:

●  Historial de eventos realizados, incluyendo estado final y número de asistentes.
●  Detalle de ingresos del último mes, desglosado por tipo de entrada y método de

pago; debe incluir reembolsos procesados.

●  Eventos y sesiones con mayor porcentaje de ocupación.
●  Historial de solicitudes de cancelación y reembolsos.
●  Log de todas las actividades realizadas en el sistema (acciones de usuarios y

administradores).

●  Como desarrollador deberá implementar 1 reporte gráfico que considere necesario

para satisfacer las necesidades del administrador, tomando como base los
requerimientos establecidos.

Análisis y Diseño de Sistemas 1
Proyecto Escuela de Vacaciones 2026

4. Documentación

●  Requerimientos Funcionales y No Funcionales
●  Diagrama de casos de uso
●  Historias de usuario
●  Diagrama de clases
●  Diagrama de secuencias
●  Diagrama de componentes
●  Diagrama de despliegue
●  Diagrama entidad relación
●  Manual Técnico
●  Manual de Usuario

5. Entregables

●  Se debe adjuntar el link del repositorio con el nombre
AYD1_PRACTICA_VJ2026_G#, entregarlo vía UEDI.

●  El repositorio debe contener tanto el código fuente como la documentación.
●  El repositorio debe ser privado y estar alojado en GitHub.
●  Usuario de GitHub del auxiliar: douglasmhuit

Análisis y Diseño de Sistemas 1
Proyecto Escuela de Vacaciones 2026

6. Consideraciones

Gitflow

Main/Master y Develop

Estas ramas se manejan de la siguiente manera:

●  Main/Master: es la rama principal del repositorio. En esta rama se maneja un entorno

de producción; únicamente se tendrá el código funcional a presentar durante la
calificación.

●  Develop: esta rama se crea a partir de Main/Master y de ella se crearán las ramas
features. Aquí se mantendrá el código antes de realizarse un release hacia la rama
Main.

Release

Esta rama nace de develop y se utiliza para trasladar correcciones de bugs, mejoras
menores o ajustes de documentación hacia la rama main. Al fusionar release con main se
debe agregar una etiqueta con el nombre de la versión (al finalizar se espera la versión
1.0.0). La rama release también se fusiona con develop para conservar los cambios en el
desarrollo futuro; posteriormente se elimina para evitar confusión en el repositorio.

Hotfix

Nace de la rama main para corregir un error crítico en producción. Al finalizar la corrección,
se fusiona tanto en develop como en main; en main se crea una etiqueta con el nuevo
número de versión y la rama se elimina.
Debe nombrarse como hotfix/v#.#.#.

Features

Para cada funcionalidad se debe crear una rama con la nomenclatura
"feature/featureName_#Id", donde featureName es el nombre de la funcionalidad e Id el
número de carnet del responsable. Al finalizar cada feature se debe fusionar a la rama
develop.

Análisis y Diseño de Sistemas 1
Proyecto Escuela de Vacaciones 2026

Requisitos de UI/UX
Con el objetivo de fomentar el desarrollo de interfaces intuitivas, accesibles y visualmente
consistentes, todos los grupos deberán aplicar buenas prácticas de diseño de interfaces de
usuario (UI) y de experiencia de usuario (UX) en la implementación de EVENTCORE. Estas
prácticas deberán reflejarse en cada pantalla del sistema, tanto en la vista de administrador
como en la del asistente.

Herramientas a utilizar:

La elección de la herramienta o librería de estilizado queda a discreción del equipo y debe
estar alineada con la tecnología principal del proyecto. No se permitirá el uso de plantillas
preconstruidas ni descargadas (AdminLTE, templates comprados o similares). Si el
equipo desea utilizar una librería de componentes específica, deberá justificar su elección al
tutor académico durante clase.

Aplicación de los principios heurísticos de Jakob Nielsen:

●  Visibilidad del estado del sistema (mensajes de carga, confirmaciones, errores).
●  Coincidencia entre el sistema y el mundo real (uso de términos comprensibles para

el usuario).

●  Control y libertad del usuario (opciones para deshacer o cancelar acciones).
●  Consistencia y estándares (iconografía, paleta de colores y ubicaciones coherentes).
●  Prevención de errores (confirmaciones antes de eliminar, validaciones de

formulario).

●  Reconocimiento antes que memorización (menús visibles, etiquetas descriptivas).
●  Flexibilidad y eficiencia (accesos directos, flujos reducidos de pasos).
●  Diseño estético y minimalista (solo la información necesaria en cada vista).
●  Ayuda al usuario a reconocer, diagnosticar y recuperarse de errores.
●  Ayuda y documentación accesible dentro del sistema.

Cada grupo deberá seleccionar al menos 6 de estos principios, documentar cuáles eligió y
demostrar su aplicación concreta en el sistema como parte de los entregables de UI/UX.

Análisis y Diseño de Sistemas 1
Proyecto Escuela de Vacaciones 2026

7. Restricciones

➢  Es obligatorio el uso de una estrategia de branching GitFlow (se recomienda

GitKraken u otra herramienta visual de Git).

➢  Se debe desarrollar con los grupos establecidos en el laboratorio.
➢  Para la calificación se debe presentar la práctica en alguna computadora de los

integrantes del grupo.

➢  Se debe realizar al menos 1 release a la rama Main; solo se calificará el último

commit de esta rama con el tag 1.0.0 (se revisará la fecha y hora del último commit).
➢  La elección del lenguaje y framework queda a discreción del equipo, tanto para
el backend como para el frontend. El equipo deberá justificar razonablemente las
tecnologías elegidas (Node.js, Go, Java, C#, Python, etc. para backend; React, Vue,
Angular, Svelte u otros para frontend).

➢  Toda la información debe almacenarse en una base de datos relacional, para ello, se
deja a discreción del grupo si se utiliza de manera local o en la nube. El motor de
base de datos debe ser SQL Server. Incluir el diagrama entidad relación en el
manual técnico.

➢  Aplicar buenas prácticas en el uso de commits (Conventional Commits).
➢  El manual técnico y de usuario deben entregarse en archivos de tipo Markdown.
➢  Durante la calificación se preguntará información relevante para verificar la autoría;
todos los integrantes deben estar presentes, ya que mediante actividades (HotFix)
se validará su participación en la práctica.

➢  Se debe crear un repositorio privado en GitHub donde se registre el avance de la

práctica, con commits de todos los integrantes del grupo.

➢  Queda prohibido el uso de plantillas preconstruidas o descargadas

(AdminLTE, templates comprados, etc.) sin que el estudiante diseñe la
estructura base de la UI.

➢  No usar generadores automáticos de CRUD o módulos completos de

autenticación/paneles donde el alumno no implemente la lógica desde cero.
➢  No usar plataformas no-code o low-code que eviten el desarrollo manual del

backend y frontend.

➢  No usar servicios que provean backend completo (API + DB + Auth + panel)

listos para usar, como Supabase y similares.

➢  Se puede usar inteligencia artificial u otras ayudas como apoyo, pero cada

integrante debe ser capaz de explicar cada parte de su código y justificar sus
decisiones. De lo contrario, se considerará falta de autoría.

Nota: Si un integrante no tiene aporte se penalizará con el 100% de la nota obtenida.

Análisis y Diseño de Sistemas 1
Proyecto Escuela de Vacaciones 2026

8. Cronograma

Tarea

Fecha

Entrega enunciado

2 de junio de 2026

Fecha Entrega

11 de junio de 2026

Fecha Calificación

12-13 junio de 2026

9. Rúbrica de Calificación

Criterio

Descripción

Análisis y
Requisitos del
Sistema

Identificación clara de actores (asistentes, ponentes,
administrador, tipos de entrada, etc.), procesos del sistema,
y requisitos funcionales y no funcionales documentados
correctamente

Implementación
Funcional

El sistema permite gestionar eventos, sesiones,
inscripciones y pagos con reglas de validación
correctamente aplicadas y sin traslapes de horario.

Control de
Versiones

Uso consistente de Git: commits frecuentes y bien
nombrados (Conventional Commits), uso correcto de
ramas GitFlow y manejo de conflictos documentado en
GitHub.

Documentación
Técnica y de
Usuario

Manual técnico y guía de usuario clara en formato
Markdown. Incluye instrucciones de instalación,
configuración y uso del sistema.

Puntos
Máximos

20 puntos

20 puntos

20 puntos

20 puntos

Interfaz de
Usuario
(UI/UX)

Interfaz clara, intuitiva, accesible y funcional. Se evalúa la
aplicación de al menos 6 principios heurísticos de Jakob
Nielsen, debidamente documentados en los entregables.

20 puntos

Nota: Si no supera los 12 puntos en la implementación no tiene derecho a los
demás puntos, control de versiones, documentación e interfaz.

Análisis y Diseño de Sistemas 1
Proyecto Escuela de Vacaciones 2026

10. Valores

En el desarrollo de la práctica, se espera que cada estudiante demuestre honestidad
académica y profesionalismo. Por lo tanto, se establecen los siguientes principios:

1.  Originalidad del Trabajo

a.  Cada estudiante o equipo debe desarrollar su propio código y/o

documentación, aplicando los conocimientos adquiridos en el curso.

2.  Prohibición de Copias y Plagio

a.  Si se detecta la copia total o parcial del código, documentación o cualquier

otro entregable, la calificación será de 0 puntos.

b.  Esto incluye la reproducción de código entre compañeros, la reutilización de
proyectos de semestres anteriores o el uso de código externo sin la debida
referencia.

3.  Uso Responsable de Recursos Externos

a.  El uso de bibliotecas, frameworks y ejemplos de código externos está

permitido, siempre y cuando se referencien correctamente y se comprendan
plenamente. (Consultar con el catedrático su política.)

4.  Revisión y Detección de Plagio

a.  Se podrán utilizar herramientas automatizadas y revisiones manuales para

identificar similitudes entre proyectos.

b.  En caso de sospecha, el estudiante deberá justificar su código y demostrar

su desarrollo individual o en equipo. Si esto no es comprobable, la
calificación será de 0 puntos.

Al detectarse estos aspectos se informará al catedrático del curso, quien realizará las
acciones que considere oportunas.

