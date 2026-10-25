import os
import random
from datetime import datetime, timedelta

from config import get_connection
from faker import Faker

fake = Faker("es_CO")
random.seed(2025)
fake.seed_instance(2025)


def poblar_base_datos():
    """Genera y carga los datos de prueba del modelo TurismoUQ."""
    conn = get_connection()
    cursor = conn.cursor()
    print("Iniciando carga masiva basada en el Diagrama ER entregado...")

    # Municipios.
    municipios = [
        "Armenia",
        "Salento",
        "Filandia",
        "Montenegro",
        "Quimbaya",
        "Calarcá",
        "Circasia",
        "La Tebaida",
        "Pijao",
        "Buenavista",
        "Córdoba",
        "Génova",
    ]
    for mun in municipios:
        cursor.execute(
            "INSERT INTO municipio (nombre, descripcion) VALUES (:1, :2)",
            [mun, f"Municipio de {mun}, Quindío"],
        )
    print("✓ 12 Municipios insertados.")

    # Tipos de alojamiento.
    tipos = ["Finca Cafetera", "Hotel Céntrico", "Glamping", "Hostal", "Cabaña"]
    for t in tipos:
        cursor.execute("INSERT INTO tipo_alojamiento (nombre) VALUES (:1)", [t])
    print("✓ 5 Tipos de Alojamiento insertados.")

    # Alojamientos.
    alojamientos_data = []
    prefijos = ["Finca La", "Hotel El", "Glamping Alto", "Hostal", "Cabañas Las"]
    for i in range(1, 61):
        nombre = f"{prefijos[(i - 1) % len(prefijos)]} {fake.first_name()} #{i}"
        direccion = f"Km {random.randint(1, 15)} Vía {fake.street_name()}"
        telefono = f"3{random.randint(100000000, 999999999)}"
        id_mun = (i % 12) + 1
        id_tipo = ((i * 3) % 5) + 1
        alojamientos_data.append((id_mun, id_tipo, nombre, direccion, telefono))
    
    cursor.executemany("""
        INSERT INTO alojamiento (id_municipio, id_tipo_alojamiento, nombre, direccion, telefono)
        VALUES (:1, :2, :3, :4, :5)
    """, alojamientos_data)
    print("✓ 60 Alojamientos insertados.")

    # Habitaciones.
    habitaciones_data = []
    for id_aloj in range(1, 61):
        cantidad = 6 + (1 if id_aloj <= 40 else 0)
        for numero in range(1, cantidad + 1):
            habitaciones_data.append(
                (id_aloj, f"H-{numero:02d}", 2 + ((id_aloj + numero) % 5))
            )

    cursor.executemany("""
        INSERT INTO habitacion (id_alojamiento, numero, capacidad)
        VALUES (:1, :2, :3)
    """, habitaciones_data)
    print("✓ 400 Habitaciones insertadas.")

    # Temporadas y tarifas.
    temporadas = [
        ("Semana Santa 2024", datetime(2024, 3, 24), datetime(2024, 3, 31)),
        ("Mitad de Año 2024", datetime(2024, 6, 15), datetime(2024, 7, 20)),
        ("Diciembre-Enero 2024", datetime(2024, 12, 1), datetime(2025, 1, 20)),
        ("Temporada Baja 2024", datetime(2024, 1, 1), datetime(2024, 12, 31)),
        ("Temporada Baja 2025", datetime(2025, 1, 1), datetime(2025, 12, 31)),
        ("Temporada Media 2025", datetime(2025, 4, 1), datetime(2025, 11, 30)),
        ("Temporada Alta 2025", datetime(2025, 12, 1), datetime(2026, 1, 15)),
        ("Temporada Baja 2026", datetime(2026, 1, 1), datetime(2026, 12, 31)),
        ("Temporada Media 2026", datetime(2026, 4, 1), datetime(2026, 11, 30)),
        ("Temporada Alta 2026", datetime(2026, 12, 1), datetime(2027, 1, 15)),
    ]
    for nom, f_in, f_out in temporadas:
        cursor.execute(
            "INSERT INTO temporada (nombre, fecha_inicio, fecha_fin) VALUES (:1, :2, :3)",
            [nom, f_in, f_out],
        )

    tarifas_data = []
    for h_id in range(1, len(habitaciones_data) + 1):
        for temp_id in range(1, len(temporadas) + 1):
            precio = round(100000 + (h_id % 11) * 17500 + temp_id * 12000, 2)
            tarifas_data.append((h_id, temp_id, precio))

    cursor.executemany(
        "INSERT INTO tarifa (id_habitacion, id_temporada, valor_noche) VALUES (:1, :2, :3)",
        tarifas_data,
    )
    print("✓ Temporadas y Tarifas insertadas.")

    # Clientes.
    clientes_data = []
    tipos_doc = ["CC", "CE", "PASAPORTE"]
    for i in range(1, 3001):
        doc = f"{random.randint(10000000, 1099999999)}"
        tdoc = random.choice(tipos_doc)
        nombre = f"{fake.first_name()} {fake.last_name()}"
        email = f"cliente_{i}_{doc}@mail.com"
        clientes_data.append((tdoc, doc, nombre, email))

    cursor.executemany("""
        INSERT INTO cliente (tipo_identificacion, identificacion, nombre_completo, email)
        VALUES (:1, :2, :3, :4)
    """, clientes_data)
    print("✓ 3.000 Clientes insertados.")

    # Servicios.
    servicios_data = []
    nombres_serv = ["Tour del Café", "Paseo a Caballo", "Cena Gourmet", "Desayuno Típico", "Spa"]
    for aloj_id in range(1, 61):
        for s_nom in nombres_serv:
            precio = round(random.uniform(20000, 120000), 2)
            servicios_data.append((aloj_id, s_nom, precio))
            
    cursor.executemany(
        "INSERT INTO servicio (id_alojamiento, nombre, precio_unitario) VALUES (:1, :2, :3)",
        servicios_data,
    )
    print("✓ Servicios asociados a Alojamientos insertados.")

    usuarios_data = [
        (id_aloj, f"gestor_{id_aloj:02d}", "hash-demo-no-usar-en-produccion", "GESTOR")
        for id_aloj in range(1, 61)
    ]
    usuarios_data.append(
        (None, "admin_turismouq", "hash-demo-no-usar-en-produccion", "ADMIN")
    )
    cursor.executemany(
        """INSERT INTO usuario_sistema
           (id_alojamiento, username, password_hash, rol)
           VALUES (:1, :2, :3, :4)""",
        usuarios_data,
    )

    # Reservas, pagos y servicios.
    print("Generando 25.000 reservas...")
    reservas_data = []
    reserva_hab_data = []
    reserva_serv_data = []
    pagos_data = []
    estados = ["CONFIRMADA", "FINALIZADA", "CANCELADA", "PENDIENTE"]
    metodos = ["EFECTIVO", "TARJETA", "TRANSFERENCIA", "PSE"]

    start_date = datetime(2024, 1, 1)
    room_ids = list(range(1, len(habitaciones_data) + 1))
    room_weights = [1 + (room_id % 9) for room_id in room_ids]
    reservation_count = int(os.getenv("RESERVATION_COUNT", "25000"))
    
    for r_id in range(1, reservation_count + 1):
        f_creac = start_date + timedelta(days=random.randint(0, 900))
        f_in = f_creac + timedelta(days=random.randint(1, 15))
        f_out = f_in + timedelta(days=random.randint(1, 7))
        estado = random.choices(
            estados, weights=[18, 42, 12, 28], k=1
        )[0]
        id_cli = random.randint(1, 3000)
        
        reservas_data.append((id_cli, f_creac, estado))
        
        id_hab = random.choices(room_ids, weights=room_weights, k=1)[0]
        noches = (f_out - f_in).days
        subtotal_hab = round(noches * random.uniform(130000, 350000), 2)
        reserva_hab_data.append((r_id, id_hab, f_in, f_out, subtotal_hab))
        
        pagos_data.append(
            (r_id, f_creac + timedelta(hours=2), subtotal_hab, random.choice(metodos))
        )

    cursor.executemany(
        "INSERT INTO reserva (id_cliente, fecha_creacion, estado) VALUES (:1, :2, :3)",
        reservas_data,
    )
    cursor.executemany("""
        INSERT INTO reserva_habitacion (id_reserva, id_habitacion, fecha_checkin, fecha_checkout, subtotal_calculado)
        VALUES (:1, :2, :3, :4, :5)
    """, reserva_hab_data)
    cursor.executemany(
        "INSERT INTO pago (id_reserva, fecha_transaccion, monto, metodo) VALUES (:1, :2, :3, :4)",
        pagos_data,
    )

    # Líneas de servicio.
    for _ in range(round(reservation_count * 1.6)):
        id_res = random.randint(1, reservation_count)
        id_serv = random.randint(1, 300)  # 60 alojamientos * 5 servicios
        cant = random.randint(1, 4)
        p_unit = round(random.uniform(20000, 100000), 2)
        subtot = cant * p_unit
        f_consumo = start_date + timedelta(days=random.randint(0, 900))
        reserva_serv_data.append((id_res, id_serv, cant, f_consumo, subtot))

    cursor.executemany("""
        INSERT INTO reserva_servicio (id_reserva, id_servicio, cantidad, fecha_consumo, subtotal)
        VALUES (:1, :2, :3, :4, :5)
    """, reserva_serv_data)

    resenas_data = []
    for _ in range(round(reservation_count * 0.18)):
        id_cli = random.randint(1, 3000)
        id_aloj = random.randint(1, 60)
        resenas_data.append(
            (
                id_cli,
                id_aloj,
                random.choices([1, 2, 3, 4, 5], weights=[2, 3, 8, 24, 18], k=1)[0],
                random.choice(
                    [
                        "Excelente atención y ubicación.",
                        "La habitación estaba limpia y cómoda.",
                        "Buena experiencia, volvería.",
                        "El servicio puede mejorar.",
                    ]
                ),
                start_date + timedelta(days=random.randint(0, 1100)),
            )
        )
    cursor.executemany(
        """INSERT INTO resena
           (id_cliente, id_alojamiento, calificacion, comentario, fecha_publicacion)
           VALUES (:1, :2, :3, :4, :5)""",
        resenas_data,
    )

    conn.commit()
    cursor.close()
    conn.close()
    print("¡CARGA MASIVA COMPLETADA Y ALINEADA AL DIAGRAMA ER!")

if __name__ == '__main__':
    poblar_base_datos()