provider "aws" {
  region = "ap-south-1"
  profile = "fate"
}

// Creating Security Groups

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  ingress {
    description = "Security group for ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Security group for http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
     description = "Security group for efs"
     from_port = 2049
     to_port = 2049
     protocol = "tcp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}



resource "aws_efs_file_system" "foo" {
  creation_token = "my-product"

  tags = {
    Name = "MyProduct"
  }
}

resource "aws_efs_access_point" "test" {
  file_system_id = "${aws_efs_file_system.foo.id}"
}


resource "aws_efs_file_system_policy" "policy" {
  file_system_id = "${aws_efs_file_system.foo.id}"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "ExamplePolicy01",
    "Statement": [
        {
            "Sid": "ExampleSatement01",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Resource": "${aws_efs_file_system.foo.arn}",
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "true"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_efs_mount_target" "alpha" {
  file_system_id = "${aws_efs_file_system.foo.id}"
  subnet_id      = "subnet-8f7c17c3"
  security_groups =  ["${aws_security_group.allow_tls.id}"]
}



// Creating AWS Instance

resource "aws_instance" "web" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "eks"
  security_groups =  ["${aws_security_group.allow_tls.id}"]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("D:/eks.pem")
    host     = aws_instance.web.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "lwos1"
  }

}

resource "null_resource" "null-remote-1"  {
   depends_on = [aws_efs_mount_target.alpha,]
	connection {
		type     = "ssh"
		user     = "ec2-user"
		private_key = ("D:/eks.pem")
		host     = aws_instance.web.public_ip
}
// ATTACH EFS 
provisioner "remote-exec" {
	inline = [
		"sudo echo ${aws_efs_file_system.foo.dns_name}:/var/www/html efs defaults,_netdev 0 0 >> sudo /etc/fstab",
		"sudo mount  ${aws_efs_file_system.foo.dns_name}:/  /var/www/html",
		"sudo curl https://github.com/FateDaeth/aws_terraform_web.git > index.html",                                  
		"sudo cp index.html  /var/www/html/",]
}
}


// Creating s3 Bucket

resource "aws_s3_bucket" "buck" {
  bucket = "fateultimate12"
  acl    = "public-read"

  tags = {
    Name        = "Mybucket"
  }
}

// uploading file in s3

resource "aws_s3_bucket_object" "object" {
  depends_on = [
       aws_s3_bucket.buck ,
      ]

  bucket = "${aws_s3_bucket.buck.id}"
  key    = "fate.jpg"
  source = "D:/fate.jpg"
  etag = "${filemd5("D:/fate.jpg")}"
  acl = "public-read"
}

// Print IP

output "myos_ip" {
  value = aws_instance.web.public_ip
}





// Launching Browser 

resource "null_resource" "null_chrome"  {


depends_on = [
    aws_cloudfront_distribution.s3_distribution,
  ]

	provisioner "local-exec" {
	    command = "microsoftedge  ${aws_instance.web.public_ip}"
  	}
}

//Cloud Front

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
depends_on = [
    aws_s3_bucket.buck,
aws_instance.web
  ]
  origin {
    domain_name = "${aws_s3_bucket.buck.bucket_regional_domain_name}"
    origin_id   = "${local.s3_origin_id}"

  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.php"


  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "${local.s3_origin_id}"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  
    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }
    viewer_certificate {
        cloudfront_default_certificate = true
    }

}
