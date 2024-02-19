#!/bin/bash
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# CONSTANTES
INTERFACE_INTERNA="enp0s3"
HOSTNAME="srv-ad"
DOMAIN="dreconet.io"
DOMAINUP="DRECONET.IO"
IP_ADDRESS="192.168.0.253"
NETMASK="255.255.255.0"
GATEWAY="192.168.0.254"
BROADCAST="192.168.0.255"
NETWORK="192.168.0.0"
NAMESERVERS="${IP_ADDRESS} 8.8.8.8 1.1.1.1"


first() {
  # Atualiza o sistema
    echo -e "${YELLOW}Atualizando o sistema...${RESET}"
    apt update && apt upgrade -y > /dev/null
    echo -e "${GREEN}Sistema atualizado.${RESET}"
    
    # Instalando dependencias
      apt install build-essential libacl1-dev libattr1-dev libblkid-dev libgnutls-dev libreadline-dev python-dev libpam0g-dev python-dnspython gdb pkg-config libpopt-dev libldap2-dev dnsutils libbsd-dev docbook-xsl libcups2-dev nfs-kernel-server

      apt install samba samba-common smbclient cifs-utils samba-vfs-modules samba-testsuite samba-dbg samba-dsdb-modules cups cups-common cups-core-drivers nmap krb5-config winbind smbclient libnss-winbind libpam-winbind

    # Instalando kerberos
    apt install expect > /dev/null
    expect -c "
    spawn apt install krb5-user krb5-config -y
    expect \"Reino por omissão do Kerberos versão 5:\"
    send \"${DOMAINUP}\r\"
    expect \"Servidores Kerberos para seu realm:\"
    send \"${HOSTNAME}.${DOMAIN}\r\"
    expect \"Servidor administrativo para seu realm Kerberos:\"
    send \"${HOSTNAME}.${DOMAINUP}\r\"
    expect eof
    "

  echo -e "${YELLOW}Dependencias instaladas.${RESET}"


  # Modifica o arquivo hosts
    sed -i "s/127\.0\.1\.1\t.*/127.0.1.1\t${HOSTNAME}\n${IP_ADDRESS}\t${HOSTNAME}.${DOMAIN}\t${HOSTNAME}/" /etc/hosts
  echo -e "${YELLOW}Arquivo HOSTS alterado.${RESET}"


  # Altera o hostname
    sed -i "s/.*/${HOSTNAME}/" /etc/hostname
    hostname -F /etc/hostname
  echo -e "${YELLOW}HOSTNAME alterado.${RESET}"


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
    broadcast ${BROADCAST}\n\
    dns-nameservers ${NAMESERVERS}\n\
    dns-domain ${DOMAIN}\n\
    dns-search ${DOMAIN}" -e '11,$d' /etc/network/interfaces
    ifdown $INTERFACE_INTERNA && ifup $INTERFACE_INTERNA
  echo -e "${YELLOW}Arquivo INTERFACES alterado.${RESET}"


  # Renomear o arquivo smb.conf
  mv /etc/samba/smb.conf /etc/samba/smb.conf.bkp
  echo -e "${YELLOW}Arquivo samba.conf renomeado.${RESET}"


  # Parar serviços necessarios
  systemctl stop smbd nmbd winbind systemd_resolved
  systemctl disable smbd nmbd winbind systemd_resolved
  echo -e "${YELLOW}Serviços [smbd nmbd winbind systemd_resolved] parados.${RESET}"

  samba-tool domain provision --use-rfc2307 --use-xattr=yes --interactive

  # Move arquivo do kerberos
  mv /var/lib/samba/private/krb5.conf /etc/
  echo -e "${YELLOW}krb5.conf movido.${RESET}"

  # Iniciando e ativando samba-ad-dc
  systemctl unmask samba-ad-dc
	systemctl start samba-ad-dc
	systemctl enable samba-ad-dc
  echo -e "${YELLOW}samba-ad-dc ativado.${RESET}"
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