#!/bin/bash

# Save iptables rules for IPv4
echo "Saving iptables rules for IPv4..."
sudo iptables-save | sudo tee /etc/iptables/iptables.rules > /dev/null

# Save ip6tables rules (optional for IPv6)
# echo "Saving ip6tables rules for IPv6..."
# sudo ip6tables-save | sudo tee /etc/iptables/ip6tables.rules > /dev/null

# Restart iptables service to load saved rules
echo "Restarting iptables service..."
sudo systemctl restart iptables

echo "iptables rules saved and service restarted."
