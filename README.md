condor-image
============

 - Para construir localmente ejecute `./local`, necesitará:
   - [Docker](https://www.docker.com/)
   - [Drone](http://readme.drone.io/devs/cli/)
 - Para construir automáticamente activar el proyecto en Drone
   - Generar los secretos necesarios según el archivo `secrets_example.yml` de la siguiente manera:

   ```
   cp secrets_example.yml .drone.sec.yml
   # editar el archivo .drone.sec.yml
   # gedit .drone.sec.yml
   # vim .drone.sec.yml
   # emacs .drone.sec.yml
   # etc...
   drone secure --repo plataforma/condor-image --checksum
   rm .drone.sec.yml
   git add .drone.sec
   git commit -m "configurando secretos"
   # git push <<remote>> <<branch>>
   ```

Actualmente este repositorio genera imágenes de AWS (AMIs).

Requerimientos
==============

 - El stack de cfn-base llamado `condorB<<nombre del branch>>`
