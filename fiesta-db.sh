setenforce 0
sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config
systemctl disable firewalld
systemctl stop firewalld
hostnamectl set-hostname db-vm
sudo yum install -y mariadb mariadb-server git
sudo /usr/bin/mysql_install_db --user=mysql --ldata=/var/lib/mysql
sudo mkdir /run/mysqld
sudo chown mysql:mysql /run/mysqld
sudo systemctl enable mariadb
sudo systemctl start mariadb
sudo mkdir /code
sudo git clone https://github.com/sharonpamela/Fiesta /code/Fiesta
sudo mysql < /code/Fiesta/seeders/FiestaDB-mySQL.sql
sudo echo "grant all privileges on FiestaDB.* to fiesta@'%' identified by 'fiesta';" | sudo mysql
sudo echo "grant all privileges on FiestaDB.* to fiesta@localhost identified by 'fiesta';" | sudo mysql
sudo sed -i 's/socket=\/var\/lib\/mysql\/mysql.sock/socket=\/var\/lib\/mysql\/mysql.sock\nlog_bin=\/var\/log\/mariadb\/mariadb-bin.log/g' /etc/my.cnf
sudo systemctl daemon-reload
sudo systemctl restart mariadb
sudo mysqladmin --user=root password 'nutanix/4u'