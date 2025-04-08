#!/bin/sh
# IPtables rules:
# Allow traffic from the VM network to the Internet
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -s 172.16.100.0/24 -j ACCEPT

# Block traffic from private IP ranges to other private IP ranges, except for the VM network
iptables -A FORWARD -s 10.0.0.0/8 -d 10.0.0.0/8 -j DROP
iptables -A FORWARD -s 10.0.0.0/8 -d 172.16.0.0/12 -j DROP
iptables -A FORWARD -s 10.0.0.0/8 -d 192.168.0.0/16 -j DROP
iptables -A FORWARD -s 172.16.0.0/12 -d 10.0.0.0/8 -j DROP
iptables -A FORWARD -s 172.16.0.0/12 -d 172.16.0.0/12 -j DROP
iptables -A FORWARD -s 172.16.0.0/12 -d 192.168.0.0/16 -j DROP
iptables -A FORWARD -s 192.168.0.0/16 -d 10.0.0.0/8 -j DROP
iptables -A FORWARD -s 192.168.0.0/16 -d 172.16.0.0/12 -j DROP
iptables -A FORWARD -s 192.168.0.0/16 -d 192.168.0.0/16 -j DROP

# Exempt access to the VM network
iptables -A FORWARD -s 10.0.0.0/8 -d 172.16.100.0/24 -j ACCEPT
iptables -A FORWARD -s 172.16.0.0/12 -d 172.16.100.0/24 -j ACCEPT
iptables -A FORWARD -s 192.168.0.0/16 -d 172.16.100.0/24 -j ACCEPT

# Allow all traffic destined to the Internet
iptables -A FORWARD -d 0.0.0.0/0 -j ACCEPT

# Block the rest of the traffic
iptables -A FORWARD -j DROP

# Save to IPTables file for persistence on reboot
iptables-save > /etc/iptables/rules.v4