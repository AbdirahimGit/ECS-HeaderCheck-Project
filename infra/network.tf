resource "aws_vpc" "project_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "tf project vpc"
  }
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.project_vpc.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name = "tf public subnet a"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.project_vpc.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "eu-west-2b"
  tags = {
    Name = "tf public subnet b"
  }
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.project_vpc.id
  cidr_block        = "10.1.3.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name = "tf private subnet a"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.project_vpc.id
  cidr_block        = "10.1.4.0/24"
  availability_zone = "eu-west-2b"
  tags = {
    Name = "tf private subnet b"
  }
}

resource "aws_internet_gateway" "project_igw" {
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    Name = "tf project igw"
  }
}

resource "aws_eip" "project_nat_eip" {
  domain = "vpc"
  tags = {
    Name = "tf project nat eip"
  }
}

resource "aws_nat_gateway" "project_nat_gw" {
  allocation_id = aws_eip.project_nat_eip.id
  subnet_id     = aws_subnet.public_subnet_a.id
  depends_on    = [aws_internet_gateway.project_igw]
  tags = {
    Name = "tf project nat gw"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.project_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project_igw.id
  }

  tags = {
    Name = "tf public route table"
  }
}

resource "aws_route_table" "private_route_table_a" {
  vpc_id = aws_vpc.project_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.project_nat_gw.id
  }

  tags = {
    Name = "tf private route table a"
  }
}

resource "aws_route_table" "private_route_table_b" {
  vpc_id = aws_vpc.project_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.project_nat_gw.id
  }

  tags = {
    Name = "tf private route table b"
  }
}

resource "aws_route_table_association" "association_public_subnet_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "association_public_subnet_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "association_private_subnet_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_route_table_a.id
}

resource "aws_route_table_association" "association_private_subnet_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_route_table_b.id
}
