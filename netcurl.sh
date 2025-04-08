echo "Testing connectivity to various IP addresses using curl"
echo "--------------------------------------------------"
echo "10.100.0.4"
curl --max-time 5 10.100.0.4
echo "10.110.0.4"
curl --max-time 5 10.110.0.4
echo "10.120.0.4"
curl --max-time 5 10.120.0.4
echo "172.16.100.4"
curl --max-time 5 172.16.100.4
echo "172.16.3.4"
curl --max-time 5 172.16.3.4
echo "172.16.4.4"
curl --max-time 5 172.16.4.4
echo "172.16.5.4"
curl --max-time 5 172.16.5.4
echo "172.16.6.4"
curl --max-time 5 172.16.6.4
echo "172.16.2.4"
curl --max-time 5 172.16.2.4
echo "172.16.1.4"
curl --max-time 5 172.16.1.4