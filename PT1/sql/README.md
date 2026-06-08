# 📦 EVENTCORE — Manual de la base de datos

Esquema relacional del sistema de gestión de eventos y conferencias (Proyecto AYD1, Escuela de
Vacaciones 2026). El DDL está **partido en archivos numerados** que se ejecutan **en orden**.

- **Motor:** SQL Server 2016+ (probado en `azure-sql-edge` sobre Apple Silicon).
- **Tamaño del modelo:** 21 tablas · 26 claves foráneas · 1 relación N:M.
- **Sin `GO`:** todos los scripts usan `;` como separador, para correr directo en **DBeaver**.

---

## 🗂️ Archivos y orden de ejecución

Ejecutá **del 01 al 08, en orden**. Cada archivo empieza con `USE EventCore;`, así que es seguro
correrlos uno por uno.

| # | Archivo | Crea / hace | Depende de |
|--:|---------|-------------|------------|
| 1 | `01_database.sql` | Crea la base `EventCore` (idempotente) y entra en ella | — |
| 2 | `02_lookups.sql` | Catálogos: `Roles`, los 4 `Estados…`, `Dias`, `Horarios` | 01 |
| 3 | `03_catalogos_base.sql` | `Usuarios`, `Ponentes`, `Salas`, `TiposEntrada` | 02 |
| 4 | `04_nucleo.sql` | `Eventos`, `Sesiones` (agendada por `DiaID`+`HorarioID`), `MaterialesRecurso` | 02, 03 |
| 5 | `05_inscripciones.sql` | `Inscripciones`, `InscripcionSesion` (puente N:M), `CodigosInvitacion` | 03, 04 |
| 6 | `06_pagos_cancelaciones.sql` | `Tarjetas`, `Pagos`, `SolicitudesCancelacion` | 03, 05 |
| 7 | `07_bitacora.sql` | `LogActividad` | 03 |
| 8 | `08_seeds.sql` | Llena los catálogos (roles, estados, días, horarios) | 02 |

**Auxiliares (no van en el orden normal):**

| Archivo | Para qué | Cuándo usarlo |
|---------|----------|---------------|
| `drops.sql` | Borra las 21 tablas en orden inverso a las FKs (primero los hijos) | Para "empezar de cero" antes de re-correr todo |
| `checks.sql` | Catálogo re-ejecutable de todas las reglas `CHECK` (como `ALTER TABLE`) | Referencia / re-aplicar una validación suelta |

> Los `CHECK` ya están **incluidos en línea** en cada tabla de los archivos 02–07.
> `checks.sql` los reúne aparte como documentación y respaldo re-aplicable.

---

## ⚙️ Requisitos previos

1. **Contenedor corriendo.** Imagen `mcr.microsoft.com/azure-sql-edge`. Ejemplo:
   ```bash
   docker run -e "ACCEPT_EULA=1" -e "MSSQL_SA_PASSWORD=TuPassword_Fuerte1" \
     -p 1433:1433 --name eventcore-db -d mcr.microsoft.com/azure-sql-edge:latest
   ```
2. **DBeaver** instalado, con una conexión a SQL Server hacia ese contenedor.

### Conexión en DBeaver (los 3 puntos que más fallan)

| Campo | Valor |
|-------|-------|
| **Host** | `localhost` si DBeaver corre en la misma máquina/VM que Docker; la **IP de la VM** si DBeaver está en la Mac y el contenedor en Debian |
| **Port** | `1433` |
| **Usuario / Pass** | `sa` / la contraseña del contenedor |
| **SSL** | ✅ activar **"Trust server certificate"** (driver moderno cifra por defecto y rebota con cert autofirmado) |

---

## ▶️ Cómo correr los scripts (paso a paso)

1. Conectá DBeaver al contenedor.
2. Abrí `01_database.sql` y ejecutá **todo el archivo** con **"Execute SQL Script" → `Alt+X` (`⌥X` en Mac)**.
   - ⚠️ **No uses `⌘+Enter`/`Ctrl+Enter`**: eso corre una sola instrucción, no el archivo entero.
3. En la barra de DBeaver, dejá la **base activa** en `EventCore` (refrescá con `F5` si no aparece en el árbol).
4. Repetí el paso 2 con `02`, `03`, `04`, `05`, `06`, `07` y `08`, **en ese orden**.
5. Al terminar `08_seeds.sql`, en la pestaña **Results** vas a ver el conteo de filas por catálogo.

### Verificar que quedó todo
```sql
USE EventCore;

-- ¿Las 21 tablas?
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = N'BASE TABLE' ORDER BY TABLE_NAME;

-- ¿Las 26 FKs?
SELECT OBJECT_NAME(parent_object_id) AS TablaHijo, name AS FK,
       OBJECT_NAME(referenced_object_id) AS TablaPadre
FROM sys.foreign_keys ORDER BY TablaHijo;
```

---

## 🔄 Empezar de cero (reset)

Si algo salió mal y querés reinstalar limpio:

1. Ejecutá `drops.sql` con `Alt+X` (borra las 21 tablas; no toca la base).
2. Volvé a correr `02` … `08` en orden.

Para borrar **la base entera**:
```sql
USE master;
DROP DATABASE IF EXISTS EventCore;
```

---

## 🧠 Notas de diseño (por qué está así)

- **Lookup vs CHECK.** Los conjuntos que pueden crecer (estados, roles) son **tablas lookup** con
  FK y extensibles. Los enums fijos (modalidad, método de pago, tipo de tarjeta) son **CHECK**,
  porque no cambian nunca.
- **`Dias` y `Horarios`** son catálogos **predefinidos**: el frontend asigna día y hora a una
  sesión **por id** (`DiaID`, `HorarioID`), no con texto libre. `Horarios` usa `TIME` para poder
  validar `HoraFin > HoraInicio`.
- **PK explícita vs IDENTITY.** Los catálogos sembrados a mano usan PK fija (id estable y citable);
  las tablas de negocio usan `IDENTITY` (autonumérico).
- **Borrado lógico (`Activo`)** en los maestros: se desactivan, no se eliminan.
- **Un índice por cada FK:** las FKs no se indexan solas; cada una tiene su `IX_…` para acelerar joins.

> El diccionario de datos completo y el diagrama ER están en la carpeta superior:
> `../eventcore-tablas.md`, `../eventcore-relaciones.md`, `../entidades-y-foraneas.md`, `../eventcore-er.*`.
