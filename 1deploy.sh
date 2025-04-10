#!/bin/bash

# Parameters (make changes based on your requirements)
region1=westus3
region2=westus3
region3=westus3
region4=westus3

rg=lab-vwan-3p 
vwanname=vwan-3p
hub1name=hub1
hub2name=hub2
hub3name=hub3
hub4name=hub4
username=azureuser
password="Msft123Msft123"
vmsize=Standard_DS1_v2

#Variables
mypip=$(curl -4 ifconfig.io -s)

# Pre-Requisites
# Check if virtual wan extension is installed if not install it
if ! az extension list | grep -q virtual-wan; then
    echo "virtual-wan extension is not installed, installing it now..."
    az extension add --name virtual-wan --only-show-errors
fi

# Adding script starting time and finish time
start=`date +%s`
echo "Script started at $(date)"

# create rg
az group create -n $rg -l $region1 --output none

echo Creating vwan and vhubs...
# create virtual wan
az network vwan create -g $rg -n $vwanname --branch-to-branch-traffic true --location $region1 --type Standard --output none
az network vhub create -g $rg --name $hub1name --address-prefix 192.168.1.0/24 --vwan $vwanname --location $region1 --sku Standard --no-wait
az network vhub create -g $rg --name $hub2name --address-prefix 192.168.2.0/24 --vwan $vwanname --location $region2 --sku Standard --no-wait
az network vhub create -g $rg --name $hub3name --address-prefix 192.168.3.0/24 --vwan $vwanname --location $region3 --sku Standard --no-wait
az network vhub create -g $rg --name $hub4name --address-prefix 192.168.4.0/24 --vwan $vwanname --location $region3 --sku Standard --no-wait

echo Creating branches vNETs...
# create location1 branch virtual network
az network vnet create --address-prefixes 10.110.0.0/16 -n branch1 -g $rg -l $region1 --subnet-name main --subnet-prefixes 10.110.0.0/24 --output none

# create location2 branch virtual network
az network vnet create --address-prefixes 10.120.0.0/16 -n branch2 -g $rg -l $region2 --subnet-name main --subnet-prefixes 10.120.0.0/24 --output none

echo Creating spoke VNETs...
# create spokes virtual network
# Hub1
az network vnet create --address-prefixes 172.16.1.0/24 -n sd-wan-prod -g $rg -l $region1 --subnet-name main --subnet-prefixes 172.16.1.0/27 --output none
# Hub2
az network vnet create --address-prefixes 172.16.2.0/24 -n sd-wan-dev -g $rg -l $region2 --subnet-name main --subnet-prefixes 172.16.2.0/27 --output none
#Hub3
az network vnet create --address-prefixes 172.16.3.0/24 -n hub3-fw-vnet -g $rg -l $region3 --subnet-name main --subnet-prefixes 172.16.3.0/27 --output none
az network vnet create --address-prefixes 172.16.4.0/24 -n hub3-spoke-vnet -g $rg -l $region3 --subnet-name main --subnet-prefixes 172.16.4.0/27 --output none
# Region3
az network vnet create --address-prefixes 172.16.5.0/24 -n hub4-fw-vnet -g $rg -l $region4 --subnet-name main --subnet-prefixes 172.16.5.0/27 --output none
az network vnet create --address-prefixes 172.16.6.0/24 -n hub4-spoke-vnet -g $rg -l $region4 --subnet-name main --subnet-prefixes 172.16.6.0/27 --output none

echo Creating NSGs...
#Update NSGs:
az network nsg create --resource-group $rg --name default-nsg-$region1 --location $region1 -o none
az network nsg create --resource-group $rg --name default-nsg-$region2 --location $region2 -o none
az network nsg create --resource-group $rg --name default-nsg-$region3 --location $region3 -o none
az network nsg create --resource-group $rg --name default-nsg-$region4 --location $region4 -o none
# Add my home public IP to NSG for SSH acess
az network nsg rule create -g $rg --nsg-name default-nsg-$region1 -n 'default-allow-ssh' --direction Inbound --priority 100 --source-address-prefixes $mypip --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 22 --access Allow --protocol Tcp --description "Allow inbound SSH" --output none
az network nsg rule create -g $rg --nsg-name default-nsg-$region2 -n 'default-allow-ssh' --direction Inbound --priority 100 --source-address-prefixes $mypip --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 22 --access Allow --protocol Tcp --description "Allow inbound SSH" --output none
az network nsg rule create -g $rg --nsg-name default-nsg-$region3 -n 'default-allow-ssh' --direction Inbound --priority 100 --source-address-prefixes $mypip --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 22 --access Allow --protocol Tcp --description "Allow inbound SSH" --output none
az network nsg rule create -g $rg --nsg-name default-nsg-$region4 -n 'default-allow-ssh' --direction Inbound --priority 100 --source-address-prefixes $mypip --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 22 --access Allow --protocol Tcp --description "Allow inbound SSH" --output none

# Add VNET to Any
az network nsg rule create -g $rg --nsg-name default-nsg-$region1 -n 'vnet-to-any' --direction Inbound --priority 120 --source-address-prefixes VirtualNetwork --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges '*' --access Allow --protocol '*' --description "Vnet to Any" --output none
az network nsg rule create -g $rg --nsg-name default-nsg-$region2 -n 'vnet-to-any' --direction Inbound --priority 120 --source-address-prefixes VirtualNetwork --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges '*' --access Allow --protocol '*' --description "Vnet to Any" --output none
az network nsg rule create -g $rg --nsg-name default-nsg-$region3 -n 'vnet-to-any' --direction Inbound --priority 120 --source-address-prefixes VirtualNetwork --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges '*' --access Allow --protocol '*' --description "Vnet to Any" --output none
az network nsg rule create -g $rg --nsg-name default-nsg-$region4 -n 'vnet-to-any' --direction Inbound --priority 120 --source-address-prefixes VirtualNetwork --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges '*' --access Allow --protocol '*' --description "Vnet to Any" --output none

# Associated NSG to the VNET subnets (Spokes and Branches)
az network vnet subnet update --id $(az network vnet list -g $rg --query '[?location==`'$region1'`].{id:subnets[0].id}' -o tsv) --network-security-group default-nsg-$region1 -o none
az network vnet subnet update --id $(az network vnet list -g $rg --query '[?location==`'$region2'`].{id:subnets[0].id}' -o tsv) --network-security-group default-nsg-$region2 -o none
az network vnet subnet update --id $(az network vnet list -g $rg --query '[?location==`'$region3'`].{id:subnets[0].id}' -o tsv) --network-security-group default-nsg-$region3 -o none
az network vnet subnet update --id $(az network vnet list -g $rg --query '[?location==`'$region4'`].{id:subnets[0].id}' -o tsv) --network-security-group default-nsg-$region4 -o none

echo Creating VMs in both branches...
# create a VM in each branch spoke
az vm create -n branch1VM  -g $rg --image Ubuntu2204 --size $vmsize -l $region1 --subnet main --vnet-name branch1 --admin-username $username --admin-password $password --nsg "" --public-ip-address "" --no-wait
az vm create -n branch2VM  -g $rg --image Ubuntu2204 --size $vmsize -l $region2 --subnet main --vnet-name branch2 --admin-username $username --admin-password $password --nsg "" --public-ip-address "" --no-wait

echo Creating VPN Gateways in both branches...
# create pips for VPN GW's in each branch
az network public-ip create -n branch1-vpngw-pip -g $rg --location $region1 --output none
az network public-ip create -n branch2-vpngw-pip -g $rg --location $region2 --output none

# Create Subnets and VPN gateways
az network vnet subnet create -g $rg --vnet-name branch1 -n GatewaySubnet --address-prefixes 10.110.100.0/26 --output none
az network vnet subnet create -g $rg --vnet-name branch2 -n GatewaySubnet --address-prefixes 10.120.100.0/26 --output none

az network vnet-gateway create -n branch1-vpngw --public-ip-addresses branch1-vpngw-pip -g $rg --vnet branch1 --asn 65510 --gateway-type Vpn -l $region1 --sku VpnGw1 --vpn-gateway-generation Generation1 --no-wait 
az network vnet-gateway create -n branch2-vpngw --public-ip-addresses branch2-vpngw-pip -g $rg --vnet branch2 --asn 65509 --gateway-type Vpn -l $region2 --sku VpnGw1 --vpn-gateway-generation Generation1 --no-wait

echo Creating Spoke VMs...
# Create VMs without Public IPs in the spokes
az vm create -n sd-wan-prod -g $rg --image Ubuntu2204 --size $vmsize -l $region1 --subnet main --vnet-name sd-wan-prod --admin-username $username --admin-password $password --nsg "" --public-ip-address "" --no-wait
az vm create -n sd-wan-dev -g $rg --image Ubuntu2204 --size $vmsize -l $region2 --subnet main --vnet-name sd-wan-dev --admin-username $username --admin-password $password --nsg "" --public-ip-address "" --no-wait
az vm create -n hub3-spoke -g $rg --image Ubuntu2204 --size $vmsize -l $region3 --subnet main --vnet-name hub3-spoke-vnet --admin-username $username --admin-password $password --nsg "" --public-ip-address "" --no-wait
az vm create -n hub4-spoke -g $rg --image Ubuntu2204 --size $vmsize -l $region4 --subnet main --vnet-name hub4-spoke-vnet --admin-username $username --admin-password $password --nsg "" --public-ip-address "" --no-wait

# Create NVAs on each transit vnet
az vm create -n hub3-fw-nva -g $rg --image Ubuntu2204 --public-ip-sku Standard --size $vmsize -l $region3 --subnet main --vnet-name hub3-fw-vnet --admin-username $username --admin-password $password --nsg "" --no-wait
az vm create -n hub4-fw-nva -g $rg --image Ubuntu2204 --public-ip-sku Standard --size $vmsize -l $region4 --subnet main --vnet-name hub4-fw-vnet --admin-username $username --admin-password $password --nsg "" --no-wait

echo "Creating DMZ vnet..."
# Create DMZ vnet
az network vnet create --address-prefixes 172.16.100.0/24 -n dmz-vnet -g $rg -l $region1 --subnet-name main --subnet-prefixes 172.16.100.0/27 --output none
echo "Create Ubuntu VM in DMZ vnet..."
# Create a VM in the DMZ vnet
az vm create -n dmz-nva -g $rg --image Ubuntu2204 --public-ip-sku Standard --size $vmsize -l $region1 --subnet main --vnet-name dmz-vnet --admin-username $username --admin-password $password --nsg "" --no-wait

# Build a loop script to wait for VMs to be created
echo "Waiting for all VMs to be created..."
vmList=$(az vm list -g $rg --query "[].name" -o tsv)

for vm in $vmList; do
    echo "Waiting for VM $vm to be created..."
    az vm wait -g $rg -n $vm --created
    echo "VM $vm has been created."
done
#Enable boot diagnostics for all VMs in the resource group (Serial console)
#Enable boot diagnostics
az vm boot-diagnostics enable --ids $(az vm list -g $rg --query '[].id' -o tsv) -o none
### Install tools for networking connectivity validation such as traceroute, tcptraceroute, iperf and others (check link below for more details) 
nettoolsuri="https://raw.githubusercontent.com/dmauser/azure-vm-net-tools/main/script/nettools.sh"
for vm in `az vm list -g $rg --query "[?contains(storageProfile.imageReference.publisher,'Canonical')].name" -o tsv`
do
 az vm extension set \
 --resource-group $rg \
 --vm-name $vm \
 --name customScript \
 --publisher Microsoft.Azure.Extensions \
 --protected-settings "{\"fileUris\": [\"$nettoolsuri\"],\"commandToExecute\": \"./nettools.sh\"}" \
 --no-wait
done

echo Checking Hub1 provisioning status...
# Checking Hub1 provisioning and routing state 
prState=''
rtState=''
while [[ $prState != 'Succeeded' ]];
do
    prState=$(az network vhub show -g $rg -n $hub1name --query 'provisioningState' -o tsv)
    echo "$hub1name provisioningState="$prState
    sleep 5
done

while [[ $rtState != 'Provisioned' ]];
do
    rtState=$(az network vhub show -g $rg -n $hub1name --query 'routingState' -o tsv)
    echo "$hub1name routingState="$rtState
    sleep 5
done

echo Creating Hub1 vNET connections
# create spoke to Vwan connections to hub1
az network vhub connection create -n sd-wan-prodconn --remote-vnet sd-wan-prod -g $rg --vhub-name $hub1name --no-wait
prState=''
while [[ $prState != 'Succeeded' ]];
do
    prState=$(az network vhub connection show -n sd-wan-prodconn --vhub-name $hub1name -g $rg  --query 'provisioningState' -o tsv)
    echo "vnet connection sd-wan-prodconn provisioningState="$prState
    sleep 5
done
# create spoke to Vwan connections to hub1
az network vhub connection create -n dmz-vnetconn --remote-vnet dmz-vnet -g $rg --vhub-name $hub1name --no-wait
prState=''
while [[ $prState != 'Succeeded' ]];
do
    prState=$(az network vhub connection show -n dmz-vnetconn --vhub-name $hub1name -g $rg  --query 'provisioningState' -o tsv)
    echo "vnet connection dmz-vnetconn provisioningState="$prState
    sleep 5
done

echo Creating Hub1 VPN Gateway...
# Creating VPN gateways in each Hub1
az network vpn-gateway create -n $hub1name-vpngw -g $rg --location $region1 --vhub $hub1name --no-wait 

echo Checking Hub2 provisioning status...
# Checking Hub2 provisioning and routing state 
prState=''
rtState=''
while [[ $prState != 'Succeeded' ]];
do
    prState=$(az network vhub show -g $rg -n $hub2name --query 'provisioningState' -o tsv)
    echo "$hub2name provisioningState="$prState
    sleep 5
done

while [[ $rtState != 'Provisioned' ]];
do
    rtState=$(az network vhub show -g $rg -n $hub2name --query 'routingState' -o tsv)
    echo "$hub2name routingState="$rtState
    sleep 5
done

# create spoke to Vwan connections to hub2
az network vhub connection create -n sd-wan-devconn --remote-vnet sd-wan-dev -g $rg --vhub-name $hub2name --no-wait

prState=''
while [[ $prState != 'Succeeded' ]];
do
    prState=$(az network vhub connection show -n sd-wan-devconn --vhub-name $hub2name -g $rg  --query 'provisioningState' -o tsv)
    echo "vnet connection sd-wan-devconn provisioningState="$prState
    sleep 5
done
echo Creating Hub2 VPN Gateway...
# Creating VPN gateways in each Hub2
az network vpn-gateway create -n $hub2name-vpngw -g $rg --location $region2 --vhub $hub2name --no-wait

echo Checking Hub3 provisioning status...
# Checking Hub3 provisioning and routing state 
prState=''
rtState=''
while [[ $prState != 'Succeeded' ]];
do
    prState=$(az network vhub show -g $rg -n $hub3name --query 'provisioningState' -o tsv)
    echo "$hub3name provisioningState="$prState
    sleep 5
done

while [[ $rtState != 'Provisioned' ]];
do
    rtState=$(az network vhub show -g $rg -n $hub3name --query 'routingState' -o tsv)
    echo "$hub3name routingState="$rtState
    sleep 5
done

# create spoke to Vwan connections to hub3
az network vhub connection create -n hub3-fw-vnetconn --remote-vnet hub3-fw-vnet -g $rg --vhub-name $hub3name --no-wait

prState=''
while [[ $prState != 'Succeeded' ]];
do
    prState=$(az network vhub connection show -n hub3-fw-vnetconn --vhub-name $hub3name -g $rg  --query 'provisioningState' -o tsv)
    echo "vnet connection hub4-fw-vnetconn provisioningState="$prState
    sleep 5
done

echo Checking Hub4 provisioning status...
# Checking Hub4 provisioning and routing state 
prState=''
rtState=''
while [[ $prState != 'Succeeded' ]];
do
    prState=$(az network vhub show -g $rg -n $hub4name --query 'provisioningState' -o tsv)
    echo "$hub3name provisioningState="$prState
    sleep 5
done

while [[ $rtState != 'Provisioned' ]];
do
    rtState=$(az network vhub show -g $rg -n $hub4name --query 'routingState' -o tsv)
    echo "$hub3name routingState="$rtState
    sleep 5
done
# create spoke to Vwan connections to hub4
az network vhub connection create -n hub4-fw-vnetconn --remote-vnet hub4-fw-vnet -g $rg --vhub-name $hub4name --no-wait

prState=''
while [[ $prState != 'Succeeded' ]];
do
    prState=$(az network vhub connection show -n hub4-fw-vnetconn --vhub-name $hub4name -g $rg  --query 'provisioningState' -o tsv)
    echo "vnet connection hub4-fw-vnetconn provisioningState="$prState
    sleep 5
done

######### Hub3 and Hub4 Vnet peerings ###########
echo Creating VNET peerings...
az network vnet peering create -g $rg -n hub3-fw-vnet-to-hub3-spoke-vnet --vnet-name hub3-fw-vnet --allow-vnet-access --allow-forwarded-traffic --remote-vnet $(az network vnet show -g $rg -n hub3-spoke-vnet --query id --out tsv) --output none
az network vnet peering create -g $rg -n hub3-spoke-vnet-to-hub3-fw-vnet --vnet-name hub3-spoke-vnet --allow-vnet-access --allow-forwarded-traffic --remote-vnet $(az network vnet show -g $rg -n hub3-fw-vnet --query id --out tsv) --output none
az network vnet peering create -g $rg -n hub4-fw-vnet-to-hub4-spoke-vnet --vnet-name hub4-fw-vnet --allow-vnet-access --allow-forwarded-traffic --remote-vnet $(az network vnet show -g $rg -n hub4-spoke-vnet --query id --out tsv) --output none
az network vnet peering create -g $rg -n hub4-spoke-vnet-to-hub4-fw-vnet --vnet-name hub4-spoke-vnet --allow-vnet-access --allow-forwarded-traffic --remote-vnet $(az network vnet show -g $rg -n hub4-fw-vnet --query id --out tsv) --output none

########## hub3-fw-vnet and hub4-fw-vnet peering to/from dmz-vnet ###########
az network vnet peering create -g $rg -n hub3-fw-vnet-to-dmz-vnet --vnet-name hub3-fw-vnet --allow-vnet-access --allow-forwarded-traffic --remote-vnet $(az network vnet show -g $rg -n dmz-vnet --query id --out tsv) --output none
az network vnet peering create -g $rg -n dmz-vnet-to-hub3-fw-vnet --vnet-name dmz-vnet --allow-vnet-access --allow-forwarded-traffic --remote-vnet $(az network vnet show -g $rg -n hub3-fw-vnet --query id --out tsv) --output none
az network vnet peering create -g $rg -n hub4-fw-vnet-to-dmz-vnet --vnet-name hub4-fw-vnet --allow-vnet-access --allow-forwarded-traffic --remote-vnet $(az network vnet show -g $rg -n dmz-vnet --query id --out tsv) --output none
az network vnet peering create -g $rg -n dmz-vnet-to-hub4-fw-vnet --vnet-name dmz-vnet --allow-vnet-access --allow-forwarded-traffic --remote-vnet $(az network vnet show -g $rg -n hub4-fw-vnet --query id --out tsv) --output none

######### Enable FW-vnet as NVAs ###########
# Turning hub3-fw-nva into a router
echo Turning hub3-fw-nva into a router...
### Enable IP Forwarded on the az-hub-lxvm nic
az network nic update --resource-group $rg --name hub3-fw-nvaVMNic --ip-forwarding true -o none --no-wait
### az run command on az-hub-lxvm using uri: https://raw.githubusercontent.com/dmauser/AzureVM-Router/refs/heads/master/linuxrouter.sh
az vm run-command invoke -g $rg -n hub3-fw-nva --command-id RunShellScript --scripts "curl -s https://raw.githubusercontent.com/dmauser/AzureVM-Router/refs/heads/master/linuxrouter.sh | bash" -o none --no-wait

# Turning hub4-fw-nva into a router
echo Turning hub4-fw-nva into a router...
### Enable IP Forwarded on the az-hub-lxvm nic
az network nic update --resource-group $rg --name hub4-fw-nvaVMNic --ip-forwarding true -o none --no-wait
### az run command on az-hub-lxvm using uri: https://raw.githubusercontent.com/dmauser/AzureVM-Router/refs/heads/master/linuxrouter.sh
az vm run-command invoke -g $rg -n hub4-fw-nva --command-id RunShellScript --scripts "curl -s https://raw.githubusercontent.com/dmauser/AzureVM-Router/refs/heads/master/linuxrouter.sh | bash" -o none --no-wait

# Turning dmz-nva into a router
echo Turning dmz-nva into a router...
### Enable IP Forwarded on the dmz-nva nic
az network nic update --resource-group $rg --name dmz-nvaVMNic --ip-forwarding true -o none --no-wait
### az run command on dmz-nva using uri: https://raw.githubusercontent.com/dmauser/AzureVM-Router/refs/heads/master/linuxrouter.sh
az vm run-command invoke -g $rg -n dmz-nva --command-id RunShellScript --scripts "curl -s https://raw.githubusercontent.com/dmauser/AzureVM-Router/refs/heads/master/linuxrouter.sh | bash" -o none --no-wait

######### Static Route Propagation ###########
echo creating static route to their respective NVAs...
#hub3-fw-vnet vnet connection
spokevnet=hub3-fw-vnet
# List Private IP of hub3-fw-nvaVMNic
hub3nvaip=$(az network nic show -g $rg -n hub3-fw-nvaVMNic --query ipConfigurations[0].privateIPAddress -o tsv)
vnetid=$(az network vnet show -n $spokevnet -g $rg --query id -o tsv)
dstcidr=172.16.4.0/24
conn=hub3-fw-vnetconn
propagateStaticRoutes=true #Static Route propagation true or false
vnetLocalRouteOverrideCriteria=Equal #Equal = Onlink enabled Contains=Onlink disabled
apiversion='2024-05-01' #Set API version
#SubID
subid=$(az account list --query "[?isDefault == \`true\`].id" --all -o tsv)
#vHubRegion
vhubregion=$(az network vhub show -g $rg -n $hub3name --query id --query location -o tsv)
az rest --method put --uri https://management.azure.com/subscriptions/$subid/resourceGroups/$rg/providers/Microsoft.Network/virtualHubs/$hub3name/hubVirtualNetworkConnections/$conn?api-version=$apiversion \
 --body '{"name": "'$conn'", "properties": {"remoteVirtualNetwork": {"id": "'$vnetid'"}, "enableInternetSecurity": true, "routingConfiguration": {"propagatedRouteTables": {}, "vnetRoutes": {"staticRoutes": [{"name": "'$hub1name-indirect-spokes-rt'", "addressPrefixes": ["'$dstcidr'"], "nextHopIpAddress": "'$hub3nvaip'"}], "staticRoutesConfig": {"propagateStaticRoutes": "'$propagateStaticRoutes'", "vnetLocalRouteOverrideCriteria": "'$vnetLocalRouteOverrideCriteria'"}}}}}' \
 --output none

#hub4-fw-vnet vnet connection
spokevnet=hub4-fw-vnet
# List Private IP of hub4-fw-nvaVMNic
hub4nvaip=$(az network nic show -g $rg -n hub4-fw-nvaVMNic --query ipConfigurations[0].privateIPAddress -o tsv)
vnetid=$(az network vnet show -n $spokevnet -g $rg --query id -o tsv)
dstcidr=172.16.6.0/24
conn=hub4-fw-vnetconn
propagateStaticRoutes=true #Static Route propagation true or false
vnetLocalRouteOverrideCriteria=Equal #Equal = Onlink enabled Contains=Onlink disabled
apiversion='2024-05-01' #Set API version
#SubID
subid=$(az account list --query "[?isDefault == \`true\`].id" --all -o tsv)
#vHubRegion
vhubregion=$(az network vhub show -g $rg -n $hub4name --query id --query location -o tsv)
az rest --method put --uri https://management.azure.com/subscriptions/$subid/resourceGroups/$rg/providers/Microsoft.Network/virtualHubs/$hub4name/hubVirtualNetworkConnections/$conn?api-version=$apiversion \
 --body '{"name": "'$conn'", "properties": {"remoteVirtualNetwork": {"id": "'$vnetid'"}, "enableInternetSecurity": true, "routingConfiguration": {"propagatedRouteTables": {}, "vnetRoutes": {"staticRoutes": [{"name": "'$hub1name-indirect-spokes-rt'", "addressPrefixes": ["'$dstcidr'"], "nextHopIpAddress": "'$hub4nvaip'"}], "staticRoutesConfig": {"propagateStaticRoutes": "'$propagateStaticRoutes'", "vnetLocalRouteOverrideCriteria": "'$vnetLocalRouteOverrideCriteria'"}}}}}' \
 --output none

########## For traffic indirect spokes to Hub3 and Hub 4 NVAs ###########
echo Creating UDRs for the spoke VNETs to route traffic to their respective NVAs
# Create UDR from hub3-spoke-vnet to hub3-fw-vnet
az network route-table create -g $rg -n hub3-spoke-vnet-rt --location $region3 --output none
az network route-table route create -g $rg --route-table-name hub3-spoke-vnet-rt -n route-to-hub3-fw-vnet --address-prefix 0.0.0.0/0 --next-hop-type VirtualAppliance --next-hop-ip-address $hub3nvaip --output none
az network vnet subnet update --vnet-name hub3-spoke-vnet -g $rg --name main --route-table hub3-spoke-vnet-rt --output none

az network route-table create -g $rg -n hub4-spoke-vnet-rt --location $region4 --output none
az network route-table route create -g $rg --route-table-name hub4-spoke-vnet-rt -n route-to-hub4-fw-vnet --address-prefix 0.0.0.0/0 --next-hop-type VirtualAppliance --next-hop-ip-address $hub4nvaip --output none
az network vnet subnet update --vnet-name hub4-spoke-vnet -g $rg --name main --route-table hub4-spoke-vnet-rt --output none

########## For traffic indirect Hub NVAs to fw-dmzvm ###########
# Get private IP from fw-dmzvm
dmzvmnicip=$(az network nic show -g $rg -n dmz-nvaVMNic --query ipConfigurations[0].privateIPAddress -o tsv)

# Create UDR from hub3-fw-vnet to fw-dmzvm
az network route-table create -g $rg -n hub3-fw-vnet-rt --location $region3 --output none
az network route-table route create -g $rg --route-table-name hub3-fw-vnet-rt -n route-to-fw-dmzvm --address-prefix 0.0.0.0/0 --next-hop-type VirtualAppliance --next-hop-ip-address $dmzvmnicip --output none
az network vnet subnet update --vnet-name hub3-fw-vnet -g $rg --name main --route-table hub3-fw-vnet-rt --output none

# Create UDR from hub4-fw-vnet to fw-dmzvm
az network route-table create -g $rg -n hub4-fw-vnet-rt --location $region4 --output none
az network route-table route create -g $rg --route-table-name hub4-fw-vnet-rt -n route-to-fw-dmzvm --address-prefix 0.0.0.0/0 --next-hop-type VirtualAppliance --next-hop-ip-address $dmzvmnicip --output none
az network vnet subnet update --vnet-name hub4-fw-vnet -g $rg --name main --route-table hub4-fw-vnet-rt --output none

######### VPN Gateways provisioning status ###########
echo Validating Branches VPN Gateways provisioning...
#Branches VPN Gateways provisioning status
prState=$(az network vnet-gateway show -g $rg -n branch1-vpngw --query provisioningState -o tsv)
if [[ $prState == 'Failed' ]];
then
    echo VPN Gateway is in fail state. Deleting and rebuilding.
    az network vnet-gateway delete -n branch1-vpngw -g $rg
    az network vnet-gateway create -n branch1-vpngw --public-ip-addresses branch1-vpngw-pip -g $rg --vnet branch1 --asn 65510 --gateway-type Vpn -l $region1 --sku VpnGw1 --vpn-gateway-generation Generation1 --no-wait 
    sleep 5
else
    prState=''
    while [[ $prState != 'Succeeded' ]];
    do
        prState=$(az network vnet-gateway show -g $rg -n branch1-vpngw --query provisioningState -o tsv)
        echo "branch1-vpngw provisioningState="$prState
        sleep 5
    done
fi

prState=$(az network vnet-gateway show -g $rg -n branch2-vpngw --query provisioningState -o tsv)
if [[ $prState == 'Failed' ]];
then
    echo VPN Gateway is in fail state. Deleting and rebuilding.
    az network vnet-gateway delete -n branch2-vpngw -g $rg
    az network vnet-gateway create -n branch2-vpngw --public-ip-addresses branch2-vpngw-pip -g $rg --vnet branch2 --asn 65509 --gateway-type Vpn -l $region2 --sku VpnGw1 --vpn-gateway-generation Generation1 --no-wait 
    sleep 5
else
    prState=''
    while [[ $prState != 'Succeeded' ]];
    do
        prState=$(az network vnet-gateway show -g $rg -n branch2-vpngw --query provisioningState -o tsv)
        echo "branch2-vpngw provisioningState="$prState
        sleep 5
    done
fi

echo Validating vHubs VPN Gateways provisioning...
#vWAN Hubs VPN Gateway Status
prState=$(az network vpn-gateway show -g $rg -n $hub1name-vpngw --query provisioningState -o tsv)
while [[ $prState != 'Succeeded' ]];
do
    if [[ $prState == 'Failed' ]];
    then
        echo VPN Gateway is in fail state. Deleting and rebuilding.
        az network vpn-gateway delete -n $hub1name-vpngw -g $rg || { echo "Failed to delete VPN Gateway"; exit 1; }
        az network vpn-gateway create -n $hub1name-vpngw -g $rg --location $region1 --vhub $hub1name --no-wait || { echo "Failed to create VPN Gateway"; exit 1; }
        sleep 5
    fi

    prState=$(az network vpn-gateway show -g $rg -n $hub1name-vpngw --query provisioningState -o tsv)
    if [[ -z $prState ]]; then
        echo "Error fetching provisioning state for $hub1name-vpngw"; exit 1;
    fi
    echo $hub1name-vpngw "provisioningState="$prState
    sleep 5
done

prState=$(az network vpn-gateway show -g $rg -n $hub2name-vpngw --query provisioningState -o tsv)
while [[ $prState != 'Succeeded' ]];
do
    if [[ $prState == 'Failed' ]];
    then
        echo VPN Gateway is in fail state. Deleting and rebuilding.
        az network vpn-gateway delete -n $hub2name-vpngw -g $rg || { echo "Failed to delete VPN Gateway"; exit 1; }
        az network vpn-gateway create -n $hub2name-vpngw -g $rg --location $region2 --vhub $hub2name --no-wait || { echo "Failed to create VPN Gateway"; exit 1; }
        sleep 5
    fi

    prState=$(az network vpn-gateway show -g $rg -n $hub2name-vpngw --query provisioningState -o tsv)
    if [[ -z $prState ]]; then
        echo "Error fetching provisioning state for $hub2name-vpngw"; exit 1;
    fi
    echo $hub2name-vpngw "provisioningState="$prState
    sleep 5
done

echo Building VPN connections from VPN Gateways to the respective Branches...
# get bgp peering and public ip addresses of VPN GW and VWAN to set up connection
# Branch 1 and Hub1 VPN Gateway variables
bgp1=$(az network vnet-gateway show -n branch1-vpngw -g $rg --query 'bgpSettings.bgpPeeringAddresses[0].defaultBgpIpAddresses[0]' -o tsv)
pip1=$(az network vnet-gateway show -n branch1-vpngw -g $rg --query 'bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[0]' -o tsv)
vwanh1gwbgp1=$(az network vpn-gateway show -n $hub1name-vpngw -g $rg --query 'bgpSettings.bgpPeeringAddresses[0].defaultBgpIpAddresses[0]' -o tsv)
vwanh1gwpip1=$(az network vpn-gateway show -n $hub1name-vpngw -g $rg --query 'bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[0]' -o tsv)
vwanh1gwbgp2=$(az network vpn-gateway show -n $hub1name-vpngw -g $rg --query 'bgpSettings.bgpPeeringAddresses[1].defaultBgpIpAddresses[0]' -o tsv)
vwanh1gwpip2=$(az network vpn-gateway show -n $hub1name-vpngw -g $rg --query 'bgpSettings.bgpPeeringAddresses[1].tunnelIpAddresses[0]' -o tsv)

# Branch 2 and Hub2 VPN Gateway variables
bgp2=$(az network vnet-gateway show -n branch2-vpngw -g $rg --query 'bgpSettings.bgpPeeringAddresses[0].defaultBgpIpAddresses[0]' -o tsv)
pip2=$(az network vnet-gateway show -n branch2-vpngw -g $rg --query 'bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[0]' -o tsv)
vwanh2gwbgp1=$(az network vpn-gateway show -n $hub2name-vpngw -g $rg --query 'bgpSettings.bgpPeeringAddresses[0].defaultBgpIpAddresses[0]' -o tsv)
vwanh2gwpip1=$(az network vpn-gateway show -n $hub2name-vpngw  -g $rg --query 'bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[0]' -o tsv)
vwanh2gwbgp2=$(az network vpn-gateway show -n $hub2name-vpngw -g $rg --query 'bgpSettings.bgpPeeringAddresses[1].defaultBgpIpAddresses[0]' -o tsv)
vwanh2gwpip2=$(az network vpn-gateway show -n $hub2name-vpngw -g $rg --query 'bgpSettings.bgpPeeringAddresses[1].tunnelIpAddresses[0]' -o tsv)

# create virtual wan vpn site
az network vpn-site create --ip-address $pip1 -n site-branch1 -g $rg --asn 65510 --bgp-peering-address $bgp1 -l $region1 --virtual-wan $vwanname --device-model 'Azure' --device-vendor 'Microsoft' --link-speed '50' --with-link true --output none
az network vpn-site create --ip-address $pip2 -n site-branch2 -g $rg --asn 65509 --bgp-peering-address $bgp2 -l $region2 --virtual-wan $vwanname --device-model 'Azure' --device-vendor 'Microsoft' --link-speed '50' --with-link true --output none

# create virtual wan vpn connection
az network vpn-gateway connection create --gateway-name $hub1name-vpngw -n connection-site-branch1 -g $rg --enable-bgp true --remote-vpn-site site-branch1 --internet-security --shared-key 'abc123' --output none
az network vpn-gateway connection create --gateway-name $hub2name-vpngw -n connection-site-branch2 -g $rg --enable-bgp true --remote-vpn-site site-branch2 --internet-security --shared-key 'abc123' --output none

# create connection from vpn gw to local gateway and watch for connection succeeded
az network local-gateway create -g $rg -n lng-$hub1name-gw1 --gateway-ip-address $vwanh1gwpip1 --asn 65515 --bgp-peering-address $vwanh1gwbgp1 -l $region1 --output none
az network vpn-connection create -n branch1-to-$hub1name-gw1 -g $rg -l $region1 --vnet-gateway1 branch1-vpngw --local-gateway2 lng-$hub1name-gw1 --enable-bgp --shared-key 'abc123' --output none

az network local-gateway create -g $rg -n lng-$hub1name-gw2 --gateway-ip-address $vwanh1gwpip2 --asn 65515 --bgp-peering-address $vwanh1gwbgp2 -l $region1 --output none
az network vpn-connection create -n branch1-to-$hub1name-gw2 -g $rg -l $region1 --vnet-gateway1 branch1-vpngw --local-gateway2 lng-$hub1name-gw2 --enable-bgp --shared-key 'abc123' --output none

az network local-gateway create -g $rg -n lng-$hub2name-gw1 --gateway-ip-address $vwanh2gwpip1 --asn 65515 --bgp-peering-address $vwanh2gwbgp1 -l $region2 --output none
az network vpn-connection create -n branch2-to-$hub2name-gw1 -g $rg -l $region2 --vnet-gateway1 branch2-vpngw --local-gateway2 lng-$hub2name-gw1 --enable-bgp --shared-key 'abc123' --output none

az network local-gateway create -g $rg -n lng-$hub2name-gw2 --gateway-ip-address $vwanh2gwpip2 --asn 65515 --bgp-peering-address $vwanh2gwbgp2 -l $region2 --output none
az network vpn-connection create -n branch2-to-$hub2name-gw2 -g $rg -l $region2 --vnet-gateway1 branch2-vpngw --local-gateway2 lng-$hub2name-gw2 --enable-bgp --shared-key 'abc123' --output none

echo Deployment has finished
# Add script ending time but hours, minutes and seconds
end=`date +%s`
runtime=$((end-start))
echo "Script finished at $(date)"
echo "Total script execution time: $(($runtime / 3600)) hours $((($runtime / 60) % 60)) minutes and $(($runtime % 60)) seconds."


