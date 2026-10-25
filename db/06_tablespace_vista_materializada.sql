-- TurismoUQ - Segunda entrega: tablespace y ocupacion mensual.
--
-- PARTE ADMINISTRATIVA (ejecutar como SYS/SYSTEM y ajustar la ruta):
-- CREATE TABLESPACE turismouq_historico
-- DATAFILE '/ruta/valida/oracle/turismouq_historico01.dbf'
-- SIZE 100M AUTOEXTEND ON NEXT 10M MAXSIZE 500M;
-- GRANT QUOTA UNLIMITED ON turismouq_historico TO usuario_turismouq;
--
-- El tablespace separa historicos de los datos operativos para facilitar
-- retencion, respaldo y politicas de almacenamiento. Oracle XE requiere una
-- ruta de datafile existente y privilegios de administracion.

-- Ejecutar como el usuario del proyecto, despues de crear el tablespace:
-- CREATE TABLE reserva_historico (
--     id_reserva NUMBER NOT NULL,
--     id_cliente NUMBER NOT NULL,
--     fecha_creacion DATE NOT NULL,
--     estado VARCHAR2(30) NOT NULL,
--     fecha_archivo DATE DEFAULT SYSDATE NOT NULL
-- ) TABLESPACE turismouq_historico;

BEGIN
    EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_ocupacion_mensual';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -12003 THEN
            RAISE;
        END IF;
END;
/

CREATE MATERIALIZED VIEW mv_ocupacion_mensual
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
WITH meses AS (
    SELECT ADD_MONTHS(DATE '2024-01-01', LEVEL - 1) inicio_mes
    FROM dual
    CONNECT BY LEVEL <= 36
),
noches_ocupadas AS (
    SELECT DISTINCT
        h.id_alojamiento,
        h.id_habitacion,
        TRUNC(rh.fecha_checkin) + dias.noche - 1 fecha_noche
    FROM reserva_habitacion rh
    JOIN reserva r ON r.id_reserva = rh.id_reserva
    JOIN habitacion h ON h.id_habitacion = rh.id_habitacion
    CROSS JOIN LATERAL (
        SELECT LEVEL noche
        FROM dual
        CONNECT BY LEVEL <= TRUNC(rh.fecha_checkout) - TRUNC(rh.fecha_checkin)
    ) dias
    WHERE r.estado IN ('CONFIRMADA', 'FINALIZADA')
),
alojamientos_base AS (
    SELECT a.id_alojamiento, a.nombre alojamiento, mu.nombre municipio,
           COUNT(h.id_habitacion) habitaciones
    FROM alojamiento a
    JOIN municipio mu ON mu.id_municipio = a.id_municipio
    JOIN habitacion h ON h.id_alojamiento = a.id_alojamiento
    GROUP BY a.id_alojamiento, a.nombre, mu.nombre
),
ocupacion_mensual AS (
    SELECT ab.id_alojamiento,
           m.inicio_mes,
           COUNT(DISTINCT TO_CHAR(o.fecha_noche, 'YYYYMMDD') ||
                          ':' || TO_CHAR(o.id_habitacion)) noches_ocupadas
    FROM alojamientos_base ab
    CROSS JOIN meses m
    LEFT JOIN noches_ocupadas o
      ON o.id_alojamiento = ab.id_alojamiento
     AND o.fecha_noche >= m.inicio_mes
     AND o.fecha_noche < ADD_MONTHS(m.inicio_mes, 1)
    GROUP BY ab.id_alojamiento, m.inicio_mes
)
SELECT
    EXTRACT(YEAR FROM m.inicio_mes) anio,
    EXTRACT(MONTH FROM m.inicio_mes) mes,
    ab.id_alojamiento,
    ab.alojamiento,
    ab.municipio,
    om.noches_ocupadas,
    ab.habitaciones *
        (ADD_MONTHS(m.inicio_mes, 1) - m.inicio_mes) noches_disponibles,
    ROUND(
        om.noches_ocupadas
        / NULLIF(
            ab.habitaciones *
            (ADD_MONTHS(m.inicio_mes, 1) - m.inicio_mes), 0
        ) * 100,
        2
    ) porcentaje_ocupacion
FROM meses m
CROSS JOIN alojamientos_base ab
JOIN ocupacion_mensual om
  ON om.id_alojamiento = ab.id_alojamiento
 AND om.inicio_mes = m.inicio_mes;

-- Refresco posterior a nuevas cargas:
-- EXEC DBMS_MVIEW.REFRESH('MV_OCUPACION_MENSUAL', 'C');
