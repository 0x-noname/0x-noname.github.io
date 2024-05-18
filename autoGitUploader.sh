#!/bin/bash

# Colores
gr="\e[0;32m\033[1m"
end="\033[0m\e[0m"
yel="\e[0;33m\033[1m"
pur="\e[0;35m\033[1m"
ga="\e[0;37m\033[1m"
tur="\e[0;36m\033[1m"

clear
echo -e "\n${ga}AutoGitUploader${end}\n"
read -p "[!] Nombre máquina: " name
read -p "[!] Plataforma: " nweb

echo -e "\n${ga}[${end}${gr}+${end}${ga}]${end} ${pur}Lanzando${end} ${yel}git status${end}\n"
git status

echo -e "\n${ga}[${end}${gr}+${end}${ga}]${end} ${pur}Lanzando${end} ${yel}git add --all :!autoGitUploader.sh${end}\n"
git add --all ':!autoGitUploader.sh'

echo -e "\n${ga}[${end}${gr}+${end}${ga}]${end} ${pur}Lanzando${end} ${yel}git commit${end} ${ga}con el comentario${end} ${tur}$name-$nweb${end}\n"
git commit -S -m "add-$name-$nweb"

echo -e "\n${ga}[${end}${gr}+${end}${ga}]${end} ${pur}Lanzando${end} ${yel}git push${end}\n"
git push -u origin main
