## To create new vault

```shell
ansible-vault create vars/vault.yml  
```

To view content of vault

```shell
ansible-vault view vars/vault.yml 
```

To edit content of vault

```shell
ansible-vault edit vars/vault.yml 
```

## To connect

Create hosts file

## Command

```shell
ansible-playbook playbooks/init.yml  -J 
```

J - ask about vault pass