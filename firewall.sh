#!/bin/bash
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# CONSTANTES
INTERFACE_INTERNA="enp0s8"
INTERFACE_EXTERNA="enp0s3"
HOSTNAME="srv-fw"
DOMAIN="bacalhau.local"
IP_ADDRESS="192.168.1.254"
NETMASK="255.255.255.0"
GATEWAY="192.168.1.254"
BROADCAST="192.168.1.255"
NETWORK="192.168.1.0"

#------------------------------------------------------------------------------#

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

atualizar_sistema() {
    # Atualiza o sistema
    echo -e "${RED}Atualizando o sistema...${RESET}"
    apt update && apt upgrade -y > /dev/null
    echo -e "${RED}Sistema atualizado.${RESET}"
    apt install squid apache2 sarg -y > /dev/null
    echo -e "${RED}Dependencias instaladas.${RESET}"
}

alterar_hosts() {
    # Modifica o arquivo hosts
    sed -i "s/127\.0\.1\.1\t.*/127.0.1.1\t${HOSTNAME}\n${IP_ADDRESS}\t${HOSTNAME}.${DOMAIN}\t${HOSTNAME}/" /etc/hosts
    echo -e "${RED}Arquivo HOSTS alterado.${RESET}"
}

alterar_hostname() {
    # Altera o hostname
    sed -i "s/.*/${HOSTNAME}/" /etc/hostname
    hostname -F /etc/hostname
    echo -e "${RED}HOSTNAME alterado.${RESET}"
}

configurar_interface_de_rede() {
    # Configura a interface de rede
    sed -i -e "10a \
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
    echo -e "${RED}Arquivo INTERFACES alterado.${RESET}"
}

copiar_arquivos() {
    # Copia os arquivos
    cp /home/scripts/docs/firewall /usr/local/sbin/firewall
    chmod +x /usr/local/sbin/firewall
    echo -e "${RED}Arquivo [firewall] copiado.${RESET}"

    cp /home/scripts/docs/sqd /usr/local/sbin/sqd
    chmod +x /usr/local/sbin/sqd
    echo -e "${RED}Arquivo [sqd] copiado.${RESET}"

    cp /usr/share/squid/errors/pt-br/ERR_ACCESS_DENIED /usr/share/squid/errors/pt-br/ERR_ACCESS_DENIED.bk
    cp /home/scripts/docs/HTML.html /usr/share/squid/errors/pt-br/ERR_ACCESS_DENIED
    echo -e "${RED}Arquivo [ERR_ACCESS_DENIED] copiado.${RESET}"

    cp /home/scripts/docs/squid.conf /etc/squid/squid.conf
    echo -e "${RED}Arquivo [squid.conf] copiado.${RESET}"

    cp -r /home/scripts/docs/files /etc/squid
    echo -e "${RED}Pasta [files] copiada.${RESET}"
}

pasta_cache_squid() {
    # Cria a pasta cache do squid
    mkdir /etc/squid/cache
    chmod 777 /etc/squid/cache
    squid -z > /dev/null
    echo -e "${RED}Pasta [cache] criada.${RESET}"
}

inicializacao_firewall() {
    # Arquivo de inicialização do Firewall
    cp /home/scripts/docs/firewall.service /lib/systemd/system/firewall.service
    systemctl daemon-reload
    systemctl enable firewall.service
    echo -e "${RED}Criado serviço para o firewall.${RESET}"
}

modificar_sarg() {
    # Modifica o SARG
    mv /etc/sarg/sarg.conf /etc/sarg/sarg.conf.bk
    cp /home/scripts/docs/sarg.conf /etc/sarg/sarg.conf
    echo -e "${RED}Editado o arquivo [sarg.conf].${RESET}"
}

reiniciar_sistema() {
    # Reinicia o sistema
    echo -e "${RED}pressione qualquer tecla...${RESET}"
    read -n1 -s
    echo -e "${RED}O sistema sera reinicializado.${RESET}"
    sleep 5
    reboot
}

# MAIN
verificacao_inicial
atualizar_sistema
alterar_hosts
alterar_hostname
configurar_interface_de_rede
copiar_arquivos
pasta_cache_squid
inicializacao_firewall
modificar_sarg
reiniciar_sistema