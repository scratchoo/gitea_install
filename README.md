# A bash script to intall Gitea on ubuntu 18.04

The instructions in this script are from on https://www.vultr.com/docs/how-to-install-gitea-on-ubuntu-18-04 

To prevent the error: **The database settings are invalid: Error 1071: Specified key was too long; max key length is 767 bytes** We install mariaDB 10.4 instructions are from: https://computingforgeeks.com/how-to-install-mariadb-10-4-on-ubuntu-18-04-ubuntu-16-04/

# how to use it ?

First ssh to your remote server

`ssh root@IP_OF_YOUR_MACHIN`

Then download the script and execute it as the following :

```
curl https://raw.githubusercontent.com/scratchoo/gitea_install/master/gitea.sh --output script.sh | chmod +x
bash script.sh
```
