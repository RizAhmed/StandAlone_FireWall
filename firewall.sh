#!/bin/bash

#user configurable section
IPT="iptables"
#firewall interface
FIREWALL_IF="eno1"
#host interface
HOST_IF="enp3s2"
IP_HOST="192.168.10.12"
IP_FIREWALL="192.168.10.13"
IP_EXT_FIREWALL="192.168.0.13"

WAN_ADDR="0.0.0.0/0"
BROADCAST_SRC_IP="0.0.0.0"
BROADCAST_DEST_IPT="255.255.255.255"
DHCP_SERVERS="192.168.0.100"
DNS_SERVERS="8.8.8.8"

LB_INTERFACE="lo"
LOOPBACK_IP="127.0.0.1"

#allowed ports
#ALLOW_TCP="22"
#ALLOW_UDP="53"
#deny ports
#DENY_TCP="0"
#DENY_UDP="0"

#allowed ICMP types
ALLOW_ICMP=("3" "0" "8")

#ports
PRIVPORTS="0:1023"
UNPRIVPORTS="1024:65535"
TELNET_PORT="23"

#Valid TCP UDP ports
VALID_TCP_PORTS="80,443,53,22,21"
VALID_UDP_PORTS="80,443,53,22,21"

#INVALID TCP UDP Ports
INVALID_TCP_PORTS="32768:32775,137:139,111,115"
INVALID_UDP_PORTS="32768:32775,137:139"
#TCP Flags
TCP_FLAGS="SYN"


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

  $IPT -X
  $IPT -t nat -X
  $IPT -t mangle -X

  $IPT -F
  $IPT -t nat -F
  $IPT -t mangle -F

  echo "Firewall rules reset!"
  exit 0
fi

#firewall implementation section

# set default policy to DROP
$IPT --policy INPUT DROP
$IPT --policy OUTPUT DROP
$IPT --policy FORWARD DROP

#DHCP Traffic

#DROP packets

#drop all packets destined for the firewall host from outside
$IPT -A FORWARD -i $FIREWALL_IF -d $IP_EXT_FIREWALL -j DROP

#do not accept any packets with a source address from outside matching
#your internal network
$IPT -A FORWARD -s 192.168.10.0/24 -i $FIREWALL_IF -j DROP

#ACCEPT packets
#inbound/outbound TCP packets on allowed ports
$IPT -A FORWARD -p TCP -m multiport --sport $VALID_TCP_PORTS -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A FORWARD -p TCP -m multiport --dport $VALID_TCP_PORTS -m state --state NEW,ESTABLISHED -j ACCEPT

#inbound/outbound UDP packets on allowed ports
$IPT -A FORWARD -p UDP -m multiport --sport $VALID_UDP_PORTS -j ACCEPT
$IPT -A FORWARD -p UDP -m multiport --dport $VALID_UDP_PORTS -j ACCEPT
#inbound/outbound ICMP packets based on type numbers

$IPT -N ICMP_TRAFFIC

for i in "${ALLOW_ICMP[@]}"
do
  :
  $IPT -A FORWARD -p ICMP -i $FIREWALL_IF -o $HOST_IF --icmp-type $i -m state --state NEW,ESTABLISHED -j ACCEPT
  $IPT -A FORWARD -p ICMP -i $HOST_IF -o $FIREWALL_IF --icmp-type $i -m state --state NEW,ESTABLISHED -j ACCEPT
  echo "allowed icmp service $i"
done

$IPT -A FORWARD -p icmp -j ICMP_TRAFFIC
#Reject Packets that have syn bit set and are destined for High ports
$IPT -A FORWARD -p tcp --syn --dport $UNPRIVPORTS -j DROP

#Accept Fragments (However, we dont need to create these rules)
$IPT -A FORWARD -p tcp --fragment -j ACCEPT
$IPT -A FORWARD -p udp --fragment -j ACCEPT


#Rules for NEW and Established Traffic

$IPT -A FORWARD -p tcp -m multiport --sports $UNPRIVPORTS  -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A FORWARD -p tcp -m multiport --dports $VALID_TCP_PORTS -m state --state NEW,ESTABLISHED -j ACCEPT

$IPT -A FORWARD -p tcp -m multiport --sports $VALID_TCP_PORTS -m state --state ESTABLISHED -j ACCEPT
$IPT -A FORWARD -p tcp -m multiport --dports $UNPRIVPORTS -m state --state ESTABLISHED -j ACCEPT

$IPT -A FORWARD -p udp -m multiport --sports $UNPRIVPORTS  -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A FORWARD -p udp -m multiport --dports $VALID_TCP_PORTS -m state --state NEW,ESTABLISHED -j ACCEPT

$IPT -A FORWARD -p udp -m multiport --sports $VALID_TCP_PORTS -m state --state ESTABLISHED -j ACCEPT
$IPT -A FORWARD -p udp -m multiport --dports $UNPRIVPORTS -m state --state ESTABLISHED -j ACCEPT

#Rule to Block SYN FIN Packets
echo "Configuring to Block SYN and FIN Packets..."
$IPT -A FORWARD -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
echo "Successfully configured SYN FIN Rule..."

#Rule to Block Telnet Packets
echo "Configuring Telnet Rule..."
$IPT -A FORWARD -p tcp --sport 23 -j DROP
$IPT -A FORWARD -p tcp --dport 23 -j DROP
echo "Successfully Configured Telnet Rules..."

echo "Blocking Defined TCP and UDP Ports..."
#Blocking all external Traffic directed to INVALID_UDP_PORTS/INVALID_TCP_PORTS
$IPT -A FORWARD -p tcp -i $FIREWALL_IF -m multiport --dports $INVALID_UDP_PORTS -j DROP
$IPT -A FORWARD -p udp -i $FIREWALL_IF -m multiport --dports $INVALID_UDP_PORTS -j DROP
echo "Rules for Defined TCP and UDP ports configured successfully..."

# prerouting
# allow ssh forwarding
$IPT -t nat -A PREROUTING -i $FIREWALL_IF -p tcp -d $IP_EXT_FIREWALL --dport 22 -j DNAT --to-destination $IP_HOST:22
$IPT -t nat -A POSTROUTING -o $HOST_IF -p tcp --dport 22 -j SNAT --to-source $IP_FIREWALL

# allow ftp forwarding
$IPT -t nat -A PREROUTING -i $FIREWALL_IF -p tcp -d $IP_EXT_FIREWALL --dport 21 -j DNAT --to-destination $IP_HOST:21
$IPT -t nat -A POSTROUTING -o $HOST_IF -p tcp --dport 21 -j SNAT --to-source $IP_FIREWALL

# FTP, SSH minimum delay, ftp maximum throughput
$IPT -A PREROUTING -t mangle -p tcp --sport ssh -j TOS --set-tos Minimize-Delay
$IPT -A PREROUTING -t mangle -p tcp --sport ftp -j TOS --set-tos Minimize-Delay
$IPT -A PREROUTING -t mangle -p tcp --sport ftp-data -j TOS --set-tos Maximize-Throughput
