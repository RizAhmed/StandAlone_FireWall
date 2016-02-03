#!/bin/bash

#user configurable section
IPT="iptables"
#firewall interface
FIREWALL_IF="eno1"
#host interface
HOST_IF="enp3s2"
IP_HOST="192.168.10.100"
IP_FIREWALL="192.168.10.13"

LB_INTERFACE="lo"
LOOPBACK_IP="127.0.0.1"

#allowed ports
ALLOW_TCP="20,21,22,53,68,80,443"
ALLOW_UDP="20,21,22,53,68"

#allowed ICMP types
ALLOW_ICMP=("0" "3" "8")

#shortcut to resetting the default policy
if [ "$1" = "reset" ]
then
  $IPT --policy INPUT ACCEPT
  $IPT --policy OUTPUT ACCEPT
  $IPT --policy FORWARD ACCEPT
  $IPT -t nat --policy PREROUTING ACCEPT
  $IPT -t nat --policy OUTPUT ACCEPT
  $IPT -t nat --policy POSTROUTING ACCEPT
  $IPT -t mangle --policy PREROUTING ACCEPT
  $IPT -t mangle --policy OUTPUT ACCEPT

  $IPT --flush
  $IPT -t nat --flush
  $IPT -t mangle --flush

  $IPT -X
  $IPT -t nat -X
  $IPT -t mangle -X

  echo "Firewall rules reset!"
  exit 0
fi

#firewall implementation section

# set default policy to DROP
$IPT --policy INPUT DROP
$IPT --policy OUTPUT DROP
$IPT --policy FORWARD DROP

#DROP packets

#drop all packets destined for the firewall host from outside
$IPT -A INPUT -i $FIREWALL_IF -d $IP_FIREWALL -j DROP

#do not accept any packets with a source address from outside matching
#your internal network
$IPT -A FORWARD -s 192.168.10.0/24 -i $FIREWALL_IF -j DROP

#ACCEPT packets
#inbound/outbound TCP packets on allowed ports
$IPT -A FORWARD -p TCP -m multiport --sport $ALLOW_TCP -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A FORWARD -p TCP -m multiport --dport $ALLOW_TCP -m state --state NEW,ESTABLISHED -j ACCEPT

#inbound/outbound UDP packets on allowed ports
$IPT -A FORWARD -p UDP -m multiport --sport $ALLOW_UDP -j ACCEPT
$IPT -A FORWARD -p UDP -m multiport --dport $ALLOW_UDP -j ACCEPT
#inbound/outbound ICMP packets based on type numbers
for i in "${ALLOW_ICMP[@]}"
do
  :
  $IPT -A FORWARD -p ICMP -i $FIREWALL_IF -o $HOST_IF --icmp-type $i -j ACCEPT
  $IPT -A FORWARD -p ICMP -i $HOST_IF -o $FIREWALL_IF --icmp-type $i -j ACCEPT
  echo "allowed icmp service $i"
done
