#cloud-config
users:
  - name: "gebruiker"
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: true
    ssh_authorized_keys:
      - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMIJc6eOKRMaaMbr+7SE3ELTk924IOO4sjHApXz1IZiS"