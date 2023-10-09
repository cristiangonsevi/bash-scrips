#!/bin/bash

# Variables de configuración
PROJECT_NAME="MCDT_FRONTEND"
REMOTE_USER="ec2-user"
REMOTE_HOST="3.99.155.148"
REMOTE_DIR="/home/ec2-user/dist/$PROJECT_NAME"
REPO_NAME="MCDT_FRONTEND"
REPO_URL="git@github.com:crisegoteam/${REPO_NAME}.git"
BRANCH_NAME="experimental"
PRIVATE_KEY="/home/cgonzalez/ssh_keys/mcdt.pem"

set -e # Finalizar el script si ocurre un error

# Instalar zip si no está presente (para Amazon Linux)
if [ $(cat /etc/os-release) == *"Amazon Linux"* ]; then
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

# Construir la aplicación
if ! npm install --legacy-peer-deps; then
  echo "Error: No se pudo instalar las dependencias de npm."
  exit 1
fi

mkdir -p src/environments
CONTENT="
export const environment = {
  production: true,
  api: {
    url: 'https://api.momcandoittoo.com/v1',
  },
  host: {
    url: 'https://test.momcandoittoo.com',
  },
  web_push: {
    publicKey:
      'BOQBWMEwFHWSlrhL_lOap5qFez0SLBQnL49uyBhwOX6i74F7sjez1zxkz8b8IHIFIDXxlKy-pNyGH8MqmiNEBGw',
    privateKey: 'EsdmVVecIqSiru3UlBNbvHOA4VIQTU3e0s3j5cmbc2w',
  },
};
"
touch src/environments/environment.prod.ts 

echo "$CONTENT" > src/environments/environment.prod.ts

echo "====================== Show environment files ========================"

ls -l src/environments 
cat src/environments/environment.prod.ts

if ! npm run build:ssr; then
  echo "Error: No se pudo construir la aplicación."
  exit 1
fi

# Comprimir los artifacts
cd "dist/$PROJECT_NAME"
ls -l
zip -r artifacts.zip .

# Crear directorio remoto si no existe
ssh -i "$PRIVATE_KEY" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_DIR"

# Borrar contenido previo si hay
ssh -i "$PRIVATE_KEY" "$REMOTE_USER@$REMOTE_HOST" << EOF

  set -e # Finalizar el script remoto si ocurre un error
 echo "Borrando contenido de $REMOTE_DIR"
 rm -rf $REMOTE_DIR
 ls -l

 echo "========== Intentando borrar $REMOTE_DIR" 
 if [ -d "$REMOTE_DIR" ]; then
    echo "=========== Borrando $REMOTE_DIR"
    rm -rf $REMOTE_DIR
    mkdir -p $REMOTE_DIR
  else
    echo "Error: La carpeta remota no existe."
    mkdir -p $REMOTE_DIR
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

  # node $REMOTE_DIR/server/main.js
  

# Verificar si el proceso de PM2 existe
if pm2 describe mcdt-frontend >/dev/null 2>&1; then
  # El proceso de PM2 existe, ejecutar el comando para detenerlo
  pm2 delete mcdt-frontend
  if [ $? -eq 0 ]; then
    echo "Proceso de PM2 detenido correctamente."
  else
    echo "Error al detener el proceso de PM2."
  fi
fi

  # Aquí puedes agregar cualquier otra lógica que deseas ejecutar después de verificar la existencia del proceso

  cd
  pm2 start dist/$PROJECT_NAME/server/main.js --name mcdt-frontend

  # Borrar los artifacts
  cd ..
  rm -rf artifacts.zip

  # Borrar el repositorio
  rm -rf repo

EOF

# Borrar los artifacts en la computadora local
rm artifacts.zip
rm -rf repo
