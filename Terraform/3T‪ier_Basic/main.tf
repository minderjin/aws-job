############## [variable] ################

variable "allow_ip_address" {
    description = "SSH 접속을 허용할 IP list"
    type    = list(string)
    default = [
        "211.60.50.190/32",
    ]
}

variable "db_port" {
    description = "DB 포트 정보"
    type    = string
    default = "3306"
}

variable "key_name" {
    description = "EC2 접속시 사용할 키페어 이름"
    type        = string
    default     = "ssh-key"
}

variable "region" {
    description = "리전을 선택합니다. e.g: ap-northeast-2"
    type        = string
    default     = "ap-northeast-2"
}

variable "name" {
    description = "프로젝트 이름을 입력합니다."
    type        = string
    default     = "terra-demo"
}

variable "vpc_cidr" {
    description = "VPC 의 기본 CIDR 정의"
    type        = string
    default     = "10.11.0.0/16"
}

variable "az_names" {
    description = "Availability Zones"
    type    = list(string)
    default = [
        "ap-northeast-2a",
        "ap-northeast-2c"
    ]
}

variable "public_subnets" {
    description = "퍼블릭 서브넷 목록을 입력합니다."
    type = list(object({
        zone = string
        cidr = string
    }))
    
    default = [
        {
            zone = "ap-northeast-2a"
            cidr = "10.11.1.0/25"
        },
        {
            zone = "ap-northeast-2c"
            cidr = "10.11.1.128/25"
        }
    ]
}

variable "private_subnets" {
    description = "프라이빗 서브넷 목록을 입력합니다."
    type    = list(object({
        zone = string
        cidr = string
    }))
    
    default = [
        {
            zone = "ap-northeast-2a"
            cidr = "10.11.101.0/25"
        },
        {
            zone = "ap-northeast-2c"
            cidr = "10.11.101.128/25"
        },
    ]
}


variable "tags" {
    default = {
        "MadeBy" = "terraform"
    }
}

############## [resource] ################

############################
############## 1. VPC

resource "aws_vpc" "this" {
    cidr_block = var.vpc_cidr
    #instance_tenancy = "default"
    
    enable_dns_hostnames = true
    
    tags = merge(
        {
            Name = format("%s-vpc", var.name)
        },
        var.tags
    )
}

resource "aws_subnet" "public" {
    count   = length(var.public_subnets)
    
    vpc_id  = aws_vpc.this.id
    
    availability_zone   = var.public_subnets[count.index].zone
    cidr_block  = var.public_subnets[count.index].cidr
    
    # AUTO-ASIGN PUBLIC IP
    map_public_ip_on_launch = true
    
    tags = merge(
        {
            Name = format(
                "%s-public-%s",
                var.name,
                element(split("", var.public_subnets[count.index].zone), length(var.public_subnets[count.index].zone) - 1)
            )
        },
        var.tags,
    )
}

resource "aws_subnet" "private" {
    count   = length(var.private_subnets)
    
    vpc_id  = aws_vpc.this.id
    
    availability_zone   = var.private_subnets[count.index].zone
    cidr_block  = var.private_subnets[count.index].cidr
    
    tags = merge(
        {
            Name = format(
                "%s-private-%s",
                var.name,
                element(split("", var.private_subnets[count.index].zone), length(var.private_subnets[count.index].zone) - 1)
            )
        },
        var.tags,
    )
}

resource "aws_route_table" "public" {
    #count = length(var.public_subnets)
    
    vpc_id  = aws_vpc.this.id
    
    tags    = merge(
        {
            Name = format(
                "%s-public-rt",
                var.name,
            )
        },
        var.tags,
    )
}

resource "aws_route_table" "private" {
    #count = length(var.private_subnets)
    
    vpc_id  = aws_vpc.this.id
    
    tags    = merge(
        {
            Name = format(
                "%s-private-rt",
                var.name,
            )
        },
        var.tags,
    )
}

resource "aws_route_table_association" "public" {
    count   = length(var.public_subnets)
    
    subnet_id   = aws_subnet.public[count.index].id
    route_table_id  = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
    count   = length(var.private_subnets)
    
    subnet_id   = aws_subnet.private[count.index].id
    route_table_id  = aws_route_table.private.id
}

####################
### Gateway Config 
resource "aws_internet_gateway" "this" {
    vpc_id  = aws_vpc.this.id
    
    tags = merge(
        {
            Name = format("%s-igw", var.name)
        },
        var.tags
    )
}

resource "aws_eip" "nat" {
    vpc = true
    
    depends_on = [aws_route_table.public]
    
    tags = merge(
        {
            Name = format(
                "%s-nat-eip-%s",
                var.name,
                element(split("", var.public_subnets[0].zone), length(var.public_subnets[0].zone) - 1)
            )
        },
        var.tags
    )
}

resource "aws_nat_gateway" "this" {
    subnet_id  = aws_subnet.public[0].id
    allocation_id = aws_eip.nat.id
    
    tags = merge(
        {
            Name = format(
                "%s-nat-%s",
                var.name,
                element(split("", var.public_subnets[0].zone), length(var.public_subnets[0].zone) - 1)
            )
        },
        var.tags
    )
}

####################
### Routing
resource "aws_route" "public" {
    
    route_table_id  = aws_route_table.public.id
    destination_cidr_block  = "0.0.0.0/0"
    
    # IGW(Internet Gateway) or VPG(Virtual Private Gateway)
    gateway_id      = aws_internet_gateway.this.id
    
    timeouts {
        create = "5m"
    }
}

resource "aws_route" "private" {
    
    route_table_id  = aws_route_table.private.id
    destination_cidr_block  = "0.0.0.0/0"
    
    # NAT Gateway
    nat_gateway_id      = aws_nat_gateway.this.id
    
    timeouts {
        create = "5m"
    }
}



############################
############## 2. Security

resource "aws_security_group" "bastion" {
    name    = format("%s-%s-sg", var.name, "bastion")
    description = "security group for ${var.name}"
    
    vpc_id  = aws_vpc.this.id
    
    egress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        self = true
        description = "self refer"
    }
    
    ingress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        self = true
        description = "self refer"
    }
    
    # ALL
    egress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "all"
    }
    
    # SSH
    ingress {
        from_port = "22"
        to_port = "22"
        protocol = "tcp"
        cidr_blocks = var.allow_ip_address
        description = "from my ip"
    }
    
    tags = merge(
        {
            Name = format(
                "%s-bastion-sg",
                var.name
            )
        },
        var.tags
    )
}

resource "aws_security_group" "elb" {
    name    = format("%s-%s-sg", var.name, "elb")
    description = "security group for ${var.name}"
    
    vpc_id  = aws_vpc.this.id
    
    egress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        self = true
        description = "self refer"
    }
    
    ingress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        self = true
        description = "self refer"
    }
    
    # ALL
    egress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "all"
    }
    
    # HTTP
    ingress {
        from_port = "80"
        to_port = "80"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "all http traffic"
    }
    
    tags = merge(
        {
            Name = format(
                "%s-elb-sg",
                var.name
            )
        },
        var.tags
    )
}

resource "aws_security_group" "was" {
    name    = format("%s-%s-sg", var.name, "was")
    description = "security group for ${var.name}"
    
    vpc_id  = aws_vpc.this.id
    
    egress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        self = true
        description = "self refer"
    }
    
    ingress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        self = true
        description = "self refer"
    }
    
    # ALL
    egress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "all"
    }
    
    # SSH
    ingress {
        from_port = "22"
        to_port = "22"
        protocol = "tcp"
        security_groups = [ aws_security_group.bastion.id ]
        description = "from bastion"
    }
    
    # HTTP
    ingress {
        from_port = "80"
        to_port = "80"
        protocol = "tcp"
        security_groups = [ aws_security_group.elb.id ]
        description = "from elb"
    }
    
    tags = merge(
        {
            Name = format(
                "%s-was-sg",
                var.name
            )
        },
        var.tags
    )
}

resource "aws_security_group" "db" {
    name    = format("%s-%s-sg", var.name, "db")
    description = "security group for ${var.name}"
    
    vpc_id  = aws_vpc.this.id
    
    egress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        self = true
        description = "self refer"
    }
    
    ingress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        self = true
        description = "self refer"
    }
    
    # ALL
    egress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "all"
    }
    
    # SSH
    ingress {
        from_port = var.db_port
        to_port = var.db_port
        protocol = "tcp"
        security_groups = [ aws_security_group.bastion.id ]
        description = "from bastion"
    }
    
    # DB
    ingress {
        from_port = var.db_port
        to_port = var.db_port
        protocol = "tcp"
        security_groups = [ aws_security_group.was.id ]
        description = "from was"
    }
    
    tags = merge(
        {
            Name = format(
                "%s-db-sg",
                var.name
            )
        },
        var.tags
    )
}

##############
############## 3. EC2

resource "aws_instance" "was" {
    ami = "ami-0bea7fd38fabe821a"
    instance_type = "t2.micro"
    
    key_name = var.key_name
    
    vpc_security_group_ids = [aws_security_group.was.id]
    subnet_id = aws_subnet.private[0].id
    
    root_block_device {
        volume_size = 10
        volume_type = "gp2"
        delete_on_termination = true
    }
    
    
    tags = merge(
        {
            Name = format(
                "%s-was",
                var.name
            )
        },
        var.tags
    )
}

resource "aws_instance" "bastion" {
    ami = "ami-0bea7fd38fabe821a"
    instance_type = "t2.micro"
    
    key_name = var.key_name
    
    vpc_security_group_ids = [aws_security_group.bastion.id]
    subnet_id = aws_subnet.public[0].id
    
    root_block_device {
        volume_size = 8
        volume_type = "gp2"
        delete_on_termination = true
    }
    
    
    tags = merge(
        {
            Name = format(
                "%s-bastion",
                var.name
            )
        },
        var.tags
    )
}

resource "aws_eip" "bastion" {
    vpc = true
    
    depends_on = [aws_route_table.public]
    instance = aws_instance.bastion.id
    
    tags = merge(
        {
            Name = format(
                "%s-bastion-eip-%s",
                var.name,
                element(split("", var.public_subnets[0].zone), length(var.public_subnets[0].zone) - 1)
            )
        },
        var.tags
    )
}


##############
############## 4. ELB

## TODO ALB
resource "aws_alb" "was" {
    name    = format("%s-was-alb", var.name)
    internal    = false
    security_groups = [aws_security_group.elb.id]
    subnets        = aws_subnet.public.*.id
    
    tags  = merge(
        {
            Name = format(
                "%s-was-alb",
                var.name
            )
        },
        var.tags
    )
    
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_alb_target_group" "was" {
    name    = format("%s-was-target-group", var.name)
    port    = 80
    protocol    = "HTTP"
    vpc_id  = aws_vpc.this.id
    
    health_check {
        path        = "/"
        healthy_threshold   = 3
        unhealthy_threshold = 3
    }
    
    tags = merge(
        {
            Name = format(
                "%s-was-target-group",
                var.name
            )
        },
        var.tags
    )
}

resource "aws_alb_target_group_attachment" "was" {
    target_group_arn    = aws_alb_target_group.was.arn
    target_id           = aws_instance.was.id
    port                = 80
}

resource "aws_alb_listener" "aws-http" {
    load_balancer_arn   = aws_alb.was.arn
    port    = "80"
    protocol    = "HTTP"
    
    default_action {
        target_group_arn = aws_alb_target_group.was.arn
        type    = "forward"
    }
}

##############
############## 5. RDS

## TODO RDS인스턴스



############## [output] ################

output "vpc_id" {
    value = aws_vpc.this.id
}

output "public_subnet_ids" {
    value = aws_subnet.public.*.id
}

output "private_subnet_ids" {
    value = aws_subnet.private.*.id
}

output "nat_gateway_ip" {
    value = aws_eip.nat.public_ip
}

output "bastion_ip" {
    value = aws_eip.bastion.public_ip
}
