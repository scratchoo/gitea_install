# A bash script to intall Gitea + Let's encrypt certificat for you on ubuntu 18.04

## Note :
The instructions in this script are from on https://www.vultr.com/docs/how-to-install-gitea-on-ubuntu-18-04 

To prevent the error: **The database settings are invalid: Error 1071: Specified key was too long; max key length is 767 bytes** We install mariaDB 10.4 instructions are from: https://computingforgeeks.com/how-to-install-mariadb-10-4-on-ubuntu-18-04-ubuntu-16-04/

# how to use the script ?

Before using this script, please make sure you have DNS setting in place because the (let's encrypt) do a check for you domain before installation, in this example I will use Digitalocean for my server and namecheap as my registrar

## Fee free to use the following link to get $50 when you register for a digitalocean account :

https://m.do.co/c/1053282d64cd

1) Create a vps machine (a droplet if you are using digitalocean)

2) Copy the IP address of your virtual machine (vps/droplet) and click add domain

![alt text](https://github.com/scratchoo/gitea_install/raw/master/digitalocean_domain.png)

3) add basic A records as the following :

![Adding domain to digitalocea](https://github.com/scratchoo/gitea_install/raw/master/add_domain_digitalocean.png)

4) now go and log in to your domain registrar (namecheap in my case), and change DNS setting to custom DNS, and add the following:

ns1.digitalocean.com
ns2.digitalocean.com
ns3.digitalocean.com

![namecheap with digitalocean DNS](https://github.com/scratchoo/gitea_install/raw/master/namecheap_digitalocean_dns.png)


Digitalocean has a good article for that with different registrar here: https://www.digitalocean.com/community/tutorials/how-to-point-to-digitalocean-nameservers-from-common-domain-registrars


**Once you configured your DNS... let's use our script**

First ssh to your remote server

`ssh root@IP_OF_YOUR_MACHIN`

Then download the script and execute it as the following :

```
curl https://raw.githubusercontent.com/scratchoo/gitea_install/master/gitea.sh --output script.sh | chmod +x
bash script.sh
```

# Trouble shooting 

While this script is tested, if you face the nginx error 
```
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xe" for details.
```
Then you can check the log file to track the error :

`sudo tail -n 1000 /var/log/nginx/error.log`
