# ── AMI data sources ──

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
}

# ── Security Group ──

locals {
  ami_id = var.ami_id != null ? var.ami_id : (var.os_type == "ubuntu" ? data.aws_ami.ubuntu.id : data.aws_ami.windows.id)

  os_ingress_ports = var.os_type == "ubuntu" ? { ssh = 22 } : {
    rdp          = 3389
    winrm_http   = 5985
    winrm_https  = 5986
    
  }
}

resource "aws_security_group" "ec2_sg" {
  name = "devtools-sg-${var.name}"

  dynamic "ingress" {
    for_each = local.os_ingress_ports
    content {
      description = ingress.key
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    description = "devtools high ports"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP ping"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ── User data ──

locals {
  ubuntu_userdata = <<-EOF
#!/bin/bash
apt-get update -y
apt-get install -y python3
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd
EOF

  windows_userdata = <<-EOF
<powershell>
net user Administrator "TempP@ssw0rd123!"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 0
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
${var.winrm_script}
</powershell>
EOF

  user_data_value = var.user_data_override != null ? var.user_data_override : (var.os_type == "ubuntu" ? local.ubuntu_userdata : local.windows_userdata)
}

# ── EC2 Instance ──

resource "aws_instance" "this" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  user_data                   = local.user_data_value

  tags = {
    Name        = var.name
    Environment = var.environment
    Project     = "devtools-lab"
    OSType      = var.os_type
    AnsibleRole = var.os_type == "ubuntu" ? "linux-devtools" : "windows-devtools"
  }
}