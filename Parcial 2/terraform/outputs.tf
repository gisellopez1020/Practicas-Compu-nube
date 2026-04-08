output "haproxy_status" {
  value = "vm-haproxy (${var.haproxy_ip}) — HAProxy instalado"
}

output "microservices_status" {
  value = "vm-microservices (${var.microservices_ip}) — Docker instalado, contenedores desplegados vía Ansible"
}
