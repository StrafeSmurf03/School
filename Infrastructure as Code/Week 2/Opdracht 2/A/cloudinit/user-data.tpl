#cloud-config
users:
  - name: ${username}
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo
    shell: /bin/bash
    ssh_authorized_keys:
      - ${ssh_key}

package_update: true
package_upgrade: true
packages:
  - wget
  - ntpdate

runcmd:
  - systemctl restart systemd-timesyncd.service