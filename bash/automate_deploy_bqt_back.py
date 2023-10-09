import os
import subprocess

# Declaramos las variables que vamos a usar

SSH_KEY = None
SSH_USER = None
SSH_HOST = None
PROJECT_DIR = None
BRANCH_NAME = None

# Preguntamos si vamos a usar llave privada

print("¿Quieres acceder con llave privada? (y/n)")
answer = input()

if answer == "y":
  # Solicitamos la ruta de la llave privada
  print("Introduce la ruta de la llave privada:")
  SSH_KEY = input()

# Solicitamos el nombre de usuario ssh si no está definido

if SSH_USER is None:
  print("Introduce el nombre de usuario ssh:")
  SSH_USER = input()

# Solicitamos el host ssh si no está definido

if SSH_HOST is None:
  print("Introduce el host ssh:")
  SSH_HOST = input()

# Solicitamos el directorio del proyecto si no está definido

if PROJECT_DIR is None:
  print("Introduce el directorio del proyecto:")
  PROJECT_DIR = input()

# Solicitamos la branch a hacer pull si no está definida

if BRANCH_NAME is None:
  print("Introduce la branch a hacer pull:")
  BRANCH_NAME = input()

# Nos conectamos por ssh al servidor remoto

if SSH_KEY is not None:
  command = "ssh -i {} {}@{}".format(SSH_KEY, SSH_USER, SSH_HOST)
else:
  command = "ssh {}".format(SSH_USER, SSH_HOST)

subprocess.run(command)

# Hacemos un git pull

command = "cd {} && git pull origin {}".format(PROJECT_DIR, BRANCH_NAME)
subprocess.run(command)

# Reiniciamos pm2

command = "pm2 restart all"
subprocess.run(command)

