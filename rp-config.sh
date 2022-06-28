#!/bin/sh

: <<COMMENT
After running this:
  wlan0 will become an AP
  wlan0 and eth0 will be bridged into br0
  dhcp server will run on br0
  no internet at all
COMMENT



# Install hostapd
sudo apt install hostapd
sudo systemctl unmask hostapd
sudo systemctl enable hostapd

# Install dnsmasq
sudo apt install dnsmasq



# Config Netplan
sudo cat > /etc/netplan/50-cloud-init.yaml << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      optional: true
    wlan0:
      dhcp4: no
      optional: true
  bridges:
    br0:
      interfaces: [eth0, wlan0]
      addresses: [192.168.0.1/24]
      routes:
        - to: default
          via: 0.0.0.0
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
      optional: true
EOF
sudo netplan apply

# Config hostapd
sudo cat > /etc/hostapd/hostapd.conf << EOF
interface=wlan0
bridge=br0

hw_mode=g
channel=7

macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0

ssid=tmtcontrol
wpa_passphrase=tmtcontrol
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF
sudo systemctl start hostapd

# Config dnsmasq
sudo cat > /etc/dnsmasq.conf << EOF
port=0
interface=br0
dhcp-range=192.168.0.1,192.168.0.100,12h
dhcp-host=fe:86:7a:47:30:73,192.168.0.2
dhcp-host=f2:11:e6:b9:95:e0,192.168.0.3
dhcp-host=8a:d8:2a:5f:f1:44,192.168.0.4
EOF
dnsmasq --test
sudo systemctl restart dnsmasq
