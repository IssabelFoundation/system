#!/bin/bash
#
# issabel_migration_callcenter.sh
#
# Schema-aware restore/migration of a Call Center CE (call_center) mysqldump
# into the live database: loads the dump into a disposable staging database,
# then for every table present in both copies the rows through the columns
# the two schemas share, so a dump from an older module version (columns the
# live schema dropped, columns it later added, latin1 tables) restores
# without touching the live schema itself.
#
# Copyright (C) 2026
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# Strategy / Estrategia:
#   1. Load the dump into a staging database (utf8mb4).
#   2. Per table in both: empty the target (DELETE) and INSERT ... SELECT
#      the common columns inside one transaction, so a failed copy leaves
#      the target table's own rows in place (FK/unique checks off).
#      Target-only tables keep their rows; source-only tables are reported
#      and skipped.
#   3. Re-sync AUTO_INCREMENT, then heal the rows the live module requires:
#      the agentconsole ECCP client must not keep its factory password and
#      must exist, and every agent needs an eccp_password.
#   4. Drop the staging database.
#
# Usage:
#   issabel_migration_callcenter.sh --dump <file.sql> [--db call_center] \
#       [--defaults-file <mysql client cnf>] [--staging <name>] \
#       [--keep-staging] [-h|--help]
#
#   --defaults-file  a mysql option file with [client] credentials; without
#                    it the root password is read from /etc/issabel.conf
#                    (mysqlrootpwd=) and passed through MYSQL_PWD.
#
# Exit codes:
#   0   success
#   2   bad arguments / missing dump file
#   3   target database does not exist
#   5   failed to load the dump into staging
#   6   one or more tables failed to copy

set -uo pipefail

DUMP_FILE=""
TARGET_DB="call_center"
DEFAULTS_FILE=""
STAGING_DB=""
KEEP_STAGING=0

usage() { sed -n '/^# Usage:/,/^# Exit codes:/p' "$0" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dump)          DUMP_FILE="$2"; shift 2 ;;
        --db)            TARGET_DB="$2"; shift 2 ;;
        --defaults-file) DEFAULTS_FILE="$2"; shift 2 ;;
        --staging)       STAGING_DB="$2"; shift 2 ;;
        --keep-staging)  KEEP_STAGING=1; shift ;;
        -h|--help)       usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ -z "$DUMP_FILE" ]]; then
    echo "ERROR: --dump is required | ERROR: --dump es obligatorio" >&2
    exit 2
fi
if [[ ! -f "$DUMP_FILE" || ! -s "$DUMP_FILE" ]]; then
    echo "ERROR: dump file not found or empty: $DUMP_FILE | ERROR: no se encuentra el dump o está vacío: $DUMP_FILE" >&2
    exit 2
fi

MYSQL_USER="root"
MYSQL_PASSWORD=""
if [[ -z "$DEFAULTS_FILE" ]]; then
    if [[ -f /etc/issabel.conf ]]; then
        MYSQL_PASSWORD=$(grep -E '^mysqlrootpwd=' /etc/issabel.conf | head -1 | cut -d= -f2-)
    fi
    if [[ -z "$MYSQL_PASSWORD" ]]; then
        echo "ERROR: no --defaults-file and no mysqlrootpwd in /etc/issabel.conf | ERROR: sin --defaults-file y sin mysqlrootpwd en /etc/issabel.conf" >&2
        exit 2
    fi
fi

# One query helper: mq <db-or-empty> <sql>. --defaults-file must be the
# first mysql argument, so both forms go through here and nowhere else.
mq() {
    local db="$1" sql="$2"
    if [[ -n "$DEFAULTS_FILE" ]]; then
        mysql --defaults-file="$DEFAULTS_FILE" --batch --raw --skip-column-names ${db:+"$db"} -e "$sql"
    else
        MYSQL_PWD="$MYSQL_PASSWORD" mysql -u"$MYSQL_USER" --batch --raw --skip-column-names ${db:+"$db"} -e "$sql"
    fi
}

mqload() { # mqload <db> <file>
    local db="$1" file="$2"
    if [[ -n "$DEFAULTS_FILE" ]]; then
        mysql --defaults-file="$DEFAULTS_FILE" ${db:+"$db"} < "$file"
    else
        MYSQL_PWD="$MYSQL_PASSWORD" mysql -u"$MYSQL_USER" ${db:+"$db"} < "$file"
    fi
}

echo "Restore of $TARGET_DB from $DUMP_FILE | Restauración de $TARGET_DB desde $DUMP_FILE"

# Target database must exist before anything is created
if ! mq "" "SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = '$TARGET_DB';" | grep -qx "$TARGET_DB"; then
    echo "ERROR: target database $TARGET_DB does not exist - install the Call Center module first | ERROR: no existe la base $TARGET_DB - instale primero el módulo Call Center" >&2
    exit 3
fi

[[ -n "$STAGING_DB" ]] || STAGING_DB="${TARGET_DB}_stage_$$"
STAGING_CREATED=0
cleanup() {
    if [[ "$STAGING_CREATED" == "1" && "$KEEP_STAGING" == "0" ]]; then
        mq "" "DROP DATABASE IF EXISTS \`$STAGING_DB\`;" >/dev/null 2>&1 || true
        echo "Staging database $STAGING_DB dropped | Base temporal $STAGING_DB eliminada"
    fi
}
trap cleanup EXIT

if ! mq "" "DROP DATABASE IF EXISTS \`$STAGING_DB\`;" >/dev/null; then
    echo "ERROR: cannot drop a leftover staging database | ERROR: no se pudo eliminar una base temporal previa" >&2
    exit 5
fi
if ! mq "" "CREATE DATABASE \`$STAGING_DB\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;" >/dev/null; then
    echo "ERROR: cannot create staging database $STAGING_DB | ERROR: no se pudo crear la base temporal $STAGING_DB" >&2
    exit 5
fi
STAGING_CREATED=1

echo "Loading dump into $STAGING_DB (this may take a while) | Cargando dump en $STAGING_DB (puede tardar)"
if ! mqload "$STAGING_DB" "$DUMP_FILE" >/dev/null; then
    echo "ERROR: failed to load dump into staging | ERROR: falló la carga del dump en la base temporal" >&2
    exit 5
fi

TARGET_TABLES=$(mq "" "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='$TARGET_DB' AND TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME;")
if [[ -z "$TARGET_TABLES" ]]; then
    echo "ERROR: no base tables found in $TARGET_DB | ERROR: no hay tablas en $TARGET_DB" >&2
    exit 6
fi
SOURCE_TABLES=$(mq "" "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='$STAGING_DB' AND TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME;")

# Source-only tables: nothing to copy them into
for table in $SOURCE_TABLES; do
    if ! printf '%s\n' "$TARGET_TABLES" | grep -qx "$table"; then
        echo "SKIP table $table: not in target schema, not copied | OMITIDA tabla $table: no está en el esquema destino, no se copia"
    fi
done

# Parents first (defensive: FK checks are disabled during the copy anyway)
ORDERED_TABLES=$(mq "" "SELECT t.TABLE_NAME FROM information_schema.TABLES t LEFT JOIN (SELECT DISTINCT TABLE_NAME, REFERENCED_TABLE_NAME FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA='$TARGET_DB' AND REFERENCED_TABLE_NAME IS NOT NULL) k ON k.TABLE_NAME = t.TABLE_NAME WHERE t.TABLE_SCHEMA='$TARGET_DB' AND t.TABLE_TYPE='BASE TABLE' GROUP BY t.TABLE_NAME ORDER BY COUNT(k.REFERENCED_TABLE_NAME), t.TABLE_NAME;")

FAILED_TABLES=()
COPIED=0
for table in $ORDERED_TABLES; do
    if ! printf '%s\n' "$SOURCE_TABLES" | grep -qx "$table"; then
        echo "SKIP table $table: not in source backup, left untouched | OMITIDA tabla $table: no está en el respaldo, no se toca"
        continue
    fi

    COMMON_COLS=$(mq "" "SET SESSION group_concat_max_len=1048576; SELECT IFNULL(GROUP_CONCAT(CONCAT('\`', s.COLUMN_NAME, '\`') ORDER BY t.ORDINAL_POSITION SEPARATOR ', '), 'NULL') FROM information_schema.COLUMNS s JOIN information_schema.COLUMNS t ON t.TABLE_SCHEMA='$TARGET_DB' AND t.TABLE_NAME='$table' AND t.COLUMN_NAME=s.COLUMN_NAME AND IFNULL(t.EXTRA,'') NOT LIKE '%GENERATED%' AND IFNULL(t.EXTRA,'') NOT LIKE '%VIRTUAL%' WHERE s.TABLE_SCHEMA='$STAGING_DB' AND s.TABLE_NAME='$table';")
    if [[ -z "$COMMON_COLS" || "$COMMON_COLS" == "NULL" ]]; then
        echo "SKIP table $table: no common columns with target | OMITIDA tabla $table: sin columnas en común con el destino"
        continue
    fi

    SRC_ROWS=$(mq "$STAGING_DB" "SELECT COUNT(*) FROM \`$table\`;")
    # The emptying and the refill run inside one transaction, so a failed
    # copy leaves the target table's own rows in place: the mysql client
    # stops at the first failed statement and closes the connection without
    # COMMIT, and the server rolls the transaction back. DELETE, not
    # TRUNCATE: TRUNCATE is DDL and commits implicitly, which would empty
    # the table before the INSERT had a chance to fail. The AUTO_INCREMENT
    # resync below covers the counter a DELETE leaves behind.
    COPY_SQL="SET SESSION FOREIGN_KEY_CHECKS=0; SET SESSION UNIQUE_CHECKS=0; SET SESSION SQL_MODE='NO_AUTO_VALUE_ON_ZERO'; START TRANSACTION; DELETE FROM \`$TARGET_DB\`.\`$table\`; INSERT INTO \`$TARGET_DB\`.\`$table\` ($COMMON_COLS) SELECT $COMMON_COLS FROM \`$STAGING_DB\`.\`$table\`; COMMIT;"
    if ! mq "" "$COPY_SQL" >/dev/null; then
        echo "FAIL table $table: copy statement failed | FALLO tabla $table: falló la sentencia de copia"
        FAILED_TABLES+=("$table")
        continue
    fi
    TGT_ROWS=$(mq "$TARGET_DB" "SELECT COUNT(*) FROM \`$table\`;")
    if [[ "$TGT_ROWS" != "$SRC_ROWS" ]]; then
        echo "FAIL table $table: copied $TGT_ROWS of $SRC_ROWS rows | FALLO tabla $table: copiadas $TGT_ROWS de $SRC_ROWS filas"
        FAILED_TABLES+=("$table")
        continue
    fi
    echo "COPY table $table: $SRC_ROWS rows | COPIADA tabla $table: $SRC_ROWS filas"
    COPIED=$((COPIED+1))
done

# Re-sync AUTO_INCREMENT so the next insert does not collide
AI_ROWS=$(mq "" "SELECT t.TABLE_NAME, c.COLUMN_NAME FROM information_schema.TABLES t JOIN information_schema.COLUMNS c ON c.TABLE_SCHEMA=t.TABLE_SCHEMA AND c.TABLE_NAME=t.TABLE_NAME WHERE t.TABLE_SCHEMA='$TARGET_DB' AND t.TABLE_TYPE='BASE TABLE' AND c.EXTRA LIKE '%auto_increment%';")
while IFS=$'\t' read -r tbl col; do
    [[ -z "$tbl" ]] && continue
    NEXT=$(mq "$TARGET_DB" "SELECT IFNULL(MAX(\`$col\`),0)+1 FROM \`$tbl\`;")
    mq "$TARGET_DB" "ALTER TABLE \`$tbl\` AUTO_INCREMENT=$NEXT;" >/dev/null 2>&1 \
        || echo "WARN could not resync AUTO_INCREMENT on $tbl | AVISO no se pudo re-sincronizar AUTO_INCREMENT en $tbl"
done <<< "$AI_ROWS"

# Heal the rows the live module requires (the same statements the module's
# own installer runs), each guarded by table existence.
table_exists() {
    [[ "$(mq "" "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='$TARGET_DB' AND TABLE_TYPE='BASE TABLE' AND TABLE_NAME='$1';")" == "1" ]]
}
if table_exists eccp_authorized_clients; then
    mq "$TARGET_DB" "UPDATE eccp_authorized_clients SET md5_password=MD5(CONCAT(NOW(),RAND())) WHERE username='agentconsole' AND md5_password=MD5('agentconsole');" >/dev/null \
        || echo "WARN could not renew the default agentconsole ECCP password | AVISO no se pudo renovar la contraseña ECCP de fábrica de agentconsole"
    mq "$TARGET_DB" "INSERT INTO eccp_authorized_clients (username, md5_password) SELECT 'agentconsole', MD5(CONCAT(NOW(),RAND())) FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM eccp_authorized_clients WHERE username='agentconsole');" >/dev/null \
        || echo "WARN could not create the agentconsole ECCP client | AVISO no se pudo crear el cliente ECCP agentconsole"
fi
if table_exists agent; then
    mq "$TARGET_DB" "UPDATE agent SET eccp_password=SHA1(CONCAT(NOW(),RAND(),number)) WHERE eccp_password IS NULL OR eccp_password='';" >/dev/null \
        || echo "WARN could not backfill the agents' ECCP passwords | AVISO no se pudo rellenar las contraseñas ECCP de los agentes"
fi

echo "----"
echo "Tables copied: $COPIED | Tablas copiadas: $COPIED"
if [[ ${#FAILED_TABLES[@]} -gt 0 ]]; then
    echo "Migration finished with errors in: ${FAILED_TABLES[*]} | Migración terminada con errores en: ${FAILED_TABLES[*]}"
    exit 6
fi
echo "Migration finished OK | Migración terminada OK"
exit 0
