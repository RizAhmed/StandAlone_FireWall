#!/bin/bash

#user configurable section
ALLOW_TCP="20,21,22,53,68,80,443"
ALLOW_UDP="20,21,22,53,68"
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