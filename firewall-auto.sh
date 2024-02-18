#!/bin/bash
vermelho="\033[0;31m"
reset="\033[0m"

# CONSTANTES
INTERFACE_INTERNA="enp0s8"
INTERFACE_EXTERNA="enp0s3"
HOSTNAME="srv-fw"
DOMAIN="dreconet.io"
IP_ADDRESS="192.168.0.254"
NETMASK="255.255.255.0"
GATEWAY="192.168.0.254"
BROADCAST="192.168.0.255"
NETWORK="192.168.0.0"

first() {
    # Atualiza o sistema
    echo -e "${vermelho}Atualizando o sistema...${reset}"
    sudo apt update && sudo apt upgrade -y
    echo -e "${vermelho}Sistema atualizado.${reset}"
    sudo apt install squid apache2 sarg -y
    echo -e "${vermelho}Dependencias instaladas.${reset}"


    # Altera o hostname
    sudo sed -i "s/.*/${HOSTNAME}/" /etc/hostname
    sudo hostname -F /etc/hostname
    echo -e "${vermelho}HOSTNAME alterado.${reset}"

    # Modifica o arquivo hosts
    sudo sed -i "s/127\.0\.1\.1\t.*/127.0.1.1\t${HOSTNAME}\n${IP_ADDRESS}\t${HOSTNAME}.${DOMAIN}\t${HOSTNAME}/" /etc/hosts
    echo -e "${vermelho}Arquivo HOSTS alterado.${reset}"

    # Configura a interface de rede
    sudo sed -i -e "10a \
    # Interface Externa\n\
    auto ${INTERFACE_EXTERNA}\n\
    iface ${INTERFACE_EXTERNA} inet dhcp\n\
    \n\
    # Interface Interna\n\
    auto ${INTERFACE_INTERNA}\n\
    iface ${INTERFACE_INTERNA} inet static\n\
    address ${IP_ADDRESS}\n\
    netmask ${NETMASK}\n\
    network ${NETWORK}\n\
    broadcast ${BROADCAST}\n" -e '11,$d' /etc/network/interfaces
    echo -e "${vermelho}Arquivo INTERFACES alterado.${reset}"

    # Copia os arquivos
    cp /home/scripts/docs/firewall /usr/local/sbin/firewall
    cp /home/scripts/docs/sqd /usr/local/sbin/sqd
    cp /usr/share/squid/errors/pt-br/ERR_ACCESS_DENIED /usr/share/squid/errors/pt-br/ERR_ACCESS_DENIED.bk
    cp /home/scripts/docs/HTML.html /usr/share/squid/errors/pt-br/ERR_ACCESS_DENIED
    cp /home/scripts/docs/squid.conf /etc/squid/squid.conf
    cp /home/scripts/docs/files /etc/squid/

    # Cria a pasta cache do squid
    mkdir /etc/squid/cache
    chmod 777 /etc/squid/cache
    sudo squid -z

    # Arquivo de inicialização do Firewall
    cp /home/scripts/docs/firewall.service /lib/systemd/system/firewall.service
    systemctl daemon-reload
    systemctl enable firewall.service









    # Reinicia o sistema
    echo -e "${vermelho}se as interfaces estão configuradas, pressione enter...${reset}"
    read -n1 -s
    echo -e "${vermelho}O sistema será reinicializado.${reset}"
    echo -e "${vermelho}logo após execute a segunda parte do script com o parametro 'af'${reset}"
    sleep 5
    reboot
}

first