# Bypassing BGW210-700 with Ubuntu

These are the configs to use an Ubuntu 18.04 VM as a bypass for the AT&T BGW210-700 Residential Gateway.

The general concepts and configs behind this guide are based on the excellent post [here](https://www.haught.org/2018/04/13/att-router-bypass/) by Matt Haught. I have adapted the network configs for Ubuntu, and am using an external router instead of the Linux VM as a router, but the underlying principles are the same.

Note: If all of this works right, you will get a red "Broadband" light on the BGW210. This is due to the gateway being unable to get a DHCP lease from AT&T.

## Topology

```
# Interface Names are from the perspective of the Ubuntu VM - see 00-netplan.yaml

            ONT 
   ens192f1--|                                (ens192f0 + ens192f1 = br0)
             |                                                        |
ens160---< UBUNTU --ens192f0--- BGW210                                |
     |       |                                                        |
     |       |--ens256                                                |
     |    SophosUTM                                       (ens256 + vlan0 = br1)
     |       | 
     |----> LAN
```

## Required Materials

1. ESXi Host. THis will run an Ubuntu VM to bypass the BGW210, and a Sophos UTM VM to serve as the gateway/firewall.
    1. Hardware
        1. 4 cores/8GB minimun for 1Gbps connection
        1. Atleast one physical NIC, plus a PCI addon card with more NICs, dual or quad port Intel preferred.
    1. Config
        1. One vSwitch attached to the LAN, I just use the onboard NIC for the management network and the LAN vSwitch
        1. One private vSwitch for traffic between the Ubuntu VM and the Sophos VM
    1. Ubuntu 18.04 VM
        1. 1-2 vCPUs
        1. 1GB RAM should be plenty
        1. 4 NICs, atleast two of them physical, from the Intel card.
            1. The two physical NICs should connect to the ONT and the BGW210. They are ens192f0/1 in the above topology
            1. One virtual NIC (in the example, ens160) should connect to the standard LAN. This should have a static IP address or a static DHCP lease, so that SSHD can be bound to a specific IP. This is important because this server will directly face the public internet. This could also be a physical NIC if you have a quad port PCI card.
            1. A second virtual NIC attached to the private vSwitch. This is ens256 in the example.
    1. Sophos UTM VM
        1. 4+ vCPUs
        1. 4GB+ of RAM
        1. 2 or more NICs, all virtual
            1. One NIC attached to the private vSwitch shared with the Ubuntu VM
            1. One NIC attached to the LAN that this VM is the gateway for.
            1. Any number of other NICs for any VLANs you may have. Add any VLANs you are sure you need at creation time, as adding them later may renumber your NICs

## Ubuntu VM Setup

1. Install `00-netplan.yaml` to `/etc/netplan/`
    1. Modify the interface names to match your environment
1. Install `00-netplan_hook.sh` to `/etc/networkd-dispatcher/configured.d/`
    1. Modify the interface name to match your environment
1. Configure the `ListenAddress` directive in `/etc/ssh/sshd_config` to only listen on the IP address assigned to the LAN interface.

## Sophos UTM VM Setup

1. Configure the WAN interface with the MAC of the ONT port on the BGW210
    1. Browse through the WebAdmin consle to Interfaces & Routing --> Interfaces --> Hardware
    1. Edit your WAN NIC
    1. Set the "Virtual MAC" to the correct address