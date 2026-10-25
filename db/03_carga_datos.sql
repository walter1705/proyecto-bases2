-- TurismoUQ: carga reproducible de datos de demostracion.
-- Ejecutar despues de 01_ddl.sql en SQL*Plus, SQLcl o SQL Developer.
-- La carga no depende de data/config.py ni contiene credenciales.

BEGIN
    FOR i IN 1..12 LOOP
        INSERT INTO municipio (nombre, descripcion)
        VALUES (
            CASE i
                WHEN 1 THEN 'Armenia' WHEN 2 THEN 'Salento'
                WHEN 3 THEN 'Filandia' WHEN 4 THEN 'Montenegro'
                WHEN 5 THEN 'Quimbaya' WHEN 6 THEN 'Calarca'
                WHEN 7 THEN 'Circasia' WHEN 8 THEN 'La Tebaida'
                WHEN 9 THEN 'Pijao' WHEN 10 THEN 'Buenavista'
                WHEN 11 THEN 'Cordoba' ELSE 'Genova'
            END,
            'Municipio turistico del Quindio'
        );
    END LOOP;

    INSERT INTO tipo_alojamiento (nombre) VALUES ('Finca Cafetera');
    INSERT INTO tipo_alojamiento (nombre) VALUES ('Hotel Centrico');
    INSERT INTO tipo_alojamiento (nombre) VALUES ('Glamping');
    INSERT INTO tipo_alojamiento (nombre) VALUES ('Hostal');
    INSERT INTO tipo_alojamiento (nombre) VALUES ('Cabana');

    FOR i IN 1..60 LOOP
        INSERT INTO alojamiento (
            id_municipio, id_tipo_alojamiento, nombre, direccion, telefono
        ) VALUES (
            MOD(i - 1, 12) + 1,
            MOD(i * 3, 5) + 1,
            'Alojamiento TurismoUQ ' || TO_CHAR(i),
            'Km ' || TO_CHAR(MOD(i, 15) + 1) || ' via principal',
            '3' || LPAD(TO_CHAR(100000000 + i), 9, '0')
        );
    END LOOP;

    -- 400 habitaciones: los primeros 40 alojamientos tienen 7 y los demas 6.
    FOR alojamiento_id IN 1..60 LOOP
        FOR numero IN 1..(6 + CASE WHEN alojamiento_id <= 40 THEN 1 ELSE 0 END) LOOP
            INSERT INTO habitacion (id_alojamiento, numero, capacidad)
            VALUES (
                alojamiento_id,
                'H-' || LPAD(TO_CHAR(numero), 2, '0'),
                2 + MOD(alojamiento_id + numero, 5)
            );
        END LOOP;
    END LOOP;

    INSERT INTO temporada (nombre, fecha_inicio, fecha_fin)
    VALUES ('Semana Santa 2024', DATE '2024-03-24', DATE '2024-03-31');
    INSERT INTO temporada (nombre, fecha_inicio, fecha_fin)
    VALUES ('Mitad de Ano 2024', DATE '2024-06-15', DATE '2024-07-20');
    INSERT INTO temporada (nombre, fecha_inicio, fecha_fin)
    VALUES ('Diciembre-Enero 2024', DATE '2024-12-01', DATE '2025-01-20');
    INSERT INTO temporada (nombre, fecha_inicio, fecha_fin)
    VALUES ('Temporada Baja 2024', DATE '2024-01-01', DATE '2024-12-31');
    INSERT INTO temporada (nombre, fecha_inicio, fecha_fin)
    VALUES ('Temporada Baja 2025', DATE '2025-01-01', DATE '2025-12-31');
    INSERT INTO temporada (nombre, fecha_inicio, fecha_fin)
    VALUES ('Temporada Media 2025', DATE '2025-04-01', DATE '2025-11-30');
    INSERT INTO temporada (nombre, fecha_inicio, fecha_fin)
    VALUES ('Temporada Alta 2025', DATE '2025-12-01', DATE '2026-01-15');
    INSERT INTO temporada (nombre, fecha_inicio, fecha_fin)
    VALUES ('Temporada Baja 2026', DATE '2026-01-01', DATE '2026-12-31');
    INSERT INTO temporada (nombre, fecha_inicio, fecha_fin)
    VALUES ('Temporada Media 2026', DATE '2026-04-01', DATE '2026-11-30');
    INSERT INTO temporada (nombre, fecha_inicio, fecha_fin)
    VALUES ('Temporada Alta 2026', DATE '2026-12-01', DATE '2027-01-15');

    FOR habitacion_id IN 1..400 LOOP
        FOR temporada_id IN 1..10 LOOP
            INSERT INTO tarifa (id_habitacion, id_temporada, valor_noche)
            VALUES (
                habitacion_id,
                temporada_id,
                100000 + MOD(habitacion_id, 11) * 17500 + temporada_id * 12000
            );
        END LOOP;
    END LOOP;

    FOR i IN 1..3000 LOOP
        INSERT INTO cliente (
            tipo_identificacion, identificacion, nombre_completo, email
        ) VALUES (
            CASE MOD(i, 3) WHEN 0 THEN 'CC' WHEN 1 THEN 'CE' ELSE 'PASAPORTE' END,
            TO_CHAR(10000000 + i),
            'Cliente TurismoUQ ' || TO_CHAR(i),
            'cliente_' || TO_CHAR(i) || '@turismouq.test'
        );
    END LOOP;

    FOR alojamiento_id IN 1..60 LOOP
        INSERT INTO usuario_sistema (
            id_alojamiento, username, password_hash, rol
        ) VALUES (
            alojamiento_id, 'gestor_' || LPAD(TO_CHAR(alojamiento_id), 2, '0'),
            'hash-demo-no-usar-en-produccion', 'GESTOR'
        );
        FOR servicio_id IN 1..5 LOOP
            INSERT INTO servicio (id_alojamiento, nombre, precio_unitario)
            VALUES (
                alojamiento_id,
                CASE servicio_id
                    WHEN 1 THEN 'Tour del Cafe' WHEN 2 THEN 'Paseo a Caballo'
                    WHEN 3 THEN 'Cena Gourmet' WHEN 4 THEN 'Desayuno Tipico'
                    ELSE 'Spa'
                END,
                20000 + servicio_id * 15000 + MOD(alojamiento_id, 7) * 2500
            );
        END LOOP;
    END LOOP;
    INSERT INTO usuario_sistema (
        id_alojamiento, username, password_hash, rol
    ) VALUES (NULL, 'admin_turismouq', 'hash-demo-no-usar-en-produccion', 'ADMIN');

    FOR i IN 1..25000 LOOP
        INSERT INTO reserva (id_cliente, fecha_creacion, estado)
        VALUES (
            MOD(i - 1, 3000) + 1,
            DATE '2024-01-01' + MOD(i * 17, 1095),
            CASE
                WHEN MOD(i, 25) < 11 THEN 'FINALIZADA'
                WHEN MOD(i, 25) < 18 THEN 'CONFIRMADA'
                WHEN MOD(i, 25) < 22 THEN 'PENDIENTE'
                ELSE 'CANCELADA'
            END
        );

        INSERT INTO reserva_habitacion (
            id_reserva, id_habitacion, fecha_checkin, fecha_checkout,
            subtotal_calculado
        ) VALUES (
            i,
            1 + MOD(i * 37, 400),
            DATE '2024-01-03' + MOD(i * 17, 1095),
            DATE '2024-01-03' + MOD(i * 17, 1095) + 1 + MOD(i, 7),
            (1 + MOD(i, 7)) * (130000 + MOD(i * 7919, 220000))
        );

        INSERT INTO pago (id_reserva, fecha_transaccion, monto, metodo)
        VALUES (
            i,
            DATE '2024-01-02' + MOD(i * 17, 1095),
            (1 + MOD(i, 7)) * (130000 + MOD(i * 7919, 220000)),
            CASE MOD(i, 4)
                WHEN 0 THEN 'EFECTIVO' WHEN 1 THEN 'TARJETA'
                WHEN 2 THEN 'TRANSFERENCIA' ELSE 'PSE'
            END
        );

        IF MOD(i, 5) = 0 THEN
            INSERT INTO reserva_servicio (
                id_reserva, id_servicio, cantidad, fecha_consumo, subtotal
            ) VALUES (
                i, 1 + MOD(i * 13, 300), 1 + MOD(i, 4),
                DATE '2024-01-04' + MOD(i * 17, 1095),
                (1 + MOD(i, 4)) * (20000 + MOD(i, 100000))
            );
        END IF;
    END LOOP;

    FOR i IN 1..4500 LOOP
        INSERT INTO resena (
            id_cliente, id_alojamiento, calificacion, comentario, fecha_publicacion
        ) VALUES (
            MOD(i * 7, 3000) + 1,
            MOD(i * 11, 60) + 1,
            CASE
                WHEN MOD(i, 20) < 2 THEN 1
                WHEN MOD(i, 20) < 5 THEN 2
                WHEN MOD(i, 20) < 12 THEN 3
                WHEN MOD(i, 20) < 18 THEN 4
                ELSE 5
            END,
            CASE MOD(i, 4)
                WHEN 0 THEN 'Excelente atencion y ubicacion.'
                WHEN 1 THEN 'Habitacion limpia y comoda.'
                WHEN 2 THEN 'Buena experiencia, volveria.'
                ELSE 'El servicio puede mejorar.'
            END,
            DATE '2024-01-05' + MOD(i * 19, 1100)
        );
    END LOOP;

    COMMIT;
END;
/

PROMPT Carga de datos TurismoUQ completada.
