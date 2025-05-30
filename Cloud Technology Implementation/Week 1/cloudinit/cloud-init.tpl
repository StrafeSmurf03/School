#cloud-config
users:
  - name: ${ssh_username}
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
        - ${ssh_key}
