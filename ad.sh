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
    echo -e "${YELLOW}Atualizando o sistema..."
    apt update > /dev/null
    apt upgrade -y > /dev/null
    echo -e "${GREEN}Sistema atualizado.${RESET}"
    
    # Instalando dependencias
      echo -e "${YELLOW}Instalando dependencias..."
      apt install build-essential libacl1-dev libattr1-dev libblkid-dev libgnutls-dev libreadline-dev python-dev libpam0g-dev python-dnspython gdb pkg-config libpopt-dev libldap2-dev dnsutils libbsd-dev docbook-xsl libcups2-dev nfs-kernel-server -y > /dev/null

      apt install samba samba-common smbclient cifs-utils samba-vfs-modules samba-testsuite samba-dbg samba-dsdb-modules cups cups-common cups-core-drivers nmap winbind smbclient libnss-winbind libpam-winbind -y > /dev/null

    # Instalando kerberos
    apt install expect -y > /dev/null
    expect -c "
    spawn apt install krb5-user krb5-config -y
    expect \"Reino por omissão do Kerberos versão 5:\"
    send \"${DOMAINUP}\r\"
    expect \"Servidores Kerberos para seu realm:\"
    send \"${HOSTNAME}.${DOMAIN}\r\"
    expect \"Servidor administrativo para seu realm Kerberos:\"
    send \"${HOSTNAME}.${DOMAINUP}\r\"
    expect eof
    " > /dev/null

  echo -e "${GREEN}Dependencias instaladas.${RESET}"


  # Modifica o arquivo hosts
    sed -i "s/127\.0\.1\.1\t.*/127.0.1.1\t${HOSTNAME}\n${IP_ADDRESS}\t${HOSTNAME}.${DOMAIN}\t${HOSTNAME}/" /etc/hosts
  echo -e "${GREEN}Arquivo HOSTS alterado.${RESET}"


  # Altera o hostname
    sed -i "s/.*/${HOSTNAME}/" /etc/hostname
    hostname -F /etc/hostname 
  echo -e "${GREEN}HOSTNAME alterado.${RESET}"


  # Configura a interface de rede
    sed -i -e "10a \
    auto ${INTERFACE_INTERNA}\n\
    iface ${INTERFACE_INTERNA} inet static\n\
    address ${IP_ADDRESS}\n\
    netmask ${NETMASK}\n\
    network ${NETWORK}\n\
    broadcast ${BROADCAST}\n\
    dns-nameservers ${NAMESERVERS}\n\
    dns-domain ${DOMAIN}\n\
    dns-search ${DOMAIN}" -e '11,$d' /etc/network/interfaces
    ifdown $INTERFACE_INTERNA > /dev/null
    ifup $INTERFACE_INTERNA > /dev/null
  echo -e "${GREEN}Arquivo INTERFACES alterado.${RESET}"


  # Renomear o arquivo smb.conf
  mv /etc/samba/smb.conf /etc/samba/smb.conf.bkp
  echo -e "${GREEN}Arquivo samba.conf renomeado.${RESET}"


  # Parar servicos necessarios
  systemctl stop smbd nmbd winbind systemd_resolved > /dev/null
  systemctl disable smbd nmbd winbind systemd_resolved > /dev/null
  echo -e "${RED}Servicos [smbd nmbd winbind systemd_resolved] parados.${RESET}"

  # Provisionando o dominio
  echo -e "${YELLOW}Preencha os campos...${RESET}"
  samba-tool domain provision --use-rfc2307 --use-xattr=yes --interactive

  # Move arquivo do kerberos
  mv /var/lib/samba/private/krb5.conf /etc/
  echo -e "${GREEN}krb5.conf movido.${RESET}"

  # Iniciando e ativando samba-ad-dc
  systemctl unmask samba-ad-dc > /dev/null
	systemctl start samba-ad-dc > /dev/null
	systemctl enable samba-ad-dc > /dev/null
  echo -e "${GREEN}samba-ad-dc ativado.${RESET}"
  echo -e "${RED}Reiniciando sistema...${RESET}"
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