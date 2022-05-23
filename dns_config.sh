#!/usr/bin/env bash
############################################
# Autor: Leonardo Teixeira                 #
# Server: Servidor DNS                     #
# CENTOS 7 - 8 e REDHAT derivados          #
# kernel 4.18.0-383.el8.x86_64             #
############################################

echo "Digite seu Hostname"
read HOSTNAME
sudo hostnamectl set-hostname $HOSTNAME

echo "instalando bind"
sudo yum install bind bind-utils -y

echo "configurando arquivo named.conf"
mv /etc/named.conf /etc/named.bkp
cat > /etc/named.conf << "EOF"
#/etc/named.conf
options {
        listen-on port 53 { localhost; };
        listen-on-v6 port 53 { localhost; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        secroots-file   "/var/named/data/named.secroots";
        recursing-file  "/var/named/data/named.recursing";
        allow-query     { localhost;localnets;192.168.15.0/24; };
        recursion yes;

        dnssec-enable yes;
        dnssec-validation yes;

        managed-keys-directory "/var/named/dynamic";

        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";
        include "/etc/crypto-policies/back-ends/bind.config";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
        type hint;
        file "named.ca";
};

zone "elton.ddns.net" IN {
        type master;
        file "/etc/bind/direta.db";
};

zone "192.168.15.in-addr.arpa" IN {
        type master;
        file "/etc/bind/inversa.db";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
#end
EOF

sudo mkdir /etc/bind
sudo touch /etc/bind/direta.db
sudo touch /etc/bind/inversa.db
sudo chown -R named:named /etc/bind/
sudo chmod 750 -R /etc/bind

echo "configurando zona direta"
cat > /etc/bind/zona_direta.db << "EOF"
$TTL 8h ;
@       IN      SOA     dns.elton.ddns.net. root.elton.ddns.net. (
                        20211228 ; serial
                        3h ; refresh
                        30 ; retry
                        4d ; expiry
                        1h ; negative cache
);
@       IN      NS      dns.elton.ddns.net.
dns     IN      A       192.168.15.56
ldap    IN      A       192.168.15.20
www     IN      A       192.168.15.15
web     IN      CNAME   www
ftp     IN      CNAME   www
firewall        IN      A       192.168.15.56
proxy   IN      CNAME   firewall
EOF

echo "configurando zone reversa"
cat > /etc/bind/zone_reversa.db << "EOF"
$TTL 8h ;
@       IN      SOA     dns.elton.ddns.net. root.elton.ddns.net. (
                        20211228 ; serial
                        3h ; refresh
                        30 ; retry
                        4d ; expiry
                        1h ; negative cache
);
@       IN      NS      elton.ddns.net.
56      IN      PTR     dns.elton.ddns.net.
20      IN      PTR     ldap.elton.ddns.net.
15      IN      PTR     www.elton.ddns.net.
25      IN      PTR     firewall.elton.ddns.net.
EOF

echo "checando configurações named.conf"
sudo named-checkconf

echo "checando configurações zona direta"
sudo named-checkzone elton.ddns.net /etc/bind/direta.db
sudo named-checkzone 192.168.15.56 /etc/bind/direta.db

echo "checando configuração zona inversa"
sudo named-checkzone elton.ddns.net /etc/bind/inversa.db
sudo named-checkzone 192.168.15.56 /etc/bind/inversa.db

echo "habilitando serviço para boot do sistema"
sudo systemctl enable named

echo "iniciando o servico"
sudo systemctl start named
sudo systemctl status named
