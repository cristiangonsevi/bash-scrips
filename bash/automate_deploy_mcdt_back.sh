#!/bin/bash

# Variables de configuración
PROJECT_NAME="MCDT_BACKEND"
REMOTE_USER="ec2-user"
REMOTE_HOST="3.99.155.148"
REMOTE_DIR="/home/ec2-user/dist_server/$PROJECT_NAME"
REPO_NAME="MCDT_BACKEND"
REPO_URL="git@github.com:crisegoteam/${REPO_NAME}.git"
BRANCH_NAME="experimental"
PRIVATE_KEY="/home/cgonzalez/ssh_keys/mcdt.pem"

set -e # Finalizar el script si ocurre un error

# Instalar zip si no está presente (para Amazon Linux)
if [ $(cat /etc/os-release) = *"Amazon Linux"* ]; then
  if ! command -v zip &> /dev/null; then
    echo "Instalando zip en Ubuntu Linux..."
    sudo apt install -y zip
  fi
fi

echo "Repositorio: $REPO_URL"

cd /tmp

# Verificar si la carpeta /tmp/$PROJECT_NAME existe y borrarla si es necesario
if [ -d "$PROJECT_NAME" ]; then
  echo "Borrando la carpeta existente /tmp/$PROJECT_NAME..."
  rm -rf "$PROJECT_NAME"
fi

# Bajar los últimos cambios de la rama
if ! git clone "$REPO_URL"; then
  echo "Error: No se pudo clonar el repositorio."
  exit 1
fi

cd "$REPO_NAME"
if ! git checkout "$BRANCH_NAME"; then
  echo "Error: No se pudo cambiar a la rama $BRANCH_NAME."
  exit 1
fi

if ! git pull origin "$BRANCH_NAME"; then
  echo "Error: No se pudo obtener los últimos cambios de la rama $BRANCH_NAME."
  exit 1
fi

ls -l

echo "============ Intall nest dependencies ============="


# Construir la aplicación
if ! yarn install --proudction; then
  echo "Error: No se pudo instalar las dependencias de npm."
  exit 1
fi

if ! yarn build; then
  echo "Error: No se pudo construir la aplicación."
  exit 1
fi

#Contruir admin ui
cd admin-ui

yarn install

echo "====== Hacer npm link ============"

yarn build -- --aot

zip -r admin-ui.zip ui

mv admin-ui.zip ../dist

# Comprimir los artifacts
cd "../dist"

echo "============== listing current dir ======================"
pwd
ls -l

unzip admin-ui.zip

if [ ! -d "config" ]; then
  mkdir -p config/env
fi

echo "======================== listing current dir"
ls -l
pwd

# Contenido del archivo prod.env
CONTENT='NODE_ENV=prod
PORT=3000
URL=https://admin.momcandoittoo.com
FRONT_URL=https://test.momcandoittoo.com
ALLOWED_SOURCES=https://admin.momcandoittoo.com,https://test.momcandoittoo.com,https://manage.momcandoittoo.com
JWT_SECRET=mcdt_jwt_secret
DB_NAME=momcandoittoo
DB_HOST=localhost
DB_PORT=3306
DB_USER=admin
DB_PASSWORD=c48khm6nvhjYXxbi

MAIL_FROM_NAME=MCDT - NOREPLY
MAIL_FROM_EMAIL=noreply@momcandoittoo.com
MAIL_ADMIN=albertsevilla1996@gmail.com
MAIL_HOST=in-v3.mailjet.com
MAIL_PORT=465
MAIL_IGNORETLS=false
MAIL_SECURE=false
MAIL_REQUIRETLS=false
MAIL_USER=011c6133587b65826432f92a733a3dd3
MAIL_PASSWORD=43435281aca778f11000de73241f4fb0

AWS_REGION=ca-central-1
AWS_SECRET_KEY=zCdS0issPc4NatLHl5fRkusREOisDD2EFRZb4zFh
AWS_ACCESS_KEY=AKIATPPHOM5UX5OXWR4P
AWS_S3_BUCKET_NAME=momcandoittoo

WEB_PUSH_PUBLIC_KEY=BOQBWMEwFHWSlrhL_lOap5qFez0SLBQnL49uyBhwOX6i74F7sjez1zxkz8b8IHIFIDXxlKy-pNyGH8MqmiNEBGw
WEB_PUSH_PRIVATE_KEY=EsdmVVecIqSiru3UlBNbvHOA4VIQTU3e0s3j5cmbc2w'


# Crear el archivo prod.env en el directorio config
mkdir -p config/env
touch config/env/prod.env
echo "$CONTENT" > config/env/prod.env

echo "Archivo prod.env creado exitosamente en el directorio config."

echo "=========== listando archivos antes de comprimir =================="
ls -l

cd ..

zip -r artifacts.zip dist package.json

# Crear directorio remoto si no existe
ssh -i "$PRIVATE_KEY" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_DIR"

# Borrar contenido previo si hay
ssh -i "$PRIVATE_KEY" "$REMOTE_USER@$REMOTE_HOST" << EOF

  set -e # Finalizar el script remoto si ocurre un error

 echo "========== Intentando borrar $REMOTE_DIR" 
 if [ -d "$REMOTE_DIR" ]; then
    echo "=========== Borrando $REMOTE_DIR"
    sudo rm -rf $REMOTE_DIR
    mkdir -p $REMOTE_DIR
  else
    echo "Error: La carpeta remota no existe."
    exit 1
  fi

  echo "El contenido de la carpeta remota se ha borrado correctamente."
  ls -l $REMOTE_DIR

EOF

# Subir los artifacts al servidor remoto
if ! scp -i "$PRIVATE_KEY" artifacts.zip "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"; then
  echo "Error: No se pudo subir los artifacts al servidor remoto."
  exit 1
fi

# Conectar al servidor remoto y realizar las siguientes operaciones
ssh -i "$PRIVATE_KEY" "$REMOTE_USER@$REMOTE_HOST" << EOF

  set -e # Finalizar el script remoto si ocurre un error

NODE_ENV=prod

  # Instalar zip si no está presente (para Amazon Linux)
  if [[ \$(cat /etc/os-release) == *"Amazon Linux"* ]]; then
    if ! command -v zip &> /dev/null; then
      echo "Instalando zip en Amazon Linux..."
      sudo yum install -y zip
    fi
  fi

  #if [ -d "$REMOTE_DIR" ]; then
    #echo "Borrando la carpeta existente $REMOTE_DIR..."
    #rm -rf "$REMOTE_DIR"
  #fi

  #mkdir -p $REMOTE_DIR

  # Extraer los artifacts
  cd "$REMOTE_DIR"
  if ! unzip -o artifacts.zip; then
    echo "Error: No se pudo extraer los artifacts en el servidor remoto."
    exit 1
  fi
 
  echo "Directorio actual"
  pwd

  echo "Listando directorio actual"
  ls -l

  yarn install --production=true

  pm2 delete mcdt-backend
  pm2 start dist/src/main.js --name mcdt-backend

  #node $REMOTE_DIR/main

  # Borrar los artifacts
  cd ..
  rm -rf artifacts.zip

  # Borrar el repositorio
  rm -rf repo

EOF

# Borrar los artifacts en la computadora local
rm artifacts.zip
rm -rf repo
