#!/bin/bash

#user configurable section
IPT="iptables"
<<<<<<< HEAD
#firewall interface
FIREWALL_IF="eno1"
#host interface
HOST_IF="enp3s2"
IP_HOST="192.168.10.100"
IP_FIREWALL"192.168.10.13"

=======
ETH0="eth0"
ETH1="eth1"
>>>>>>> 0f061320698946596e6c50b8a50391f0358f0c90
LB_INTERFACE="lo"
LOOPBACK_IP="127.0.0.1"

#allowed ports
ALLOW_TCP="22"
ALLOW_UDP="53"
ALLOW_ICMP="8"

#deny ports
DENY_TCP="0"
DENY_UDP="0"

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

<<<<<<< HEAD
#firewall implementation section

# set default policy to DROP
$IPT --policy INPUT DROP
$IPT --policy OUTPUT DROP
$IPT --policy FORWARD DROP

#inbound/outbound TCP packets on allowed ports


#inbound/outbound UDP packets on allowed ports

#inbound/outbound ICMP packets based on type numbers

#drop all packets destined for the firewall host from outside

#do not accept any packets with a source address from outside matching
#your internal network
=======
#firewall implementation section
>>>>>>> 0f061320698946596e6c50b8a50391f0358f0c90
