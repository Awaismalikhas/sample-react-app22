data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "${var.instance_type}-ec2-sg"
  description = "Security group for EC2 allowing SSH and app port 3000"

  ingress {
    description = "Allow SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP for React app"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_type}-ec2-sg"
  }
}

resource "aws_instance" "ec2_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = data.aws_subnets.default.ids[0]
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  
  user_data = <<-EOF
    #!/bin/bash
    set -e  # Exit on any error
    set -x  # Debug output
    
    # Update system
    echo "Updating system packages..."
    apt-get update -y
    
    # Install prerequisites
    echo "Installing prerequisites..."
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker's official GPG key
    echo "Adding Docker GPG key..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "Adding Docker repository..."
    echo \
      "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      \$(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update again with Docker repo
    apt-get update -y
    
    # Install Docker
    echo "Installing Docker..."
    apt-get install -y docker-ce docker-ce-cli containerd.io
    
    # Start and enable Docker
    echo "Starting Docker service..."
    systemctl enable docker
    systemctl start docker
    
    # Add ubuntu user to docker group
    echo "Adding ubuntu user to docker group..."
    usermod -aG docker ubuntu
    
    # Restart Docker service to apply group changes
    echo "Restarting Docker service..."
    systemctl restart docker
    
    # Verify installation
    echo "Verifying Docker installation..."
    docker --version
    
    # Check Docker service status after restart
    echo "Checking Docker service status..."
    systemctl status docker --no-pager
  EOF

  tags = {
    Name = var.instance_name
  }
}
