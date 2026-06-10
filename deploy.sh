#!/bin/bash
set -e

echo "=== 1. Uruchamianie Terraform ==="
terraform apply -auto-approve

echo "=== 2. Pobieranie IP maszyny ==="
VM_IP=$(terraform output -raw vm_public_ip)

echo "=== 3. Oczekiwanie na SSH ==="
while ! nc -z -v -w5 $VM_IP 22; do
    echo "Maszyna sie uruchamia..."
    sleep 5
done

echo "=== 4. Konfiguracja przez Ansible ==="
ansible-playbook -i "$VM_IP," -u azureuser --private-key ~/.ssh/id_rsa playbook.yml

echo "=== Sukces ==="
echo "Adres strony: http://$VM_IP"
