#!/bin/bash

# Cambia la configuración de needrestart para reiniciar automáticamente los servicios
sudo sed -i 's/#$nrconf{restart} = .*/$nrconf{restart} = "a";/' /etc/needrestart/needrestart.conf

# Muestra el contenido actual del archivo para verificar el cambio
cat /etc/needrestart/needrestart.conf

# Actualiza el sistema y los paquetes
sudo dnf update -y

# Configura dnf para instalaciones desatendidas
echo "assumeyes=1" | sudo tee -a /etc/dnf/dnf.conf

# Instala el entorno de escritorio GNOME
sudo dnf groupinstall "Workstation" -y

# Instala paquetes adicionales
sudo dnf install gnome-tweaks gnome-system-monitor gnome-software htop rar libgtk2.0-0 libasound2 libdbus-glib-1 -y

# Configura el fondo de pantalla
gsettings set org.gnome.desktop.background picture-uri "file:///usr/share/backgrounds/warty-final-ubuntu.png"

# Configura el tema del cursor Oxygen como el tema predeterminado
sudo update-alternatives --config x-cursor-theme <<< 2

# Install auto-cpufreq para laptops
if ! command -v auto-cpufreq &>/dev/null; then
    git clone https://github.com/AdnanHodzic/auto-cpufreq.git
    cd auto-cpufreq && echo "i" | sudo ./auto-cpufreq-installer
fi

# Configura auto-cpufreq
if ! [ -f /etc/auto-cpufreq.conf ]; then
    sudo tee /etc/auto-cpufreq.conf >/dev/null <<EOL
# Configuración para cuando la laptop está usando batería
[battery]
governor = powersave
turbo = auto

# Configuración para cuando la laptop está conectada a la corriente
[charger]
governor = performance
turbo = auto
EOL
fi

# Asegura que GNOME Power Profiles Daemon esté desactivado
# Esto evita conflictos con auto-cpufreq
if pgrep "gnome-power-p" >/dev/null; then
    sudo systemctl stop gnome-power-profiles-daemon
    sudo systemctl disable gnome-power-profiles-daemon
fi

# Instala psutil (necesario para auto-cpufreq)
sudo dnf install python3-psutil -y

# Habilita y inicia el servicio auto-cpufreq
sudo systemctl enable --now auto-cpufreq

# Configura el tamaño de pantalla
for screen in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    xrandr --output $screen --auto
done

# Establece colemak como diseño de teclado predeterminado
setxkbmap us -variant colemak

sudo dnf install git curl wget -y

# Configura Alacritty como terminal predeterminada
#sudo update-alternatives --config x-terminal-emulator

# Instala fuentes adicionales (opcional)
sudo dnf install fira-code-fonts powerline-fonts -y

# Instala paquetes de desarrollo (opcional)
sudo dnf install python3-pip -y

# Instala Flatpak
sudo dnf install flatpak -y

# Agrega el repositorio Flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Instala aplicaciones a través de Flatpak
flatpak_apps=(
    "com.visualstudio.code"
    "com.getpostman.Postman"
    "com.brave.Browser"
    "org.flameshot.Flameshot"
    "io.dbeaver.DBeaverCommunity"
)

for app in "${flatpak_apps[@]}"; do
    flatpak install flathub "$app" -y
done

# Instala Docker (opcional)
sudo dnf install docker -y

# Agrega tu usuario al grupo docker
sudo usermod -aG docker $USER

# Inicia y habilita el servicio Docker
sudo systemctl enable --now docker.service

# Instala Node.js y npm (opcional)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
source ~/.bashrc
nvm install node

# Instala Yarn (opcional)
sudo npm install -g yarn

# Instala Git
sudo dnf install git -y

# Instala Oh My Bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"

# Configura el tema de Powerline como predeterminado
sed -i 's/OSH_THEME=".*"/OSH_THEME="powerline-multiline"/' ~/.bashrc

# Recarga la configuración de la terminal
source ~/.bashrc

# Instala Go
if ! command -v go &>/dev/null; then
    curl -OL https://go.dev/dl/go1.21.1.linux-amd64.tar.gz
    sudo tar -C /usr/local -xvf go1.21.1.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a ~/.profile >/dev/null
    source ~/.profile
fi

# Instala AppImageLauncher
wget https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher-2.2.0-travis995.x86_64.rpm
sudo dnf install appimagelauncher-2.2.0-travis995.x86_64.rpm -y
rm -f appimagelauncher-2.2.0-travis995.x86_64.rpm

# Instala ResponsivelyApp
wget https://github.com/responsively-org/responsively-app-releases/releases/download/v1.8.0/ResponsivelyApp-1.8.0.AppImage
chmod +x ResponsivelyApp-1.8.0.AppImage
app_dir="$HOME/.local/share/applications/ResponsivelyApp"
mkdir -p "$app_dir"
mv ResponsivelyApp-1.8.0.AppImage "$app_dir/"
tee "$app_dir/ResponsivelyApp.desktop" >/dev/null <<EOL
[Desktop Entry]
Name=ResponsivelyApp
Exec="$app_dir/ResponsivelyApp-1.8.0.AppImage"
Icon="$app_dir/icon.png"
Type=Application
Categories=Development;
EOL
chmod +x "$app_dir/ResponsivelyApp.desktop"

# Limpia paquetes innecesarios
sudo dnf autoremove -y
sudo dnf clean all

# Mensaje de finalización
echo "CONFIGURACIÓN FINALIZADA. Reiniciando..."
sudo reboot
