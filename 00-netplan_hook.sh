#!/usr/bin/env bash

# The interface attached directly to the ONT port of the BGW210-700
ATT_GATEWAY_INTERFACE="ens192f0"

if [[ ${IFACE} = "br0" ]]
then
  # Once the bridge comes up, enable forwarding of 802.1X packets
  echo -n 8 > /sys/class/net/br0/bridge/group_fwd_mask
elif [[ ${IFACE} = "${ATT_GATEWAY_INTERFACE}" ]]
then
  # Once the interface of the BGW210-700 comes up, block all non-802.1X traffic to/from it
  ebtables -t filter -A FORWARD -i "${ATT_GATEWAY_INTERFACE}" --proto 802_1Q --vlan-encap 0x888e -j ACCEPT
  ebtables -t filter -A FORWARD -i "${ATT_GATEWAY_INTERFACE}" --proto 802_1Q -j DROP
  ebtables -t filter -A FORWARD -o "${ATT_GATEWAY_INTERFACE}" --proto 802_1Q --vlan-encap 0x888e -j ACCEPT
  ebtables -t filter -A FORWARD -o "${ATT_GATEWAY_INTERFACE}" --proto 802_1Q -j DROP
fi