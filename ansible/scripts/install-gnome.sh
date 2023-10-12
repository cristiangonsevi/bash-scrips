#!/bin/bash

sudo dnf install @base-x gnome-shell gnome-terminal nautilus gnome-calculator gnome-tweaks gnome-system-monitor gnome-software @development-tools htop -y
sudo systemctl enable gdm
sudo systemctl set-default graphical.target

sudo dnf install gnome-terminal-nautilus -y
