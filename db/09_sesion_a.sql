-- Concurrencia: sesion A.
SET SERVEROUTPUT ON
ACCEPT habitacion_a NUMBER PROMPT 'id_habitacion: '
ACCEPT cliente_a NUMBER PROMPT 'id_cliente: '

DECLARE
    l_temporada temporada.id_temporada%TYPE;
BEGIN
    BEGIN
        SELECT id_temporada INTO l_temporada
        FROM temporada WHERE nombre = 'PRUEBA CONCURRENCIA E3';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO temporada (nombre, fecha_inicio, fecha_fin)
            VALUES ('PRUEBA CONCURRENCIA E3',
                    DATE '2035-01-01', DATE '2035-12-31')
            RETURNING id_temporada INTO l_temporada;
    END;

    BEGIN
        INSERT INTO tarifa (id_habitacion, id_temporada, valor_noche)
        VALUES (&habitacion_a, l_temporada, 150000);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;
END;
/
COMMIT;

DECLARE
    l_reserva reserva.id_reserva%TYPE;
    l_valor NUMBER;
BEGIN
    l_valor := pkg_turismouq.fn_valor_estadia(
        &habitacion_a, DATE '2035-09-01', DATE '2035-09-10');
    sp_reserva_pago_atomico(
        &cliente_a, &habitacion_a,
        DATE '2035-09-01', DATE '2035-09-10',
        1, l_valor, 'EFECTIVO', l_reserva);
    DBMS_OUTPUT.PUT_LINE('Sesion A reserva: ' || l_reserva);
END;
/

-- No ejecute COMMIT ni ROLLBACK hasta coordinar con la sesion B.
