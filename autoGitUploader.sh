#!/bin/bash

#Colours
gr="\e[0;32m\033[1m"
end="\033[0m\e[0m"
yel="\e[0;33m\033[1m"
pur="\e[0;35m\033[1m"
ga="\e[0;37m\033[1m"
tur="\e[0;36m\033[1m"

clear
echo -e "\n${ga}AutoUpload${end}\n"
read -p "[!] Nombre máquina: " name
read -p "[!] Nombe Web: " nweb
#echo -e "\n${ga}[${end}${gr}+${end}${ga}]${end} ${ga}Has introducido${end} ${tur}$name-$nweb${end}"
echo -e "\n${ga}[${end}${gr}+${end}${ga}]${end} ${pur}Lanzando${end} ${yel}git status${end}"
git status
echo -e "${ga}[${end}${gr}+${end}${ga}]${end} ${pur}Lanzando${end} ${yel}git add .${end}"
git add .
echo -e "${ga}[${end}${gr}+${end}${ga}]${end} ${pur}Lanzando${end} ${yel}git commit${end} ${ga}con el comentario${end} ${tur}$name-$nweb${end} "
git commit -m "add-$name-$nweb"
echo -e "${ga}[${end}${gr}+${end}${ga}]${end} ${pur}Lanzando${end} ${yel}git push${end}"
git push -u origin main
