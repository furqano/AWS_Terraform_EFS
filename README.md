# Configuring AWS EFS Service using Terraform

#### Goal is to launch a webserver by using Terraform but here we will be using EFS as a persistent storage .

#### [Lets go to Working Example](https://medium.com/@mohamedfurqan.o/aws-terraform-launching-webserver-on-aws-using-terraform-efs-elastic-file-system-4d45c093f8a8?source=friends_link&sk=785772a7168f279c88c5b4e21cce8e89)



<b> Persistent Storage <b> — Persistent storage means that the storage resource outlives any other resource and is always available, regardless of the state of a running instance.
  
##### Why use EFS as a persistent storage ?

An application can access files on EFS just like it would do in an on-premise environment. S3 does not support NFS. Comparing EFS to another popular Amazon service, Elastic Block Storage (EBS), the major advantage of EFS is that it offers shared storage.

