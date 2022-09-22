# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    "Name" = "Main"
  }
}

# Create VPC Subnet
resource "aws_subnet" "web_subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "Web Subnet 1"
  }
}

resource "aws_subnet" "web_subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "Web Subnet 2"
  }
}

resource "aws_subnet" "application_subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "Application Subnet 1"
  }
}

resource "aws_subnet" "application_subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "Application Subnet 2"
  }
}

# Create Database Private Subnet
resource "aws_subnet" "database_subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "Database Subnet 1"
  }
}

resource "aws_subnet" "database_subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "ap-southeast-1b"

  tags = {
    Name = "Database Subnet 2"
  }
}

# Create EC2 instance
resource "aws_instance" "webserver1" {
  ami                    = "ami-0801a1e12f4a9ccc0"
  instance_type          = "t2.micro"
  availability_zone      = "ap-southeast-1a"
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]
  subnet_id              = aws_subnet.web_subnet1.id
  key_name               = "ssh_key"
  #user_data              = file("/Users/wileong/Documents/Terraform/ProjectA/apache.sh")

  tags = {
    Name = "Web Server 1"
  }

  metadata_options {
    http_endpoint = "disabled"
    http_tokens   = "required"
  }
  monitoring = true
}

resource "aws_instance" "webserver2" {
  ami                    = "ami-0801a1e12f4a9ccc0"
  instance_type          = "t2.micro"
  availability_zone      = "ap-southeast-1b"
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]
  subnet_id              = aws_subnet.web_subnet2.id
  key_name               = "ssh_key"
  #user_data              = file("/Users/wileong/Documents/Terraform/ProjectA/apache.sh")

  tags = {
    Name = "Web Server 2"
  }

  metadata_options {
    http_endpoint = "disabled"
    http_tokens   = "required"
  }
  monitoring = true
}

resource "aws_instance" "application1" {
  ami               = "ami-0801a1e12f4a9ccc0"
  instance_type     = "t2.micro"
  availability_zone = "ap-southeast-1a"
  subnet_id         = aws_subnet.application_subnet1.id
  key_name          = "ssh_key"

  tags = {
    Name = "App Server 1"
  }

  metadata_options {
    http_endpoint = "disabled"
    http_tokens   = "required"
  }
  monitoring             = true
  vpc_security_group_ids = ["<security_group_id>"]
}

resource "aws_instance" "application2" {
  ami               = "ami-0801a1e12f4a9ccc0"
  instance_type     = "t2.micro"
  availability_zone = "ap-southeast-1b"
  subnet_id         = aws_subnet.application_subnet2.id
  key_name          = "ssh_key"

  tags = {
    Name = "App Server 2"
  }

  metadata_options {
    http_endpoint = "disabled"
    http_tokens   = "required"
  }
  monitoring             = true
  vpc_security_group_ids = ["<security_group_id>"]
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Internet Gateway"
  }
}

# Create Web Subnet route table
resource "aws_route_table" "web_rt" {
  vpc_id = aws_vpc.main.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Web Route Table"
  }
}

# Associate Web Subnet to Web RT
resource "aws_route_table_association" "Web1" {
  subnet_id      = aws_subnet.web_subnet1.id
  route_table_id = aws_route_table.web_rt.id
}

resource "aws_route_table_association" "Web2" {
  subnet_id      = aws_subnet.web_subnet2.id
  route_table_id = aws_route_table.web_rt.id
}

# Create Web Security Group
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["<cidr>"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["<cidr>"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web SG"
  }
}

# Create Web Server Security Group
resource "aws_security_group" "webserver_sg" {
  name        = "Webserver-SG"
  description = "Allow inbound traffic from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow traffic from web layer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Webserver SG"
  }
}

# Create Database Security Group
resource "aws_security_group" "db_sg" {
  name        = "Database_SG"
  description = "Allow inbound traffic from application layer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow traffic from application layer"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.webserver_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Database SG"
  }
}

resource "aws_lb" "external_elb" {
  name               = "External-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.web_subnet1.id, aws_subnet.web_subnet2.id]

  access_logs {
    bucket  = "<s3_bucket_name>"
    enabled = true
  }
}

resource "aws_lb_target_group" "external_elb_tg" {
  name     = "ALB-Target"
  port     = 80
  protocol = "HTTPS"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_target_group_attachment" "external_elb1" {
  target_group_arn = aws_lb_target_group.external_elb_tg.arn
  target_id        = aws_instance.webserver1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "external_elb2" {
  target_group_arn = aws_lb_target_group.external_elb_tg.arn
  target_id        = aws_instance.webserver2.id
  port             = 80
}

resource "aws_lb_listener" "external_elb" {
  load_balancer_arn = aws_lb.external_elb.arn
  port              = "80"
  protocol          = "HTTPS"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external_elb_tg.arn
  }
}

resource "aws_db_instance" "default" {
  allocated_storage                   = 200
  db_subnet_group_name                = aws_db_subnet_group.default.id
  engine                              = "mysql"
  instance_class                      = "db.t2.micro"
  multi_az                            = true
  db_name                             = "mydb"
  username                            = "dbadmin"
  password                            = "verysecret"
  skip_final_snapshot                 = true
  vpc_security_group_ids              = [aws_security_group.db_sg.id]
  iam_database_authentication_enabled = true
  backup_retention_period             = 30
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.database_subnet1.id, aws_subnet.database_subnet2.id]

  tags = {
    Name = "DB subnet group"
  }
}

resource "aws_flow_log" "main" {
  vpc_id          = "${aws_vpc.main.id}"
  iam_role_arn    = "<iam_role_arn>"
  log_destination = "${aws_s3_bucket.main.arn}"
  traffic_type    = "ALL"

  tags = {
    GeneratedBy      = "Accurics"
    ParentResourceId = "aws_vpc.main"
  }
}
resource "aws_s3_bucket" "main" {
  bucket        = "main_flow_log_s3_bucket"
  acl           = "private"
  force_destroy = true

  versioning {
    enabled    = true
    mfa_delete = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
resource "aws_s3_bucket_policy" "main" {
  bucket = "${aws_s3_bucket.main.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "main-restrict-access-to-users-or-roles",
      "Effect": "Allow",
      "Principal": [
        {
          "AWS": [
            <principal_arn>
          ]
        }
      ],
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.main.id}/*"
    }
  ]
}
POLICY
}