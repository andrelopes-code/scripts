#!/bin/bash
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# CONSTANTES
INTERFACE_INTERNA="enp0s8"
INTERFACE_EXTERNA="enp0s3"
HOSTNAME="srv-fw"
DOMAIN="magalu.local"
IP_ADDRESS="192.168.15.254"
NETMASK="255.255.255.15"
GATEWAY="192.168.15.254"
BROADCAST="192.168.15.255"
NETWORK="192.168.15.0"


first() {
    # Atualiza o sistema
        echo -e "${RED}Atualizando o sistema...${RESET}"
        apt update && apt upgrade -y > /dev/null
        echo -e "${RED}Sistema atualizado.${RESET}"
        apt install squid apache2 sarg -y > /dev/null
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


    # Cria a pasta cache do squid
        mkdir /etc/squid/cache
        chmod 777 /etc/squid/cache
        squid -z > /dev/null
        echo -e "${RED}Pasta [cache] criada.${RESET}"


    # Arquivo de inicialização do Firewall
        cp /home/scripts/docs/firewall.service /lib/systemd/system/firewall.service
        systemctl daemon-reload
        systemctl enable firewall.service
        echo -e "${RED}Criado serviço para o firewall.${RESET}"


    # Modifica o SARG
        mv /etc/sarg/sarg.conf /etc/sarg/sarg.conf.bk
        cp /home/scripts/docs/sarg.conf /etc/sarg/sarg.conf
        echo -e "${RED}Editado o arquivo [sarg.conf].${RESET}"


    # Reinicia o sistema
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