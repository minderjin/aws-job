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
    count = length(var.private_subnets)
    
    ami = var.ec2_ami
    instance_type = "t2.micro"
    key_name = var.key_name
    user_data = <<EOF
        #!/bin/sh
        yum -y install httpd php mysql php-mysql
        chkconfig httpd on
        service httpd start
        if [ ! -f /var/www/html/bootcamp-app.tar.gz ]; then
           cd /var/www/html
           wget https://s3.amazonaws.com/awstechbootcamp/GettingStarted/bootcamp-app.tar.gz
           tar xvfz bootcamp-app.tar.gz
           chown apache:root /var/www/html/rds.conf.php
        fi
        yum -y update
    EOF
    
    vpc_security_group_ids = [aws_security_group.was.id]
    subnet_id = aws_subnet.private[count.index].id
    
    root_block_device {
        volume_size = 10
        volume_type = "gp2"
        delete_on_termination = true
    }
    
    
    tags = merge(
        {
            Name = format(
                "%s-was-%s",
                var.name,
                element(split("", var.public_subnets[count.index].zone), length(var.public_subnets[count.index].zone) - 1)
            )
        },
        var.tags
    )
}

resource "aws_instance" "bastion" {
    ami = var.ec2_ami
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
############## 4. ELB (ALB)
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
    count   = length(aws_instance.was)
    
    target_group_arn    = aws_alb_target_group.was.arn
    target_id           = aws_instance.was[count.index].id
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
############## 5. EFS

resource "aws_efs_file_system" "efs" {
    creation_token = "my-efs"
    
    tags = merge(
        {
            Name = format(
                "%s-efs",
                var.name
            )
        },
        var.tags
    )
}

resource "aws_efs_mount_target" "alpha" {
    count = length(aws_subnet.private)
    
    file_system_id = aws_efs_file_system.efs.id
    security_groups = [aws_security_group.was.id]
    subnet_id      = aws_subnet.private[count.index].id
}



##############
############## 6. AutoScaling

resource "aws_launch_configuration" "as_conf" {
    name_prefix   = format("%s-tt-lc-", var.name)
    image_id      = var.autoscale_ami
    instance_type = "t3.micro"
    user_data = <<EOF
        #!/bin/sh
        sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-4ae9b42b.efs.ap-northeast-2.amazonaws.com:/ /home/ec2-user/efs
    EOF
    
    security_groups =  [ 
            aws_security_group.was.id
        ]
        
    key_name = var.key_name
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "was" {
    name                = format("%s-was-asg", var.name)
    min_size            = var.autoscale_cf[0].min_size
    max_size            = var.autoscale_cf[0].max_size
    
    target_group_arns   = [
            aws_alb_target_group.was.arn
        ]
    health_check_grace_period = 300
    health_check_type         = "EC2"
    force_delete              = true
    
    launch_configuration = aws_launch_configuration.as_conf.name
    vpc_zone_identifier  = aws_subnet.private.*.id
    
    #vpc_zone_identifier  = [
    #        aws_subnet.private-was[0].id,
    #        aws_subnet.private-was[1].id,
    #    ]
    
    enabled_metrics           = [
            "GroupDesiredCapacity",
            "GroupInServiceCapacity",
            "GroupInServiceInstances",
            "GroupMaxSize",
            "GroupMinSize",
            "GroupPendingCapacity",
            "GroupPendingInstances",
            "GroupStandbyCapacity",
            "GroupStandbyInstances",
            "GroupTerminatingCapacity",
            "GroupTerminatingInstances",
            "GroupTotalCapacity",
            "GroupTotalInstances",
        ]
        
    lifecycle {
        create_before_destroy = true
    }
    
    timeouts {
        delete = "15m"
    }
}

resource "aws_autoscaling_policy" "was" {
    name            = format("%s-as-policy", var.name)
    policy_type     = "TargetTrackingScaling"
    
    autoscaling_group_name = aws_autoscaling_group.was.name
    estimated_instance_warmup = 300
    
    target_tracking_configuration {
        predefined_metric_specification {
            predefined_metric_type = "ASGAverageCPUUtilization"
        }
        
        target_value = var.autoscale_cf[0].target_value #CPU Average
        disable_scale_in = false
    }
}
