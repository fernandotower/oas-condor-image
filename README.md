Requerimientos
==============

 - Un bucket de S3 (el cuál llamaremos **oas-repo** a partir de ahora) para guardar binarios externos (por ejemplo los instaladores de los controladores de Oracle Database)
 - El bucket **oas-repo** debe tener en el "directorio" `/rpms/` los siguientes archivos:
   - oracle-instantclient12.1-basic-12.1.0.2.0-1.x86\_64.rpm
   - oracle-instantclient12.1-devel-12.1.0.2.0-1.x86\_64.rpm
   - oracle-instantclient12.1-sqlplus-12.1.0.2.0-1.x86\_64.rpm

   Estos archivos se consiguen en la página web de Oracle y se necesita una cuenta para poderlos bajar, Oracle no ofrece una forma desatendida de bajarlos.
 - Un usuario de AWS (el cuál llamaremos **ami-builder** a partir de ahora) con suficientes accesos para crear AMIs
   - El usuario **ami-builder** debe tener los privilegios listados en esta página: https://www.packer.io/docs/builders/amazon.html en la sección "Using An IAM Instance Profile"
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
   - Por conveniencia el usuario **ami-builder** podría tener privilegios de listar roles y verificar cómo estos están asignados, **esta política no es necesaria, sólamente conveniente**:
   ```
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "Stmt1465486855068",
         "Action": [
           "iam:GetInstanceProfile",
           "iam:GetRole",
           "iam:GetRolePolicy",
           "iam:ListAttachedRolePolicies",
           "iam:ListInstanceProfiles",
           "iam:ListInstanceProfilesForRole",
           "iam:ListRolePolicies",
           "iam:ListRoles",
         ],
         "Effect": "Allow",
         "Resource": "*"
       }
     ]
   }
   ```
 - Un rol de IAM en la cuenta (que **debe** llamarse **oas-ami-builder-role**) basado en "Amazon EC2 AWS Service Roles" para poder construir las AMI's base
   - El rol **oas-ami-builder-role** debe tener acceso de lectura a todo el bucket **oas-repo**, como ayuda se incluye esta política de IAM de ejemplo, **se debe reemplazar** `<bucket-name>` **por el nombre del bucket que se creó**.
   ```
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "Stmt1465487922400",
         "Action": [
           "s3:Get*",
           "s3:List*"
         ],
         "Effect": "Allow",
         "Resource": "arn:aws:s3:::<bucket-name>"
       },
       {
         "Sid": "Stmt1465487950391",
         "Action": [
           "s3:Get*",
           "s3:List*"
         ],
         "Effect": "Allow",
         "Resource": "arn:aws:s3:::<bucket-name>/*"
       }
     ]
   }
   ```
 - La región de AWS utilizada debe contar con una VPC y una subred configuradas correctamente, esto viene por defecto en las cuentas de Amazon AWS. No está en el **scope** de este proyecto crear dichos recursos.
 - Un rol de IAM en la cuenta (el cuál a partir de ahora llamaremos **oas-condor-role**) basado en "Amazon EC2 AWS Service Roles"
   - El rol **oas-condor-role** debe tener los siguientes privilegios.
     - terminate-instances

Seguridad
---------

Durante la creación desatendida se configura automáticamente la base de datos MariDB y las respuestas al `mysql_secure_installation` se encuentran en el archivo `/var/lib/mysql_secure_installation_answers` este archivo se encuentra protegido por el modo `400`.

Mantenimiento
-------------

Dado que este proyecto crea recursos de manera programática, la cantidad de recursos no utilizados puede llegar a crecer si no se mantiene bajo control. Este proyecto etiqueta todos los recuersos creados de la siguiente manera:

**external-ref**

 * `BRANCH-GITCOMMIT-BUILDCOUNTER` si el proceso es ejecutado desde el sistema de CI
 * `SNAPSHOT-SNAPSHOT-TIMESTAMP` si el proceso es ejecutado manualmente

**ami-name**

 * oas-condor-estudiantes

**promoted**

 * no

**expiration-timestamp**

 * TIMESTAMP + 1 mes para las AMI y Snapshots
 * TIMESTAMP + 1 día para las instancias temporales de Packer

El script de mantenimiento `./cleanup.sh` toma estas etiquetas para realizar un proceso de limpieza. Siguiendo este pseudo-código:

```
Por cada uno de los recursos creados programáticamente en la cuenta de AWS
  Si "expiration-timestamp" es menor que el timestamp actual && "promoted" es igual a "no"
    => borar el recurso
Fin
```

Este script es invocado como parte del proceso de creación de nuevas AMI aunque el administrador de la cuenta también lo puede ejecutar manualmente para hacer limpieza de recursos de manera inmediata.
