#!/bin/bash

# Variables de configuración
BACKUP_DIR="/home/cgonzalez/bk"
DATE=$(date +%Y%m%d%H%M%S)
FILENAME="backup_$DATE.tar.gz"
MYSQL_USER="admin"
MYSQL_PASSWORD="admin"

# Buscar contenedores con el nombre que contiene "mysql-container"
containers=$(docker container ls -a --format '{{.Names}}' | grep "mysql")

# Realizar respaldo de cada base de datos en los contenedores encontrados
for container in $containers; do
    # Obtener el ID del contenedor
    container_id=$(docker container ls -aqf "name=$container")

    # Obtener lista de bases de datos
    databases=$(docker exec $container_id mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql)")

    # Crear directorio de respaldo
    mkdir -p $BACKUP_DIR/$container

    # Realizar respaldo de cada base de datos
    for database in $databases; do
        docker exec $container_id mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $database > $BACKUP_DIR/$container/$database.sql
    done
done

# Comprimir los respaldos en un archivo tar.gz
tar -czvf $BACKUP_DIR/$FILENAME -C $BACKUP_DIR .

# Eliminar respaldos individuales
rm -rf $BACKUP_DIR/*/*.sql

echo "Respaldo completo en $BACKUP_DIR/$FILENAME"