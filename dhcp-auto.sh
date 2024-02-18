#!/bin/bash
vermelho="\033[0;31m"
reset="\033[0m"

# CONSTANTES
INTERFACE_INTERNA="enp0s3"
INTERFACE_EXTERNA=""
HOSTNAME="srv-dhcp"
DOMAIN="dreconet.io"
IP_ADDRESS="192.168.0.252"
NETMASK="255.255.255.0"
GATEWAY="192.168.0.254"
BROADCAST="192.168.0.255"
NETWORK="192.168.0.0"

# CONSTANTES DHCP
RANGE="192.168.0.20 192.168.0.230"
NAMESERVERS="192.168.0.253, 192.168.15.1, 8.8.8.8, 1.1.1.1"


first() {
    # Atualiza o sistema
    echo -e "${vermelho}Atualizando o sistema...${reset}"
    sudo apt update && sudo apt upgrade -y
    echo -e "${vermelho}Sistema atualizado.${reset}"
    sudo apt install isc-dhcp-server
    echo -e "${vermelho}Dependencias instaladas.${reset}"


    # Altera o hostname
    sudo sed -i "s/.*/${HOSTNAME}/" /etc/hostname
    sudo hostname -F /etc/hostname
    echo -e "${vermelho}HOSTNAME alterado.${reset}"

    # Modifica o arquivo hosts
    sudo sed -i "s/127\.0\.1\.1\t.*/\
    127.0.1.1\t${HOSTNAME}\n${IP_ADDRESS}\t${HOSTNAME}.${DOMAIN}\t${HOSTNAME}" /etc/hosts
    echo -e "${vermelho}Arquivo HOSTS alterado.${reset}"

    # Configura a interface de rede
    sudo sed -i -e "10a \
    auto ${INTERFACE_INTERNA}\n\
    iface ${INTERFACE_INTERNA} inet static\n\
    address ${IP_ADDRESS}\n\
    netmask ${NETMASK}\n\
    gateway ${GATEWAY}\n\
    network ${NETWORK}\n\
    broadcast ${BROADCAST}\n" -e '11,$d' /etc/network/interfaces
    echo -e "${vermelho}Arquivo INTERFACES alterado.${reset}"

    # Crontab e reinicia o sistema
    echo "@reboot $(realpath "$0") second" | sudo crontab -
    echo -e "${vermelho}Crontab adicionado, reinicializando (TROQUE PARA REDE INTERNA)...${reset}"
    sleep 10
    reboot
}

second() {
    # Remove o crontab
    sleep 40
    sudo crontab -l | grep -v "@reboot $(realpath "$0") second" | crontab -
    echo -e "${vermelho}Crontab removido.${reset}"
    mkdir /home/andrelps/passouaqui

    # Configurar o dhcpd.conf
    {
        echo "# Configuração do serviço DHCP."
        echo "authoritative;"
        echo "subnet ${NETWORK} netmask ${NETMASK} {"
        echo "    range ${RANGE};"
        echo "    option domain-name-servers ${NAMESERVERS};"
        echo "    option domain-name \"${HOSTNAME}.${DOMAIN}\";"
        echo "    option subnet-mask ${NETMASK};"
        echo "    option routers ${GATEWAY};"
        echo "    option broadcast-address ${BROADCAST};"
        echo "    default-lease-time 600;"
        echo "    max-lease-time 7200;"
        echo "}"
    } >> /etc/dhcp/dhcpd.conf
    echo -e "${vermelho}dhcpd.conf configurado.${reset}"


    # Configura o arquivo default/isc-dhcp-server
    sudo sed -i "s/INTERFACES=\"\"/INTERFACES=\"${INTERFACE_INTERNA}\"/" /etc/default/isc-dhcp-server
    echo -e "${vermelho}default/isc-dhcp-server configurado.${reset}"

    # Reinicia o serviço DHCP
    sudo systemctl restart isc-dhcp-server
    sudo systemctl status isc-dhcp-server
}


# MAIN
case $1 in
second)second;;
*)first;;
esac