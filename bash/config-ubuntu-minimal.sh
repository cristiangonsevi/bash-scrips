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
sudo apt install gnome-session nautilus ubuntu-wallpapers-jammy gnome-terminal gnome-tweaks gnome-system-monitor gnome-software oxygen-cursor-theme htop rar libgtk2.0-0 libasound2 libdbus-glib-1-2 -y

gsettings set org.gnome.desktop.background picture-uri "/usr/share/backgrounds/warty-final-ubuntu.png"

# Configura el tema del cursor Oxygen como el tema predeterminado
echo "2" | sudo update-alternatives --config x-cursor-theme && 1

# Install auto-cpufreq for laptops
if ! command -v auto-cpufreq &>/dev/null; then
    git clone https://github.com/AdnanHodzic/auto-cpufreq.git
    cd auto-cpufreq && echo "i" | sudo ./auto-cpufreq-installer
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

sudo apt install git curl wget build-essential -y

# Configure Alacritty as the default terminal if there are more than one
# sudo update-alternatives --config x-terminal-emulator

# Install additional fonts (optional)
sudo apt install fonts-firacode fonts-powerline -y

# Install development packages (optional)
sudo apt install python3-pip -y

# Install Flatpak
sudo apt install flatpak -y

# add flatpak repo
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Allow install without prompt password
flatpak remote-modify --system flathub --auth=<system|user>


# Install applications via Flatpak
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

    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
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

# Install Oh My Bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"

# Configura el tema de Powerline como predeterminado
sed -i 's/OSH_THEME=".*"/OSH_THEME="powerline-multiline"/' ~/.bashrc

# Recarga la configuración de la terminal
source ~/.bashrc

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

# Clean up unnecessary packages
sudo apt autoremove -y
sudo apt clean

# Completion message
echo "CONFIGURATION ENDED"
sudo reboot
