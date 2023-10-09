#!/bin/bash

# Declaramos las variables que vamos a usar

SSH_KEY=""
SSH_USER="ubuntu"
SSH_HOST="backend.brokerquotetool.com"
PROJECT_DIR="/home/ubuntu/ufc-comparador-backend"
BRANCH_NAME="experimental"

# Preguntamos si vamos a usar llave privada

echo "¿Quieres acceder con llave privada? (y/n) default n"
ANSWER="n"
read -r ANSWER

echo "Your answer ""$ANSWER"

if [[ $ANSWER == "y" ]]; then
  # Solicitamos la ruta de la llave privada
  echo "Introduce la ruta de la llave privada:"
  read -r SSH_KEY

  # Verificamos que la llave exista
  if [[ ! -f "$SSH_KEY" ]]; then
    echo "La llave privada no existe."
    exit 1
  fi
else
  echo "User press a different key"
  exit 1
fi

# Solicitamos el nombre de usuario ssh si no está definido

if [[ -z "$SSH_USER" ]]; then
  echo "Introduce el nombre de usuario ssh:"
  read -r SSH_USER
else
  echo "*************** Current ssh user is: $SSH_USER ***************"
  echo "Would you like to change it? y/n "
  read -r ANSWER
  if [[ $ANSWER == "y" ]]; then
    echo "Introduce el user ssh:"
    read -r SSH_USER
  fi
fi

# Solicitamos el host ssh si no está definido

if [[ -z "$SSH_HOST" ]]; then
  echo "Introduce el host ssh:"
  read -r SSH_HOST
else
  echo "*************** Current host is: $SSH_HOST ***************"
  echo "Would you like to change it? y/n "
  read -r ANSWER
  if [[ $ANSWER == "y" ]]; then
    echo "Introduce el host ssh:"
    read -r SSH_HOST
  fi
fi

# Solicitamos el directorio del proyecto si no está definido

if [[ -z "$PROJECT_DIR" ]]; then
  echo "Introduce el directorio del proyecto:"
  read -r PROJECT_DIR
else
  echo "*************** Current ssh folder is: $PROJECT_DIR ***************"
  echo "Would you like to change it? y/n "
  read -r ANSWER
  if [[ $ANSWER == "y" ]]; then
    echo "Introduce el project dir:"
    read -r PROJECT_DIR
  fi
fi

# Solicitamos la branch a hacer pull si no está definida

if [[ -z "$BRANCH_NAME" ]]; then
  echo "Introduce la branch a hacer pull:"
  read -r BRANCH_NAME
else
  echo "*************** Current git branch is: $BRANCH_NAME ***************"
  echo "Would you like to change it? y/n "
  read -r ANSWER
  if [[ $ANSWER == "y" ]]; then
    echo "Introduce el git branch:"
    read -r BRANCH_NAME
  fi
fi

echo "Is thi information ok? y/n"
echo "=== SSH KEY: $SSH_KEY"
echo "=== SSH USER: $SSH_USER"
echo "=== SSH HOST: $SSH_HOST"
echo "=== PROJECT DIR: $PROJECT_DIR"
echo "=== GIT BRANCH: $BRANCH_NAME"
read -r ANSWER

if [[ $ANSWER == 'n' ]]; then
  exit
fi

# Nos conectamos por ssh al servidor remoto

ssh -i "$SSH_KEY" "$SSH_USER"@"$SSH_HOST" <<EOF

# Hacemos un git pull

cd "$PROJECT_DIR" || return
git pull origin "$BRANCH_NAME"

# Reiniciamos pm2

pm2 restart all

EOF
