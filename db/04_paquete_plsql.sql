-- TurismoUQ - Segunda entrega: paquete PL/SQL.
-- Compatible con Oracle Database XE 21c.

CREATE OR REPLACE PACKAGE pkg_turismouq AS
    FUNCTION fn_valor_estadia(
        p_id_habitacion IN habitacion.id_habitacion%TYPE,
        p_fecha_in      IN DATE,
        p_fecha_out     IN DATE
    ) RETURN NUMBER;

    PROCEDURE sp_crear_reserva(
        p_id_cliente      IN reserva.id_cliente%TYPE,
        p_id_habitacion   IN habitacion.id_habitacion%TYPE,
        p_fecha_in        IN DATE,
        p_fecha_out       IN DATE,
        p_num_huespedes   IN NUMBER,
        p_id_reserva      OUT reserva.id_reserva%TYPE
    );

    PROCEDURE sp_liquidacion_mensual(
        p_anio           IN NUMBER,
        p_mes            IN NUMBER,
        p_id_alojamiento IN alojamiento.id_alojamiento%TYPE DEFAULT NULL
    );
END pkg_turismouq;
/

CREATE OR REPLACE PACKAGE BODY pkg_turismouq AS
    c_estado_invalido CONSTANT PLS_INTEGER := -20001;
    c_habitacion_noexiste CONSTANT PLS_INTEGER := -20002;
    c_tarifa_faltante CONSTANT PLS_INTEGER := -20003;
    c_cliente_noexiste CONSTANT PLS_INTEGER := -20004;
    c_capacidad_excedida CONSTANT PLS_INTEGER := -20005;
    c_habitacion_ocupada CONSTANT PLS_INTEGER := -20006;

    FUNCTION fn_valor_estadia(
        p_id_habitacion IN habitacion.id_habitacion%TYPE,
        p_fecha_in      IN DATE,
        p_fecha_out     IN DATE
    ) RETURN NUMBER IS
        l_total NUMBER := 0;
        l_valor tarifa.valor_noche%TYPE;
        l_habitacion NUMBER;
    BEGIN
        IF p_fecha_in IS NULL OR p_fecha_out IS NULL
           OR TRUNC(p_fecha_out) <= TRUNC(p_fecha_in) THEN
            raise_application_error(c_estado_invalido,
                'La fecha de salida debe ser posterior a la fecha de entrada.');
        END IF;

        SELECT id_habitacion
        INTO l_habitacion
        FROM habitacion
        WHERE id_habitacion = p_id_habitacion;

        FOR i IN 0 .. (TRUNC(p_fecha_out) - TRUNC(p_fecha_in) - 1) LOOP
            BEGIN
                /* Precedencia: temporada especial (no Baja), luego la de
                   intervalo mas corto y finalmente el menor identificador. */
                SELECT valor_noche
                INTO l_valor
                FROM (
                    SELECT t.valor_noche
                    FROM tarifa t
                    JOIN temporada s ON s.id_temporada = t.id_temporada
                    WHERE t.id_habitacion = l_habitacion
                      AND TRUNC(p_fecha_in) + i BETWEEN TRUNC(s.fecha_inicio)
                                                    AND TRUNC(s.fecha_fin)
                    ORDER BY
                        CASE WHEN UPPER(s.nombre) LIKE 'TEMPORADA BAJA%' THEN 2 ELSE 1 END,
                        (TRUNC(s.fecha_fin) - TRUNC(s.fecha_inicio)) ASC,
                        s.id_temporada
                )
                WHERE ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    raise_application_error(
                        c_tarifa_faltante,
                        'No existe tarifa para la noche ' ||
                        TO_CHAR(TRUNC(p_fecha_in) + i, 'YYYY-MM-DD')
                    );
            END;
            l_total := l_total + l_valor;
        END LOOP;

        RETURN l_total;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            raise_application_error(c_habitacion_noexiste,
                'La habitacion indicada no existe.');
    END fn_valor_estadia;

    PROCEDURE sp_crear_reserva(
        p_id_cliente      IN reserva.id_cliente%TYPE,
        p_id_habitacion   IN habitacion.id_habitacion%TYPE,
        p_fecha_in        IN DATE,
        p_fecha_out       IN DATE,
        p_num_huespedes   IN NUMBER,
        p_id_reserva      OUT reserva.id_reserva%TYPE
    ) IS
        l_capacidad habitacion.capacidad%TYPE;
        l_cliente NUMBER;
        l_valor NUMBER;
    BEGIN
        IF p_fecha_in IS NULL OR p_fecha_out IS NULL
           OR TRUNC(p_fecha_out) <= TRUNC(p_fecha_in) THEN
            raise_application_error(c_estado_invalido,
                'El intervalo de estadia no es valido.');
        END IF;
        IF p_num_huespedes IS NULL OR p_num_huespedes < 1 THEN
            raise_application_error(c_capacidad_excedida,
                'El numero de huespedes debe ser positivo.');
        END IF;

        BEGIN
            SELECT capacidad INTO l_capacidad
            FROM habitacion WHERE id_habitacion = p_id_habitacion;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                raise_application_error(c_habitacion_noexiste,
                    'La habitacion indicada no existe.');
        END;
        IF p_num_huespedes > l_capacidad THEN
            raise_application_error(c_capacidad_excedida,
                'El numero de huespedes excede la capacidad de la habitacion.');
        END IF;

        BEGIN
            SELECT id_cliente INTO l_cliente
            FROM cliente WHERE id_cliente = p_id_cliente;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                raise_application_error(c_cliente_noexiste,
                    'El cliente indicado no existe.');
        END;

        SELECT COUNT(*)
        INTO l_cliente
        FROM reserva r
        JOIN reserva_habitacion rh ON rh.id_reserva = r.id_reserva
        WHERE rh.id_habitacion = p_id_habitacion
          AND r.estado IN ('CONFIRMADA', 'FINALIZADA')
          AND TRUNC(p_fecha_in) < TRUNC(rh.fecha_checkout)
          AND TRUNC(p_fecha_out) > TRUNC(rh.fecha_checkin);
        IF l_cliente > 0 THEN
            raise_application_error(c_habitacion_ocupada,
                'La habitacion ya esta ocupada en las fechas indicadas.');
        END IF;

        l_valor := fn_valor_estadia(p_id_habitacion, p_fecha_in, p_fecha_out);

        INSERT INTO reserva (id_cliente, fecha_creacion, estado)
        VALUES (p_id_cliente, SYSDATE, 'CONFIRMADA')
        RETURNING id_reserva INTO p_id_reserva;

        INSERT INTO reserva_habitacion (
            id_reserva, id_habitacion, fecha_checkin, fecha_checkout,
            subtotal_calculado
        ) VALUES (
            p_id_reserva, p_id_habitacion, TRUNC(p_fecha_in), TRUNC(p_fecha_out),
            l_valor
        );
    END sp_crear_reserva;

    PROCEDURE sp_liquidacion_mensual(
        p_anio           IN NUMBER,
        p_mes            IN NUMBER,
        p_id_alojamiento IN alojamiento.id_alojamiento%TYPE DEFAULT NULL
    ) IS
        l_inicio DATE;
        l_fin DATE;
        l_ingresos NUMBER;

        CURSOR c_alojamientos(p_alojamiento alojamiento.id_alojamiento%TYPE) IS
            SELECT id_alojamiento, nombre
            FROM alojamiento
            WHERE p_alojamiento IS NULL OR id_alojamiento = p_alojamiento
            ORDER BY id_alojamiento;
    BEGIN
        IF p_anio IS NULL OR p_mes NOT BETWEEN 1 AND 12 THEN
            raise_application_error(c_estado_invalido,
                'El anio y el mes de liquidacion no son validos.');
        END IF;
        l_inicio := TO_DATE(p_anio || LPAD(p_mes, 2, '0'), 'YYYYMM');
        l_fin := ADD_MONTHS(l_inicio, 1);

        FOR alojamiento IN c_alojamientos(p_id_alojamiento) LOOP
            SELECT NVL(SUM(
                rh.subtotal_calculado /
                NULLIF(TRUNC(rh.fecha_checkout) - TRUNC(rh.fecha_checkin), 0) *
                (LEAST(TRUNC(rh.fecha_checkout), l_fin) -
                 GREATEST(TRUNC(rh.fecha_checkin), l_inicio))
            ), 0)
            INTO l_ingresos
            FROM reserva_habitacion rh
            JOIN reserva r ON r.id_reserva = rh.id_reserva
            JOIN habitacion h ON h.id_habitacion = rh.id_habitacion
            WHERE h.id_alojamiento = alojamiento.id_alojamiento
              AND r.estado IN ('CONFIRMADA', 'FINALIZADA')
              AND rh.fecha_checkin < l_fin
              AND rh.fecha_checkout > l_inicio;

            DBMS_OUTPUT.PUT_LINE(
                'Alojamiento ' || alojamiento.id_alojamiento || ' - ' ||
                alojamiento.nombre || ': ' || TO_CHAR(ROUND(l_ingresos, 2))
            );
        END LOOP;
    END sp_liquidacion_mensual;
END pkg_turismouq;
/
