// AWS vpc allows for ~65k addresses
resource "aws_vpc" "cookiegpt-vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "cookiegpt-vpc"
    }
}

// Create 2 subnets which allows for 256 addresses each
resource "aws_subnet" "cookiegpt-subnet-1" {
    vpc_id = aws_vpc.cookiegpt-vpc.id

    // Can't believe it doesn't do this automatically 
    map_public_ip_on_launch = true

    cidr_block = "10.0.1.0/24"
    
    tags = {
        Name = "cookiegpt-subnet"
    }
}
resource "aws_subnet" "cookiegpt-subnet-2" {
    vpc_id = aws_vpc.cookiegpt-vpc.id
    map_public_ip_on_launch = true
    cidr_block = "10.0.2.0/24"
    
    tags = {
        Name = "cookiegpt-subnet-2"
    }
}

// Allows our cluster to access the internet (required for pulling docker containers)
resource "aws_internet_gateway" "cookiegpt-internet-gateway" {
    vpc_id = aws_vpc.cookiegpt-vpc.id
}

// Route table routes traffic to the internet gateway
resource "aws_route_table" "cookiegpt-route-table" {
    vpc_id = aws_vpc.cookiegpt-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.cookiegpt-internet-gateway.id
    }
}

// Associate all traffic from the subnets to the route table-- all traffic is redirected according to the route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.cookiegpt-subnet-1.id
  route_table_id = aws_route_table.cookiegpt-route-table.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.cookiegpt-subnet-2.id
  route_table_id = aws_route_table.cookiegpt-route-table.id
}