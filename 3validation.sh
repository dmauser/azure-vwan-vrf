#!/bin/bash
# Parameters 
rg=lab-vwan-3p #set resource group

#### Validate connectivity between VNETs and Branches

# 1) Test connectivity between VMs (they can be accessible via SSH over Public IP or Serial Console)

#List of VMs Public IP for SSH access
az network public-ip list -g $rg --query "[].{name:name,ip:ipAddress}" -o table 

#List of VMs Private IPs
for nicname in `az network nic list -g $rg --query [].name -o tsv`
do 
echo -e $nicname private IP:
az network nic show -g $rg --name $nicname --query "ipConfigurations[].privateIPAddress" --output tsv
echo -e 
done

# For connectivity test you can also use curl or traceroute. For example from BranchVM1 or BranchVM2 run:

curl -s https://raw.githubusercontent.com/dmauser/azure-vwan-vrf/refs/heads/main/scripts/netcurl.sh | bash

# 2) Dump VMs route tables:
for nicname in `az network nic list -g $rg --query [].name -o tsv`
do 
echo -e $nicname effective routes:
az network nic show-effective-route-table -g $rg --name $nicname --output table | grep -E "User|VirtualNetworkGateway"
echo -e 
done

# 3) Dump all vHUBs route tables.
for vhubname in `az network vhub list -g $rg --query "[].id" -o tsv | rev | cut -d'/' -f1 | rev`
do
  for routetable in `az network vhub route-table list --vhub-name $vhubname -g $rg --query "[].id" -o tsv`
   do
   if [ "$(echo $routetable | rev | cut -d'/' -f1 | rev)" != "noneRouteTable" ]; then
     echo -e vHUB: $vhubname 
     echo -e Effective route table: $(echo $routetable | rev | cut -d'/' -f1 | rev)   
     az network vhub get-effective-routes -g $rg -n $vhubname \
     --resource-type RouteTable \
     --resource-id $routetable \
     --query "value[].{addressPrefixes:addressPrefixes[0], asPath:asPath, nextHopType:nextHopType}" \
     --output table
     echo
    fi
   done
done

# Dump the Branches VPN Gateway routes:
vpngws=$(az network vnet-gateway list -g $rg --query [].name -o tsv) 
array=($vpngws)
for vpngw in "${array[@]}"
 do 
 echo "*** $vpngw BGP peer status ***"
 az network vnet-gateway list-bgp-peer-status -g $rg -n $vpngw -o table
 echo "*** $vpngw BGP learned routes ***"
 az network vnet-gateway list-learned-routes -g $rg -n $vpngw -o table
 echo
done

# VPN Gateways advertised routes per BGP peer.
vpngws=$(az network vnet-gateway list -g $rg --query [].name -o tsv) 
array=($vpngws)
for vpngw in "${array[@]}"
 do 
  ips=$(az network vnet-gateway list-bgp-peer-status -g $rg -n $vpngw --query 'value[].{ip:neighbor}' -o tsv)
  array2=($ips)
   for ip in "${array2[@]}"
   do
   echo *** $vpngw advertised routes to peer $ip ***
   az network vnet-gateway list-advertised-routes -g $rg -n $vpngw -o table --peer $ip
  done
 echo
done