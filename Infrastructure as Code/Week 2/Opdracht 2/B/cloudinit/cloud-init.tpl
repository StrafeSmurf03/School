#cloud-config
users:
  - name: ${iac_username}
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
        - ${ssh_key}

write_files:
  - path: /home/${iac_username}/hello.txt
    content: Hello World
    owner: ${iac_username}:${iac_username}
    permissions: '0644'
    defer: true

runcmd:
  - chown ${iac_username}:${iac_username} /home/${iac_username}/hello.txt