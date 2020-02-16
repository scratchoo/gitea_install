#!/bin/bash

# NOTE: no space arround = for variables
UBUNTU_VERSION=18.04
RUBY_VERSION=2.7.0
BUNDLER_VERSION="" # keep it as empty string if you want to intsall the latest bundler version
APP_NAME="myapp"


# adduser deployer
# # Enter new UNIX password:
# adduser deployer sudo
# su - deployer

# Adding Node.js 10 repository
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -

# Adding Yarn repository
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

yes "" | sudo add-apt-repository ppa:chris-lea/redis-server

# Refresh our packages list with the new repositories
sudo apt-get update

# Install our dependencies for compiiling Ruby along with Node.js and Yarn
sudo apt-get -yqq install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev dirmngr gnupg apt-transport-https ca-certificates redis-server redis-tools nodejs yarn

# Installing rvm
gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

sudo apt-get -yqq install software-properties-common

sudo apt-add-repository -y ppa:rael-gc/rvm
sudo apt-get update
sudo apt-get install rvm

echo 'source "/etc/profile.d/rvm.sh"' >> ~/.bashrc

source ~/.rvm/scripts/rvm

rvm install $RUBY_VERSION

rvm use $RUBY_VERSION --default

ruby -v

if [ -z "$BUNDLER_VERSION" ]
then
  # $BUNDLER_VERSION is empty
  # Install the latest Bundler
  gem install bundler
else
  # $BUNDLER_VERSION is NOT empty
  # For older apps that require a specific Bundler version.
  gem install bundler -v $BUNDLER_VERSION
fi

# Test and make sure bundler is installed correctly, you should see a version number.
bundle -v

# Installing NGINX & Passenger
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7

sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger bionic main > /etc/apt/sources.list.d/passenger.list'

sudo apt-get update

sudo apt-get install -yqq nginx-extras libnginx-mod-http-passenger

if [ ! -f /etc/nginx/modules-enabled/50-mod-http-passenger.conf ]; then sudo ln -s /usr/share/nginx/modules-available/mod-http-passenger.load /etc/nginx/modules-enabled/50-mod-http-passenger.conf ; fi

sudo ls /etc/nginx/conf.d/mod-http-passenger.conf

# want to change the passenger_ruby line to match the following: passenger_ruby /home/deploy/.rbenv/shims/ruby;
sed -i "s/passenger_ruby.*/passenger_ruby \/home\/deploy\/.rvm\/wrappers\/ruby-$RUBY_VERSION\/ruby;" /etc/nginx/conf.d/mod-http-passenger.conf

sudo service nginx start

# Next we're going to remove this default NGINX server and add one for our application instead.

sudo rm /etc/nginx/sites-enabled/default

sudo touch /etc/nginx/sites-enabled/$APP_NAME

cat > /etc/nginx/sites-enabled/$APP_NAME <<EOF
server {
  listen 80;
  listen [::]:80;

  server_name _;
  root /home/deploy/$APP_NAME/current/public;

  passenger_enabled on;
  passenger_app_env production;

  location /cable {
    passenger_app_group_name $APP_NAME_websocket;
    passenger_force_max_concurrent_requests_per_process 0;
  }

  # Allow uploads up to 100MB in size
  client_max_body_size 100m;

  location ~ ^/(assets|packs) {
    expires max;
    gzip_static on;
  }
}
EOF

sudo service nginx reload

# Creating a PostgreSQL Database

sudo apt-get -yqq install postgresql postgresql-contrib libpq-dev
sudo su - postgres
createuser --pwprompt deploy
createdb -O deploy $APP_NAME
exit

exec $SHELL
