# Informe Técnico — Tarea #2

**Universidad de San Carlos de Guatemala**
Facultad de Ingeniería — Escuela de Ingeniería en Ciencias y Sistemas
Laboratorio de Bases de Datos 2 — Vacaciones Junio 2026

**Estudiante:** Joshua Alexander Vasquez del Aguila
**Tipo de base NoSQL:** Documental (MongoDB)
**Caso de estudio:** Plataforma de streaming
**Herramienta de IA utilizada:** Claude (Anthropic)
**Fecha de entrega:** 26/06/2026

---

## 1. Marco Formativo

### 1.1 Valores

| Nombre del valor | ¿Cómo se aplica en tu laboratorio? |
| --- | --- |
| Honestidad académica | Toda propuesta generada por la IA fue verificada, corregida cuando hizo falta y citada como tal, en lugar de presentarla como propia sin revisión. El código entregado fue probado y comprendido, no solo copiado. |

### 1.2 Competencias

| Tipo de Competencia | Descripción |
| --- | --- |
| Competencia General | Diseñar e implementar soluciones de bases de datos acordes a un problema concreto. |
| Competencia Específica | Modelar, implementar y consultar una base de datos NoSQL utilizando herramientas de IA como apoyo, evaluando críticamente sus respuestas. |

### 1.3 Objetivos

- Aplicar conceptos de bases de datos NoSQL en un caso práctico.
- Utilizar herramientas de IA como apoyo para el modelado y las consultas.
- Analizar ventajas y limitaciones de las respuestas generadas por IA.
- Implementar operaciones CRUD y consultas avanzadas en una base NoSQL.

---

## 2. Introducción

El presente trabajo documenta el diseño y la implementación de una base de datos NoSQL
para una plataforma de streaming, similar en concepto a servicios como Netflix o
Disney+. El objetivo no fue únicamente construir una base funcional, sino hacerlo
apoyándose en una herramienta de inteligencia artificial generativa (Claude) y, sobre
todo, evaluar de forma crítica lo que esa herramienta propuso.

Una plataforma de streaming maneja información que cambia de forma y crece con rapidez:
catálogos de películas con distintos atributos, usuarios con historiales de
visualización de tamaño variable y patrones de consulta orientados a la lectura. Estas
características hacen que un modelo documental sea una opción natural, ya que permite
guardar cada entidad como un documento flexible sin un esquema rígido previo. A lo largo
del informe se explica el modelo elegido, las operaciones implementadas, las consultas
diseñadas y el análisis del aporte real de la IA en el proceso.

---

## 3. Tipo de NoSQL elegido: base documental (MongoDB)

Las bases de datos NoSQL surgen como alternativa al modelo relacional cuando se necesita
flexibilidad de esquema, escalabilidad horizontal o estructuras de datos que no encajan
cómodamente en tablas. Dentro de las familias NoSQL (documental, grafos, clave-valor y
columnar), se eligió la **documental**, representada por **MongoDB**.

Una base documental guarda la información en **documentos** con formato tipo JSON
(internamente BSON), agrupados en **colecciones**. Cada documento puede tener su propia
estructura, admite campos anidados y arreglos, y no obliga a que todos los registros de
una colección compartan exactamente los mismos campos.

**¿Por qué MongoDB para este caso?**

- Una película tiene atributos que varían (algunos arreglos como `generos`, campos
  opcionales como `idioma`); el esquema flexible se ajusta sin migraciones.
- El historial de visualización de un usuario es una lista que crece; embeberla dentro
  del propio documento del usuario evita uniones costosas y refleja cómo se consulta en
  la práctica (al abrir un perfil se quiere ver su historial completo).
- Las consultas y agregaciones de MongoDB son expresivas y suficientes para los reportes
  típicos de una plataforma de streaming (top de contenidos, filtros por género, usuarios
  más activos).
- Es la base NoSQL con mayor documentación y herramientas, lo que reduce el riesgo de
  depender de respuestas no verificables de la IA.

---

## 4. Modelo de datos implementado

El modelo se compone de dos colecciones:

### Colección `peliculas`

```json
{
  "_id": 1,
  "titulo": "Inception",
  "generos": ["Sci-Fi", "Acción"],
  "anio": 2010,
  "duracion": 148,
  "rating": 8.8,
  "idioma": "EN"
}
```

### Colección `usuarios` (con historial embebido)

```json
{
  "_id": 101,
  "nombre": "Ana López",
  "pais": "GT",
  "plan": "Premium",
  "edad": 24,
  "historial": [
    { "peliculaId": 1, "vistaEl": "2026-06-01", "puntuacion": 9 },
    { "peliculaId": 6, "vistaEl": "2026-06-03", "puntuacion": 8 }
  ]
}
```

**Decisión de diseño clave — embeber vs. referenciar.** El historial se guardó *embebido*
dentro de cada usuario en lugar de crear una tercera colección de visualizaciones. Esto
es apropiado porque el historial casi siempre se consulta junto con el usuario y su
tamaño es acotado. Para relacionar una visualización con los datos completos de la
película se usa `peliculaId`, que apunta al `_id` de la colección `peliculas`. Esta mezcla
de embeber (historial) y referenciar (película) es una práctica habitual y recomendada en
el modelado documental.

> *Nota:* en este trabajo las fechas se almacenaron como texto `"AAAA-MM-DD"` por
> simplicidad de lectura. En un entorno productivo convendría usar el tipo `Date` nativo
> de MongoDB para permitir comparaciones y ordenamientos por fecha.

---

## 5. Uso de la IA y análisis crítico

### 5.1 Interacciones realizadas

Se utilizó **Claude (Anthropic)** como asistente técnico. Las consultas principales
fueron:

1. *"Proponé un modelo NoSQL documental (MongoDB) para una plataforma de streaming con
   películas y usuarios."*
2. *"Generá 3 consultas relevantes en MongoDB para ese modelo."*
3. *"¿Cómo optimizarías esas consultas? ¿Qué índices conviene crear?"*

> **[ESPACIO PARA CAPTURAS]** — Insertar aquí las imágenes de las conversaciones con la IA.

### 5.2 Análisis crítico de las respuestas

La IA fue útil para acelerar el punto de partida: propuso una estructura razonable de
colecciones y una sintaxis de consultas en general correcta. Sin embargo, **no todo lo
que generó era correcto o adecuado**, y fue necesario revisarlo con criterio propio:

| # | Lo que propuso la IA | Problema detectado | Corrección manual aplicada |
| --- | --- | --- | --- |
| 1 | Una consulta de "top películas" con `find().sort({rating:-1})` sin límite. | Devuelve **todo** el catálogo, no un top; ineficiente y poco útil como reporte. | Se agregó `.limit(5)` para obtener un verdadero Top 5. |
| 2 | Modelar todo (películas, usuarios y vistas) en una sola colección. | Mezcla entidades distintas, genera duplicación y consultas confusas. | Se separó en `peliculas` y `usuarios`, embebiendo solo el historial dentro del usuario. |
| 3 | Sugerir índices "para todo" sin justificar. | Crear índices innecesarios penaliza la escritura y ocupa espacio. | Se creó **solo** `createIndex({ rating: -1 })`, que es el campo realmente usado para ordenar en la consulta más frecuente. |

### 5.3 Correcciones realizadas manualmente

Además de lo anterior, se validó cada operador contra la documentación oficial de
MongoDB, se probó el script completo en `mongosh` para confirmar que corre sin errores y
se ajustaron los datos de ejemplo para que las consultas devolvieran resultados
significativos (por ejemplo, asegurar que existieran varias películas de Sci-Fi
posteriores a 2010 para que la Consulta 2 no saliera vacía).

---

## 6. Operaciones CRUD implementadas

Las cuatro operaciones básicas se demostraron sobre la colección `peliculas`:

```javascript
// CREATE — agregar una película
db.peliculas.insertOne(
  { _id: 13, titulo: "Dune", generos: ["Sci-Fi","Aventura"], anio: 2021,
    duracion: 155, rating: 8.0, idioma: "EN" }
);

// READ — leer una película por título
db.peliculas.findOne({ titulo: "Inception" });

// UPDATE — actualizar el rating
db.peliculas.updateOne(
  { titulo: "Dune" },
  { $set: { rating: 8.2 } }
);

// DELETE — eliminar la película de prueba
db.peliculas.deleteOne({ titulo: "Dune" });
```

> **[ESPACIO PARA CAPTURAS]** — Insertar aquí la evidencia de ejecución de cada operación.

---

## 7. Consultas utilizadas

### Consulta 1 — Top 5 películas mejor calificadas

```javascript
db.peliculas.find({}, { _id: 0, titulo: 1, rating: 1 })
            .sort({ rating: -1 })
            .limit(5);
```

Ordena el catálogo por `rating` de mayor a menor y devuelve solo las cinco primeras.
Responde a una necesidad real de la plataforma: mostrar el contenido destacado.

### Consulta 2 — Películas de Sci-Fi estrenadas después de 2010

```javascript
db.peliculas.find(
  { generos: "Sci-Fi", anio: { $gt: 2010 } },
  { _id: 0, titulo: 1, anio: 1 }
);
```

Combina un filtro sobre un arreglo (`generos: "Sci-Fi"` busca dentro del arreglo) con un
operador de comparación (`$gt`). Útil para una sección de "novedades por género".

### Consulta 3 — Usuarios más activos (agregación)

```javascript
db.usuarios.aggregate([
  { $project: { _id: 0, nombre: 1, vistas: { $size: "$historial" } } },
  { $sort: { vistas: -1 } },
  { $limit: 5 }
]);
```

Usa el *aggregation framework*: `$project` calcula el tamaño del arreglo `historial` con
`$size`, luego se ordena y se limita. Identifica a los usuarios que más consumen
contenido, dato clave para campañas o recomendaciones.

> **[ESPACIO PARA CAPTURAS]** — Insertar aquí la evidencia de ejecución de las tres consultas.

---

## 8. Reflexión individual

**¿La IA ayudó realmente al desarrollo?**
Sí, principalmente en la fase inicial: aceleró el diseño de las colecciones y dio una
base de sintaxis correcta para las consultas. Funcionó como un buen punto de partida,
pero no como una solución lista para entregar.

**¿Qué errores detectó?**
Se detectaron consultas sin `limit` que no cumplían su propósito, una propuesta de modelo
que mezclaba todas las entidades en una sola colección y recomendaciones de índices sin
justificación. (Ver detalle en la sección 5.2.)

**¿Qué conocimientos humanos fueron necesarios para corregir la solución?**
Fue indispensable comprender el modelo de datos documental (cuándo embeber y cuándo
referenciar), conocer los operadores de MongoDB (`$gt`, `$size`, `$project`), y tener
criterio de diseño para decidir la estructura de las colecciones y los índices
realmente necesarios.

**¿Qué riesgos existen al depender totalmente de la IA?**
Entregar código que no corre o que usa sintaxis inventada; tomar malas decisiones de
diseño que escalan mal; perder la oportunidad de aprender; y, en contextos reales,
introducir problemas de rendimiento o seguridad por confiar sin verificar. La IA es un
asistente, no un reemplazo del criterio técnico.

---

## 9. Conclusiones

- El modelo documental de MongoDB se ajusta bien a una plataforma de streaming gracias a
  su esquema flexible y a la posibilidad de embeber estructuras como el historial de
  visualización.
- Se implementó una base funcional con 22 registros, operaciones CRUD completas y tres
  consultas relevantes, incluyendo una agregación.
- La IA fue un apoyo valioso para acelerar el trabajo, pero **toda su salida requirió
  verificación**: hubo errores de eficiencia, de diseño y de justificación que solo el
  criterio humano pudo corregir.
- La principal lección es metodológica: la IA potencia el desarrollo cuando quien la usa
  tiene el conocimiento para evaluar y corregir lo que produce.

---

## 10. Rúbrica de calificación

| Criterio | Descripción | Punteo |
| --- | --- | --- |
| Investigación | Diseño correcto del modelo NoSQL y justificación del tipo elegido. | 30 |
| Implementación | Base funcional, ≥20 registros, CRUD completo, 3 consultas y evidencias de ejecución. | 40 |
| Informe | Documentación, análisis crítico de la IA y conclusiones. | 30 |
| **TOTAL** |  | **100** |

---

## 11. Anexos

- **`script_mongodb.js`** — script completo ejecutable en `mongosh` (creación, inserción,
  CRUD y consultas).
- Capturas de ejecución (CRUD y consultas).
- Capturas de las conversaciones con la IA.
