#!/bin/bash
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

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
        echo -e "${RED}Atualizando o sistema...${RESET}"
        apt update > /dev/null && apt upgrade -y > /dev/null
        echo -e "${RED}Sistema atualizado.${RESET}"
        apt install isc-dhcp-server -y > /dev/null
        echo -e "${RED}Dependencias instaladas.${RESET}"


    # Modifica o arquivo hosts
        sed -i "s/127\.0\.1\.1\t.*/127.0.1.1\t${HOSTNAME}\n${IP_ADDRESS}\t${HOSTNAME}.${DOMAIN}\t${HOSTNAME}/" /etc/hosts
        echo -e "${RED}Arquivo HOSTS alterado.${RESET}"


    # Altera o hostname
        sed -i "s/.*/${HOSTNAME}/" /etc/hostname
        hostname -F /etc/hostname
        echo -e "${RED}HOSTNAME alterado.${RESET}"


    # Configura a interface de rede
        sed -i -e "10a \
        auto ${INTERFACE_INTERNA}\n\
        iface ${INTERFACE_INTERNA} inet static\n\
        address ${IP_ADDRESS}\n\
        netmask ${NETMASK}\n\
        gateway ${GATEWAY}\n\
        network ${NETWORK}\n\
        broadcast ${BROADCAST}\n" -e '11,$d' /etc/network/interfaces
        echo -e "${RED}Arquivo INTERFACES alterado.${RESET}"


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


    # Configura o arquivo default/isc-dhcp-server
        sed -i "s/INTERFACES=\"\"/INTERFACES=\"${INTERFACE_INTERNA}\"/" /etc/default/isc-dhcp-server
        echo -e "${RED}default/isc-dhcp-server configurado.${RESET}"


    # Reinicia o sistema
        echo -e "${RED}TROQUE PARA REDE INTERNA e pressione enter...${RESET}"
        read -n1 -s
        echo -e "${RED}O sistema sera reinicializado.${RESET}"
        sleep 5
        reboot
}


# MAIN
script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")
# Verifica se o diretório do script é /home/scripts.
if [ "$script_dir" != "/home/scripts" ]; then
  echo -e "${RED}Este script precisa ser executado no diretorio /home/scripts.${RESET}"
  exit 1
fi

# Verifica se foi executado com root
if [ $UID != 0 ]; then
  echo -e "${RED}Este script precisa ser executado como root.${RESET}"
  exit 1
fi

first