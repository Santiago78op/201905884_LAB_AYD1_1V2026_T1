// ============================================================
//  TAREA #2 - Bases de Datos 2
//  NoSQL Documental: MongoDB
//  Caso de estudio: Plataforma de Streaming
//  Autor: Joshua Alexander Vasquez del Aguila
//
//  CÓMO EJECUTAR (en la otra PC, dentro de mongosh):
//    mongosh
//    load("script_mongodb.js")
//  ...o copiá/pegá por bloques en la terminal de mongosh.
// ============================================================

// ---- 0) Crear / usar la base de datos --------------------
use streamingDB;

// Limpiamos por si se corre dos veces (idempotente)
db.peliculas.drop();
db.usuarios.drop();

// ============================================================
//  1) INSERCIÓN DE REGISTROS  (mínimo 20 -> aquí hay 22)
// ============================================================

// ---- Colección: peliculas (12 documentos) ----------------
db.peliculas.insertMany([
  { _id: 1,  titulo: "Inception",            generos: ["Sci-Fi", "Acción"],     anio: 2010, duracion: 148, rating: 8.8, idioma: "EN" },
  { _id: 2,  titulo: "The Matrix",           generos: ["Sci-Fi", "Acción"],     anio: 1999, duracion: 136, rating: 8.7, idioma: "EN" },
  { _id: 3,  titulo: "Parasite",             generos: ["Drama", "Thriller"],    anio: 2019, duracion: 132, rating: 8.5, idioma: "KO" },
  { _id: 4,  titulo: "Coco",                 generos: ["Animación", "Familia"], anio: 2017, duracion: 105, rating: 8.4, idioma: "ES" },
  { _id: 5,  titulo: "The Godfather",        generos: ["Drama", "Crimen"],      anio: 1972, duracion: 175, rating: 9.2, idioma: "EN" },
  { _id: 6,  titulo: "Interstellar",         generos: ["Sci-Fi", "Drama"],      anio: 2014, duracion: 169, rating: 8.6, idioma: "EN" },
  { _id: 7,  titulo: "Roma",                 generos: ["Drama"],                anio: 2018, duracion: 135, rating: 7.7, idioma: "ES" },
  { _id: 8,  titulo: "Spirited Away",        generos: ["Animación", "Fantasía"],anio: 2001, duracion: 125, rating: 8.6, idioma: "JA" },
  { _id: 9,  titulo: "Joker",                generos: ["Drama", "Crimen"],      anio: 2019, duracion: 122, rating: 8.4, idioma: "EN" },
  { _id: 10, titulo: "Gravity",              generos: ["Sci-Fi", "Thriller"],   anio: 2013, duracion: 91,  rating: 7.7, idioma: "EN" },
  { _id: 11, titulo: "El Laberinto del Fauno",generos:["Fantasía","Drama"],     anio: 2006, duracion: 118, rating: 8.2, idioma: "ES" },
  { _id: 12, titulo: "Whiplash",             generos: ["Drama", "Música"],      anio: 2014, duracion: 106, rating: 8.5, idioma: "EN" }
]);

// ---- Colección: usuarios (10 documentos) -----------------
// Cada usuario lleva embebido su historial de visualizaciones.
db.usuarios.insertMany([
  { _id: 101, nombre: "Ana López",     pais: "GT", plan: "Premium",  edad: 24,
    historial: [ { peliculaId: 1, vistaEl: "2026-06-01", puntuacion: 9 },
                 { peliculaId: 6, vistaEl: "2026-06-03", puntuacion: 8 } ] },
  { _id: 102, nombre: "Luis Pérez",    pais: "MX", plan: "Básico",   edad: 31,
    historial: [ { peliculaId: 2, vistaEl: "2026-06-02", puntuacion: 10 } ] },
  { _id: 103, nombre: "Marta Gómez",   pais: "GT", plan: "Premium",  edad: 28,
    historial: [ { peliculaId: 3, vistaEl: "2026-06-04", puntuacion: 9 },
                 { peliculaId: 9, vistaEl: "2026-06-05", puntuacion: 7 },
                 { peliculaId: 5, vistaEl: "2026-06-06", puntuacion: 10 } ] },
  { _id: 104, nombre: "Carlos Ruiz",   pais: "ES", plan: "Estándar", edad: 40,
    historial: [ { peliculaId: 4, vistaEl: "2026-06-01", puntuacion: 8 } ] },
  { _id: 105, nombre: "Sofía Mena",    pais: "GT", plan: "Básico",   edad: 19,
    historial: [ { peliculaId: 8, vistaEl: "2026-06-07", puntuacion: 9 },
                 { peliculaId: 4, vistaEl: "2026-06-08", puntuacion: 8 } ] },
  { _id: 106, nombre: "Diego Castro",  pais: "AR", plan: "Premium",  edad: 35,
    historial: [ { peliculaId: 5, vistaEl: "2026-06-02", puntuacion: 10 },
                 { peliculaId: 6, vistaEl: "2026-06-09", puntuacion: 9 } ] },
  { _id: 107, nombre: "Elena Ríos",    pais: "MX", plan: "Estándar", edad: 27,
    historial: [ { peliculaId: 12, vistaEl: "2026-06-03", puntuacion: 9 } ] },
  { _id: 108, nombre: "Pablo Díaz",    pais: "GT", plan: "Premium",  edad: 22,
    historial: [ { peliculaId: 1, vistaEl: "2026-06-10", puntuacion: 8 },
                 { peliculaId: 2, vistaEl: "2026-06-11", puntuacion: 9 } ] },
  { _id: 109, nombre: "Lucía Fernández",pais:"ES",  plan: "Básico",   edad: 33,
    historial: [ { peliculaId: 11, vistaEl: "2026-06-05", puntuacion: 8 } ] },
  { _id: 110, nombre: "Mario Torres",  pais: "AR", plan: "Estándar", edad: 45,
    historial: [ { peliculaId: 7, vistaEl: "2026-06-06", puntuacion: 7 },
                 { peliculaId: 3, vistaEl: "2026-06-12", puntuacion: 9 } ] }
]);

print("== Registros insertados ==");
print("peliculas: " + db.peliculas.countDocuments());
print("usuarios : " + db.usuarios.countDocuments());

// ============================================================
//  2) OPERACIONES CRUD
// ============================================================

// ---- CREATE: agregar una película nueva ------------------
db.peliculas.insertOne(
  { _id: 13, titulo: "Dune", generos: ["Sci-Fi","Aventura"], anio: 2021, duracion: 155, rating: 8.0, idioma: "EN" }
);
print("\n[CREATE] Película 'Dune' insertada.");

// ---- READ: leer una película por su título ---------------
print("\n[READ] Buscar 'Inception':");
printjson( db.peliculas.findOne({ titulo: "Inception" }) );

// ---- UPDATE: corregir/actualizar el rating de una peli ---
db.peliculas.updateOne(
  { titulo: "Dune" },
  { $set: { rating: 8.2 } }
);
print("\n[UPDATE] Rating de 'Dune' actualizado a 8.2:");
printjson( db.peliculas.findOne({ titulo: "Dune" }) );

// ---- DELETE: eliminar la película de prueba --------------
db.peliculas.deleteOne({ titulo: "Dune" });
print("\n[DELETE] 'Dune' eliminada. Total peliculas: " + db.peliculas.countDocuments());

// ============================================================
//  3) TRES CONSULTAS RELEVANTES
// ============================================================

// ---- Consulta 1: Top 5 películas mejor calificadas -------
print("\n[CONSULTA 1] Top 5 películas por rating:");
db.peliculas.find({}, { _id: 0, titulo: 1, rating: 1 })
            .sort({ rating: -1 })
            .limit(5)
            .forEach(p => print("  " + p.titulo + "  ->  " + p.rating));

// ---- Consulta 2: Películas de Sci-Fi posteriores a 2010 --
print("\n[CONSULTA 2] Sci-Fi estrenadas después de 2010:");
db.peliculas.find(
  { generos: "Sci-Fi", anio: { $gt: 2010 } },
  { _id: 0, titulo: 1, anio: 1 }
).forEach(p => print("  " + p.titulo + " (" + p.anio + ")"));

// ---- Consulta 3: Usuarios más activos (agregación) -------
// Cuenta cuántas películas tiene cada usuario en su historial.
print("\n[CONSULTA 3] Usuarios más activos (más visualizaciones):");
db.usuarios.aggregate([
  { $project: { _id: 0, nombre: 1, vistas: { $size: "$historial" } } },
  { $sort: { vistas: -1 } },
  { $limit: 5 }
]).forEach(u => print("  " + u.nombre + "  ->  " + u.vistas + " vistas"));

// (Consulta extra opcional) Cuántos usuarios hay por plan:
print("\n[EXTRA] Cantidad de usuarios por plan:");
db.usuarios.aggregate([
  { $group: { _id: "$plan", total: { $sum: 1 } } },
  { $sort: { total: -1 } }
]).forEach(g => print("  " + g._id + ": " + g.total));

print("\n== FIN DEL SCRIPT ==");
