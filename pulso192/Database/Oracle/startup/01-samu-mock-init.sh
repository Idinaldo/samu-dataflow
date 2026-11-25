#!/bin/bash

state=$(
    sqlplus -s / as sysdba <<'SQL'
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SET VERIFY OFF
SET ECHO OFF
VARIABLE mock_state VARCHAR2(20)
ALTER SESSION SET CONTAINER=FREEPDB1;
DECLARE
    column_count PLS_INTEGER;
    row_count PLS_INTEGER := 0;
BEGIN
    SELECT COUNT(*)
      INTO column_count
      FROM dba_tab_columns
     WHERE owner = 'SYSTEM'
       AND table_name = 'SAMU_OCORRENCIA_BRONZE';

    IF column_count = 36 THEN
        EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM SYSTEM.SAMU_OCORRENCIA_BRONZE'
            INTO row_count;
    END IF;

    IF column_count = 36 AND row_count >= 10 THEN
        :mock_state := 'MOCK_READY';
    ELSE
        :mock_state := 'MOCK_MISSING';
    END IF;
END;
/
PRINT mock_state
EXIT
SQL
) || {
    echo "Could not check the Oracle mock schema."
    exit 1
}

if [[ "$state" == *MOCK_READY* ]]; then
    echo "Oracle mock already initialized; skipping seed."
    return 0
fi

if [[ "$state" != *MOCK_MISSING* ]]; then
    echo "Unexpected Oracle mock check result:"
    echo "$state"
    exit 1
fi

echo "Initializing Oracle mock schema and sample data."
sqlplus -s / as sysdba @/opt/oracle/scripts/setup/01-samu_mock_oracle.sql
