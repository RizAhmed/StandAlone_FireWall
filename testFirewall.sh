#!/bin/bash

#user configurable section
ALLOW_TCP="20,21,22,53,68,80,443"
ALLOW_UDP="20,21,22,53,68"
ALLOW_ICMP="0,3,8"
EXTERNAL_IP="localhost"
EXTERNAL_IFACE="eno1"

#start of test script
echo "Firewall test starting..."
echo "-------------------------"
echo "NMAP test"
echo "The open ports should be: $ALLOW_TCP"
nmap -v $EXTERNAL_IP
echo "-------------------------"
echo ""
echo "-------------------------"
echo "TCP test"
echo ""
array=$(echo $ALLOW_TCP | tr "," "\n")
for port in $array
do
	echo ""
	echo "-----------------------------------------"
	echo "Testing TCP packets allowed on port $port"
	echo "Expected result: 0% packet loss"
	echo ""
	hping3 $EXTERNAL_IP -c 3 -k -S -p $port
done
echo "---------------------------------------\n"
echo "---------------------------------------"
echo "UDP test"
echo ""
array=$(echo $ALLOW_UDP | tr "," "\n")
for port in $array
do
	echo ""
	echo "-----------------------------------------"
	echo "Testing UDP packets allowed on port $port"
	echo "Expected result: 0% packet loss"
	echo ""
	hping3 $EXTERNAL_IP -c 3 -k -p $port
done
echo "---------------------------------------\n"
echo "---------------------------------------"
echo "ICMP test"
echo ""
array=$(echo $ALLOW_ICMP | tr "," "\n")
for type in $array
do
	echo ""
	echo "-----------------------------------------"
	echo "Testing ICMP packet type $type"
	echo "Expected result: 0% packet loss"
	echo ""
	hping3 $EXTERNAL_IP -c 2 -k --icmp --icmptype $type
done
echo "---------------------------------------\n"
echo "---------------------------------------"
echo "Fragment test"
echo "Expected result: 0% packet loss"
echo ""
hping3 $EXTERNAL_IP -c 1 -f -p 80
echo "---------------------------------------"
echo "Testing SYN packets on high port"
echo "Expected result: 100% packet loss"
echo ""
hping3 $EXTERNAL_IP -c 1 -S -p 45999
echo "---------------------------------------"
echo "Telnet test"
echo "Expected result: 100% packet loss"
echo ""
hping3 $EXTERNAL_IP -c 1 -p 23
echo "---------------------------------------"
echo "---------------------------------------"
echo "Blocked ports 32768-32775 test"
echo "Expected result: 100% packet loss"
echo ""
hping3 $EXTERNAL_IP -c 8 -S -p ++32768
hping3 $EXTERNAL_IP -2 -c 8 -p ++32768
echo "---------------------------------------"
echo "Blocked ports 137-139"
echo "Expected result: 100% packet loss"
echo ""
hping3 $EXTERNAL_IP -c 3 -p ++137
hping3 $EXTERNAL_IP -2 -c 3 -p ++137
echo "---------------------------------------"
echo "Blocked TCP port 111 and 515 test"
echo "Expected result: 100% packet loss"
hping3 $EXTERNAL_IP -c 1 -S -p 111
echo ""
hping3 $EXTERNAL_IP -c 1 -S -p 515
echo "---------------------------------------"
echo ""
echo "Firewall test complete"