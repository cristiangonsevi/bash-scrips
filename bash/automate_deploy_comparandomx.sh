#!/bin/bash

# Variables de configuración
REMOTE_USER="ubuntu"
REMOTE_HOST="testfront.comparandoseguro.com"
REMOTE_DIR="/home/ubuntu/frontend"
REPO_NAME="comparandomx-frontend"
REPO_URL="git@bitbucket.org:ufconline/${REPO_NAME}.git"
BRANCH_NAME="experimental"
PRIVATE_KEY="/home/cgonzalez/ssh_keys/cseguromx.pem"
PROJECT_NAME="ufc-responsive"
DISTRO_NAME="Ubuntu"

set -e # Finalizar el script si ocurre un error

# Instalar zip si no está presente (para Amazon Linux)
if [[ $(cat /etc/os-release) == *"Ubuntu"* ]]; then
  if ! command -v zip &> /dev/null; then
    echo "Instalando zip en Ubuntu Linux..."
    sudo apt install -y zip
  fi
fi

echo "Repositorio: $REPO_URL"

cd /tmp

# Verificar si la carpeta /tmp/$PROJECT_NAME existe y borrarla si es necesario
echo "Verificar si exite la carpete /tmp/$REPO_NAME"

if [ -d "$REPO_NAME" ]; then
  echo "Borrando la carpeta existente /tmp/$REPO_NAME..."
  rm -rf "$REPO_NAME"
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

# Agregando archivo de environment

echo "============== Creando archivo de environment.prod.ts ================="

carpeta="src/environments"

mv $carpeta/environment.template.ts $carpeta/environment.ts

archivo="$carpeta/environment.prod.ts"

contenido=$(cat << EOF
export const environment = {
  production: true,
  recaptcha: {
    siteKey: '6LeoAFYfAAAAALncOm84wqeXcKl3KouuiFw4UFBH',
  },
  api: {
     url: 'https://testfront.comparandoseguro.com/cseguro-admin',
  },
  emails: ['cgonzalez@ufconline.com', 'jalberto@ufconline.com'],
};

EOF
)

# Crear la carpeta si no existe
if [ ! -d "$carpeta" ]; then
  mkdir -p "$carpeta"
fi

# Crear el archivo si no existe
if [ ! -f "$archivo" ]; then
  echo "$contenido" > "$archivo"
fi

ls -l

# Construir la aplicación
if ! npm install; then
  echo "Error: No se pudo instalar las dependencias de npm."
  exit 1
fi

if ! npm run build -- --prod --aot; then
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

  if [ -d "$REMOTE_DIR" ]; then
    if ! rm -rf "$REMOTE_DIR"/*; then
      echo "Error: No se pudo borrar el contenido de la carpeta remota."
      exit 1
    fi
  else
    echo "Error: La carpeta remota no existe."
    exit 1
  fi

  echo "El contenido de la carpeta remota se ha borrado correctamente."

EOF

# Subir los artifacts al servidor remoto
if ! scp -i "$PRIVATE_KEY" artifacts.zip "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"; then
  echo "Error: No se pudo subir los artifacts al servidor remoto."
  exit 1
fi

# Conectar al servidor remoto y realizar las siguientes operaciones
ssh -i "$PRIVATE_KEY" "$REMOTE_USER@$REMOTE_HOST" << EOF

  set -e # Finalizar el script remoto si ocurre un error

  # Instalar zip si no está presente (para $DISTRO_NAME)
  if [[ \$(cat /etc/os-release) == *"$DISTRO_NAME"* ]]; then
    if ! command -v zip &> /dev/null; then
      echo "Instalando zip en $DISTRO_NAME..."
      sudo apt install -y zip
    fi
  fi

  # Extraer los artifacts
  cd "$REMOTE_DIR"
  if ! unzip -o artifacts.zip; then
    echo "Error: No se pudo extraer los artifacts en el servidor remoto."
    exit 1
  fi


  #node $REMOTE_DIR/server/main.js

  # Borrar los artifacts
  
  if ! rm -rf artifacts.zip; then
    echo "No se pudo borrar artifacts"
    exit 1
  fi

  # Borrar el repositorio
  #rm -rf repo

EOF

# Borrar los artifacts en la computadora local
rm artifacts.zip
rm -rf repo
