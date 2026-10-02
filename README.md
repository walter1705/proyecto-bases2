# TurismoUQ

Proyecto integrador de bases de datos para gestionar alojamientos turísticos del
Quindío. El modelo registra municipios, alojamientos, habitaciones, temporadas,
tarifas, clientes, reservas, servicios, pagos y reseñas.

## Estructura

- `database/01_ddl.sql`: crea las tablas, restricciones y relaciones del modelo.
- `database/02_consultas_analiticas.sql`: contiene reportes analíticos con
  `PIVOT`, `ROLLUP`, funciones de ventana, una consulta parametrizada, una vista
  materializada y `UNPIVOT`.
- `data/poblado_datos.py`: genera datos de prueba en español y los inserta en
  Oracle mediante cargas por lotes.
- `data/requirements.txt`: dependencias de Python para poblar la base.

## Requisitos

- Oracle Database con permisos para crear y eliminar las tablas del proyecto.
- Python 3.10 o posterior.
- Dependencias de `data/requirements.txt`.
- Un archivo `data/config.py` con la función `get_connection()`, que debe
  devolver una conexión `oracledb`.

Instala las dependencias con:

```bash
pip install -r data/requirements.txt
```

## Uso

1. Configura las credenciales de Oracle en `data/config.py`.
2. Ejecuta `database/01_ddl.sql` desde un cliente Oracle.
3. Ejecuta `data/poblado_datos.py` para cargar los datos de prueba.
4. Ejecuta `database/02_consultas_analiticas.sql` para consultar los reportes.

La carga crea 12 municipios, 60 alojamientos, 400 habitaciones, 3.000
clientes, 25.000 reservas y sus pagos, además de temporadas, tarifas y
servicios. El script de carga usa valores aleatorios, por lo que los resultados
numéricos cambian en cada ejecución.
