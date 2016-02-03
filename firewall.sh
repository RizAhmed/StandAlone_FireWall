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
ALLOW_TCP="22"
ALLOW_UDP="53"
#deny ports
DENY_TCP="0"
DENY_UDP="0"

#allowed ICMP types
ALLOW_ICMP=("2" "8")

#ports
PRIVPORTS="0:1023"
UNPRIVPORTS="1024:65535"
TELNET_PORT="23"

#Valid TCP UDP ports
VALID_TCP_PORTS="80,443,53,22,21"
VALID_UDP_PORTS="80.443,53,22,21"

#INVALID TCP UDP Ports
INVALID_TCP_PORTS="111,115,32768:32755,137:139"
INVALID_UDP_PORTS="32768:32755,137:139"
#TCP Flags
TCP_FLAGS = "SYN"

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
$IPT -A FORWARD -p TCP -m multiport --sport $VALID_TCP_PORTS -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A FORWARD -p TCP -m multiport --dport $VALID_TCP_PORTS -m state --state NEW,ESTABLISHED -j ACCEPT

#inbound/outbound UDP packets on allowed ports
$IPT -A FORWARD -p UDP -m multiport --sport $VALID_UDP_PORTS -j ACCEPT
$IPT -A FORWARD -p UDP -m multiport --dport $VALID_UDP_PORTS -j ACCEPT
#inbound/outbound ICMP packets based on type numbers

#Reject Packets that have syn bit set and are destined for High ports
$IPT -A FORWARD -p tcp --tcp-flags $TCP_FLAGS --dport $UNPRIVPORTS -j DROP

#Accept Fragments (However, we dont need to create these rules)
$IPT -A FORWARD -p tcp --fragment -j ACCEPT
$IPT -A FORWARD -p udp --fragment -j ACCEPT


#Rules for NEW and Established Traffic
echo "Configuring TCP Connections..."
$IPT -N tcp_chain
$IPT -A tcp_chain -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A tcp_chain -p tcp -i $HOST_IF -m multiport --sports $UNPRIVPORTS -m multiport --dports $VALID_TCP_PORTS -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A tcp_chain -p tcp -i $FIREWALL_IF -m multiport --sports $VALID_TCP_PORTS -m multiport --dports $UNPRIVPORTS -m state --state ESTABLISHED -j ACCEPT

$IPT -A tcp_chain -p tcp -i $FIREWALL_IF -m multiport --sports  $UNPRIVPORTS -m multiport --dports $VALID_TCP_PORTS -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A tcp_chain -p tcp -i $HOST_IF -m multiport --sports  $VALID_TCP_PORTS -m multiport --dports $UNPRIVPORTS --state ESTABLISHED -j ACCEPT

$IPT -A FORWARD -p tcp -j tcp_chain
echo "TCP Chain Created..."


$IPT -N udp_chain
$IPT -A udp_chain -p udp -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A FORWARD -p tcp -j udp_chain


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
$IPT -A FORWARD -p tcp -i $FIREWALL_IF -m multiport --dports $INVALID_TCP_PORTS -j DROP
$IPT -A FORWARD -p udp -i $FIREWALL_IF -m multiport --dports $INVALID_UDP_PORTS -j DROP
echo "Rules for Defined TCP and UDP ports configured successfully..."
