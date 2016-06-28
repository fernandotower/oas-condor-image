FROM 172.17.0.1:5000/plataforma/base-os:master-c924483-0
ADD target/artifacts.json /artifacts/artifacts.json
ADD target/image.tf /artifacts/image.tf
VOLUME /artifacts
