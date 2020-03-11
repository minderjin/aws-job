############## [variable] ################
provider "aws" {
  region = var.region
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "mzc"
}

variable "region" {
    description = "리전을 선택합니다. e.g: ap-northeast-2"
    type        = string
    default     = "ap-northeast-2"
}

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

variable "name" {
    description = "프로젝트 이름을 입력합니다."
    type        = string
    default     = "tt-efs"
}

variable "ec2_ami" {
    description = "설치할 OS의 AMI ID"
    type        = string
    #default    = "ami-06cf2a72dadf92410"   #CentOS 7
    default     = "ami-0bea7fd38fabe821a"   #Amazon Linux 2
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

variable "autoscale_ami" {
    description = "AutoScaling 때 사용할 AMI ID"
    type        = string
    default     = "ami-093f1eaafc86702e5"   #tt-efs-was-a-ami
    
}

variable "autoscale_cf" {
    description = "퍼블릭 서브넷 목록을 입력합니다."
    type = list(object({
        target_value = number
        min_size = number
        max_size = number
    }))
    
    default = [
        {
            target_value = 70.0 #CPU Average
            min_size = 1        #AutoScaling Instance min size
            max_size = 3        #AutoScaling Instance max size
        },
    ]
}


variable "tags" {
    default = {
        "MadeBy" = "mzc-ckj"
    }
}
