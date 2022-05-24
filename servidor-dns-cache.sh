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
sudo yum install bind vim -y

sudo systemctl enable named

sudo firewall-cmd --add=service=dns --permanent
sudo firewall-cmd --reload

# ver porta de serviço dns
#ss -ln | grep 53

echo "backup arquivo original"
sudo mv /etc/named.conf /etc/named.bkp

sudo cat > /etc/named.conf << "EOF"
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//

options {
        listen-on port 53 { 127.0.0.1;192.168.15.70; };
        listen-on-v6 port 53 { ::1; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        secroots-file   "/var/named/data/named.secroots";
        recursing-file  "/var/named/data/named.recursing";
        allow-query     { localhost;192.168.15.0/24; };
        allow-query-cache { localhost;192.168.15.0/24; };

        /*
         - If you are building an AUTHORITATIVE DNS server, do NOT enable recursion.
         - If you are building a RECURSIVE (caching) DNS server, you need to enable
           recursion.
         - If your recursive DNS server has a public IP address, you MUST enable access
           control to limit queries to your legitimate users. Failing to do so will
           cause your server to become part of large scale DNS amplification
           attacks. Implementing BCP38 within your network would greatly
           reduce such attack surface
        */
        recursion yes;
        forward only;

        forwarders {
                8.8.8.8;
        };

        dnssec-enable yes;
        dnssec-validation yes;

        managed-keys-directory "/var/named/dynamic";

        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";

        /* https://fedoraproject.org/wiki/Changes/CryptoPolicy */
        include "/etc/crypto-policies/back-ends/bind.config";
};

logging {
        channel default_file {
                file "/var/log/named/default.log" versions 3 size 5m;
                severity dynamic;
                print-time yes;
        };
        channel general_file {
                file "/var/log/named/general.log" versions 3 size 5m;
                severity dynamic;
                print-time yes;
        };
        channel database_file {
                file "/var/log/named/database.log" versions 3 size 5m;
                severity dynamic;
                print-time yes;
        };
        channel security_file {
                file "/var/log/named/security.log" versions 3 size 5m;
                severity dynamic;
                print-time yes;
        };
        channel config_file {
                file "/var/log/named/config.log" versions 3 size 5m;
                severity dynamic;
                print-time yes;
        };
        channel resolver_file {
                file "/var/log/named/resolver.log" versions 3 size 5m;
                severity dynamic;
                print-time yes;
        };
        channel xfer-in_file {
                file "/var/log/named/xfer-in.log" versions 3 size 5m;
                severity dynamic;
                print-time yes;
        };
        channel xfer-out_file {
                file "/var/log/named/xfer-out.log" versions 3 size 5m;
                severity dynamic;
                print-time yes;
        };
        channel notify_file {
                file "/var/log/named/notify.log" versions 3 size 5m;
                severity dynamic;
                print-time yes;
        };
        channel client_file {
                file "/var/log/named/client.log" versions 3 size 5m;
                severity dynamic;
                print-time yes;
        };
        channel unmatched_file {
                file "/var/log/named/unmatched.log" versions 3 size 5m;
                severity dynamic;
                print-time yes;
        };
        channel queries_file {
                file "/var/log/named/queries.log" versions 3 size 5m;
                severity dynamic;
                print-time yes;
        };
        channel network_file {
                file "/var/log/named/network.log" versions 3 size 5m;
                severity dynamic;
                print-time yes;
        };
        channel update_file {
                file "/var/log/named/update.log" versions 3 size 5m;
                severity dynamic;
                print-time yes;
        };
        channel dispatch_file {
                file "/var/log/named/dispatch.log" versions 3 size 5m;
                severity dynamic;
                print-time yes;
        };
        channel dnssec_file {
                file "/var/log/named/dnssec.log" versions 3 size 5m;
                severity dynamic;
                print-time yes;
        };
        channel lame-servers_file {
                file "/var/log/named/lame-servers.log" versions 3 size 5m;
                severity dynamic;
                print-time yes;
        };

category default { default_file; };
category general { general_file; };
category database { database_file; };
category security { security_file; };
category config { config_file; };
category resolver { resolver_file; };
category xfer-in { xfer-in_file; };
category xfer-out { xfer-out_file; };
category notify { notify_file; };
category client { client_file; };
category unmatched { unmatched_file; };
category queries { queries_file; };
category network { network_file; };
category update { update_file; };
category dispatch { dispatch_file; };
category dnssec { dnssec_file; };
category lame-servers { lame-servers_file; };

};

zone "." IN {
        type hint;
        file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
EOF

sudo mkdir /var/log/named
sudo chown named:named /var/log/named
sudo named-checkconf
sudo systemctl restart named
sudo ls /var/log/named/

#ver request em tempo de execução
#tail -n 0 -f /var/log/named/queries.log
# na maquina cliente para teste user
# time host google.com 
# dig -x google.com
