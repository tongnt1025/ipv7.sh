#!/bin/bash
# define some constants. Those are your WAN IP which need to be whitelisted.
fpt_ip="103.121.88.0/24"
vnpt_ip="103.48.81.0/24"
ip_vphn="14.162.145.194"
ip_vphcm="14.241.230.218"
# delete all configuration and set default policy for each chain.
iptables -F
iptables -X
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -N ZIMBRA-FIREWALL
iptables -A INPUT -j ZIMBRA-FIREWALL
iptables -A FORWARD -j ZIMBRA-FIREWALL
# Stop some attacks
iptables -A ZIMBRA-FIREWALL -p tcp --tcp-flags ALL NONE -j DROP
iptables -A ZIMBRA-FIREWALL -p tcp ! --syn -m state --state NEW -j DROP
iptables -A ZIMBRA-FIREWALL -p tcp --tcp-flags ALL ALL -j DROP
# Accept save connection and icmp
iptables -A ZIMBRA-FIREWALL -i lo -j ACCEPT
iptables -A ZIMBRA-FIREWALL -p icmp --icmp-type any -j ACCEPT
iptables -A ZIMBRA-FIREWALL -m state --state ESTABLISHED,RELATED -j ACCEPT
# Drop invalid packets immediately
#iptables -A INPUT   -m state --state INVALID -j DROP
#iptables -A FORWARD -m state --state INVALID -j DROP
#iptables -A OUTPUT  -m state --state INVALID -j DROP
iptables -A ZIMBRA-FIREWALL -m state --state INVALID -j DROP
# Drop bogus TCP packets
#iptables -A INPUT -p tcp -m tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
iptables -A ZIMBRA-FIREWALL -p tcp -m tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
#iptables -A INPUT -p tcp -m tcp --tcp-flags SYN,RST SYN,RST -j DROP
iptables -A ZIMBRA-FIREWALL -p tcp -m tcp --tcp-flags SYN,RST SYN,RST -j DROP
#iptables -A INPUT -p tcp -m tcp --tcp-flags RST RST -m limit --limit 2/second --limit-burst 2 -j ACCEPT
iptables -A ZIMBRA-FIREWALL -p tcp -m tcp --tcp-flags RST RST -m limit --limit 2/second --limit-burst 2 -j ACCEPT
# enable this rule if have has layer remote 2/3 devices
iptables -A ZIMBRA-FIREWALL -p tcp --tcp-flags FIN,SYN,RST,ACK RST,ACK -j ACCEPT
# enable ssh and snmp
#iptables -A ZIMBRA-FIREWALL -m state -state NEW -m tcp -p tcp -dport 22 -j ACCEPT -s $vnpt_ip
#iptables -A ZIMBRA-FIREWALL -m state -state NEW -m tcp -p tcp -dport 22 -j ACCEPT -s $fpt_ip
#iptables -A ZIMBRA-FIREWALL -m state -state NEW -m udp -p udp -dport 161 -j ACCEPT -s $vnpt_ip
#iptables -A ZIMBRA-FIREWALL -m state -state NEW -m udp -p udp -dport 161 -j ACCEPT -s $fpt_ip
iptables -A ZIMBRA-FIREWALL -j ACCEPT -s $fpt_ip
iptables -A ZIMBRA-FIREWALL -j ACCEPT -s $vnpt_ip
iptables -A ZIMBRA-FIREWALL -j ACCEPT -s $ip_vphn
iptables -A ZIMBRA-FIREWALL -j ACCEPT -s $ip_vphcm
# enable zimbra ports
iptables -A ZIMBRA-FIREWALL -m state --state NEW -m tcp -p tcp --dport 25 -j ACCEPT
iptables -A ZIMBRA-FIREWALL -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
iptables -A ZIMBRA-FIREWALL -m state --state NEW -m tcp -p tcp --dport 110 -j ACCEPT
iptables -A ZIMBRA-FIREWALL -m state --state NEW -m tcp -p tcp --dport 143 -j ACCEPT
iptables -A ZIMBRA-FIREWALL -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
iptables -A ZIMBRA-FIREWALL -m state --state NEW -m tcp -p tcp --dport 465 -j ACCEPT
iptables -A ZIMBRA-FIREWALL -m state --state NEW -m tcp -p tcp --dport 587 -j ACCEPT
iptables -A ZIMBRA-FIREWALL -m state --state NEW -m tcp -p tcp --dport 993 -j ACCEPT
iptables -A ZIMBRA-FIREWALL -m state --state NEW -m tcp -p tcp --dport 995 -j ACCEPT
iptables -A ZIMBRA-FIREWALL -m state --state NEW -m tcp -p tcp -dport 7071 -j ACCEPT
#iptables -A ZIMBRA-FIREWALL -m state --state NEW -m tcp -p tcp -dport 9071 -j ACCEPT
# log and reject everything else
#iptables -A ZIMBRA-FIREWALL -j LOG -m limit -limit 10/m -log-prefix “DROP ON INPUT: ” -log-tcp-options -log-ip-options -log-level INFO
iptables -A ZIMBRA-FIREWALL -j DROP
# save configuraton and restart iptables
#/etc/rc.d/init.d/iptables save
#/etc/rc.d/init.d/iptables 
## save on ubuntu: apt-get install iptables-persistent
## save on cetnos 7: 
cat > /etc/systemd/system/iptables-restore.service <<EOF
[Unit]
Description=IPv4 iptables firewall rules
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/iptables-restore /etc/iptables/rules.v4
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF