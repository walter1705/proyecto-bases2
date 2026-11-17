-- Entrega 3: guia de concurrencia para ejecutar en dos sesiones Oracle.
-- Use dos conexiones con el mismo usuario de proyecto.

-- SESION A
PROMPT === Sesion A: limpiar datos de prueba y preparar identificadores ===
ACCEPT prueba_habitacion NUMBER PROMPT 'Ingrese id_habitacion valido: '
ACCEPT prueba_cliente NUMBER PROMPT 'Ingrese id_cliente valido: '

SELECT id_habitacion, capacidad
FROM habitacion
WHERE id_habitacion = &prueba_habitacion;

-- Ejecute primero sin bloqueo explicito:
SELECT COUNT(*)
FROM reserva_habitacion rh
JOIN reserva r ON r.id_reserva = rh.id_reserva
WHERE rh.id_habitacion = &prueba_habitacion
  AND r.estado IN ('CONFIRMADA', 'FINALIZADA')
  AND rh.fecha_checkin < DATE '2035-08-10'
  AND rh.fecha_checkout > DATE '2035-08-01';

-- SESION A: ejecutar el procedimiento en autocommit de SQL*Plus
-- SET SERVEROUTPUT ON
VAR id_reserva_a NUMBER;
DECLARE
    l_id reserva.id_reserva%TYPE;
BEGIN
    sp_reserva_pago_atomico(
        &prueba_cliente, &prueba_habitacion,
        DATE '2035-08-01', DATE '2035-08-10', 1,
        pkg_turismouq.fn_valor_estadia(
            &prueba_habitacion, DATE '2035-08-01', DATE '2035-08-10'),
        'EFECTIVO', l_id);
    :id_reserva_a := l_id;
END;
/
SELECT :id_reserva_a AS reserva_creada_en_a FROM dual;

-- No confirme hasta que la sesion B haya intentado reservar.
-- COMMIT;

-- SESION B
-- Replique los datos de conexion y ejecute simultaneamente:
-- SELECT COUNT(*) con el mismo rango.
-- sp_reserva_pago_atomico con el mismo cliente/habitacion/rango.
-- Oracle debe bloquear o rechazar segun el momento de ejecucion.

-- DESPUES DE COMMIT EN A:
-- La sesion B reintenta desde su propia lectura.
-- No puede quedar una reserva compatible con el rango ocupado.

-- COMPARACION CON FOR UPDATE:
-- El procedimiento bloquea la fila HABITACION antes de comprobar y crear.
-- Repetir el mismo procedimiento desde A y B. La segunda sesion esperara
-- hasta que A confirme o haga ROLLBACK.

-- Comprobacion posterior:
SELECT rh.id_habitacion, r.id_reserva, r.estado,
       rh.fecha_checkin, rh.fecha_checkout
FROM reserva_habitacion rh
JOIN reserva r ON r.id_reserva = rh.id_reserva
WHERE rh.id_habitacion = &prueba_habitacion
  AND r.estado IN ('CONFIRMADA', 'FINALIZADA')
  AND rh.fecha_checkin < DATE '2035-08-10'
  AND rh.fecha_checkout > DATE '2035-08-01';
