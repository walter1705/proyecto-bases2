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

BEGIN
    EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW LOG ON reserva_habitacion';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -12003 THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW LOG ON reserva';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -12003 THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW LOG ON habitacion';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -12003 THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW LOG ON alojamiento';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -12003 THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW LOG ON municipio';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -12003 THEN
            RAISE;
        END IF;
END;
/

CREATE MATERIALIZED VIEW LOG ON reserva_habitacion
WITH PRIMARY KEY, ROWID, SEQUENCE (
    id_reserva, id_habitacion, fecha_checkin, fecha_checkout
) INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW LOG ON reserva
WITH PRIMARY KEY, ROWID, SEQUENCE (estado) INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW LOG ON habitacion
WITH PRIMARY KEY, ROWID, SEQUENCE (id_alojamiento) INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW LOG ON alojamiento
WITH PRIMARY KEY, ROWID, SEQUENCE (nombre, id_municipio) INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW LOG ON municipio
WITH PRIMARY KEY, ROWID, SEQUENCE (nombre) INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW mv_ocupacion_mensual
BUILD IMMEDIATE
REFRESH FAST ON COMMIT
AS
SELECT
    EXTRACT(YEAR FROM TRUNC(rh.fecha_checkin, 'MM')) anio,
    EXTRACT(MONTH FROM TRUNC(rh.fecha_checkin, 'MM')) mes,
    a.id_alojamiento,
    a.nombre alojamiento,
    mu.nombre municipio,
    SUM(TRUNC(rh.fecha_checkout) - TRUNC(rh.fecha_checkin)) noches_ocupadas,
    COUNT(*) reservas_habitacion
FROM reserva_habitacion rh
JOIN reserva r ON r.id_reserva = rh.id_reserva
JOIN habitacion h ON h.id_habitacion = rh.id_habitacion
JOIN alojamiento a ON a.id_alojamiento = h.id_alojamiento
JOIN municipio mu ON mu.id_municipio = a.id_municipio
WHERE r.estado IN ('CONFIRMADA', 'FINALIZADA')
GROUP BY
    TRUNC(rh.fecha_checkin, 'MM'),
    a.id_alojamiento,
    a.nombre,
    mu.nombre;
