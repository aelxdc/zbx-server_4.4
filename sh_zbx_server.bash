#!/bin/bash
read -p "Digite a senha do banco de dados: " SENHA
read -p "Digite o IP do Zabbix Server: " SERVIDOR
read -p "Digite o Hostname do Zabbix Proxy: " HOSTNAME

wget https://repo.zabbix.com/zabbix/4.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.4-1%2Bbionic_all.deb
dpkg -i zabbix-release_4.*
apt update && apt upgrade -y

echo "

Instalando aplicações

"
apt install mariadb-server zabbix-server-mysql zabbix-frontend-php \\
zabbix-apache-conf zabbix-agent snmp snmp-mibs-downloader apache2 -y

mv /etc/snmp/snmp.conf /etc/snmp/Old_snmp.conf
echo "
# As the snmp packages come without MIB files due to license reasons, loading
# of MIBs is disabled by default. If you added the MIBs you can reenable
# loading them by commenting out the following line.
mibs +ALL
mibAllowUnderline 1
" > /etc/snmp/snmp.conf
cp mibs_conectcor/* /usr/share/snmp/mibs/

echo "Creating database zabbix"
mysql -e "create database zabbix character set utf8 collate utf8_bin;"

echo "Creating user zabbix"
mysql -e "create user zabbix@localhost identified by '$SENHA';"

echo "Grant permissions on tables"
mysql -e "grant all privileges on zabbix.* to zabbix@localhost;"

echo "Importing zabbix schema to DB"
zcat /usr/share/doc/zabbix-server-mysql/schema.sql.gz | mysql -uzabbix -p$SENHA zabbix


sed -i "s@Server=127.0.0.1@Server=$SERVIDOR@g" /etc/zabbix/zabbix_proxy.conf
sed -i "s@Hostname=Zabbix proxy@Hostname=$HOSTNAME@g" /etc/zabbix/zabbix_proxy.conf
sed -i "s@DBUser=zabbix@DBUser="zabbix_proxy"@g" /etc/zabbix/zabbix_proxy.conf
sed -i "s@# DBPassword=@ DBPassword=$SENHA@g" /etc/zabbix/zabbix_proxy.conf


systemctl enable zabbix-server.service
systemctl restart zabbix-server.service