#!/bin/bash

# Actualizar e instalar actualizaciones
sudo apt update
sudo apt upgrade -y

# Limpiar paquetes obsoletos
sudo apt autoremove --purge -y

# Limpiar cachés de paquetes
sudo apt clean

# Limpiar caché de APT
sudo apt autoclean

# Limpiar caché de archivos temporales
sudo rm -rf /tmp/*

# Limpiar caché de thumbnails
sudo rm -rf ~/.cache/thumbnails/*

# Liberar memoria RAM
echo "Liberando memoria RAM..."
sudo sync && sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches' && sudo sh -c 'echo 1 > /proc/sys/vm/drop_caches'
sudo swapoff -a && sudo swapon -a

# Limpieza de Docker
echo "Limpiando Docker..."
# Obtener IDs de los contenedores en ejecución
running_containers=$(docker ps -q --no-trunc)

# Eliminar contenedores detenidos
stopped_containers=$(docker ps -aq --no-trunc --filter "status=exited")
if [ -n "$stopped_containers" ]; then
    docker rm $stopped_containers
fi

# Obtener IDs de las imágenes en uso
used_images=$(docker ps -q --no-trunc --format "{{.Image}}")

# Eliminar imágenes no utilizadas
unused_images=$(docker images -q --no-trunc --filter "dangling=true")
if [ -n "$unused_images" ]; then
    docker rmi $unused_images
fi

# Eliminar imágenes no utilizadas por los contenedores en ejecución
if [ -n "$running_containers" ]; then
    for container_id in $running_containers; do
        container_image=$(docker inspect --format "{{.Image}}" $container_id)
        unused_image=$(docker images -q --no-trunc --filter "dangling=true" --filter "since=$container_image")
        if [ -n "$unused_image" ]; then
            docker rmi $unused_image
        fi
    done
fi

echo "Limpieza de contenedores e imágenes completada."

# Verificar si hubo errores en los comandos anteriores
if [ $? -eq 0 ]; then
    echo "Limpieza completada sin errores."
else
    echo "¡Se produjo un error durante la limpieza!"
fi
