# -----------------------------------------------------------------------------
# Public instance: HTTP from allowed_http_cidr, all outbound
# -----------------------------------------------------------------------------
resource "aws_security_group" "public" {
  name_prefix = "${local.name_prefix}-public-"
  description = "Public web server"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-public-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "public_http" {
  security_group_id = aws_security_group.public.id
  description       = "HTTP from allowed CIDR"
  cidr_ipv4         = var.allowed_http_cidr
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "public_all" {
  security_group_id = aws_security_group.public.id
  description       = "All outbound"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# -----------------------------------------------------------------------------
# Private instance: only reachable from the public instance's security group
# and ICMP (ping) from inside the VPC
# -----------------------------------------------------------------------------
resource "aws_security_group" "private" {
  name_prefix = "${local.name_prefix}-private-"
  description = "Private backend server"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-private-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "private_http_from_public" {
  security_group_id            = aws_security_group.private.id
  description                  = "HTTP from the public instance only"
  referenced_security_group_id = aws_security_group.public.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "private_icmp_from_vpc" {
  security_group_id = aws_security_group.private.id
  description       = "Ping from inside the VPC"
  cidr_ipv4         = var.vpc_cidr
  from_port         = -1
  to_port           = -1
  ip_protocol       = "icmp"
}

resource "aws_vpc_security_group_egress_rule" "private_all" {
  security_group_id = aws_security_group.private.id
  description       = "All outbound (only works with the NAT Gateway enabled)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
