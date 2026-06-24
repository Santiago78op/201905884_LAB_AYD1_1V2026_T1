# Guía paso a paso — Tarea #2 (Bases de Datos 2)

**Combinación elegida:** MongoDB (NoSQL documental) + caso *Plataforma de streaming*
**IA citada:** Claude (Anthropic) / la que uses
**Entrega:** 26/06/2026

> Hacés TODO en la otra PC. Esta guía + el archivo `script_mongodb.js` es lo único que necesitás llevar.

---

## PASO 0 — Instalar MongoDB en la otra PC (una sola vez)

1. Descargá **MongoDB Community Server** desde: https://www.mongodb.com/try/download/community
   - Sistema operativo: Windows. Package: `msi`. Dale *Download*.
2. Ejecutá el `.msi`. En el asistente:
   - Elegí **"Complete"**.
   - Dejá marcado **"Install MongoDB as a Service"** (así arranca solo).
   - Marcá también **"Install MongoDB Compass"** (es una interfaz gráfica, sirve para tomar capturas bonitas).
3. Descargá e instalá **mongosh** (la terminal de MongoDB) desde:
   https://www.mongodb.com/try/download/shell
   - Descomprimí y, para llamarlo fácil, copiá `mongosh.exe` a una carpeta que esté en el PATH (o ejecutalo desde su carpeta).

> ✅ Verificación: abrí una terminal (PowerShell o CMD) y escribí `mongosh`. Si entra a un prompt `test>`, todo está listo. Salí con `exit`.

---

## PASO 1 — Cargar la base y los datos

1. Copiá el archivo `script_mongodb.js` a la otra PC (por ejemplo al Escritorio).
2. Abrí PowerShell **en esa carpeta** y entrá a la shell:
   ```powershell
   mongosh
   ```
3. Cargá el script (ajustá la ruta si hace falta):
   ```javascript
   load("script_mongodb.js")
   ```
   Esto crea la base `streamingDB`, inserta **22 registros**, ejecuta el **CRUD** y las **3 consultas**, imprimiendo todo en pantalla.

> 💡 Alternativa recomendada para capturas: en lugar de `load()`, **copiá y pegá los bloques uno por uno**. Así cada operación sale en pantalla por separado y tomás una captura de cada una (queda más claro en el informe).

---

## PASO 2 — Tomar las evidencias (capturas)

Necesitás capturas de pantalla de:

| # | Qué capturar | Comando que lo genera |
|---|---|---|
| 1 | Conteo de registros insertados (≥20) | `db.peliculas.countDocuments()` y `db.usuarios.countDocuments()` |
| 2 | CREATE (insertar Dune) | bloque `[CREATE]` |
| 3 | READ (buscar Inception) | bloque `[READ]` |
| 4 | UPDATE (cambiar rating) | bloque `[UPDATE]` |
| 5 | DELETE (borrar Dune) | bloque `[DELETE]` |
| 6 | Consulta 1 (top 5 rating) | bloque `[CONSULTA 1]` |
| 7 | Consulta 2 (Sci-Fi > 2010) | bloque `[CONSULTA 2]` |
| 8 | Consulta 3 (usuarios más activos) | bloque `[CONSULTA 3]` |

> Para ver los datos lindos en Compass: abrí Compass → conectá a `mongodb://localhost:27017` → base `streamingDB` → colecciones `peliculas` y `usuarios`. Tomá una captura de cada colección.

---

## PASO 3 — Conversación con la IA (lo que pide la tarea)

La tarea EXIGE que muestres que usaste IA y que la **evaluaste críticamente**. Hacé esto:

1. Abrí Claude/ChatGPT y pedile, por ejemplo:
   - *"Proponé un modelo NoSQL documental (MongoDB) para una plataforma de streaming con películas y usuarios."*
   - *"Generá 3 consultas relevantes en MongoDB para ese modelo."*
   - *"¿Cómo optimizarías estas consultas con índices?"*
2. **Tomá capturas** de esas conversaciones.
3. **Encontrá al menos 1 error o mejora** y corregilo a mano (esto vale puntos). Ideas reales que casi siempre aparecen:
   - La IA suele sugerir `db.coll.find().sort()` sin `limit()` → vos agregás el `limit`.
   - A veces propone guardar todo en una sola colección gigante → vos justificás separar `peliculas` y `usuarios`.
   - Puede inventar operadores o sintaxis vieja → vos lo verificás contra la documentación.
   - Para optimizar, la consulta 1 mejora con un índice: `db.peliculas.createIndex({ rating: -1 })`.
4. Documentá: *"La IA propuso X, detecté el problema Y, lo corregí así Z."*

---

## PASO 4 — Escribir el informe técnico (30 pts)

Estructura (creá un documento Word/PDF):

1. **Carátula** (universidad, curso, tu nombre, fecha).
2. **Marco Formativo** (lo pide el punto 1 de la tarea):
   - *Valor:* Honestidad académica → "Validé y cité todo lo generado por IA en lugar de copiarlo sin revisar".
   - *Competencia general:* Diseñar e implementar soluciones de bases de datos.
   - *Competencia específica:* Modelar y operar bases NoSQL con apoyo de herramientas de IA.
   - *Objetivos:* (los 4 que ya trae la tarea).
3. **Introducción** — de qué trata el trabajo.
4. **Tipo de NoSQL elegido** — explicá qué es una base documental y por qué MongoDB.
5. **Capturas de las interacciones con IA** (Paso 3).
6. **Análisis crítico** — qué estuvo bien, qué estuvo mal en lo que dio la IA.
7. **Correcciones manuales** — lo que arreglaste vos.
8. **Modelo implementado** — explicá las colecciones `peliculas` y `usuarios` y por qué embebiste el `historial` dentro de `usuarios`.
9. **Consultas utilizadas** — pegá las 3 consultas y explicá qué hace cada una.
10. **Conclusiones**.

---

## PASO 5 — Reflexión individual (30 pts)

Respondé honestamente (2–4 líneas cada una):

- **¿La IA ayudó realmente?** — Sí, aceleró el diseño inicial y la sintaxis, pero hubo que validar todo.
- **¿Qué errores detectó?** — (el/los que encontraste en el Paso 3).
- **¿Qué conocimiento humano fue necesario?** — entender el modelo de datos, los operadores de MongoDB, y decidir cómo estructurar las colecciones.
- **¿Qué riesgos hay al depender 100% de la IA?** — código que no corre, sintaxis inventada, decisiones de diseño malas, dependencia sin aprendizaje, problemas de seguridad/datos.

---

## PASO 6 — Redactar la rúbrica (la tarea te pide escribirla vos)

Pegá esta tabla en el informe (podés ajustarla):

| Criterio | Descripción | Punteo |
|---|---|---|
| Investigación | Diseño correcto del modelo NoSQL y justificación del tipo elegido | 30 |
| Implementación | Base funcional, ≥20 registros, CRUD completo, 3 consultas y evidencias | 40 |
| Informe | Documentación, análisis crítico de la IA y conclusiones | 30 |
| **TOTAL** |  | **100** |

---

## Checklist final antes de entregar

- [ ] Base `streamingDB` creada y funcional
- [ ] ≥ 20 registros insertados (tenés 22)
- [ ] CRUD: Create, Read, Update, Delete demostrados
- [ ] 3 consultas relevantes ejecutadas
- [ ] Capturas de ejecución (Paso 2)
- [ ] Capturas de la conversación con IA (Paso 3)
- [ ] Al menos 1 error/mejora detectado y corregido a mano
- [ ] Informe técnico completo (Paso 4)
- [ ] Reflexión individual (Paso 5)
- [ ] Rúbrica redactada (Paso 6)
- [ ] Citaste qué herramienta de IA usaste
