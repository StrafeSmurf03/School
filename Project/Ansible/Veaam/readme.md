# Veeam Backup & Replication install
## Requirements
Ansible installed with winrm installed, use following commands: <br/>
```
pip install ansible-core
```
```
pip install pywinrm
```
veeamhub.veeam package installed, use following command: <br/>
```
ansible-galaxy collection install veeamhub.veeam 
```
Windows endpoint preperation, install winrm. 
Execute winrm-install.ps1 on destination host. <br/>

Update following in the hosts file: </br>
```
ansible_user
ansible_password
```
