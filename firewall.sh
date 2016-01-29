#!/bin/bash

#user configurable section
IPT="iptables"
ETH0="eth0"
ETH1="eth1"
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

#firewall implementation section