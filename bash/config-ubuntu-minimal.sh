#!/bin/bash

# Cambia la configuración de needrestart para reiniciar automáticamente los servicios
sudo sed -i 's/#$nrconf{restart} = .*/$nrconf{restart} = "a";/' /etc/needrestart/needrestart.conf

# Muestra el contenido actual del archivo para verificar el cambio
cat /etc/needrestart/needrestart.conf


# Actualiza el sistema y los paquetes
sudo apt update && sudo apt upgrade -y

# Configura dpkg para instalaciones desatendidas
echo "force-unsafe-io" | sudo tee /etc/dpkg/dpkg.cfg.d/01_nodoc

# Instala Ubuntu Desktop (ejemplo: Ubuntu Desktop)
# sudo apt install ubuntu-desktop-minimal
# for pure and minimal installation of gnome
sudo apt install gnome-session -y

sudo apt-get install gnome-tweak-tool

# Actualiza la lista de paquetes
sudo apt update

# Instala el tema del cursor Oxygen
sudo apt install oxygen-cursor-theme -y

# Configura el tema del cursor Oxygen como el tema predeterminado
sudo update-alternatives --config x-cursor-theme

# Install auto-cpufreq for laptops
if ! command -v auto-cpufreq &>/dev/null; then
    git clone https://github.com/AdnanHodzic/auto-cpufreq.git
    cd auto-cpufreq && sudo ./auto-cpufreq-installer
fi

# Configure auto-cpufreq
if ! [ -f /etc/auto-cpufreq.conf ]; then
    sudo tee /etc/auto-cpufreq.conf >/dev/null <<EOL
# Configuration for when the laptop is using battery
[battery]
governor = powersave
turbo = auto

# Configuration for when the laptop is connected to AC power
[charger]
governor = performance
turbo = auto
EOL
fi

# Ensure GNOME Power Profiles Daemon is disabled
# This prevents conflicts with auto-cpufreq
if pgrep "gnome-power-p" >/dev/null; then
    sudo systemctl stop gnome-power-profiles-daemon
    sudo systemctl disable gnome-power-profiles-daemon
fi

# Install psutil (required for auto-cpufreq)
sudo apt install python3-psutil -y

# Enable and start the auto-cpufreq service
sudo systemctl enable --now auto-cpufreq

# Set screen size
for screen in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    xrandr --output $screen --auto
done

# Set colemak as the default keyboard layout
setxkbmap us -variant colemak

# Install Alacritty and other useful tools

# Install necesary packages to install alacrity
sudo apt install cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3 -y

# Install rust for alacrity
sudo curl https://sh.rustup.rs -sSf | sh

# Add repo for install alacrity
sudo add-apt-repository ppa:aslatter/ppa -y

sudo apt install alacritty git curl wget build-essential -y

# Configure Alacritty as the default terminal
sudo update-alternatives --config x-terminal-emulator

# Install additional fonts (optional)
sudo apt install fonts-firacode fonts-powerline -y

# Install development packages (optional)
sudo apt install python3-pip -y

# Install Flatpak
sudo apt install flatpak -y

# add flatpak repo
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install applications via Flatpak
flatpak_apps=(
    "com.visualstudio.code"
    "org.audacityteam.Audacity"
    "com.bitwarden.desktop"
    "com.getpostman.Postman"
    "com.google.Chrome"
    "org.videolan.VLC"
    "io.github.mimbrero.WhatsAppDesktop"
    "org.gnome.baobab"
    "com.obsproject.Studio"
    "com.brave.Browser"
    "net.codeindustry.MasterPDFEditor"
    "us.zoom.Zoom"
    "org.mozilla.Thunderbird"
    "com.github.IsmaelMartinez.teams_for_linux"
    "io.missioncenter.MissionCenter"
    "org.gnome.Calculator"
    "org.flameshot.Flameshot"
    "org.gnome.Weather"
    "org.gnome.Calendar"
    "io.github.prateekmedia.appimagepool"
)

for app in "${flatpak_apps[@]}"; do
    flatpak install flathub "$app" -y
done

# Install Firefox Developer Edition dependencies
sudo apt-get install libgtk2.0-0 libasound2 libdbus-glib-1-2 -y

# Install Docker (optional)

for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

if ! command -v docker &>/dev/null; then
    # Set up Docker's Apt repository
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources:
    echo \
        "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |
        sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt-get update

    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo groupadd docker
    sudo usermod -aG docker $USER
    newgrp docker
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service

    # #To stop this behavior, use disable instead.
    # sudo systemctl disable docker.service
    # sudo systemctl disable containerd.service
fi

# Install Node.js and npm
if ! command -v node &>/dev/null; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    source ~/.bashrc
    nvm install node
fi

# Install Yarn (optional)
if ! command -v yarn &>/dev/null; then
    sudo npm install -g yarn
fi

# Install Git
sudo apt install git -y

# Install Oh My Zsh
if ! [ -d ~/.oh-my-zsh ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install Go
if ! command -v go &>/dev/null; then
    curl -OL https://go.dev/dl/go1.21.1.linux-amd64.tar.gz
    sudo tar -C /usr/local -xvf go1.21.1.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a ~/.profile >/dev/null
    source ~/.profile
fi

# Install AppImageLauncher
wget https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher_2.2.0-travis995.0f91801.bionic_amd64.deb
sudo dpkg -i appimagelauncher_2.2.0-travis995.0f91801.bionic_amd64.deb
sudo apt-get install -f
rm -f appimagelauncher_2.2.0-travis995.0f91801.bionic_amd64.deb

# Install ResponsivelyApp
wget https://github.com/responsively-org/responsively-app-releases/releases/download/v1.8.0/ResponsivelyApp-1.8.0.AppImage
chmod +x ResponsivelyApp-1.8.0.AppImage
app_dir="/usr/local/share/applications/ResponsivelyApp"
sudo mkdir -p "$app_dir"
sudo mv ResponsivelyApp-1.8.0.AppImage "$app_dir/"
sudo tee "$app_dir/ResponsivelyApp.desktop" >/dev/null <<EOL
[Desktop Entry]
Name=ResponsivelyApp
Exec="$app_dir/ResponsivelyApp-1.8.0.AppImage"
Icon="$app_dir/icon.png"
Type=Application
Categories=Development;
EOL
sudo chmod +x "$app_dir/ResponsivelyApp.desktop"

# Install MySQL Workbench
wget https://dev.mysql.com/get/mysql-apt-config_0.8.16-1_all.deb
sudo dpkg -i mysql-apt-config_0.8.16-1_all.deb
sudo apt update
sudo apt install mysql-workbench -y
rm mysql-apt-config_0.8.16-1_all.deb

# Install additional packages
sudo apt install htop rar -y

# Clean up unnecessary packages
sudo apt autoremove -y
sudo apt clean

# Completion message
echo "CONFIGURATION ENDED"
