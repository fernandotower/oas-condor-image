Requerimientos
==============

 - Un bucket de S3 (el cuál llamaremos **oas-repo** a partir de ahora) para guardar binarios externos (por ejemplo los instaladores de los controladores de Oracle Database)
 - El bucket **oas-repo** debe tener en el "directorio" `/rpms/` los siguientes archivos:
   - oracle-instantclient12.1-basic-12.1.0.2.0-1.x86\_64.rpm
   - oracle-instantclient12.1-devel-12.1.0.2.0-1.x86\_64.rpm
   - oracle-instantclient12.1-sqlplus-12.1.0.2.0-1.x86\_64.rpm

   Estos archivos se consiguen en la página web de Oracle y se necesita una cuenta para poderlos bajar, Oracle no ofrece una forma desatendida de bajarlos.
 - Un usuario de AWS (el cuál llamaremos **ami-builder** a partir de ahora) con suficientes accesos para crear AMIs
   - El usuraio **ami-builder** debe tener los privilegios listados en esta página: https://www.packer.io/docs/builders/amazon.html en la sección "Using An IAM Instance Profile"
   - El usuario **ami-builder** debe poder pasar roles a las instancias, adjuntarle esta política:
   ```
     {
         "Version": "2012-10-17",
         "Statement": [
             {
                 "Sid": "Stmt1453626845000",
                 "Effect": "Allow",
                 "Action": [
                     "iam:PassRole"
                 ],
                 "Resource": [
                     "*"
                 ]
             }
         ]
     }
   ```
 - Un rol de IAM en la cuenta (que **debe** llamarse **oas-ami-builder-role**) basado en "Amazon EC2 AWS Service Roles" para poder construir las AMI's base
   - El rol **oas-ami-builder-role** debe tener acceso de lectura a todo el bucket **oas-repo**
 - La región utilizada debe contar con una VPC por defecto configurada correctamente, esto viene por defecto en las cuentas de Amazon AWS creadas a partir del año 201X
