#!/bin/sh
set -ex
cd `dirname $0`

ISUCON_DB_HOST=$1
ISUCON_DB_PORT=${ISUCON_DB_PORT:-3306}
ISUCON_DB_USER=${ISUCON_DB_USER:-isucon}
ISUCON_DB_PASSWORD=${ISUCON_DB_PASSWORD:-isucon}
ISUCON_DB_NAME=${ISUCON_DB_NAME:-isucon}

mysql -u"$ISUCON_DB_USER" \
		-p"$ISUCON_DB_PASSWORD" \
		--host "$ISUCON_DB_HOST" \
		--port "$ISUCON_DB_PORT" \
		"$ISUCON_DB_NAME" < 3_schema_exclude_user_presents.sql

mysql -u"$ISUCON_DB_USER" \
		-p"$ISUCON_DB_PASSWORD" \
		--host "$ISUCON_DB_HOST" \
		--port "$ISUCON_DB_PORT" \
		"$ISUCON_DB_NAME" < 4_alldata_exclude_user_presents.sql

echo "delete from user_presents where id > 100000000000 or id < 0" | mysql -u"$ISUCON_DB_USER" \
		-p"$ISUCON_DB_PASSWORD" \
		--host "$ISUCON_DB_HOST" \
		--port "$ISUCON_DB_PORT" \
		"$ISUCON_DB_NAME"

DIR=`mysql -u"$ISUCON_DB_USER" -p"$ISUCON_DB_PASSWORD" -h "$ISUCON_DB_HOST" -Ns -e "show variables like 'secure_file_priv'" | cut -f2`
SECURE_DIR=${DIR:-/var/lib/mysql-files/}

sudo cp 5_user_presents_not_receive_data.tsv ${SECURE_DIR}/${ISUCON_DB_HOST}.tsv

echo "LOAD DATA LOCAL INFILE '${SECURE_DIR}/${ISUCON_DB_HOST}.tsv' REPLACE INTO TABLE user_presents FIELDS ESCAPED BY '|' IGNORE 1 LINES ;" | sudo mysql -u"$ISUCON_DB_USER" \
        -p"$ISUCON_DB_PASSWORD" \
        --host "$ISUCON_DB_HOST" \
        --port "$ISUCON_DB_PORT" \
        --enable-local-infile \
        "$ISUCON_DB_NAME"
