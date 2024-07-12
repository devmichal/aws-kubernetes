provider "aws" {
  region = "us-east-1"  # Zmień na region, którego chcesz użyć
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main_vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"  # Zmień na odpowiednią strefę dostępności

  tags = {
    Name = "public_subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main_igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "client_vpn_sg" {
  name        = "client_vpn_sg"
  description = "Security group for Client VPN"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "client_vpn_sg"
  }
}

resource "aws_vpn_client_endpoint" "client_vpn_endpoint" {
  description             = "Client VPN Endpoint"
  server_certificate_arn  = "arn:aws:acm:REGION:ACCOUNT_ID:certificate/CERTIFICATE_ID"
  client_cidr_block       = "10.1.0.0/22"
  authentication_options {
    type = "certificate-authentication"
    root_certificate_chain_arn = "arn:aws:acm:REGION:ACCOUNT_ID:certificate/ROOT_CERTIFICATE_ID"
  }
  connection_log_options {
    enabled = true
    cloudwatch_log_group = "/aws/vpn-client-logs"
    cloudwatch_log_stream = "vpn-client-connection"
  }

  security_group_ids = [aws_security_group.client_vpn_sg.id]
  vpc_id = aws_vpc.main_vpc.id
  subnet_ids = [aws_subnet.public_subnet.id]

  tags = {
    Name = "client_vpn_endpoint"
  }
}

resource "aws_vpn_client_endpoint_association" "association" {
  client_vpn_endpoint_id = aws_vpn_client_endpoint.client_vpn_endpoint.id
  subnet_id              = aws_subnet.public_subnet.id
}
