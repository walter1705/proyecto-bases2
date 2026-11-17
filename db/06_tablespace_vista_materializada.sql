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

CREATE MATERIALIZED VIEW LOG ON reserva_habitacion
WITH ROWID, SEQUENCE (id_habitacion, fecha_checkin, fecha_checkout)
INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW mv_ocupacion_mensual
BUILD IMMEDIATE
REFRESH FAST ON COMMIT
AS
SELECT
    TRUNC(fecha_checkin, 'MM') mes_inicio,
    id_habitacion,
    COUNT(*) reservas_habitacion,
    COUNT(TRUNC(fecha_checkout) - TRUNC(fecha_checkin)) conteo_noches,
    SUM(TRUNC(fecha_checkout) - TRUNC(fecha_checkin)) noches_ocupadas
FROM reserva_habitacion
GROUP BY TRUNC(fecha_checkin, 'MM'), id_habitacion;
