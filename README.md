# TurismoUQ

Proyecto integrador de bases de datos para gestionar alojamientos turísticos del
Quindío. El modelo registra municipios, alojamientos, habitaciones, temporadas,
tarifas, clientes, reservas, servicios, pagos y reseñas.

## Estructura

- `db/01_ddl.sql`: crea las tablas, restricciones, comentarios y relaciones del modelo.
- `db/02_consultas_analiticas.sql`: contiene los reportes analíticos numerados C1--C8.
- `db/03_carga_datos.sql`: carga autónoma para Oracle, sin depender de Python.
- `db/04_paquete_plsql.sql`: función, procedimiento y liquidación mensual.
- `db/05_triggers.sql`: auditoría de tarifas y control de solapamientos.
- `db/06_tablespace_vista_materializada.sql`: tablespace administrativo y ocupación mensual.
- `db/06_tablespace_admin.sql`: creación del tablespace como SYS/SYSTEM.
- `db/07_pruebas_entrega2.sql`: pruebas reproducibles de la segunda entrega.
- `docs/entrega2_documentacion.md`: documentación técnica de la entrega.
  `PIVOT`, `ROLLUP`, funciones de ventana, una consulta parametrizada, una vista
  materializada y `UNPIVOT`.
- `data/poblado_datos.py`: genera datos de prueba en español y los inserta en
  Oracle mediante cargas por lotes.
- `data/requirements.txt`: dependencias de Python para poblar la base.

## Requisitos

- Oracle Database con permisos para crear y eliminar las tablas del proyecto.
- Python 3.10 o posterior.
- Dependencias de `data/requirements.txt`.
- Variables de entorno `ORACLE_USER`, `ORACLE_PASSWORD` y `ORACLE_DSN` para
  que `data/config.py` pueda abrir la conexión.

Instala las dependencias con:

```bash
pip install -r data/requirements.txt
```

## Uso

1. Define `ORACLE_USER`, `ORACLE_PASSWORD` y `ORACLE_DSN` en el entorno.
2. Ejecuta `db/01_ddl.sql` desde un cliente Oracle.
3. Ejecuta `db/03_carga_datos.sql` para una carga 100% SQL, o
   `python data/poblado_datos.py` para la carga por lotes de Python.
4. (Opcional, como SYS/SYSTEM) Ajusta y ejecuta `db/06_tablespace_admin.sql`.
5. Ejecuta `db/04_paquete_plsql.sql`, `db/05_triggers.sql` y
   `db/06_tablespace_vista_materializada.sql`.
6. Ejecuta `db/02_consultas_analiticas.sql` para consultar los reportes.
7. Ejecuta `db/07_pruebas_entrega2.sql` para verificar la segunda entrega.

La carga crea 12 municipios, 60 alojamientos, 400 habitaciones, 3.000
clientes, 25.000 reservas y sus pagos, además de temporadas, tarifas, servicios,
usuarios y reseñas. La distribución de habitaciones, reservas, calificaciones y
estados es deliberadamente asimétrica. Las consultas C2, C3, C4, C6, C7 y C8
excluyen reservas canceladas de los ingresos.
