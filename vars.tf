variable "var_project" {
  default = "datacom-operations-two"
}

variable "var_prefix" {
  default = "lab"
}

variable "var_company" {
  default = "Datacom"
}

variable "var_region" {
  default = "us-central1"
}

variable "var_zone" {
  default = "us-central1-c"
}

variable "var_network_subnet" {
  default = "10.30.1.0/24"
}

variable "var_network_ip" {
  type = "map"
  default = {
    ad1     = "10.30.1.11"
    ad2     = "10.30.1.12"
    member1 = "10.30.1.21"
    member2 = "10.30.1.22"
  }
}

variable "var_ports" {
  type = "map"
  default = {
    winrmhttp  = "5985"
    winrmhttps = "21002"
  }
}

variable "ad_server_domain" {
  default = "datacomlab.com"
}

variable "ad_server_user" {
  default = "dclabadmin"
}

variable "ad_server_password" {
  default = "Fzp2u41x0QpBaP"
}

variable "local_admin_user" {
  default = "dclablocaladmin"
}

variable "local_admin_password" {
  default = "Ttp2u33x0QnWyu"
}
