FROM 192.168.12.212:5000/plataforma/base-os:master-a417036-3
ADD target artifacts
VOLUME /artifacts
