#! /bin/bash
echo "Testing connectivity to various IP addresses using ping"
echo "--------------------------------------------------"
echo "Pinging 10.110.0.4"
ping -O -c 5 10.110.0.4
echo "Pinging 10.120.0.4"
ping -O -c 5 10.120.0.4
echo "Pinging 172.16.100.4"
ping -O -c 5 172.16.100.4
echo "Pinging 172.16.3.4"
ping -O -c 5 172.16.3.4
echo "Pinging 172.16.4.4"
ping -O -c 5 172.16.4.4
echo "Pinging 172.16.5.4"
ping -O -c 5 172.16.5.4
echo "Pinging 172.16.6.4"
ping -O -c 5 172.16.6.4
echo "Pinging 172.16.2.4"
ping -O -c 5 172.16.2.4
echo "Pinging 172.16.1.4"
ping -O -c 5 172.16.1.4