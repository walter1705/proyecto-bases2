-- Entrega 3: pruebas reproducibles de transacciones.
SET SERVEROUTPUT ON

DELETE FROM reserva_habitacion
WHERE id_reserva IN (
    SELECT r.id_reserva
    FROM reserva r
    JOIN cliente c ON c.id_cliente = r.id_cliente
    WHERE c.identificacion = 'E3-PRUEBA'
);
DELETE FROM pago
WHERE id_reserva IN (
    SELECT r.id_reserva
    FROM reserva r
    JOIN cliente c ON c.id_cliente = r.id_cliente
    WHERE c.identificacion = 'E3-PRUEBA'
);
DELETE FROM reserva
WHERE id_cliente IN (
    SELECT id_cliente FROM cliente WHERE identificacion = 'E3-PRUEBA'
);
DELETE FROM tarifa
WHERE id_temporada IN (
    SELECT id_temporada FROM temporada WHERE nombre = 'PRUEBA E3'
);
DELETE FROM temporada WHERE nombre = 'PRUEBA E3';
DELETE FROM cliente WHERE identificacion = 'E3-PRUEBA';
COMMIT;

DECLARE
    l_habitacion habitacion.id_habitacion%TYPE;
    l_temporada temporada.id_temporada%TYPE;
    l_cliente cliente.id_cliente%TYPE;
    l_tarifa tarifa.id_tarifa%TYPE;
    l_reserva reserva.id_reserva%TYPE;
    l_valor NUMBER;
    l_antes NUMBER;
    l_despues NUMBER;
BEGIN
    SELECT MIN(id_habitacion) INTO l_habitacion FROM habitacion;

    INSERT INTO temporada (nombre, fecha_inicio, fecha_fin)
    VALUES ('PRUEBA E3', DATE '2036-01-01', DATE '2036-12-31')
    RETURNING id_temporada INTO l_temporada;

    INSERT INTO tarifa (id_habitacion, id_temporada, valor_noche)
    VALUES (l_habitacion, l_temporada, 125000)
    RETURNING id_tarifa INTO l_tarifa;

    INSERT INTO cliente (tipo_identificacion, identificacion, nombre_completo, email)
    VALUES ('CC', 'E3-PRUEBA', 'Cliente Prueba E3',
            'e3-prueba@turismouq.test')
    RETURNING id_cliente INTO l_cliente;

    l_valor := pkg_turismouq.fn_valor_estadia(
        l_habitacion, DATE '2036-06-10', DATE '2036-06-13');

    SELECT COUNT(*) INTO l_antes
    FROM reserva r
    JOIN cliente c ON c.id_cliente = r.id_cliente
    WHERE c.identificacion = 'E3-PRUEBA';

    sp_reserva_pago_atomico(
        l_cliente, l_habitacion,
        DATE '2036-06-10', DATE '2036-06-13',
        1, l_valor, 'PSE', l_reserva);

    SELECT COUNT(*) INTO l_despues
    FROM reserva r
    JOIN cliente c ON c.id_cliente = r.id_cliente
    WHERE c.identificacion = 'E3-PRUEBA';

    DBMS_OUTPUT.PUT_LINE(
        'EXITO antes=' || l_antes || ' despues=' || l_despues ||
        ' reserva=' || l_reserva);

    COMMIT;

    SAVEPOINT prueba_fallo;
    BEGIN
        sp_reserva_pago_atomico(
            l_cliente, l_habitacion,
            DATE '2036-06-20', DATE '2036-06-23',
            1, l_valor + 1, 'TARJETA', l_reserva);
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO prueba_fallo;
            DBMS_OUTPUT.PUT_LINE('FALLO CONTROLADO: ' || SQLERRM);
    END;

    SELECT COUNT(*) INTO l_antes
    FROM reserva r
    JOIN cliente c ON c.id_cliente = r.id_cliente
    WHERE c.identificacion = 'E3-PRUEBA';
    DBMS_OUTPUT.PUT_LINE('FALLO reservas persistidas=' || l_antes);
END;
/

-- Consultas de verificacion.
SELECT r.id_reserva, c.identificacion, r.estado,
       rh.fecha_checkin, rh.fecha_checkout,
       rh.subtotal_calculado
FROM reserva r
JOIN cliente c ON c.id_cliente = r.id_cliente
JOIN reserva_habitacion rh ON rh.id_reserva = r.id_reserva
WHERE c.identificacion = 'E3-PRUEBA';

SELECT p.id_pago, p.id_reserva, p.monto, p.metodo
FROM pago p
JOIN reserva r ON r.id_reserva = p.id_reserva
JOIN cliente c ON c.id_cliente = r.id_cliente
WHERE c.identificacion = 'E3-PRUEBA';

-- Limpieza explicita al finalizar.
DELETE FROM reserva_habitacion
WHERE id_reserva IN (
    SELECT r.id_reserva
    FROM reserva r
    JOIN cliente c ON c.id_cliente = r.id_cliente
    WHERE c.identificacion = 'E3-PRUEBA'
);
DELETE FROM pago
WHERE id_reserva IN (
    SELECT r.id_reserva
    FROM reserva r
    JOIN cliente c ON c.id_cliente = r.id_cliente
    WHERE c.identificacion = 'E3-PRUEBA'
);
DELETE FROM reserva
WHERE id_cliente IN (
    SELECT id_cliente FROM cliente WHERE identificacion = 'E3-PRUEBA'
);
DELETE FROM tarifa
WHERE id_temporada IN (
    SELECT id_temporada FROM temporada WHERE nombre = 'PRUEBA E3'
);
DELETE FROM temporada WHERE nombre = 'PRUEBA E3';
DELETE FROM cliente WHERE identificacion = 'E3-PRUEBA';
COMMIT;

PROMPT === Pruebas de seguridad: ejecutar cada usuario por separado ===
-- tu_recepcion:
-- SELECT * FROM v_recepcion_reservas;
-- SELECT * FROM v_recepcion_clientes;
-- SELECT * FROM reserva;                 -- debe ser ORA-00942
-- SELECT * FROM cliente;                -- debe ser ORA-00942
-- EXEC pkg_turismouq.sp_liquidacion_mensual(2026,6); -- gerente solamente
