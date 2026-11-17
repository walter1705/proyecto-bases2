-- Entrega 3: vistas y privilegios.
-- Ejecutar como el propietario del esquema TurismoUQ.

CREATE OR REPLACE VIEW v_recepcion_reservas AS
SELECT r.id_reserva,
       c.nombre_completo AS cliente,
       c.identificacion,
       a.nombre AS alojamiento,
       h.numero AS habitacion,
       rh.fecha_checkin,
       rh.fecha_checkout,
       r.estado
FROM reserva r
JOIN cliente c ON c.id_cliente = r.id_cliente
JOIN reserva_habitacion rh ON rh.id_reserva = r.id_reserva
JOIN habitacion h ON h.id_habitacion = rh.id_habitacion
JOIN alojamiento a ON a.id_alojamiento = h.id_alojamiento;

CREATE OR REPLACE VIEW v_recepcion_clientes AS
SELECT id_cliente, identificacion, nombre_completo, email
FROM cliente;

CREATE OR REPLACE VIEW v_admin_alojamientos AS
SELECT a.id_alojamiento, a.nombre alojamiento, m.nombre municipio,
       h.id_habitacion, h.numero, h.capacidad,
       t.id_temporada, t.nombre temporada,
       ta.valor_noche
FROM alojamiento a
JOIN municipio m ON m.id_municipio = a.id_municipio
JOIN habitacion h ON h.id_alojamiento = a.id_alojamiento
JOIN tarifa ta ON ta.id_habitacion = h.id_habitacion
JOIN temporada t ON t.id_temporada = ta.id_temporada;

CREATE OR REPLACE VIEW v_gerencia_ingresos AS
SELECT EXTRACT(YEAR FROM p.fecha_transaccion) anio,
       EXTRACT(MONTH FROM p.fecha_transaccion) mes,
       m.nombre municipio,
       SUM(p.monto) ingresos
FROM pago p
JOIN reserva r ON r.id_reserva = p.id_reserva
JOIN reserva_habitacion rh ON rh.id_reserva = r.id_reserva
JOIN habitacion h ON h.id_habitacion = rh.id_habitacion
JOIN alojamiento a ON a.id_alojamiento = h.id_alojamiento
JOIN municipio m ON m.id_municipio = a.id_municipio
WHERE r.estado <> 'CANCELADA'
GROUP BY EXTRACT(YEAR FROM p.fecha_transaccion),
         EXTRACT(MONTH FROM p.fecha_transaccion),
         m.nombre;

CREATE OR REPLACE VIEW v_auditoria_operaciones AS
SELECT id_auditoria, id_tarifa, usuario_bd,
       fecha_evento, operacion, valor_anterior, valor_nuevo
FROM auditoria_tarifa;

-- Recepcion: solo vistas y procedimientos; nunca tablas base.
GRANT SELECT ON v_recepcion_reservas TO rol_tu_recepcion;
GRANT SELECT ON v_recepcion_clientes TO rol_tu_recepcion;
GRANT EXECUTE ON pkg_turismouq TO rol_tu_recepcion;
GRANT EXECUTE ON sp_reserva_pago_atomico TO rol_tu_recepcion;

-- Administrador de alojamiento: gestion operacional limitada.
GRANT SELECT, INSERT, UPDATE ON alojamiento TO rol_tu_admin_alojamiento;
GRANT SELECT, INSERT, UPDATE ON habitacion TO rol_tu_admin_alojamiento;
GRANT SELECT, INSERT, UPDATE ON tarifa TO rol_tu_admin_alojamiento;
GRANT SELECT, INSERT, UPDATE ON servicio TO rol_tu_admin_alojamiento;
GRANT SELECT ON v_admin_alojamientos TO rol_tu_admin_alojamiento;

-- Gerente: lectura administrativa y liquidaciones.
GRANT SELECT ON v_gerencia_ingresos TO rol_tu_gerente;
GRANT SELECT ON mv_ocupacion_mensual TO rol_tu_gerente;
GRANT EXECUTE ON pkg_turismouq TO rol_tu_gerente;

-- Auditor: lectura controlada de auditoria y pagos.
GRANT SELECT ON v_auditoria_operaciones TO rol_tu_auditor;
GRANT SELECT ON pago TO rol_tu_auditor;
GRANT SELECT ON reserva TO rol_tu_auditor;
GRANT SELECT ON reserva_habitacion TO rol_tu_auditor;
