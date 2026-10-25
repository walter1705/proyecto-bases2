"""Configuración local para la conexión a Oracle.

Defina ORACLE_USER, ORACLE_PASSWORD y ORACLE_DSN en el entorno. No guarde
credenciales en este archivo ni lo copie a un repositorio público.
"""

import os

import oracledb


def get_connection() -> oracledb.Connection:
    """Abre la conexión usando variables de entorno."""
    required = ("ORACLE_USER", "ORACLE_PASSWORD", "ORACLE_DSN")
    missing = [name for name in required if not os.getenv(name)]
    if missing:
        raise RuntimeError(
            "Faltan variables de conexión a Oracle: " + ", ".join(missing)
        )

    return oracledb.connect(
        user=os.environ["ORACLE_USER"],
        password=os.environ["ORACLE_PASSWORD"],
        dsn=os.environ["ORACLE_DSN"],
    )
