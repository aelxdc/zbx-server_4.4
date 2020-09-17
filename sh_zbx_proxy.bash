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
apt install mariadb-server zabbix-proxy-mysql snmp snmp-mibs-downloader -y

mv /etc/snmp/snmp.conf /etc/snmp/Old_snmp.conf
echo "
# As the snmp packages come without MIB files due to license reasons, loading
# of MIBs is disabled by default. If you added the MIBs you can reenable
# loading them by commenting out the following line.
mibs +ALL
mibAllowUnderline 1
" > /etc/snmp/snmp.conf
cp mibs_conectcor/* /usr/share/snmp/mibs/

echo "Creating database zabbix_proxy"
mysql -e "create database zabbix_proxy character set utf8 collate utf8_bin;"

echo "Creating user zabbix_proxy"
mysql -e "create user zabbix_proxy@localhost identified by '$SENHA';"

echo "Grant permissions on tables"
mysql -e "grant all privileges on zabbix_proxy.* to zabbix_proxy@localhost;"

echo "Importing zabbix schema to DB"
zcat /usr/share/doc/zabbix-proxy-mysql/schema.sql.gz | mysql -uzabbix_proxy -p$SENHA zabbix_proxy


sed -i "s@Server=127.0.0.1@Server=$SERVIDOR@g" /etc/zabbix/zabbix_proxy.conf
sed -i "s@Hostname=Zabbix proxy@Hostname=$HOSTNAME@g" /etc/zabbix/zabbix_proxy.conf
sed -i "s@DBUser=zabbix@DBUser="zabbix_proxy"@g" /etc/zabbix/zabbix_proxy.conf
sed -i "s@# DBPassword=@ DBPassword=$SENHA@g" /etc/zabbix/zabbix_proxy.conf


systemctl enable zabbix-proxy.service
systemctl restart zabbix-proxy.service