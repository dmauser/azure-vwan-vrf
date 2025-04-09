#!/bin/bash

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

# Adding script starting time and finish time
start=`date +%s`
echo "Script started at $(date)"


# Configuring labels for vHUBs...
echo Configuring labels for vHUBs...
az network vhub route-table update -n defaultroutetable -g $rg --vhub-name $hub1name --labels default prod --no-wait
az network vhub route-table update -n defaultroutetable -g $rg --vhub-name $hub2name --labels default dev --no-wait
az network vhub route-table update -n defaultroutetable -g $rg --vhub-name $hub3name --labels default vendor1 --no-wait
az network vhub route-table update -n defaultroutetable -g $rg --vhub-name $hub4name --labels default vendor2 --no-wait

# Update VNET connections
echo Configuring labels for VNET connections...
az network vhub connection update --name dmz-vnetconn --vhub-name $hub1name --resource-group $rg --labels prod --no-wait
az network vhub connection update --name sd-wan-prodconn --vhub-name $hub1name --resource-group $rg --labels prod vendor1 vendor2 --no-wait
az network vhub connection update --name sd-wan-devconn --vhub-name $hub2name --resource-group $rg --labels dev vendor1 vendor2 --no-wait
az network vhub connection update --name hub3-fw-vnetconn --vhub-name $hub3name --resource-group $rg --labels vendor1 prod dev --no-wait
az network vhub connection update --name hub4-fw-vnetconn --vhub-name $hub4name --resource-group $rg --labels vendor2 prod dev --no-wait

# VPN Connections Labels (This is required to isolate branches.)
echo Configuring labels for VPN connections...
default_hub1=$(az network vhub route-table show --name defaultroutetable --vhub-name $hub1name -g $rg --query id -o tsv)
default_hub2=$(az network vhub route-table show --name defaultroutetable --vhub-name $hub2name -g $rg --query id -o tsv)
az network vpn-gateway connection update --gateway-name $hub1name-vpngw -n connection-site-branch1 -g $rg --propagated $default_hub1 --label prod vendor1 vendor2 --output none --no-wait
az network vpn-gateway connection update --gateway-name $hub2name-vpngw -n connection-site-branch2 -g $rg --propagated $default_hub2 --label dev vendor1 vendor2 --output none --no-wait

# Apply iptables rules to NVA
echo Configuring iptables rules on DMZ-NVA...
scripturi="https://raw.githubusercontent.com/dmauser/azure-vwan-vrf/refs/heads/main/scripts/iptables.sh"
az vm run-command invoke -g $rg -n dmz-nva --command-id RunShellScript --scripts "curl -s $scripturi | bash" --output none --no-wait

echo Deployment has finished
# Add script ending time but hours, minutes and seconds
end=`date +%s`
runtime=$((end-start))
echo "Script finished at $(date)"
echo "Total script execution time: $(($runtime / 3600)) hours $((($runtime / 60) % 60)) minutes and $(($runtime % 60)) seconds."