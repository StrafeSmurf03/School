#cloud-config
users:
  - name: ${ssh_username}
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
        - ${ssh_key}

package_update: true
package_upgrade: true

packages:
  - nginx

runcmd:
  # Zorg ervoor dat Nginx draait en ingeschakeld is bij het opstarten
  - systemctl enable nginx
  - systemctl start nginx

  # Configureer Nginx om te proxy'en naar de Blob Storage
  - |
    cat > /etc/nginx/sites-available/default <<'EOF'
    server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/html;
        index index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
            try_files $uri $uri/ =404;
        }

        # Nginx proxy configuratie voor Blob Storage
        # Wanneer iemand /media/afbeelding.jpg aanvraagt, haalt Nginx deze op uit Blob Storage.
        location /media/ {
            proxy_pass https://storageaccount2jensban.blob.core.windows.net/blobcontainer/;
            proxy_redirect off;
            proxy_set_header Host "Storage_Account-1.blob.core.windows.net";
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
    EOF

  # Herstart Nginx om de nieuwe configuratie te laden
  - systemctl restart nginx