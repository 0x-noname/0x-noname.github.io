#!/bin/bash
clear
echo -e "\nAutoUpload\n"
read -p "Nombre máquina: " name
read -p "Nombe Web: " nweb
echo "has introducido $name-$nweb"
echo "[+] Lanzando git status"
git status
echo "[+] Lanzando git add ."
git add .
echo "[+] Lanzando git commit con el comentario $name-$nweb "
git commit -m "add-$name-$nweb"
echo "[+] Lanzando git push"
git push -u origin main
