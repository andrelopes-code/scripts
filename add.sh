#!/bin/bash
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

instalar_dependencias() {
  # Instalando dependencias
  echo -e "${YELLOW}Instalando dependencias..."
  apt install build-essential libacl1-dev libattr1-dev libblkid-dev libgnutls-dev libreadline-dev python-dev libpam0g-dev python-dnspython gdb pkg-config libpopt-dev libldap2-dev dnsutils libbsd-dev docbook-xsl libcups2-dev nfs-kernel-server isc-dhcp-server 

  apt install samba samba-common smbclient cifs-utils samba-vfs-modules samba-testsuite samba-dbg samba-dsdb-modules cups cups-common cups-core-drivers nmap winbind smbclient libnss-winbind libpam-winbind 

  # Instalando kerberos
  apt install krb5-user krb5-config -y
}

renomear_arquivo_smb() {
  # Renomear o arquivo smb.conf
  mv /etc/samba/smb.conf /etc/samba/smb.conf.bkp
  echo -e "${GREEN}Arquivo samba.conf renomeado.${RESET}"
}

parar_servicos_necessarios() {
  # Parar servicos necessarios
  systemctl stop smbd nmbd winbind systemd_resolved > /dev/null
  systemctl disable smbd nmbd winbind systemd_resolved > /dev/null
  echo -e "${RED}Servicos [smbd nmbd winbind systemd_resolved] parados.${RESET}"
}

provisionar_dominio() {
  # Provisionando o dominio
  echo -e "${YELLOW}Preencha os campos...${RESET}"
  samba-tool domain provision --use-rfc2307 --use-xattr=yes --interactive
}

mover_arquivo_krb() {
  # Move arquivo do kerberos
  if [[ ! -f "/var/lib/samba/private/krb5.conf" ]]; then
    echo -e "${RED}krb5.conf não econtrado.${RESET}"
    exit 1
  fi
  mv /var/lib/samba/private/krb5.conf /etc/
  echo -e "${GREEN}krb5.conf movido.${RESET}"
}

# MAIN
instalar_dependencias
renomear_arquivo_smb
parar_servicos_necessarios
provisionar_dominio
mover_arquivo_krb
