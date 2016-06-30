FROM 10.20.0.126:5000/plataforma/base-os:develop-c11852e-3
ADD target/artifacts.json /artifacts/artifacts.json
ADD target/image.tf /artifacts/image.tf
VOLUME /artifacts
