---
layout: single
title: Dominator - HackMyVM
excerpt: "Empezamos el 2022 con Dominator, Dominator es una máquina Linux creada por d4t4s3c, en esta máquina encontraremos una llave rsa
en un directorio oculto, el cual tendremos que crackear para encontrar el passphrase para conectarnos al sistema. Una vez dentro del 
sistema elevaremos privilegios mediante un binario con el bit SUID activado."
date: 2022-01-01
classes: wide
header:
  teaser: /assets/images/hmvm-Dominator/hmvmDominator.png
  teaser_home_page: true
  icon: /assets/images/hmvm.png
categories:
  - hackmyvm
  - linux
  - Fácil
tags:
  - hackmyvm
  - dig
  - dns
  - ssh
  - suid
  - d4t4s3c
---

### Escaneo de puertos
```bash
nmap -p- -T5 --open -v -n -Pn 10.0.2.8

PORT      STATE SERVICE
53/tcp    open  domain
80/tcp    open  http
65222/tcp open  unknown
```

### Escaneo de servicios
```bash
nmap -sCV -p 53,80,65222 10.0.2.8

PORT      STATE SERVICE VERSION
53/tcp    open  domain  (unknown banner: not currently available)
| fingerprint-strings: 
|   DNSVersionBindReqTCP: 
|     version
|     bind
|_    currently available
| dns-nsid: 
|_  bind.version: not currently available
80/tcp    open  http    Apache httpd 2.4.38 ((Debian))
|_http-title: Apache2 Debian Default Page: It works
|_http-server-header: Apache/2.4.38 (Debian)
65222/tcp open  ssh     OpenSSH 7.9p1 Debian 10+deb10u2 (protocol 2.0)
| ssh-hostkey: 
|   2048 f7:ea:48:1a:a3:46:0b:bd:ac:47:73:e8:78:25:af:42 (RSA)
|   256 2e:41:ca:86:1c:73:ca:de:ed:b8:74:af:d2:06:5c:68 (ECDSA)
|_  256 33:6e:a2:58:1c:5e:37:e1:98:8c:44:b1:1c:36:6d:75 (ED25519)
```

### Escaneo web
```bash
nmap --script http-enum -p80 10.0.2.8          

PORT   STATE SERVICE
80/tcp open  http
| http-enum: 
|_  /robots.txt: Robots file
```

### Robots

![](/assets/images/hmvm-Dominator/robots.png)

Añado el nombre de dominio a mi archivo hosts y lanzo dig.

![](/assets/images/hmvm-Dominator/dig.png)

Pongo el directorio encontrado en la url pero no me muestra ninguna página.

![](/assets/images/hmvm-Dominator/directorioraro.png)

Me voy a cyberchef y decodifico la cadena de texto.

![](/assets/images/hmvm-Dominator/cocinerorot13.png)

Ahora pongo el directorio `supersecret` en la url y veo lo siguiente:

![](/assets/images/hmvm-Dominator/supersecret.png)

Le doy click a hans_key y veo que se trata de una llave rsa.

![](/assets/images/hmvm-Dominator/key_rsa.png)

Uso la llave rsa para conectarme a la máquina objetivo pero no puedo porque me pide un passphrase.

![](/assets/images/hmvm-Dominator/id_rsaPassword.png)

Con la herramienta RSAcrack voy a tratar de encontrar la contraseña.

![](/assets/images/hmvm-Dominator/rsacrack.png)

Me conecto al sistema usando el passphrase encontrado con RSAcrack.

![](/assets/images/hmvm-Dominator/hans.png)

Lanzo un ls para ver que archivos hay en el directorio, veo que no existe el user.txt.

![](/assets/images/hmvm-Dominator/note.png)

Busco el archivo user.txt con find.
```bash
find / -type f -iname user.txt 2>/dev/null
/home/hans/.local/share/Trash/files/user.txt
```

Una vez encuentro el archivo ya puedo leer la flag.
```bash
cat .local/share/Trash/files/user.txt
SxxxxxxxxxxxxxxxxxxxxxJ
```

Hago una búsqueda de binarios con permisos SUID.

![](/assets/images/hmvm-Dominator/systemctl.png)

Utilizo el recurso online GTFObins.

![](/assets/images/hmvm-Dominator/gtfobinsSystemctl.png)


![](/assets/images/hmvm-Dominator/privesc.png)

Leo la flag de root.
```bash
bash-5.0# cat /root/root.txt 
ZxxxxxxxxxxxxxxxxxxxxxR
```
