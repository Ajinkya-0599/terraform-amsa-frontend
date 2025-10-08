############################################################
# Terraform: AMSA EC2 Infrastructure with Monitoring
############################################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.6.0"
}

provider "aws" {
  region = var.aws_region
}

############################################################
# Variables
############################################################
variable "aws_region" {
  default = "us-east-2"
}

variable "key_name" {
  description = "Existing EC2 key pair for SSH"
  default     = "key-ohio"
}

variable "instance_type" {
  default     = "t3.micro"
  description = "EC2 instance type"
}

variable "ami_id" {
  description = "Ubuntu 22.04 AMI ID for ap-south-1"
  default     = "ami-077b630ef539aa0b5"  
}

variable "alert_email" {
  description = "Email address to receive CloudWatch alerts"
  default     = "ajinkya.suryawanshi@alphaseam.com"
}

############################################################
# Security Group
############################################################
resource "aws_security_group" "amsa_sg" {
  name        = "AmsaSecurityGroup"
  description = "Allow SSH, HTTP, and Backend API"

  # Ingress rules
  ingress {
    description      = "SSH access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  ingress {
    description      = "HTTP access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  ingress {
    description      = "Backend API access"
    from_port        = 3001
    to_port          = 3001
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  # Egress rules
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  tags = {
    Name = "Amsa-SecurityGroup"
  }
}


############################################################
# IAM Role + Instance Profile (for CloudWatch Agent)
############################################################
resource "aws_iam_role" "cw_role" {
  name = "AmsaCloudWatchRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cw_attach" {
  role       = aws_iam_role.cw_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy" 
}

resource "aws_iam_instance_profile" "cw_profile" {
  name = "AmsaInstanceProfile-1"
  role = aws_iam_role.cw_role.name
}

############################################################
# EC2 Instance
############################################################
resource "aws_instance" "amsa_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.cw_profile.name
  vpc_security_group_ids = [aws_security_group.amsa_sg.id]

  tags = {
    Name = "Amsa-EC2-Instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              apt update && apt upgrade -y
              apt install -y git curl unzip build-essential nginx
              curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
              apt install -y nodejs
              npm install -g pm2 serve

              # --- Frontend setup ---
              mkdir -p /var/www/terraform-amsa-frontend
              if [ ! -d /home/ubuntu/terraform-amsa-frontend ]; then
                git clone https://github.com/Ajinkya-0599/terraform-amsa-frontend.git /home/ubuntu/terraform-amsa-frontend
              fi
              cd /home/ubuntu/terraform-amsa-frontend
              npm install
              npm run build
              npm run export
              rm -rf /var/www/terraform-amsa-frontend
              cp -r out/* /var/www/terraform-amsa-frontend

              # --- Backend setup ---
              if [ ! -d /home/ubuntu/terraform-amsa-backend ]; then
                git clone https://github.com/Ajinkya-0599/terraform-amsa-frontend.git /home/ubuntu/terraform-amsa-backend
              fi
              cd /home/ubuntu/terraform-amsa-backend
              npm install
              pm2 start server.js --name terraform-amsa-backend --watch
              pm2 save

              # --- Nginx config ---
              cat <<NGINX > /etc/nginx/sites-available/amsa
              server {
                  listen 80;
                  server_name _;
                  root /var/www/terraform-amsa-frontend;
                  index index.html;

                  location / {
                      try_files \$uri \$uri/ /index.html;
                  }

                  location /api {
                      proxy_pass http://localhost:3001;
                      proxy_http_version 1.1;
                      proxy_set_header Upgrade \$http_upgrade;
                      proxy_set_header Connection 'upgrade';
                      proxy_set_header Host \$host;
                      proxy_cache_bypass \$http_upgrade;
                  }
              }
              NGINX
              ln -sf /etc/nginx/sites-available/amsa /etc/nginx/sites-enabled/amsa
              rm -f /etc/nginx/sites-enabled/default
              nginx -t
              systemctl enable nginx
              systemctl restart nginx

              # --- CloudWatch Agent ---
              mkdir -p /opt/aws/amazon-cloudwatch-agent/bin
              cat <<CWCFG > /opt/aws/amazon-cloudwatch-agent/bin/config.json
              {
                "metrics": {
                  "metrics_collected": {
                    "cpu": {
                      "measurement": ["usage_idle","usage_user","usage_system"],
                      "metrics_collection_interval": 60
                    },
                    "mem": {
                      "measurement": ["mem_used_percent"],
                      "metrics_collection_interval": 60
                    },
                    "disk": {
                      "measurement": ["used_percent"],
                      "resources": ["/"],
                      "metrics_collection_interval": 60
                    },
                    "procstat": {
                      "measurement": ["pid_count"],
                      "metrics_collection_interval": 60,
                      "process_name": "server.js"
                    }
                  }
                }
              }
              CWCFG
              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
              EOF
}

############################################################
# SNS Topic + Subscription
############################################################
resource "aws_sns_topic" "alarm_topic" {
  name         = "AmsaMonitoringAlerts"
  display_name = "Amsa Monitoring Alerts"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.alarm_topic.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

############################################################
# CloudWatch Alarms
############################################################
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "Amsa-CPU-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.alarm_topic.arn]
  dimensions = {
    InstanceId = aws_instance.amsa_instance.id
  }
}

resource "aws_cloudwatch_metric_alarm" "mem_high" {
  alarm_name          = "Amsa-Memory-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_actions       = [aws_sns_topic.alarm_topic.arn]
  dimensions = {
    InstanceId = aws_instance.amsa_instance.id
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_high" {
  alarm_name          = "Amsa-Disk-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.alarm_topic.arn]
  dimensions = {
    InstanceId = aws_instance.amsa_instance.id
    path       = "/"
  }
}

############################################################
# CloudWatch Dashboard
############################################################
resource "aws_cloudwatch_dashboard" "amsa_dashboard" {
  dashboard_name = "AmsaMonitoringDashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x    = 0,
        y    = 0,
        width = 12,
        height = 6,
        properties = {
          title = "CPU Utilization",
          metrics = [["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.amsa_instance.id]],
          period = 300,
          stat   = "Average",
          region = var.aws_region
        }
      },
      {
        type = "metric",
        x    = 0,
        y    = 6,
        width = 12,
        height = 6,
        properties = {
          title = "Memory Usage (%)",
          metrics = [["CWAgent", "mem_used_percent", "InstanceId", aws_instance.amsa_instance.id]],
          period = 300,
          stat   = "Average",
          region = var.aws_region
        }
      },
      {
        type = "metric",
        x    = 0,
        y    = 12,
        width = 12,
        height = 6,
        properties = {
          title = "Disk Usage (%)",
          metrics = [["CWAgent", "disk_used_percent", "InstanceId", aws_instance.amsa_instance.id, "path", "/"]],
          period = 300,
          stat   = "Average",
          region = var.aws_region
        }
      }
    ]
  })
}

############################################################
# Outputs
############################################################
output "public_ip" {
  value = aws_instance.amsa_instance.public_ip
}

output "public_dns" {
  value = aws_instance.amsa_instance.public_dns
}

output "alarm_topic_arn" {
  value = aws_sns_topic.alarm_topic.arn
}
