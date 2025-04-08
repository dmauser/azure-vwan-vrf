# Parameters (make changes based on your requirements)
rg=lab-vwan-3p 
vwanname=vwan-3p

# List the Privat IP addesses of the VMs in the resource group
vmsips=$(az vm list-ip-addresses -g $rg --query "[].virtualMachine.network.privateIpAddresses[0]" -o tsv)
# Loop script to echo each vmips private IP address
for vmips in $vmsips; do
    # Construct the Bastion SSH command
    echo curl $vmips
done

