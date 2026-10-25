-- Ejecutar como SYS o SYSTEM, no como el usuario operativo del proyecto.
-- Sustituya la ruta por un directorio permitido en su instalación XE 21c.
DEFINE DATAFILE_PATH = '/ruta/valida/oracle/turismouq_historico01.dbf'
DEFINE PROJECT_USER = 'USUARIO_TURISMOUQ'

CREATE TABLESPACE turismouq_historico
DATAFILE '&DATAFILE_PATH'
SIZE 100M
AUTOEXTEND ON NEXT 10M MAXSIZE 500M;

GRANT QUOTA UNLIMITED ON turismouq_historico TO &PROJECT_USER;

-- Verificación administrativa:
SELECT tablespace_name, status, contents
FROM dba_tablespaces
WHERE tablespace_name = 'TURISMOUQ_HISTORICO';
