################################################################################
##########This is a Script File to set the Routing tables and the NIC###########
##########Created BY: Vishav Singh, Rizwan Ahmed                     ###########
##########Date: 1-FEB-2016                                           ###########
##########Course No: COMP-8006                                       ###########
################################################################################

# Network Interface Details For Firewall
Firewall_NIC="eno01"
Firewall_Internal_NIC="enp3s2"

Firewall_HOST_IP="192.168.10.13"
Internal_HOST_IP="192.168.10.2"

if [ "$1" = "firewall" ]
 then
   sudo ifconfig $Firewall_Internal_NIC $Firewall_HOST_IP up
   echo "1" >/proc/sys/net/ipv4/ip_forward

   #New Routing rule for the current network
   route add -net 192.168.0.0 netmask 255.255.255.0 gw 192.168.0.8

   #Routing rule for the the new internal network
   route add -net 192.168.10.0/24 gw $Firewall_HOST_IP
  #statements
fi

if ["$1" = "internal"]
 then
   sudo ifconfig $Internal_NIC $Internal_HOST_IP up
  #statements
fi
