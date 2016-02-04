# StandAlone_FireWall
This is the second assignment for COMP-8006
To set up the firewall, first set the network interface names and IP addresses of the machine that will run the firewall and one of the internal hosts in the “hosts.sh” file.

Both machines, firewall and internal host, must have this script installed. 

For the machine running the firewall, run the hosts script using “firewall” as the argument to set up the routing table and add MASQUERADE. As for the internal host, have the script run with “internal” as the argument to set up the host’s routing table.

To run the firewall: “sh firewall.sh” 
To flush all rules and reset default policy to ACCEPT: “sh firewall.sh reset”

To run the test script: “sh testFirewall.sh”
