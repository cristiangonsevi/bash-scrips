#!/bin/bash

sudo dnf install @base-x gnome-shell gnome-terminal nautilus gnome-calculator gnome-tweaks gnome-system-monitor gnome-software @development-tools htop rar libgtk2.0-0 libasound2 libdbus-glib-1 -y
sudo systemctl enable gdm
sudo systemctl set-default graphical.target

sudo dnf install gnome-terminal-nautilus xdg-user-dirs xdg-user-dirs-gtk ffmpegthumbnailer -y