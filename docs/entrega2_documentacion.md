# Segunda entrega PL/SQL - TurismoUQ

## Integrantes y repositorio

- Integrante 1: ______________________________
- Integrante 2: ______________________________
- Integrante 3: ______________________________
- Repositorio GitHub: ________________________

## Objetivo

Esta entrega agrega la capa PL/SQL sobre el modelo relacional de la primera
entrega. Se implementan cálculo de estadías, creación validada de reservas,
liquidación mensual, paquete, auditoría, control de disponibilidad, tablespace
histórico y ocupación mensual precalculada.

## Componentes

- `04_paquete_plsql.sql`: `PKG_TURISMOUQ` expone `FN_VALOR_ESTADIA`,
  `SP_CREAR_RESERVA` y `SP_LIQUIDACION_MENSUAL`.
- `05_triggers.sql`: auditoría de `TARIFA` mediante trigger compuesto y
  control de solapamientos sin consultar la tabla mutante durante la fase por
  fila.
- `06_tablespace_vista_materializada.sql`: comando administrativo parametrizable
  para el tablespace y vista `MV_OCUPACION_MENSUAL`.
- `06_tablespace_admin.sql`: creación efectiva del tablespace con una cuenta
  administrativa y una ruta configurable.
- `07_pruebas_entrega2.sql`: pruebas positivas y negativas con `DBMS_OUTPUT`,
  consultas de estado y `ROLLBACK`.

## Reglas de negocio

`FN_VALOR_ESTADIA` cobra desde el check-in hasta la noche anterior al
check-out. Si hay temporadas superpuestas, primero se elige una temporada cuyo
nombre no empiece por `TEMPORADA BAJA`; luego la de menor duración y finalmente
el menor `ID_TEMPORADA`. Así se evita duplicar cobros y se priorizan temporadas
especiales.

`SP_CREAR_RESERVA` valida cliente, habitación, intervalo, capacidad, tarifa y
disponibilidad. El número de huéspedes se recibe como parámetro porque el
esquema original no lo persiste; la capacidad se valida contra `HABITACION`.
El procedimiento no hace `COMMIT`, por lo que la transacción queda bajo control
del llamador.

La liquidación considera únicamente reservas `CONFIRMADA` y `FINALIZADA`.
Cuando una estadía atraviesa un mes, distribuye el subtotal proporcionalmente
por número de noches. No combina pagos y servicios, evitando duplicación.

El trigger de auditoría captura usuario, instante, operación y valores anterior
y nuevo en `AUDITORIA_TARIFA`. El control de disponibilidad usa sección por
fila para guardar identificadores y sección posterior a la sentencia para
consultar las tablas sin `ORA-04091`. También controla cambios de estado de
`PENDIENTE` a confirmado/finalizado.

La vista materializada usa `REFRESH COMPLETE ON DEMAND`, porque la expansión de
estadías por noche y la deduplicación de datos históricos no justifican un
refresco incremental. La ocupación es la cantidad de noches-habitación
distintas; la disponibilidad es el número de habitaciones multiplicado por los
días del mes.

## Orden de ejecución en Oracle XE 21c

```sql
@db/01_ddl.sql
@db/03_carga_datos.sql
@db/04_paquete_plsql.sql
@db/05_triggers.sql
@db/06_tablespace_vista_materializada.sql
@db/02_consultas_analiticas.sql
@db/07_pruebas_entrega2.sql
```

El bloque `CREATE TABLESPACE` debe ejecutarse previamente como `SYS` o
`SYSTEM`, sustituyendo la ruta por un datafile válido y otorgando cuota al
usuario del proyecto. No se afirma su creación hasta verificarla con
`DBA_TABLESPACES`/`USER_TABLESPACES`.

## Validación

Se validó localmente la sintaxis de los archivos Python y el formato del
repositorio. No hay una instancia Oracle XE disponible en este entorno, por lo
que la compilación PL/SQL, la creación de la vista materializada, el tablespace
y los resultados numéricos deben verificarse ejecutando los scripts en Oracle
XE 21c. El script de pruebas consulta `USER_ERRORS` para identificar cualquier
error de compilación.
