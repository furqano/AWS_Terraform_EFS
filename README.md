# aws_terraform_efs

#### Goal is to launch a webserver by using Terraform but here we will be using EFS as a persistent storage .

<b>Persistent Storage<b> — Persistent storage means that the storage resource outlives any other resource and is always available, regardless of the state of a running instance.
  
##### Why use EFS as a persistent storage ?

An application can access files on EFS just like it would do in an on-premise environment. S3 does not support NFS. Comparing EFS to another popular Amazon service, Elastic Block Storage (EBS), the major advantage of EFS is that it offers shared storage.

