#!/bin/bash

sudo apt update
apt -y install expect
apt -y install pwgen
sudo apt -y install nginx
sudo apt -y install git
#sudo apt -y install mariadb-server mariadb-client

sudo apt-get -y install software-properties-common
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
sudo add-apt-repository "deb [arch=amd64,arm64,ppc64el] http://mariadb.mirror.liquidtelecom.com/repo/10.4/ubuntu $(lsb_release -cs) main"
sudo apt -y update
sudo apt -y install mariadb-server mariadb-client

CURRENT_MYSQL_PASSWORD=''

read -p 'mariadb root password: ' mariarootpwd

echo Thank you, MariaDB Root pass will be $mariarootpwd

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

mysql -uroot <<MYSQL_SCRIPT
CREATE DATABASE gitea;
CREATE USER 'giteauser'@'localhost' IDENTIFIED BY '$mariapwd';
GRANT ALL PRIVILEGES ON gitea.* TO 'giteauser'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

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

sudo wget -O gitea https://dl.gitea.io/gitea/1.5.0/gitea-1.5.0-linux-amd64
sudo chmod +x gitea

sudo cp gitea /usr/local/bin/gitea

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

sudo rm /etc/nginx/sites-enabled/default

read -p "what's your gitea domain name ? " domain_name

sudo touch /etc/nginx/sites-available/git

# https://golb.hplar.ch/2018/06/self-hosted-git-server.html
cat > /etc/nginx/sites-available/git <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name git.$domain_name;


    client_max_body_size 20m;
    location / {
        proxy_pass http://localhost:3000;
    }
}

EOF

sudo ln -s /etc/nginx/sites-available/git /etc/nginx/sites-enabled/git

sudo systemctl reload nginx

echo Thank you ! go to your your_domain.com/install to register a Gitea account :)
