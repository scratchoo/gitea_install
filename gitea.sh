#!/bin/bash

sudo apt update
apt -y install expect
# apt -y install pwgen
sudo apt -y install nginx
sudo apt -y install git

# ================= Install MariaDB Database Server =======================

sudo apt-get -y install software-properties-common
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
sudo add-apt-repository "deb [arch=amd64,arm64,ppc64el] http://mariadb.mirror.liquidtelecom.com/repo/10.4/ubuntu $(lsb_release -cs) main"
sudo apt -y update
sudo apt -y install mariadb-server mariadb-client

CURRENT_MYSQL_PASSWORD=''

read -p 'mariadb root password: ' mariarootpwd

echo Thank you, MariaDB Root pass will be $mariarootpwd

echo 'Wait please...'

SECURE_MYSQL=$(expect -c "
# set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"$CURRENT_MYSQL_PASSWORD\r\"
expect \"Change the root password?\"
send \"y\r\"
expect \"New password:\"
send \"$mariarootpwd\r\"
expect \"Re-enter new password:\"
send \"$mariarootpwd\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")

echo "$SECURE_MYSQL"


sudo systemctl restart mariadb.service

read -p 'MariaDB user password: ' mariapwd
echo Thank you,  MariaDB user password will be $mariapwd

read -p 'Database name : ' db_name
read -p 'Database username : ' db_username
echo Your database name is $db_name and your database username is $db_username

mysql -uroot <<MYSQL_SCRIPT
CREATE DATABASE $db_name;
CREATE USER '$db_username'@'localhost' IDENTIFIED BY '$mariapwd';
GRANT ALL PRIVILEGES ON $db_name.* TO '$db_username'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# ================= Prepare the Gitea Environment =================

sudo adduser \
   --system \
   --shell /bin/bash \
   --gecos 'Git Version Control' \
   --group \
   --disabled-password \
   --home /home/git \
   git

sudo mkdir -p /var/lib/gitea/{custom,data,indexers,public,log}
sudo chown git:git /var/lib/gitea/{data,indexers,log}
sudo chmod 750 /var/lib/gitea/{data,indexers,log}
sudo mkdir /etc/gitea
sudo chown root:git /etc/gitea
sudo chmod 770 /etc/gitea

# ================ Install Gitea =============================

sudo wget -O gitea https://dl.gitea.io/gitea/1.5.0/gitea-1.5.0-linux-amd64
sudo chmod +x gitea

sudo cp gitea /usr/local/bin/gitea

# ========== Create a service file to start Gitea automatically ===========

sudo touch /etc/systemd/system/gitea.service


cat > /etc/systemd/system/gitea.service <<EOF
[Unit]
Description=Gitea (Git with a cup of tea)
After=syslog.target
After=network.target
#After=mysqld.service
#After=postgresql.service
#After=memcached.service
#After=redis.service

[Service]
# Modify these two values and uncomment them if you have
# repos with lots of files and get an HTTP error 500 because
# of that
###
#LimitMEMLOCK=infinity
#LimitNOFILE=65535
RestartSec=2s
Type=simple
User=git
Group=git
WorkingDirectory=/var/lib/gitea/
ExecStart=/usr/local/bin/gitea web -c /etc/gitea/app.ini
Restart=always
Environment=USER=git HOME=/home/git GITEA_WORK_DIR=/var/lib/gitea
# If you want to bind Gitea to a port below 1024 uncomment
# the two values below
###
#CapabilityBoundingSet=CAP_NET_BIND_SERVICE
#AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target

EOF

sudo systemctl daemon-reload
sudo systemctl enable gitea
sudo systemctl start gitea

sudo systemctl status gitea

# Ask for the domain that will be used for gitea
read -p "what's the domain/subdomain you will use for gitea ? (i.e: example.com or subdomain.example.com) " domain_name

# ============ Install and setup Let’s Encrypt =========

sudo apt -y install certbot python-certbot-nginx
sudo service nginx stop
sudo certbot certonly --standalone -d $domain_name


# ====== Configure Nginx as a reverse proxy =======

sudo rm /etc/nginx/sites-enabled/default

sudo touch /etc/nginx/sites-available/git

# https://golb.hplar.ch/2018/06/self-hosted-git-server.html
cat > /etc/nginx/sites-available/git <<EOF

server {
    listen 443 ssl;
    server_name ${domain_name};
    ssl_certificate /etc/letsencrypt/live/${domain_name}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${domain_name}/privkey.pem;

    location / {
        proxy_set_header  X-Real-IP  \$remote_addr;
        proxy_pass http://${domain_name};
    }
}

# Redirect HTTP requests to HTTPS
server {
    listen 80;
    server_name ${domain_name};
    return 301 https://\$host\$request_uri;
}


EOF

sudo ln -s /etc/nginx/sites-available/git /etc/nginx/sites-enabled/git

# sudo systemctl reload nginx
sudo service nginx start

echo "Thank you ! go to your your_domain.com/install to register a Gitea account :)"
