setenforce 0
sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config
systemctl disable firewalld
systemctl stop firewalld
hostnamectl set-hostname web-vm
yum upgrade -y
sudo yum install -y mysql mysql-client git gcc curl wget vim gcc-c++
curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -
sudo yum install -y nodejs
node --version
git clone https://github.com/sharonpamela/Fiesta.git /code/Fiesta
cd /code/Fiesta
npm install
cd /code/Fiesta/client
npm install
npm run build
npm install nodemon concurrently
sed -i 's/REPLACE_DB_NAME/FiestaDB/g' /code/Fiesta/config/config.js
sed -i "s/REPLACE_DB_HOST_ADDRESS/$1/g" /code/Fiesta/config/config.js
sed -i "s/REPLACE_DB_DIALECT/mysql/g" /code/Fiesta/config/config.js
sed -i "s/REPLACE_DB_USER_NAME/fiesta/g" /code/Fiesta/config/config.js
sed -i "s/REPLACE_DB_PASSWORD/fiesta/g" /code/Fiesta/config/config.js
sed -i 's/REPLACE_DB_DOMAIN_NAME/\/\/DB_DOMAIN_NAME/g' /code/Fiesta/config/config.js
echo '[Service]
ExecStart=/usr/bin/node /code/Fiesta/index.js
Restart=always
RestartSec=2s
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=fiesta
User=root
Group=root
Environment=NODE_ENV=production PORT=80
[Install]
WantedBy=multi-user.target' | sudo tee /etc/systemd/system/fiesta.service
sudo systemctl daemon-reload
sudo systemctl start fiesta
sudo systemctl enable fiesta
sudo systemctl status fiesta -l
