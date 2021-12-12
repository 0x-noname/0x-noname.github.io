---
layout: single
title: Webmaster - HackMyVM
excerpt: "Webmaster es máquina Linux creada por sML. En esta máquina encontraremos unas credenciales de acceso usando dig, dig es una 
herramienta que permite realizar múltiples consultas a servidores DNS. Una vez tenemos acceso al sistema obtendremos el root 
mediante un archivo php malicioso."
date: 2021-12-10
classes: wide
header:
  teaser: /assets/images/hmvm-Webmaster/hmvmWebmaster.png
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
  - sudo
  - sML
---

### Escaneo de puertos
```bash
nmap -p- -T5 --open -v -n -Pn 10.0.2.5

PORT   STATE SERVICE
22/tcp open  ssh
53/tcp open  domain
80/tcp open  http
```

### Escaneo de servicios
```bash
nmap -sCV -p 80 10.0.2.5 

PORT   STATE SERVICE VERSION
80/tcp open  http    nginx 1.14.2
|_http-title: Site doesn't have a title (text/html).
|_http-server-header: nginx/1.14.2
```
### WEB

![](/assets/images/hmvm-Webmaster/web.png)

Al mirar el código fuente veo un nombre de dominio.

![](/assets/images/hmvm-Webmaster/cfuenteweb.png)

Añado el nombre de dominio `webmaster.hmv` a mi archivo hosts y seguidamente lanzo un dig.

![](/assets/images/hmvm-Webmaster/dig.png)

Uso el usuario `john` y la contraseña encontrada para conectarme a través de ssh.

```bash
ssh john@webmaster.hmv
Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
john@webmaster:~$ id
uid=1000(john) gid=1000(john) groups=1000(john),24(cdrom),25(floppy),29(audio),30(dip),44(video),46(plugdev),109(netdev)
```

Obtengo la flag user.txt.
```bash
john@webmaster:~$ cat user.txt 
H******o
```

### sudo -l

![](/assets/images/hmvm-Webmaster/sudo.png)

Comprobando los permisos del directorio /var/www/html.

![](/assets/images/hmvm-Webmaster/permisoswww.png)

Como tengo permisos de  lectura, escritura y ejecución crearé un fichero php malicioso.

![](/assets/images/hmvm-Webmaster/shellnona.png)

Compruebo que el fichero php es funcional.

![](/assets/images/hmvm-Webmaster/testphpmalicioso.png)

Dejo un netcat a la escucha y lanzo la shell.

![](/assets/images/hmvm-Webmaster/sendshell.png)

Obtengo la shell de root.
```bash
nc -nlvp 4444
listening on [any] 4444 ...
connect to [10.0.2.4] from (UNKNOWN) [10.0.2.5] 33282
id
uid=0(root) gid=0(root) groups=0(root)
```

Como root leo la flag de root.
```bash
root@webmaster:~# cat root.txt 
H**********d
```
