-- 1. Ocupación por municipio y mes.
SELECT *
FROM (
    SELECT m.nombre AS municipio,
           TO_CHAR(rh.fecha_checkin, 'MM') AS mes,
           rh.id_reserva
    FROM municipio m
    JOIN alojamiento a ON m.id_municipio = a.id_municipio
    JOIN habitacion h ON a.id_alojamiento = h.id_alojamiento
    JOIN reserva_habitacion rh ON h.id_habitacion = rh.id_habitacion
)
PIVOT (
    COUNT(DISTINCT id_reserva)
    FOR mes IN (
        '01' AS Ene, '02' AS Feb, '03' AS Mar, '04' AS Abr, 
        '05' AS May, '06' AS Jun, '07' AS Jul, '08' AS Ago, 
        '09' AS Sep, '10' AS Oct, '11' AS Nov, '12' AS Dic
    )
)
ORDER BY municipio;


-- 2. Ingresos por municipio, tipo de alojamiento y temporada.
-- Usa el subtotal registrado y prioriza temporadas especiales.
WITH NochesReserva AS (
    SELECT m.id_municipio,
           m.nombre AS municipio,
           ta.id_tipo_alojamiento,
           ta.nombre AS tipo_alojamiento,
           rh.id_reserva_habitacion,
           rh.subtotal_calculado / NULLIF(TRUNC(rh.fecha_checkout) - TRUNC(rh.fecha_checkin), 0) AS ingreso_noche,
           TRUNC(rh.fecha_checkin) + n.n - 1 AS fecha_noche
    FROM reserva_habitacion rh
    JOIN habitacion h ON rh.id_habitacion = h.id_habitacion
    JOIN alojamiento a ON h.id_alojamiento = a.id_alojamiento
    JOIN municipio m ON a.id_municipio = m.id_municipio
    JOIN tipo_alojamiento ta ON a.id_tipo_alojamiento = ta.id_tipo_alojamiento
    CROSS JOIN LATERAL (
        SELECT LEVEL AS n
        FROM dual
        CONNECT BY LEVEL <= TRUNC(rh.fecha_checkout) - TRUNC(rh.fecha_checkin)
    ) n
),
CandidatasTemporada AS (
    SELECT nr.*,
           temp.id_temporada,
           temp.nombre AS temporada,
           CASE
               WHEN temp.id_temporada IS NULL THEN NULL
               WHEN UPPER(temp.nombre) LIKE 'TEMPORADA BAJA%' THEN 2
               ELSE 1
           END AS prioridad
    FROM NochesReserva nr
    LEFT JOIN temporada temp
        ON nr.fecha_noche BETWEEN TRUNC(temp.fecha_inicio) AND TRUNC(temp.fecha_fin)
),
TemporadasPriorizadas AS (
    SELECT ct.*,
           MIN(prioridad) OVER (PARTITION BY id_reserva_habitacion, fecha_noche) AS prioridad_minima
    FROM CandidatasTemporada ct
),
NochesClasificadas AS (
    SELECT id_municipio,
           municipio,
           id_tipo_alojamiento,
           tipo_alojamiento,
           id_reserva_habitacion,
           fecha_noche,
           ingreso_noche,
           CASE
               WHEN COUNT(id_temporada) = 0 THEN NULL
               WHEN SUM(CASE WHEN prioridad = prioridad_minima THEN 1 ELSE 0 END) > 1 THEN NULL
               ELSE MIN(CASE WHEN prioridad = prioridad_minima THEN id_temporada END)
           END AS id_temporada,
           CASE
               WHEN COUNT(id_temporada) = 0 THEN '*** SIN TEMPORADA ***'
               WHEN SUM(CASE WHEN prioridad = prioridad_minima THEN 1 ELSE 0 END) > 1 THEN '*** TEMPORADA AMBIGUA ***'
               ELSE MAX(CASE WHEN prioridad = prioridad_minima THEN temporada END)
           END AS temporada
    FROM TemporadasPriorizadas
    GROUP BY id_municipio,
             municipio,
             id_tipo_alojamiento,
             tipo_alojamiento,
             id_reserva_habitacion,
             fecha_noche,
             ingreso_noche
)
SELECT 
    CASE WHEN GROUPING(id_municipio) = 1 THEN '--- TOTAL GENERAL ---' ELSE municipio END AS municipio,
    CASE
        WHEN GROUPING(id_municipio) = 1 THEN NULL
        WHEN GROUPING(id_tipo_alojamiento) = 1 THEN '--- SUBTOTAL MUNICIPIO ---'
        ELSE tipo_alojamiento
    END AS tipo_alojamiento,
    CASE
        WHEN GROUPING(id_municipio) = 1 THEN NULL
        WHEN GROUPING(id_tipo_alojamiento) = 1 THEN NULL
        WHEN GROUPING(id_temporada) = 1 THEN '--- SUBTOTAL TIPO ---'
        ELSE temporada
    END AS temporada,
    ROUND(SUM(ingreso_noche), 2) AS ingresos_totales
FROM NochesClasificadas
GROUP BY ROLLUP (
    (id_municipio, municipio),
    (id_tipo_alojamiento, tipo_alojamiento),
    (id_temporada, temporada)
)
ORDER BY GROUPING(id_municipio),
         municipio,
         GROUPING(id_tipo_alojamiento),
         tipo_alojamiento,
         GROUPING(id_temporada),
         temporada;


-- 3. Tres alojamientos con mayor ingreso por municipio.
WITH IngresosAlojamiento AS (
    SELECT m.id_municipio,
           m.nombre AS municipio,
           a.id_alojamiento,
           a.nombre AS alojamiento,
           SUM(rh.subtotal_calculado) AS ingresos_totales
    FROM municipio m
    JOIN alojamiento a ON m.id_municipio = a.id_municipio
    JOIN habitacion h ON a.id_alojamiento = h.id_alojamiento
    JOIN reserva_habitacion rh ON h.id_habitacion = rh.id_habitacion
    GROUP BY m.id_municipio,
             m.nombre,
             a.id_alojamiento,
             a.nombre
),
RankingIngresos AS (
    SELECT municipio,
           alojamiento,
           ingresos_totales,
           RANK() OVER (PARTITION BY id_municipio ORDER BY ingresos_totales DESC) AS ranking
    FROM IngresosAlojamiento
)
SELECT municipio, alojamiento, ROUND(ingresos_totales, 2) AS ingresos_totales, ranking
FROM RankingIngresos
WHERE ranking <= 3
ORDER BY municipio, ranking, alojamiento;


-- 4. Variación mensual de ingresos.
WITH IngresosMensuales AS (
    SELECT TRUNC(p.fecha_transaccion, 'MM') AS mes_anio,
           SUM(p.monto) AS ingresos_mes
    FROM pago p
    GROUP BY TRUNC(p.fecha_transaccion, 'MM')
)
SELECT 
    TO_CHAR(mes_anio, 'YYYY-MM') AS mes,
    ingresos_mes,
    LAG(ingresos_mes, 1) OVER (ORDER BY mes_anio) AS ingresos_mes_anterior,
    ROUND(ingresos_mes - LAG(ingresos_mes, 1) OVER (ORDER BY mes_anio), 2) AS variacion_absoluta,
    ROUND(((ingresos_mes - LAG(ingresos_mes, 1) OVER (ORDER BY mes_anio)) / 
           NULLIF(LAG(ingresos_mes, 1) OVER (ORDER BY mes_anio), 0)) * 100, 2) || '%' AS variacion_porcentual
FROM IngresosMensuales
ORDER BY mes_anio;


-- 5. Reservas dentro de un rango de fechas.
SELECT r.id_reserva,
       c.nombre_completo AS cliente,
       a.nombre AS alojamiento,
       rh.fecha_checkin,
       rh.fecha_checkout,
       r.estado
FROM reserva r
JOIN cliente c ON r.id_cliente = c.id_cliente
JOIN reserva_habitacion rh ON r.id_reserva = rh.id_reserva
JOIN habitacion h ON rh.id_habitacion = h.id_habitacion
JOIN alojamiento a ON h.id_alojamiento = a.id_alojamiento
WHERE rh.fecha_checkin >= TO_DATE(:fecha_inicio, 'YYYY-MM-DD')
  AND rh.fecha_checkout <= TO_DATE(:fecha_fin, 'YYYY-MM-DD')
ORDER BY rh.fecha_checkin;


-- 6. Vista materializada de ocupación mensual.

-- Elimina la vista previa si existe.
BEGIN
    EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_ocupacion_mensual';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -12003 THEN
            RAISE;
        END IF;
END;
/

CREATE MATERIALIZED VIEW mv_ocupacion_mensual
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT 
    m.nombre AS municipio,
    TO_CHAR(rh.fecha_checkin, 'YYYY-MM') AS mes,
    COUNT(DISTINCT rh.id_reserva) AS total_reservas,
    COUNT(DISTINCT rh.id_habitacion) AS total_habitaciones_reservadas
FROM municipio m
JOIN alojamiento a ON m.id_municipio = a.id_municipio
JOIN habitacion h ON a.id_alojamiento = h.id_alojamiento
JOIN reserva_habitacion rh ON h.id_habitacion = rh.id_habitacion
GROUP BY m.nombre, TO_CHAR(rh.fecha_checkin, 'YYYY-MM');

-- COMPLETE mantiene exactitud con COUNT DISTINCT.
-- ON DEMAND evita recalcular la vista en cada transacción.


-- 7. Resumen de pagos por método.
WITH ResumenPagos AS (
    SELECT 
        SUM(CASE WHEN metodo = 'EFECTIVO' THEN monto ELSE 0 END) AS efectivo,
        SUM(CASE WHEN metodo = 'TARJETA' THEN monto ELSE 0 END) AS tarjeta,
        SUM(CASE WHEN metodo = 'TRANSFERENCIA' THEN monto ELSE 0 END) AS transferencia,
        SUM(CASE WHEN metodo = 'PSE' THEN monto ELSE 0 END) AS pse
    FROM pago
)
SELECT metodo_pago, total_recaudado
FROM ResumenPagos
UNPIVOT (
    total_recaudado FOR metodo_pago IN (
        efectivo AS 'Efectivo',
        tarjeta AS 'Tarjeta',
        transferencia AS 'Transferencia',
        pse AS 'PSE'
    )
);


-- 8. Retención y ticket promedio por tipo de alojamiento.
SELECT 
    ta.nombre AS tipo_alojamiento,
    COUNT(DISTINCT r.id_cliente) AS clientes_unicos,
    ROUND(COUNT(DISTINCT r.id_reserva) / NULLIF(COUNT(DISTINCT r.id_cliente), 0), 2) AS promedio_reservas_por_cliente,
    ROUND(AVG(p.monto), 2) AS ticket_promedio_pago
FROM tipo_alojamiento ta
JOIN alojamiento a ON ta.id_tipo_alojamiento = a.id_tipo_alojamiento
JOIN habitacion h ON a.id_alojamiento = h.id_alojamiento
JOIN reserva_habitacion rh ON h.id_habitacion = rh.id_habitacion
JOIN reserva r ON rh.id_reserva = r.id_reserva
JOIN pago p ON r.id_reserva = p.id_reserva
GROUP BY ta.nombre
ORDER BY ticket_promedio_pago DESC;
