-- TurismoUQ - pruebas reproducibles de la segunda entrega.
-- Ejecutar despues de 04, 05 y 06. Las pruebas usan SAVEPOINT y ROLLBACK.
SET SERVEROUTPUT ON

PROMPT === Estado de objetos PL/SQL ===
SELECT object_name, object_type, status
FROM user_objects
WHERE object_name IN (
    'PKG_TURISMOUQ', 'TRG_AUDITORIA_TARIFA',
    'TRG_CONTROL_SOLAPAMIENTO_RH', 'TRG_CONTROL_SOLAPAMIENTO_ESTADO',
    'MV_OCUPACION_MENSUAL'
)
ORDER BY object_type, object_name;

-- Limpieza preventiva para permitir repetir la prueba tras una ejecución
-- interrumpida.
DELETE FROM reserva_habitacion
WHERE id_reserva IN (
    SELECT r.id_reserva
    FROM reserva r
    JOIN cliente c ON c.id_cliente = r.id_cliente
    WHERE c.identificacion = 'E2-PRUEBA'
);
DELETE FROM reserva
WHERE id_cliente IN (
    SELECT id_cliente FROM cliente WHERE identificacion = 'E2-PRUEBA'
);
DELETE FROM auditoria_tarifa
WHERE id_tarifa IN (
    SELECT t.id_tarifa
    FROM tarifa t
    JOIN temporada s ON s.id_temporada = t.id_temporada
    WHERE s.nombre = 'PRUEBA E2'
);
DELETE FROM tarifa
WHERE id_temporada IN (
    SELECT id_temporada FROM temporada WHERE nombre = 'PRUEBA E2'
);
DELETE FROM temporada WHERE nombre = 'PRUEBA E2';
DELETE FROM cliente WHERE identificacion = 'E2-PRUEBA';
COMMIT;

SAVEPOINT inicio_pruebas_entrega2;

DECLARE
    l_habitacion NUMBER;
    l_temporada NUMBER;
    l_cliente NUMBER;
    l_tarifa NUMBER;
    l_reserva NUMBER;
    l_valor NUMBER;
    l_auditorias NUMBER;
BEGIN
    SELECT MIN(id_habitacion) INTO l_habitacion FROM habitacion;
    INSERT INTO temporada (nombre, fecha_inicio, fecha_fin)
    VALUES ('PRUEBA E2', DATE '2030-01-01', DATE '2030-12-31')
    RETURNING id_temporada INTO l_temporada;
    INSERT INTO tarifa (id_habitacion, id_temporada, valor_noche)
    VALUES (l_habitacion, l_temporada, 150000)
    RETURNING id_tarifa INTO l_tarifa;
    INSERT INTO cliente (tipo_identificacion, identificacion, nombre_completo, email)
    VALUES ('CC', 'E2-PRUEBA', 'Cliente Prueba E2', 'e2-prueba@turismouq.test')
    RETURNING id_cliente INTO l_cliente;

    l_valor := pkg_turismouq.fn_valor_estadia(
        l_habitacion, DATE '2030-01-10', DATE '2030-01-13'
    );
    DBMS_OUTPUT.PUT_LINE('OK funcion: 3 noches x 150000 = ' || l_valor);

    pkg_turismouq.sp_crear_reserva(
        l_cliente, l_habitacion, DATE '2030-01-10', DATE '2030-01-13', 1, l_reserva
    );
    DBMS_OUTPUT.PUT_LINE('OK reserva creada: ' || l_reserva);

    BEGIN
        l_valor := pkg_turismouq.fn_valor_estadia(
            l_habitacion, DATE '2030-01-13', DATE '2030-01-10'
        );
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK fecha invalida: ' || SQLERRM);
    END;

    BEGIN
        pkg_turismouq.sp_crear_reserva(
            l_cliente, l_habitacion, DATE '2030-01-11', DATE '2030-01-12', 1, l_reserva
        );
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK solapamiento rechazado: ' || SQLERRM);
    END;

    BEGIN
        pkg_turismouq.sp_crear_reserva(
            l_cliente, l_habitacion, DATE '2030-02-01', DATE '2030-02-02', 999, l_reserva
        );
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('OK capacidad rechazada: ' || SQLERRM);
    END;

    UPDATE tarifa SET valor_noche = valor_noche + 1 WHERE id_tarifa = l_tarifa;
    SELECT COUNT(*) INTO l_auditorias
    FROM auditoria_tarifa
    WHERE id_tarifa = l_tarifa;
    DBMS_OUTPUT.PUT_LINE('OK auditoria generada: ' || l_auditorias);

    pkg_turismouq.sp_liquidacion_mensual(2030, 1);
    DBMS_OUTPUT.PUT_LINE('OK liquidacion mensual ejecutada.');
END;
/

PROMPT === Consulta de auditoria ===
SELECT id_tarifa, usuario_bd, operacion, valor_anterior, valor_nuevo
FROM auditoria_tarifa
ORDER BY id_auditoria DESC
FETCH FIRST 5 ROWS ONLY;

PROMPT === Consulta de ocupacion ===
SELECT *
FROM mv_ocupacion_mensual
WHERE anio = 2024 AND mes = 1
FETCH FIRST 10 ROWS ONLY;

EXEC DBMS_MVIEW.REFRESH('MV_OCUPACION_MENSUAL', 'C');

PROMPT === Errores de compilacion ===
SELECT name, type, line, position, text
FROM user_errors
WHERE name IN ('PKG_TURISMOUQ', 'TRG_AUDITORIA_TARIFA',
               'TRG_CONTROL_SOLAPAMIENTO_RH', 'TRG_CONTROL_SOLAPAMIENTO_ESTADO')
ORDER BY name, sequence;

-- DBMS_MVIEW.REFRESH puede confirmar implicitamente la transaccion y dejar
-- invalido el savepoint. Por eso la limpieza final es explicita e idempotente.
DELETE FROM reserva_habitacion
WHERE id_reserva IN (
    SELECT r.id_reserva
    FROM reserva r
    JOIN cliente c ON c.id_cliente = r.id_cliente
    WHERE c.identificacion = 'E2-PRUEBA'
);
DELETE FROM reserva
WHERE id_cliente IN (
    SELECT id_cliente FROM cliente WHERE identificacion = 'E2-PRUEBA'
);
DELETE FROM auditoria_tarifa
WHERE id_tarifa IN (
    SELECT t.id_tarifa
    FROM tarifa t
    JOIN temporada s ON s.id_temporada = t.id_temporada
    WHERE s.nombre = 'PRUEBA E2'
);
DELETE FROM tarifa
WHERE id_temporada IN (
    SELECT id_temporada FROM temporada WHERE nombre = 'PRUEBA E2'
);
DELETE FROM temporada WHERE nombre = 'PRUEBA E2';
DELETE FROM cliente WHERE identificacion = 'E2-PRUEBA';
COMMIT;
PROMPT Pruebas finalizadas; los datos de demostracion fueron limpiados.
