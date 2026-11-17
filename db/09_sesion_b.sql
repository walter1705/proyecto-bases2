-- Concurrencia: sesion B.
SET SERVEROUTPUT ON
ACCEPT habitacion_b NUMBER PROMPT 'id_habitacion: '
ACCEPT cliente_b NUMBER PROMPT 'id_cliente: '

DECLARE
    l_reserva reserva.id_reserva%TYPE;
    l_valor NUMBER;
BEGIN
    l_valor := pkg_turismouq.fn_valor_estadia(
        &habitacion_b, DATE '2035-09-01', DATE '2035-09-10');
    sp_reserva_pago_atomico(
        &cliente_b, &habitacion_b,
        DATE '2035-09-01', DATE '2035-09-10',
        1, l_valor, 'EFECTIVO', l_reserva);
    DBMS_OUTPUT.PUT_LINE('Sesion B reserva: ' || l_reserva);
END;
/
