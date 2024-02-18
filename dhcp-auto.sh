#!/bin/bash

# CONSTANTES
NEW_HOSTNAME="srv-ad"
IP_ADDRESS="192.168.1.100"
NETMASK="255.255.255.0"
GATEWAY="192.168.1.1"
DNS_SERVER="8.8.8.8"


# Atualiza o sistema
apt update && apt upgrade -y

# Altera o hostname
echo "$NEW_HOSTNAME" | sudo tee /etc/hostname >/dev/null
hostname -F /etc/hostname

# Modifica o arquivo hosts
echo -e "$IP_ADDRESS\t$NEW_HOSTNAME" >> /etc/hosts

# Configura a interface de rede
cat <<EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address $IP_ADDRESS
    netmask $NETMASK
    gateway $GATEWAY
EOF

# Reinicia a interface de rede
ifdown eth0 && ifup eth0

# Instala o servidor DHCP
apt update
apt install -y isc-dhcp-server

# Configura o arquivo dhcpd.conf
cat <<EOF > /etc/dhcp/dhcpd.conf
subnet $IP_ADDRESS netmask $NETMASK {
    range 192.168.1.10 192.168.1.50;
    option routers $GATEWAY;
    option domain-name-servers $DNS_SERVER;
    option domain-name "example.com";
}
EOF

# Configura o arquivo default/isc-dhcp-server
sed -i 's/INTERFACESv4=""/INTERFACESv4="eth0"/' /etc/default/isc-dhcp-server

# Reinicia o serviço DHCP
systemctl restart isc-dhcp-server
