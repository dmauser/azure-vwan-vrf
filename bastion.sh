# Parameters (make changes based on your requirements)
rg=lab-vwan-3p 
vwanname=vwan-3p
hub1name=hub1
hub2name=hub2
hub3name=hub3
hub4name=hub4

# Variables
region1=$(az network vhub show -n $hub1name -g $rg --query location -o tsv)
region2=$(az network vhub show -n $hub2name -g $rg --query location -o tsv)
region3=$(az network vhub show -n $hub3name -g $rg --query location -o tsv)
region4=$(az network vhub show -n $hub4name -g $rg --query location -o tsv)
bastionName="dmz-vnet-bastion"
username=azureuser
password="Msft123Msft123"

### Deploy Bastion ###
# Create a public IP for the Bastion host
az network public-ip create --name dmz-vnet-bastion-pip --resource-group $rg --location $region1 --sku Standard --allocation-method Static -o none
# Create Bastion subnet in the dmz-vnet
az network vnet subnet create --name AzureBastionSubnet --resource-group $rg --vnet-name dmz-vnet --address-prefixes 172.16.100.64/26 -o none
# Deploy bastion in the dmz-vnet
az network bastion create --location $region1 --name $bastionName --resource-group $rg --vnet-name dmz-vnet --public-ip-address dmz-vnet-bastion-pip --sku Standard --enable-tunneling true --enable-ip-connect true -o none &>/dev/null &

# Check if Bastion is deployed
while true; do
    status=$(az network bastion show --name $bastionName --resource-group $rg --query provisioningState -o tsv)
    if [ "$status" == "Succeeded" ]; then
        echo "Bastion deployed successfully."
        break
    else
        echo "Waiting for Bastion deployment..."
        sleep 10
    fi
done

### Generate connections ###
# Get all VMs in the resource group
vms=$(az vm list -g $rg --query "[].{name:name}" -o tsv)
for vm in $vms; do
    # Get the private IP address of the VM
    privateIp=$(az vm list-ip-addresses -g $rg -n $vm --query "[0].virtualMachine.network.privateIpAddresses[0]" -o tsv)
        
    # Construct the Bastion SSH command
    echo "#vmname:" $vm
    echo az network bastion ssh --name "$bastionName" --resource-group "$rg" --target-ip-address "$privateIp" --auth-type "password" --username "$username"
done

# Output
#vmname: branch1VM
az network bastion ssh --name dmz-vnet-bastion --resource-group lab-vwan-3p --target-ip-address 10.110.0.4 --auth-type password --username azureuser 
#vmname: branch2VM
az network bastion ssh --name dmz-vnet-bastion --resource-group lab-vwan-3p --target-ip-address 10.120.0.4 --auth-type password --username azureuser 
#vmname: dmz-nva
az network bastion ssh --name dmz-vnet-bastion --resource-group lab-vwan-3p --target-ip-address 172.16.100.4 --auth-type password --username azureuser 
#vmname: hub3-fw-nva
az network bastion ssh --name dmz-vnet-bastion --resource-group lab-vwan-3p --target-ip-address 172.16.3.4 --auth-type password --username azureuser 
#vmname: hub3-spoke
az network bastion ssh --name dmz-vnet-bastion --resource-group lab-vwan-3p --target-ip-address 172.16.4.4 --auth-type password --username azureuser 
#vmname: hub4-fw-nva
az network bastion ssh --name dmz-vnet-bastion --resource-group lab-vwan-3p --target-ip-address 172.16.5.4 --auth-type password --username azureuser 
#vmname: hub4-spoke
az network bastion ssh --name dmz-vnet-bastion --resource-group lab-vwan-3p --target-ip-address 172.16.6.4 --auth-type password --username azureuser 
#vmname: sd-wan-dev
az network bastion ssh --name dmz-vnet-bastion --resource-group lab-vwan-3p --target-ip-address 172.16.2.4 --auth-type password --username azureuser 
#vmname: sd-wan-prod
az network bastion ssh --name dmz-vnet-bastion --resource-group lab-vwan-3p --target-ip-address 172.16.1.4 --auth-type password --username azureuser 

# Public IP DMZ NVA:  4.227.116.58