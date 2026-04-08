terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

resource "null_resource" "provision_haproxy" {

  connection {
    type        = "ssh"
    host        = var.haproxy_ip
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y haproxy",
      "sudo systemctl enable haproxy",
      "sudo systemctl start haproxy",
      "echo 'HAProxy instalado y activo en vm-haproxy'"
    ]
  }
}

resource "null_resource" "provision_microservices" {

  connection {
    type        = "ssh"
    host        = var.microservices_ip
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y ca-certificates curl gnupg lsb-release",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "sudo chmod a+r /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo usermod -aG docker vagrant",
      "echo 'Docker instalado'"
    ]
  }
}

resource "null_resource" "run_ansible" {
  depends_on = [
    null_resource.provision_microservices,
    null_resource.provision_haproxy
  ]

  provisioner "local-exec" {
    command = <<EOT
      cd /home/vagrant/microproject/ansible && \
      ansible-playbook -i inventory.ini playbook-microservices.yml && \
      ansible-playbook -i inventory.ini playbook-haproxy.yml
    EOT
  }
}
