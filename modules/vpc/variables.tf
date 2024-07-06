variable "cidr_block" {
  default = "172.16.0.0/20"
}

variable "frontend_subnet" {
  default = "172.16.0.0/21"
}

variable "backend_subnet" {
  default = "172.16.8.0/21"
}

variable "project" {
  default = "webweaver"
}

variable "env" {
  default = "dev"
}