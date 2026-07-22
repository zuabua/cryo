#!/usr/bin/env bash

gsettings set org.gnome.desktop.interface icon-theme "Tela-circle-dark"
gsettings set org.gnome.desktop.interface gtk-theme "Tokyonight-Dark"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
gsettings set org.gnome.desktop.interface cursor-theme "Adwaita"
gsettings set org.gnome.desktop.interface font-name "Cantarell 10"
echo "GTK gsettings applied."
