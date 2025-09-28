#!/bin/sh
# setup_bridge.sh

# Create a Linux bridge
ip link add br0 type bridge

# Add eth0 to the bridge (⚠️ THIS WILL DROP YOUR SSH/NETWORK!)
ip link set eth0 master br0

# Bring up bridge
ip link set br0 up

# Assign IP to bridge (your original eth0 IP)
# Example:
# ip addr add 192.168.1.10/24 dev br0
# ip route add default via 192.168.1.1

# Then tell Docker to use br0 as the bridge
# But Docker Compose can't easily use an existing bridge unless you pre-create it.