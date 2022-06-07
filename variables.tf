# Networking
variable "network" {
  type = object({
    cidr_block     = string
    Azs            = list(string)
    private_subnet = list(string)
    public_subnet  = list(string)
    nat_gateway    = bool
  })
  default = {
    Azs            = ["eu-west-3a", "eu-west-3b"]
    cidr_block     = "10.20.0.0/16"
    nat_gateway    = true
    private_subnet = ["10.20.128.0/20", "10.20.144.0/20"]
    public_subnet  = ["10.20.0.0/20", "10.20.16.0/20"]
    nat_gateway = true
  }
}


# environment
variable "tags" {
  type = object({
    name : string
    environment : string
  })
  default = {
    name        = "einstein"
    environment = "practice"
  }
}