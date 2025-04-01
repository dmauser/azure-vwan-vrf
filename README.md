# LAB: Virtual WAN deployment using VRFs

This lab demonstrates how to deploy a Virtual WAN using labels to segregate traffic between 3rd party accessing production and development environments. 

### Prerequisites
- An Azure subscription with the necessary permissions to create resources.
- Basic knowledge of Azure networking concepts, including Virtual WAN, Virtual Hubs, and VRFs.

### Networking topology

![](./media/diagram.png)

### Lab Steps

Using Azure CLI deploy run the following command to deploy the lab:

```bash
curl -s https://raw.githubusercontent.com/dmauser/azure-virtualwan/main/svh-ri-inter-region/svhri-inter-deploy.azcli | bash
```
