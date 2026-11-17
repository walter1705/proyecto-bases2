-- Entrega 3: indices y planes de ejecucion.
-- Ejecutar como propietario del esquema.

ALTER SESSION SET STATISTICS_LEVEL = ALL;

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX ix_rh_habitacion_fechas';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -1418 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX ix_pago_fecha_funcion';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -1418 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX ix_reserva_cliente_estado';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -1418 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX ix_reserva_estado_no_mejora';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -1418 THEN RAISE; END IF;
END;
/

-- Escenario 1, antes del indice compuesto:
EXPLAIN PLAN FOR
SELECT rh.id_habitacion, rh.fecha_checkin, rh.fecha_checkout
FROM reserva_habitacion rh
JOIN reserva r ON r.id_reserva = rh.id_reserva
WHERE rh.id_habitacion = 1
  AND r.estado IN ('CONFIRMADA', 'FINALIZADA')
  AND rh.fecha_checkin < DATE '2025-01-31'
  AND rh.fecha_checkout > DATE '2025-01-01';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'BASIC ROWS COST'));

CREATE INDEX ix_rh_habitacion_fechas
    ON reserva_habitacion(id_habitacion, fecha_checkin, fecha_checkout);

EXPLAIN PLAN FOR
SELECT rh.id_habitacion, rh.fecha_checkin, rh.fecha_checkout
FROM reserva_habitacion rh
JOIN reserva r ON r.id_reserva = rh.id_reserva
WHERE rh.id_habitacion = 1
  AND r.estado IN ('CONFIRMADA', 'FINALIZADA')
  AND rh.fecha_checkin < DATE '2025-01-31'
  AND rh.fecha_checkout > DATE '2025-01-01';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'BASIC ROWS COST'));

-- Escenario 2: indice basado en funcion para TRUNC(fecha).
EXPLAIN PLAN FOR
SELECT TRUNC(fecha_transaccion, 'MM') mes,
       SUM(monto) ingresos
FROM pago
WHERE TRUNC(fecha_transaccion, 'MM') = DATE '2024-06-01'
GROUP BY TRUNC(fecha_transaccion, 'MM');
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'BASIC ROWS COST'));

CREATE INDEX ix_pago_fecha_funcion
    ON pago(TRUNC(fecha_transaccion));

EXPLAIN PLAN FOR
SELECT TRUNC(fecha_transaccion, 'MM') mes,
       SUM(monto) ingresos
FROM pago
WHERE TRUNC(fecha_transaccion, 'MM') = DATE '2024-06-01'
GROUP BY TRUNC(fecha_transaccion, 'MM');
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'BASIC ROWS COST'));

-- Escenario 3: indice compuesto para reservas de un cliente por estado.
EXPLAIN PLAN FOR
SELECT id_reserva, estado, fecha_creacion
FROM reserva
WHERE id_cliente = 1
  AND estado = 'CONFIRMADA';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'BASIC ROWS COST'));

CREATE INDEX ix_reserva_cliente_estado
    ON reserva(id_cliente, estado);

EXPLAIN PLAN FOR
SELECT id_reserva, estado, fecha_creacion
FROM reserva
WHERE id_cliente = 1
  AND estado = 'CONFIRMADA';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'BASIC ROWS COST'));

-- Caso donde el indice no mejora:
-- CANCELADA puede ser poco selectivo en otro volumen de datos.
EXPLAIN PLAN FOR
SELECT id_reserva, id_cliente, fecha_creacion
FROM reserva
WHERE estado = 'CANCELADA';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'BASIC ROWS COST'));

CREATE INDEX ix_reserva_estado_no_mejora
    ON reserva(estado);

EXPLAIN PLAN FOR
SELECT id_reserva, id_cliente, fecha_creacion
FROM reserva
WHERE estado = 'CANCELADA';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'BASIC ROWS COST'));

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => USER,
        tabname => 'RESERVA_HABITACION',
        cascade => TRUE,
        estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
        method_opt => 'FOR ALL COLUMNS SIZE AUTO');
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => USER,
        tabname => 'PAGO',
        cascade => TRUE,
        estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
        method_opt => 'FOR ALL COLUMNS SIZE AUTO');
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => USER,
        tabname => 'RESERVA',
        cascade => TRUE,
        estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
        method_opt => 'FOR ALL COLUMNS SIZE AUTO');
END;
/

-- Ejecutar despues de cada consulta real y capture el SQL_ID:
-- SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));
