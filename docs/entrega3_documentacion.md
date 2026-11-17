# Entrega 3 - TurismoUQ

**Integrantes:** Walter Jhosepe Granada Bastidas y Daniel Cubillos Grimaldos

**Proyecto:** Plataforma turística del Quindío

**Curso:** Bases de Datos II

## Introducción

Esta entrega integra transacciones, concurrencia, optimización y seguridad sobre el modelo Oracle desarrollado en las entregas anteriores. Los resultados descritos distinguen revisión estática, scripts preparados y pruebas pendientes de ejecución real.

## Objetivos

- Registrar reserva y pago como una operación atómica.
- Evaluar el control concurrente con dos sesiones Oracle.
- Comparar planes de ejecución antes y después de crear índices.
- Implementar perfil, roles y usuarios según mínimo privilegio.

## 1. Transacciones

El procedimiento `sp_reserva_pago_atomico` utiliza `SAVEPOINT reserva_pago_inicio`, valida el intervalo, capacidad, cliente, tarifa, método y monto, y controla el bloqueo mediante `SELECT ... FOR UPDATE`. Si ocurre una excepción, vuelve al SAVEPOINT y vuelve a propagar el error. El procedimiento no contiene COMMIT; el llamador decide cuándo confirmar.

`db/12_pruebas_entrega3.sql` conserva una prueba exitosa y una prueba fallida por monto incoherente. La prueba exitosa debe confirmarse explícitamente con COMMIT y la fallida debe demostrar que no persiste reserva ni pago.

**Evidencia pendiente:** captura de las consultas antes y después de la operación; resultados no disponibles sin ejecución Oracle.

## 2. Concurrencia

Las sesiones A y B usan `db/09_sesion_a.sql` y `db/09_sesion_b.sql`. El procedimiento existente `sp_crear_reserva` y el procedimiento atómico bloquean la fila de HABITACION. Oracle mantiene el aislamiento READ COMMITTED: después del bloqueo, la segunda transacción reevalúa la disponibilidad antes de insertar.

Secuencia:

1. Ejecutar ambos scripts con rangos idénticos.
2. Confirmar A sin confirmar B.
3. Observar si B completa o recibe un bloqueo.
4. Confirmar o revertir B.
5. Consultar las reservas incompatibles.

**Evidencia pendiente:** bloqueo observado, wait de la sesión B, y resultado final en dos sesiones.

## 3. Índices

`db/10_indices.sql` incluye:

1. Índice compuesto `ix_rh_habitacion_fechas` sobre habitación y fechas.
2. Índice basado en función `ix_pago_fecha_funcion` sobre TRUNC(fecha_transaccion).
3. Índice compuesto `ix_reserva_cliente_estado`.
4. Caso negativo `ix_reserva_estado_no_mejora`, útil para mostrar que la baja selectividad puede llevar al optimizador a usar recorrido completo.

El script captura planes EXPLAIN PLAN antes y después y actualiza estadísticas Oracle. Para estadísticas reales debe ejecutarse `DBMS_XPLAN.DISPLAY_CURSOR`.

**Plan antes:** pendiente de ejecución Oracle.

**Plan después:** pendiente de ejecución Oracle.

**Tiempos o estadísticas:** no se inventaron.

## 4. Seguridad

`db/11_seguridad.sql` crea el perfil `tu_app_profile`, los roles:

- `tu_recepcion`
- `tu_admin_alojamiento`
- `tu_gerente`
- `tu_auditor`

El propietario ejecuta `db/11_seguridad_propietario.sql` para crear vistas y otorgar privilegios. Recepción no recibe privilegios sobre tablas base. Administrador gestiona alojamiento, habitaciones, tarifas y servicios. Gerente consulta ingresos y ocupación y puede ejecutar liquidación. Auditor consulta auditoría y registros seleccionados sin modificar datos.

### Matriz de privilegios

| Rol | Vistas autorizadas | Operaciones | Restricciones |
|---|---|---|---|
| Recepción | Reservas y clientes | Ejecutar paquete y reserva/pago | Sin acceso directo a tablas |
| Administrador alojamiento | Catálogo operacional | Insertar y actualizar alojamiento, habitación, tarifa y servicio | Sin administración global |
| Gerente | Ingresos y ocupación | Consultar reportes y liquidar | Sin modificación operativa |
| Auditor | Auditoría | Leer auditoría, pagos y reservas | Sin escritura |

## Resultados

Los scripts están preparados y revisados estáticamente. No se dispone de una instancia Oracle en esta sesión, por lo que no se afirma que se hayan obtenido planes, tiempos ni capturas reales.

## Conclusiones

La versión conserva el modelo anterior y agrega controles de atomicidad, serialización por habitación, herramientas de medición y separación de privilegios. La ejecución y evidencia visual quedan como verificaciones finales en Oracle XE.

## Revisión de requisitos

| Requisito | Estado |
|---|---|
| Reserva y pago atómicos | Implementado |
| SAVEPOINT y rollback real | Implementado; ejecución pendiente |
| Dos sesiones concurrentes | Scripts preparados |
| Índice compuesto | Implementado |
| Índice basado en función | Implementado |
| Caso sin mejora | Implementado |
| Cuatro roles | Implementado |
| Perfil y usuarios | Implementado |
| Documentación académica | Preparada |

## Anexos

Espacios reservados para:

- Captura de la operación exitosa.
- Captura de la operación fallida.
- Planes antes y después.
- Evidencia de bloqueo entre sesiones.
- Prueba negativa de acceso directo de recepción.
