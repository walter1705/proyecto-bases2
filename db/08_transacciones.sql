-- Entrega 3: reserva y pago dentro de una operacion atomica.
-- El llamador controla COMMIT y ROLLBACK. Este procedimiento no confirma
-- implicitamente ninguna transaccion.

CREATE OR REPLACE PROCEDURE sp_reserva_pago_atomico(
    p_id_cliente IN reserva.id_cliente%TYPE,
    p_id_habitacion IN habitacion.id_habitacion%TYPE,
    p_fecha_in IN DATE,
    p_fecha_out IN DATE,
    p_num_huespedes IN NUMBER,
    p_monto_pago IN pago.monto%TYPE,
    p_metodo_pago IN pago.metodo%TYPE,
    p_id_reserva OUT reserva.id_reserva%TYPE
) IS
    l_capacidad habitacion.capacidad%TYPE;
    l_valor reserva_habitacion.subtotal_calculado%TYPE;
BEGIN
    SAVEPOINT reserva_pago_inicio;

    IF p_fecha_in IS NULL OR p_fecha_out IS NULL
       OR TRUNC(p_fecha_out) <= TRUNC(p_fecha_in) THEN
        RAISE_APPLICATION_ERROR(-20301,
            'El intervalo de fechas no es valido.');
    END IF;

    IF p_num_huespedes IS NULL OR p_num_huespedes < 1 THEN
        RAISE_APPLICATION_ERROR(-20302,
            'El numero de huespedes debe ser positivo.');
    END IF;

    IF p_monto_pago IS NULL OR p_monto_pago <= 0 THEN
        RAISE_APPLICATION_ERROR(-20303,
            'El monto del pago debe ser positivo.');
    END IF;

    IF p_metodo_pago NOT IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA', 'PSE') THEN
        RAISE_APPLICATION_ERROR(-20304,
            'El metodo de pago no es valido.');
    END IF;

    BEGIN
        SELECT capacidad
        INTO l_capacidad
        FROM habitacion
        WHERE id_habitacion = p_id_habitacion
        FOR UPDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20305,
                'La habitacion indicada no existe.');
    END;

    IF p_num_huespedes > l_capacidad THEN
        RAISE_APPLICATION_ERROR(-20306,
            'El numero de huespedes excede la capacidad.');
    END IF;

    l_valor := pkg_turismouq.fn_valor_estadia(
        p_id_habitacion, p_fecha_in, p_fecha_out);

    IF ABS(NVL(p_monto_pago, 0) - l_valor) > 0.01 THEN
        RAISE_APPLICATION_ERROR(-20307,
            'El pago no coincide con el valor calculado: ' ||
            TO_CHAR(l_valor, '999999999.99'));
    END IF;

    pkg_turismouq.sp_crear_reserva(
        p_id_cliente, p_id_habitacion, p_fecha_in, p_fecha_out,
        p_num_huespedes, p_id_reserva);

    INSERT INTO pago (
        id_reserva, fecha_transaccion, monto, metodo
    ) VALUES (
        p_id_reserva, SYSDATE, p_monto_pago, p_metodo_pago
    );

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO SAVEPOINT reserva_pago_inicio;
        RAISE;
END sp_reserva_pago_atomico;
/
