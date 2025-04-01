# LAB: Virtual WAN deployment using network isolation (VRF) with labels

This lab provides a step-by-step guide to deploying a Virtual WAN with labels, enabling traffic segregation between third-party vendors and production or development environments. By following this lab, you will learn how to configure and validate network isolation effectively.

### Prerequisites

- Basic knowledge of Azure networking concepts, including Virtual WAN, Virtual Hubs, route tables, and labels.
    - Here are some resources to get you started:
      - [Azure Virtual WAN Overview](https://learn.microsoft.com/en-us/azure/virtual-wan/virtual-wan-about)
      - [About virtual Hub routing](https://learn.microsoft.com/en-us/azure/virtual-wan/about-virtual-hub-routing)

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

The network isolation (vrf) goal for this lab is to have separation between prod and dev, vendor1 and vendor2. However, vendor1 and vendor2 can access both prod and dev environments.

After you ran the script above, we will have the following labels on each Virtual Hub:
- **prod**: Production environment
- **dev**: Development environment
- **vendor1**: Vendor 1 environment
- **vendor2**: Vendor 2 environment

To achieve this, we will use the following labels:

| Connection | Connected to vHub | Propagation Label | Description |
|------------|-------------------|-------------------|-------------|
| sd-wan-prodconn | Hub1 Prod | prod, vendor1, vendor2 | sd-wan-prod vNET can advertise its routes to labels Prod, Vendor1 and Vendor 2 |
| connection-site-branch1 | Hub1 Prod | prod, vendor1, vendor2 | On-premises can advertise its routes to labels Prod, Vendor1 and Vendor 2 |
| sd-wan-devconn | Hub2 Dev | dev, vendor1, vendor2 | sd-wan-dev vNET can advertise its routes to labels Dev, Vendor1 and Vendor 2 |
| connection-site-branch2 | Hub2 Dev | dev, vendor1, vendor2 | On-premises can advertise its routes to labels Dev, Vendor1 and Vendor 2 |
| hub3-fw-vnetconn | Hub3 Vendor1 | vendor1, prod, dev | Hub3 can advertise its routes to labels Vendor1 and Vendor 2 |
| hub4-fw-vnetconn | Hub4 Vendor2 | vendor2, prod, dev | Hub4 can advertise its routes to labels Vendor1 and Vendor 2 |
| dmz-vnetconn | Hub1 Prod | prod | DMZ can advertise its routes to label Prod |

4. Validation after labels for network isolation.



### Network Diagram after applying labels
![](/media/diagram-label.png)