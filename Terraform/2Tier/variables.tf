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
