variable "haproxy_ip" {
  description = "IP de vm-haproxy"
  type        = string
  default     = "192.168.50.11"
}

variable "microservices_ip" {
  description = "IP de vm-microservices"
  type        = string
  default     = "192.168.50.12"
}

variable "ssh_user" {
  description = "Usuario SSH de los nodos target"
  type        = string
  default     = "vagrant"
}

variable "ssh_private_key" {
  description = "Ruta a la clave privada SSH en control-node"
  type        = string
  default     = "/home/vagrant/.ssh/id_rsa"
}
