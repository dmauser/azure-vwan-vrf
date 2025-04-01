# LAB: Virtual WAN deployment using VRFs

This lab demonstrates how to deploy a Virtual WAN using labels to segregate traffic between 3rd party accessing production and development environments. 

### Prerequisites

- Basic knowledge of Azure networking concepts, including Virtual WAN, Virtual Hubs, and VRFs.

### Networking topology

![](./media/diagram.png)

### Lab Steps

1. Deploy base lab resources using the following command using Azure Cloud Shell or Azure CLI.

```bash
curl -s https://raw.githubusercontent.com/dmauser/azure-vwan-vrf/refs/heads/main/1deploy.azcli | bash
```

Alternatively, you can download the script and run it locally which is going to allow you to customize the parameters.

```bash
wget -O deploy.sh https://raw.githubusercontent.com/dmauser/azure-vwan-vrf/refs/heads/main/1deploy.azcli 
chmod +xr deploy.sh
./deploy.sh
```

2. Validation before enabling labels (any to any connectivity).

2.1 Validate connectivity between all VMs.

2.2 Review the effective routes for few VMs.

3. Configure labels to segregate traffic between production and development environments as well as between vendor 1 and vendor 2.

```bash
curl -s https://raw.githubusercontent.com/dmauser/azure-vwan-vrf/refs/heads/main/2labelconfig.azcli | bash
```

4. Validation before after labels for network isolation.