variable "name" {}
variable "cidr" {}
variable "public_subnets" { default = "" }
variable "private_subnets" { default = "" }
variable "bastion_instance_id" {}
variable "azs" {}
variable "enable_dns_hostnames" {
  description = "should be true if you want to use private DNS within the VPC"
  default     = false
}
variable "enable_dns_support" {
  description = "should be true if you want to use private DNS within the VPC"
  default     = false
}

# resources
resource "aws_vpc" "mod" {
  cidr_block           = "${var.cidr}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"
  enable_dns_support   = "${var.enable_dns_support}"
  tags {
    Name = "${var.name}"
  }
  tags = {
    yor_trace = "97db6332-f675-423f-9f28-895332aaaac0"
  }
}

resource "aws_internet_gateway" "mod" {
  vpc_id = "${aws_vpc.mod.id}"
  tags = {
    yor_trace = "2b913cf2-4a82-422c-9c10-7b89b85f54d8"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.mod.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.mod.id}"
  }
  tags {
    Name = "${var.name}-public"
  }
  tags = {
    yor_trace = "598b8c63-05a7-4c78-a8e7-2a100e03efce"
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.mod.id}"
  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = "${var.bastion_instance_id}"
  }
  tags {
    Name = "${var.name}-private"
  }
  tags = {
    yor_trace = "9ca9dcc2-05c2-430f-8770-9721576e6d29"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = "${aws_vpc.mod.id}"
  cidr_block        = "${element(split(",", var.private_subnets), count.index)}"
  availability_zone = "${element(split(",", var.azs), count.index)}"
  count             = "${length(compact(split(",", var.private_subnets)))}"
  tags {
    Name = "${var.name}-private"
  }
  tags = {
    yor_trace = "8f8da41a-8e3d-4a93-bc03-423f724ad49d"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = "${aws_vpc.mod.id}"
  cidr_block        = "${element(split(",", var.public_subnets), count.index)}"
  availability_zone = "${element(split(",", var.azs), count.index)}"
  count             = "${length(compact(split(",", var.public_subnets)))}"
  tags {
    Name = "${var.name}-public"
  }

  map_public_ip_on_launch = true
  tags = {
    yor_trace = "fb8ada78-3a4f-4832-afe3-ab0012f38a4b"
  }
}

resource "aws_route_table_association" "private" {
  count          = "${length(compact(split(",", var.private_subnets)))}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "public" {
  count          = "${length(compact(split(",", var.public_subnets)))}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

# outputs
output "private_subnets" {
  value = "${join(",", aws_subnet.private.*.id)}"
}
output "public_subnets" {
  value = "${join(",", aws_subnet.public.*.id)}"
}
output "vpc_id" {
  value = "${aws_vpc.mod.id}"
}
output "vpc_cidr_block" {
  value = "${aws_vpc.mod.cidr_block}"
}
