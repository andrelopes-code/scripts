#!/bin/bash
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# CONSTANTES
INTERFACE_INTERNA="enp0s3"
HOSTNAME="srv-ad"
DOMAIN="bacalhau.local"
NETMASK="255.255.255.0"
GATEWAY="192.168.1.254"
BROADCAST="192.168.1.255"
NETWORK="192.168.1.0"

# CONSTANTES DHCP
RANGE="192.168.1.20 192.168.1.230"
NAMESERVERS="192.168.1.253, 8.8.8.8, 1.1.1.1"


verificacao_inicial() {
    script_path=$(readlink -f "$0")
    script_dir=$(dirname "$script_path")

    if [ "$script_dir" != "/home/scripts" ]; then
    echo -e "${RED}Este script precisa ser executado no diretorio /home/scripts.${RESET}"
    exit 1
    fi

    if [ $UID != 0 ]; then
    echo -e "${RED}Este script precisa ser executado como root.${RESET}"
    exit 1
    fi
}

configurar_dhcp() {
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
    echo -e "${RED}dhcpd.conf configurado.${RESET}"
}

configurar_default() {
    # Configura o arquivo default/isc-dhcp-server
    sed -i "s/INTERFACES=\"\"/INTERFACES=\"${INTERFACE_INTERNA}\"/" /etc/default/isc-dhcp-server
    echo -e "${RED}default/isc-dhcp-server configurado.${RESET}"
}

reiniciar_sistema() {
    # Reinicia o sistema
    echo -e "${RED}TROQUE PARA REDE INTERNA e pressione enter...${RESET}"
    read -n1 -s
    echo -e "${RED}O sistema sera reinicializado.${RESET}"
    sleep 5
    reboot
}

# MAIN
verificacao_inicial
configurar_dhcp
configurar_default
reiniciar_sistema