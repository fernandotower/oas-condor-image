FROM 10.20.0.126:5000/plataforma/base-os:develop-75b115c-4
ADD artifacts.json /artifacts/artifacts.json
ADD image.tf /artifacts/image.tf
VOLUME /artifacts
